import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_premium_atoms.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_premium_theme.dart';

/// Validated payload returned by [showWarehouseFormDialog].
class WarehouseFormResult {
  const WarehouseFormResult({
    required this.name,
    required this.location,
    required this.capacity,
  });

  final String name;
  final String location;
  final num capacity;
}

/// Premium create / edit dialog for a warehouse.
///
/// Returns `null` when dismissed, otherwise a validated [WarehouseFormResult].
Future<WarehouseFormResult?> showWarehouseFormDialog({
  required BuildContext context,
  Warehouse? existing,
}) {
  return showDialog<WarehouseFormResult>(
    context: context,
    barrierColor: WarehousePalette.of(context).isDark
        ? Colors.black.withValues(alpha: 0.66)
        : const Color(0xFF0F172A).withValues(alpha: 0.42),
    builder: (_) => _WarehouseFormDialog(existing: existing),
  );
}

class _WarehouseFormDialog extends StatefulWidget {
  const _WarehouseFormDialog({this.existing});

  final Warehouse? existing;

  @override
  State<_WarehouseFormDialog> createState() => _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends State<_WarehouseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _capacityController = TextEditingController(
      text: existing != null ? '${existing.capacity}' : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      WarehouseFormResult(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        capacity: num.tryParse(_capacityController.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final isEdit = widget.existing != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          border: palette.glassBorder(),
          boxShadow: palette.cardShadow,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    WarehouseGlowBadge(
                      icon: isEdit
                          ? Icons.edit_rounded
                          : Icons.add_business_rounded,
                      color: palette.brand,
                      size: 42,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Warehouse' : 'New Warehouse',
                            style:
                                WmsDesignTokens.sectionTitle(context).copyWith(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEdit
                                ? 'Update facility details'
                                : 'Add a facility to your network',
                            style: WmsDesignTokens.supporting(context).copyWith(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _FormField(
                  controller: _nameController,
                  label: 'Warehouse Name',
                  hint: 'e.g. Bakaaro',
                  icon: Icons.warehouse_rounded,
                  accent: palette.accentBlue,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _FormField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'e.g. Mogadishu',
                  icon: Icons.place_rounded,
                  accent: palette.accentTeal,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                _FormField(
                  controller: _capacityController,
                  label: 'Capacity (units)',
                  hint: 'e.g. 10000',
                  icon: Icons.speed_rounded,
                  accent: palette.accentViolet,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Capacity is required';
                    final parsed = num.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a capacity above zero';
                    }
                    return null;
                  },
                ),
                if (isEdit && widget.existing!.assignedStaff.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'ASSIGNED STAFF',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textTertiary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final staff in widget.existing!.assignedStaff)
                        WarehouseTonePill(
                          label: staff.displayName,
                          color: palette.accentViolet,
                          icon: Icons.person_rounded,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          foregroundColor: colors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: WmsDesignTokens.buttonLabel(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: WarehouseGradientButton(
                        icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
                        label: isEdit ? 'Save Changes' : 'Create Warehouse',
                        onPressed: _submit,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accent,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accent;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(WarehousePalette.radiusControl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: WmsDesignTokens.supportingDense(context).copyWith(
            color: colors.textTertiary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          cursorColor: accent,
          style: WmsDesignTokens.body(context).copyWith(
            color: colors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WmsDesignTokens.body(context).copyWith(
              color: colors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, size: 18, color: accent),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            filled: true,
            fillColor: palette.insetFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: palette.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: palette.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: accent, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: colors.error, width: 1.6),
            ),
            errorStyle: WmsDesignTokens.supportingDense(context).copyWith(
              color: colors.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
