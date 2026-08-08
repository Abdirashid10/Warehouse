import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/config/api_config.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/products/domain/entities/create_product_input.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/presentation/cubit/products_catalog_cubit.dart';

Future<void> showProductFormSheet(
  BuildContext context, {
  required ProductsCatalogCubit cubit,
  required List<ProductCategory> categories,
  Product? existing,
}) async {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final successColor = context.wms.success;

  var initialSku = existing?.sku ?? '';
  if (existing == null) {
    final categoryId = categories.firstOrNull?.id ?? '';
    if (categoryId.isNotEmpty) {
      try {
        initialSku = await cubit.previewSku(categoryId);
      } catch (_) {
        initialSku = '';
      }
    }
  }

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (sheetContext) => _ProductFormSheet(
      cubit: cubit,
      categories: categories,
      existing: existing,
      initialSkuPreview: initialSku,
      onSuccess: (message) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: successColor,
          ),
        );
      },
    ),
  );
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({
    required this.cubit,
    required this.categories,
    required this.existing,
    required this.initialSkuPreview,
    required this.onSuccess,
  });

  final ProductsCatalogCubit cubit;
  final List<ProductCategory> categories;
  final Product? existing;
  final String initialSkuPreview;
  final void Function(String message) onSuccess;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _newCategoryCtrl;

  late List<ProductCategory> _categoryList;
  late String _categoryId;
  late String _skuPreview;

  var _loadingSku = false;
  var _saving = false;
  var _creatingCategory = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _barcodeCtrl = TextEditingController(text: existing?.barcode ?? '');
    _costCtrl = TextEditingController(text: existing?.unitCost?.toString() ?? '');
    _priceCtrl = TextEditingController(text: existing?.unitPrice?.toString() ?? '');
    _minCtrl = TextEditingController(text: existing?.minStockThreshold?.toString() ?? '0');
    _newCategoryCtrl = TextEditingController();
    _categoryList = List<ProductCategory>.from(widget.categories);
    _categoryId = existing?.categoryId ?? _categoryList.firstOrNull?.id ?? '';
    _skuPreview = widget.initialSkuPreview;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _barcodeCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _minCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  void _setSheetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadSku(String catId) async {
    if (_isEdit || catId.isEmpty) return;
    _setSheetState(() => _loadingSku = true);
    try {
      final sku = await widget.cubit.previewSku(catId);
      _setSheetState(() => _skuPreview = sku);
    } catch (_) {
      _setSheetState(() => _skuPreview = '');
    } finally {
      _setSheetState(() => _loadingSku = false);
    }
  }

  Future<void> _addCategory() async {
    final name = _newCategoryCtrl.text.trim();
    if (name.isEmpty) {
      _setSheetState(() => _error = 'Enter a category name.');
      return;
    }
    _setSheetState(() {
      _creatingCategory = true;
      _error = null;
    });
    try {
      final cat = await widget.cubit.createCategory(name);
      if (!mounted) return;
      _setSheetState(() {
        _categoryList = [..._categoryList, cat]
          ..sort((a, b) => a.name.compareTo(b.name));
        _categoryId = cat.id;
      });
      _newCategoryCtrl.clear();
      await _loadSku(cat.id);
    } on ApiException catch (e) {
      _setSheetState(() => _error = ErrorMessageMapper.fromApiException(e));
    } catch (_) {
      _setSheetState(() => _error = 'Could not create category.');
    } finally {
      _setSheetState(() => _creatingCategory = false);
    }
  }

  Future<void> _submit() async {
    if (_categoryId.isEmpty) {
      _setSheetState(() => _error = 'Select or create a category first.');
      return;
    }
    final cost = num.tryParse(_costCtrl.text.trim());
    final price = num.tryParse(_priceCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty) {
      _setSheetState(() => _error = 'Product name is required.');
      return;
    }
    if (cost == null || cost < 0) {
      _setSheetState(() => _error = 'Enter a valid unit cost.');
      return;
    }
    if (price == null || price < 0) {
      _setSheetState(() => _error = 'Enter a valid unit price.');
      return;
    }

    _setSheetState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEdit) {
        await widget.cubit.updateProduct(
          widget.existing!.id,
          UpdateProductInput(
            name: _nameCtrl.text.trim(),
            categoryId: _categoryId,
            unitCost: cost,
            unitPrice: price,
            description: _descCtrl.text.trim(),
            barcode: _barcodeCtrl.text.trim(),
            minStockThreshold: num.tryParse(_minCtrl.text.trim()) ?? 0,
          ),
        );
      } else {
        await widget.cubit.createProduct(
          CreateProductInput(
            name: _nameCtrl.text.trim(),
            categoryId: _categoryId,
            unitCost: cost,
            unitPrice: price,
            description: _descCtrl.text.trim(),
            barcode: _barcodeCtrl.text.trim(),
            minStockThreshold: num.tryParse(_minCtrl.text.trim()) ?? 0,
          ),
        );
      }

      if (!mounted) return;

      final message =
          _isEdit ? 'Product updated.' : 'Product created successfully.';
      Navigator.of(context).pop();
      widget.onSuccess(message);
    } on ApiException catch (e) {
      _setSheetState(() {
        _saving = false;
        _error = ErrorMessageMapper.fromApiException(e);
      });
    } catch (_) {
      _setSheetState(() {
        _saving = false;
        _error = 'Could not save product. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Product' : 'Add Product',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (!_isEdit)
              Text(
                _loadingSku
                    ? 'Generating SKU…'
                    : 'SKU: ${_skuPreview.isEmpty ? '—' : _skuPreview}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.wms.textSecondary,
                    ),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product name *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_categoryList.isEmpty) ...[
              const Text(
                'No categories yet. Create one to register products.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCategoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'New category name',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _creatingCategory ? null : _addCategory,
                    child: _creatingCategory
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add'),
                  ),
                ],
              ),
            ] else
              DropdownButtonFormField<String>(
                key: ValueKey(_categoryId),
                initialValue: _categoryId.isEmpty ? null : _categoryId,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: [
                  for (final c in _categoryList)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _setSheetState(() => _categoryId = v);
                  _loadSku(v);
                },
              ),
            if (_categoryList.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Add new category',
                  style: TextStyle(fontSize: 14),
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCategoryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Category name',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _creatingCategory ? null : _addCategory,
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _barcodeCtrl,
              decoration: const InputDecoration(labelText: 'Barcode'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Unit cost *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Unit price *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _minCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min stock threshold'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: context.wms.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEdit ? Icons.save_outlined : Icons.add),
              label: Text(_isEdit ? 'Save changes' : 'Create product'),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

String resolveProductImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api$'), '');
  return '$base${path.startsWith('/') ? path : '/$path'}';
}

void showProductDetailSheet(BuildContext context, Product product) {
  if (!context.mounted) return;
  final colors = WmsUiColors.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (context) => _ProductDetailBody(product: product),
  );
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final imageUrl = resolveProductImageUrl(product.imageUrl);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: colors.textTertiary,
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                    ),
                    Text(
                      'SKU ${product.sku}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _detailRow(context, 'Category', product.category ?? '—'),
          _detailRow(
            context,
            'Barcode',
            product.barcode?.isNotEmpty == true ? product.barcode! : '—',
          ),
          _detailRow(
            context,
            'Unit cost',
            WmsFormatters.currency(product.unitCost),
          ),
          _detailRow(
            context,
            'Unit price',
            WmsFormatters.currency(product.unitPrice),
          ),
          _detailRow(
            context,
            'Stock',
            WmsFormatters.quantity(product.totalStock),
          ),
          _detailRow(context, 'Warehouses', '${product.warehouseCount ?? 0}'),
          _detailRow(context, 'Status', product.stockStatusLabel),
          _detailRow(
            context,
            'Updated',
            product.updatedAt != null
                ? WmsFormatters.relativeTime(product.updatedAt)
                : '—',
          ),
        ],
      ),
    );
  }
}

Widget _detailRow(BuildContext context, String label, String value) {
  final colors = WmsUiColors.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(color: colors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      ],
    ),
  );
}
