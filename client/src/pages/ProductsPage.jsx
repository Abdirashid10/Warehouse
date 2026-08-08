import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { ProductImage } from '../components/products/ProductImage';
import { ProductImageField } from '../components/products/ProductImageField';
import { formatMoney } from '../utils/productHelpers';
import { fetchNextSkuForCategory } from '../utils/skuHelpers';
import {
  resolveProductImageUrl,
  uploadProductImageFile,
  validateProductImageFile,
} from '../utils/productImage';
import {
  AlertTriangle,
  Archive,
  ArrowUpDown,
  BarChart3,
  Boxes,
  ChevronDown,
  ChevronRight,
  DollarSign,
  Filter,
  Layers,
  Package,
  Pencil,
  Plus,
  Search,
  ShieldAlert,
  Tag,
  Trash2,
  Warehouse,
  X,
} from 'lucide-react';

/* ─── API ─── */

async function fetchProducts(q) {
  const { data } = await api.get('/products', { params: q ? { q } : {} });
  return data;
}

async function fetchCategories() {
  const { data } = await api.get('/categories');
  return data;
}

const emptyForm = {
  sku: '',
  name: '',
  description: '',
  category_id: '',
  barcode: '',
  image_url: '',
  unit_cost: '',
  unit_price: '',
  min_stock_threshold: '0',
};

/* ─── Helpers ─── */

function stockStatusBadge(product) {
  const stock = product.total_stock ?? 0;
  const minStock = product.min_stock_threshold ?? 0;
  const whCount = product.warehouse_count ?? 0;

  if (whCount === 0 && stock === 0) return { label: 'No Inventory', color: 'bg-slate-100 text-slate-600 dark:bg-slate-500/20 dark:text-slate-400' };
  if (stock === 0) return { label: 'Out Of Stock', color: 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-300' };
  if (stock > 0 && stock <= minStock) return { label: 'Low Stock', color: 'bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-300' };
  return { label: 'In Stock', color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-300' };
}

function timeAgo(dateStr) {
  if (!dateStr) return '—';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(dateStr).toLocaleDateString();
}

/* ═══════════════════════════════════════════════════════════════
   Main Component
   ═══════════════════════════════════════════════════════════════ */

export function ProductsPage() {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const canManage = user?.role === 'Admin' || user?.role === 'Supervisor';

  const [search, setSearch] = useState('');
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [formError, setFormError] = useState('');
  const [imageError, setImageError] = useState('');
  const [pendingImageFile, setPendingImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [expandedRow, setExpandedRow] = useState(null);
  const [sortField, setSortField] = useState('sku');
  const [sortDir, setSortDir] = useState('asc');
  const [filterCategory, setFilterCategory] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [skuLoading, setSkuLoading] = useState(false);

  useEffect(() => {
    return () => {
      if (imagePreview?.startsWith('blob:')) URL.revokeObjectURL(imagePreview);
    };
  }, [imagePreview]);

  useEffect(() => {
    if (modal?.mode !== 'create' || !form.category_id) {
      if (modal?.mode === 'create' && !form.category_id) {
        setForm((f) => (f.sku ? { ...f, sku: '' } : f));
      }
      return undefined;
    }

    let cancelled = false;
    setSkuLoading(true);
    fetchNextSkuForCategory(form.category_id)
      .then(({ sku }) => {
        if (!cancelled) setForm((f) => ({ ...f, sku }));
      })
      .catch(() => {
        if (!cancelled) setForm((f) => ({ ...f, sku: '' }));
      })
      .finally(() => {
        if (!cancelled) setSkuLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [modal?.mode, form.category_id]);

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['products', search],
    queryFn: () => fetchProducts(search),
  });

  const { data: catData } = useQuery({
    queryKey: ['categories'],
    queryFn: fetchCategories,
  });

  const categories = catData?.categories || [];
  const products = data?.products || [];
  const summary = data?.summary || {};

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['products'] });
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
    queryClient.invalidateQueries({ queryKey: ['inventory', 'tracking'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
  };

  const createCategoryMutation = useMutation({
    mutationFn: (name) => api.post('/categories', { name }),
    onSuccess: (res) => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      const id = res.data?.category?.id;
      if (id) setForm((f) => ({ ...f, category_id: id }));
      setNewCategoryName('');
    },
  });

  const saveMutation = useMutation({
    mutationFn: ({ id, body }) => (id ? api.patch(`/products/${id}`, body) : api.post('/products', body)),
    onSuccess: () => {
      invalidate();
      setModal(null);
      setForm(emptyForm);
      resetImageState();
      setFormError('');
    },
    onError: (err) => setFormError(err.response?.data?.message || err.message || 'Save failed'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/products/${id}`),
    onSuccess: () => { invalidate(); setDeleteTarget(null); },
    onError: (err) => setFormError(err.response?.data?.message || err.message || 'Delete failed'),
  });

  function resetImageState() {
    if (imagePreview?.startsWith('blob:')) URL.revokeObjectURL(imagePreview);
    setPendingImageFile(null);
    setImagePreview(null);
    setImageError('');
  }

  function openCreate() {
    setFormError('');
    resetImageState();
    setForm({ ...emptyForm, category_id: categories[0]?.id || '' });
    setModal({ mode: 'create' });
  }

  function openEdit(p) {
    setFormError('');
    resetImageState();
    const existing = resolveProductImageUrl(p.image_url);
    setForm({
      sku: p.sku, name: p.name, description: p.description || '',
      category_id: p.category_id || '', barcode: p.barcode || '',
      image_url: existing || '', unit_cost: String(p.unit_cost ?? ''),
      unit_price: String(p.unit_price ?? ''), min_stock_threshold: String(p.min_stock_threshold ?? 0),
    });
    setImagePreview(existing);
    setModal({ mode: 'edit', id: p.id, product: p });
  }

  function handleImagePick(file) {
    try {
      validateProductImageFile(file);
      if (imagePreview?.startsWith('blob:')) URL.revokeObjectURL(imagePreview);
      setPendingImageFile(file);
      setImagePreview(URL.createObjectURL(file));
      setImageError('');
    } catch (err) { setImageError(err.message); }
  }

  function handleImageRemove() {
    resetImageState();
    setForm((f) => ({ ...f, image_url: '' }));
  }

  async function submitForm(e) {
    e.preventDefault();
    setFormError('');
    setImageError('');
    if (!form.category_id) { setFormError('Select a category.'); return; }
    let image_url = form.image_url.trim();
    try {
      if (pendingImageFile) image_url = await uploadProductImageFile(pendingImageFile);
    } catch (err) { setImageError(err.response?.data?.message || err.message || 'Image upload failed'); return; }
    const body = {
      name: form.name.trim(),
      description: form.description,
      category_id: form.category_id,
      barcode: form.barcode.trim(),
      image_url: image_url || '',
      unit_cost: Number(form.unit_cost),
      unit_price: Number(form.unit_price),
      min_stock_threshold: Number(form.min_stock_threshold) || 0,
    };
    if (modal?.mode === 'create' && !form.category_id) {
      setFormError('Select a category to generate a SKU.');
      return;
    }
    saveMutation.mutate({ id: modal?.mode === 'edit' ? modal.id : null, body });
  }

  /* ── Sorting ── */
  const handleSort = useCallback((field) => {
    setSortDir((d) => (sortField === field ? (d === 'asc' ? 'desc' : 'asc') : 'asc'));
    setSortField(field);
  }, [sortField]);

  /* ── Filtered + Sorted products ── */
  const displayProducts = useMemo(() => {
    let list = [...products];

    if (filterCategory) list = list.filter((p) => p.category_id === filterCategory);
    if (filterStatus) {
      list = list.filter((p) => {
        const s = stockStatusBadge(p).label;
        return s === filterStatus;
      });
    }

    list.sort((a, b) => {
      let va, vb;
      switch (sortField) {
        case 'name': va = a.name?.toLowerCase() || ''; vb = b.name?.toLowerCase() || ''; break;
        case 'price': va = a.unit_price || 0; vb = b.unit_price || 0; break;
        case 'stock': va = a.total_stock || 0; vb = b.total_stock || 0; break;
        case 'updated': va = a.updated_at || ''; vb = b.updated_at || ''; break;
        default: va = a.sku?.toLowerCase() || ''; vb = b.sku?.toLowerCase() || '';
      }
      if (va < vb) return sortDir === 'asc' ? -1 : 1;
      if (va > vb) return sortDir === 'asc' ? 1 : -1;
      return 0;
    });

    return list;
  }, [products, filterCategory, filterStatus, sortField, sortDir]);

  const activeFilterCount = [filterCategory, filterStatus].filter(Boolean).length;

  /* ─── KPI data ─── */
  const kpis = useMemo(() => [
    { label: 'Active Products', value: summary.total ?? products.length, icon: Package, color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-500/10' },
    { label: 'Categories', value: summary.categories ?? categories.length, icon: Layers, color: 'text-violet-600 dark:text-violet-400', bg: 'bg-violet-50 dark:bg-violet-500/10' },
    { label: 'Low Stock', value: summary.low_stock ?? 0, icon: AlertTriangle, color: 'text-amber-600 dark:text-amber-400', bg: 'bg-amber-50 dark:bg-amber-500/10', click: () => setFilterStatus('Low Stock') },
    { label: 'Out Of Stock', value: summary.out_of_stock ?? 0, icon: ShieldAlert, color: 'text-red-600 dark:text-red-400', bg: 'bg-red-50 dark:bg-red-500/10', click: () => setFilterStatus('Out Of Stock') },
    { label: 'Expiring', value: summary.expiring ?? 0, icon: Archive, color: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-500/10' },
    { label: 'Catalog Value', value: formatMoney(summary.total_value ?? 0), icon: DollarSign, color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10' },
  ], [summary, products, categories]);

  return (
    <div className="space-y-5">

      {/* ── Header ── */}
      <div className="border-b border-border pb-4">
        <div className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
          <Boxes className="h-3 w-3 text-accent" />
          Master Data
          <ChevronRight className="h-3 w-3 text-muted-foreground/50" />
          <span className="text-foreground">Products</span>
        </div>
        <div className="mt-2.5 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 className="text-xl font-semibold tracking-tight text-foreground">Products</h1>
            <p className="mt-1 text-xs text-muted-foreground">
              Centralized product master data with inventory intelligence and warehouse stock visibility.
            </p>
          </div>
          {canManage && (
            <button type="button" onClick={openCreate}
              className="inline-flex items-center gap-1.5 rounded-lg bg-accent px-3.5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-accent/90">
              <Plus className="h-3.5 w-3.5" /> Add Product
            </button>
          )}
        </div>
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-6">
        {kpis.map((k) => (
          <button key={k.label} type="button" onClick={k.click || undefined}
            className={`group flex items-center gap-3 rounded-xl border border-border bg-card px-3.5 py-3 text-left transition hover:shadow-md ${k.click ? 'cursor-pointer' : 'cursor-default'}`}>
            <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${k.bg}`}>
              <k.icon className={`h-4 w-4 ${k.color}`} />
            </div>
            <div className="min-w-0">
              <p className="text-[10px] font-medium uppercase tracking-wider text-muted-foreground">{k.label}</p>
              <p className="mt-0.5 truncate text-lg font-bold tabular-nums text-foreground">{k.value}</p>
            </div>
          </button>
        ))}
      </div>

      {/* ── Search + Filters ── */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[220px] max-w-md">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="search" value={search} onChange={(e) => setSearch(e.target.value)}
            placeholder="Search SKU, name, barcode…"
            className="h-9 w-full rounded-lg border border-border bg-card pl-9 pr-3 text-sm text-foreground placeholder:text-muted-foreground focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent/30" />
        </div>
        <button type="button" onClick={() => setShowFilters((v) => !v)}
          className={`inline-flex items-center gap-1.5 rounded-lg border px-3 py-2 text-xs font-medium transition ${showFilters || activeFilterCount > 0 ? 'border-accent/40 bg-accent/5 text-accent' : 'border-border bg-card text-muted-foreground hover:text-foreground'}`}>
          <Filter className="h-3 w-3" />
          Filters
          {activeFilterCount > 0 && <span className="ml-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-accent text-[9px] font-bold text-white">{activeFilterCount}</span>}
        </button>
        {activeFilterCount > 0 && (
          <button type="button" onClick={() => { setFilterCategory(''); setFilterStatus(''); }}
            className="text-[11px] font-medium text-accent hover:underline">Clear all</button>
        )}
        <div className="ml-auto text-[11px] text-muted-foreground">
          <span className="font-semibold tabular-nums text-foreground">{displayProducts.length}</span> of {products.length} products
        </div>
      </div>

      {showFilters && (
        <div className="flex flex-wrap items-center gap-3 rounded-lg border border-border bg-muted/30 px-4 py-3">
          <div className="flex items-center gap-2">
            <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Category</label>
            <select value={filterCategory} onChange={(e) => setFilterCategory(e.target.value)}
              className="h-8 rounded-md border border-border bg-card px-2 text-xs text-foreground">
              <option value="">All</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div className="flex items-center gap-2">
            <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Stock Status</label>
            <select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}
              className="h-8 rounded-md border border-border bg-card px-2 text-xs text-foreground">
              <option value="">All</option>
              <option value="In Stock">In Stock</option>
              <option value="Low Stock">Low Stock</option>
              <option value="Out Of Stock">Out Of Stock</option>
              <option value="No Inventory">No Inventory</option>
            </select>
          </div>
        </div>
      )}

      {/* ── Table ── */}
      {isLoading ? (
        <div className="space-y-2">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-14 animate-pulse rounded-lg bg-muted/50" />
          ))}
        </div>
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
          {error?.response?.data?.message || 'Failed to load products.'}
        </div>
      ) : displayProducts.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-border bg-muted/20 py-16">
          <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-muted">
            <Package className="h-7 w-7 text-muted-foreground" />
          </div>
          <p className="mt-4 text-sm font-semibold text-foreground">
            {products.length === 0 ? 'No products in catalog' : 'No products match filters'}
          </p>
          <p className="mt-1 max-w-xs text-center text-xs text-muted-foreground">
            {products.length === 0
              ? 'Create a product to begin building your inventory catalog.'
              : 'Adjust your search or filter criteria to see products.'}
          </p>
          {products.length === 0 && canManage && (
            <button type="button" onClick={openCreate}
              className="mt-4 inline-flex items-center gap-1.5 rounded-lg bg-accent px-3 py-1.5 text-xs font-semibold text-white">
              <Plus className="h-3 w-3" /> Add Product
            </button>
          )}
        </div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-border bg-card">
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="w-10 px-3 py-2.5" />
                  <SortTh field="sku" label="SKU" current={sortField} dir={sortDir} onSort={handleSort} />
                  <SortTh field="name" label="Product" current={sortField} dir={sortDir} onSort={handleSort} />
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Category</th>
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Barcode</th>
                  <SortTh field="price" label="Unit Price" current={sortField} dir={sortDir} onSort={handleSort} right />
                  <SortTh field="stock" label="Stock" current={sortField} dir={sortDir} onSort={handleSort} right />
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Status</th>
                  <SortTh field="updated" label="Updated" current={sortField} dir={sortDir} onSort={handleSort} right />
                  {canManage && <th className="px-3 py-2.5 text-right text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Actions</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {displayProducts.map((p) => {
                  const status = stockStatusBadge(p);
                  const expanded = expandedRow === p.id;
                  return (
                    <ProductRow key={p.id} p={p} status={status} expanded={expanded} canManage={canManage}
                      onToggle={() => setExpandedRow(expanded ? null : p.id)}
                      onEdit={() => openEdit(p)}
                      onDelete={() => setDeleteTarget(p)} />
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ── Create/Edit Modal ── */}
      {modal && (
        <ProductModal modal={modal} form={form} setForm={setForm}
          formError={formError} setFormError={setFormError}
          imageError={imageError} imagePreview={imagePreview}
          categories={categories} canManage={canManage} skuLoading={skuLoading}
          saveMutation={saveMutation} createCategoryMutation={createCategoryMutation}
          newCategoryName={newCategoryName} setNewCategoryName={setNewCategoryName}
          onClose={() => setModal(null)} onSubmit={submitForm}
          onImagePick={handleImagePick} onImageRemove={handleImageRemove}
        />
      )}

      {/* ── Delete Confirm ── */}
      {deleteTarget && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-900/20 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-xl border border-border bg-card p-5 shadow-2xl">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-100 dark:bg-red-500/20">
                <Trash2 className="h-5 w-5 text-red-600 dark:text-red-400" />
              </div>
              <div>
                <h2 className="text-base font-semibold text-foreground">Delete product?</h2>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  <span className="font-mono text-accent">{deleteTarget.sku}</span> — {deleteTarget.name}
                </p>
              </div>
            </div>
            <p className="mt-3 text-xs text-muted-foreground">
              This action is irreversible. Products with inventory records cannot be deleted.
            </p>
            <div className="mt-4 flex justify-end gap-2">
              <button type="button" onClick={() => setDeleteTarget(null)}
                className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-foreground hover:bg-muted">Cancel</button>
              <button type="button" disabled={deleteMutation.isPending}
                onClick={() => deleteMutation.mutate(deleteTarget.id)}
                className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-red-500 disabled:opacity-50">
                {deleteMutation.isPending ? 'Deleting…' : 'Delete Product'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Product Table Row (with expandable detail)
   ═══════════════════════════════════════════════════════════════ */

function ProductRow({ p, status, expanded, canManage, onToggle, onEdit, onDelete }) {
  return (
    <>
      <tr className={`group transition ${expanded ? 'bg-accent/5' : 'hover:bg-muted/30'}`}>
        {/* Expand toggle + image */}
        <td className="px-3 py-2">
          <button type="button" onClick={onToggle}
            className="flex h-8 w-8 items-center justify-center rounded-lg transition hover:bg-muted">
            <ChevronDown className={`h-3.5 w-3.5 text-muted-foreground transition-transform ${expanded ? 'rotate-180' : ''}`} />
          </button>
        </td>

        {/* SKU */}
        <td className="px-3 py-2">
          <span className="rounded bg-accent/10 px-1.5 py-0.5 font-mono text-[11px] font-bold text-accent">{p.sku}</span>
        </td>

        {/* Product (image + name) */}
        <td className="px-3 py-2">
          <div className="flex items-center gap-2.5">
            <ProductImage src={p.image_url} alt={p.name} size="sm" className="h-8 w-8 rounded-lg" />
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-foreground">{p.name}</p>
              {p.description && <p className="mt-0.5 max-w-[200px] truncate text-[10px] text-muted-foreground">{p.description}</p>}
            </div>
          </div>
        </td>

        {/* Category */}
        <td className="px-3 py-2">
          <span className="inline-flex items-center gap-1 rounded-md border border-border bg-muted/30 px-1.5 py-0.5 text-[10px] font-semibold text-foreground">
            <Tag className="h-2.5 w-2.5 text-muted-foreground" />{p.category?.name || '—'}
          </span>
        </td>

        {/* Barcode */}
        <td className="px-3 py-2">
          <span className="font-mono text-[11px] text-muted-foreground">{p.barcode || '—'}</span>
        </td>

        {/* Price */}
        <td className="px-3 py-2 text-right">
          <span className="text-sm font-semibold tabular-nums text-foreground">{formatMoney(p.unit_price)}</span>
        </td>

        {/* Stock */}
        <td className="px-3 py-2 text-right">
          <div className="text-right">
            <span className="text-sm font-bold tabular-nums text-foreground">{p.total_stock ?? 0}</span>
            {(p.warehouse_count ?? 0) > 0 && (
              <p className="text-[9px] text-muted-foreground">
                {p.warehouse_count} warehouse{p.warehouse_count > 1 ? 's' : ''}
              </p>
            )}
          </div>
        </td>

        {/* Status */}
        <td className="px-3 py-2">
          <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${status.color}`}>
            {status.label}
          </span>
        </td>

        {/* Updated */}
        <td className="px-3 py-2 text-right">
          <span className="text-[11px] text-muted-foreground">{timeAgo(p.updated_at)}</span>
        </td>

        {/* Actions */}
        {canManage && (
          <td className="px-3 py-2 text-right">
            <div className="flex justify-end gap-1 opacity-0 transition group-hover:opacity-100">
              <button type="button" onClick={onEdit}
                className="rounded-md p-1.5 text-muted-foreground transition hover:bg-muted hover:text-foreground" title="Edit">
                <Pencil className="h-3.5 w-3.5" />
              </button>
              <button type="button" onClick={onDelete}
                className="rounded-md p-1.5 text-muted-foreground transition hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-500/10 dark:hover:text-red-400" title="Delete">
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </div>
          </td>
        )}
      </tr>

      {/* Expanded Detail */}
      {expanded && (
        <tr>
          <td colSpan={canManage ? 10 : 9} className="border-b border-accent/10 bg-accent/[0.02] px-4 py-3">
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <DetailCard label="Product Details">
                <div className="flex items-start gap-3">
                  <ProductImage src={p.image_url} alt={p.name} size="md" />
                  <div className="min-w-0 space-y-1 text-xs">
                    <p><span className="text-muted-foreground">SKU:</span> <span className="font-mono font-bold text-accent">{p.sku}</span></p>
                    <p><span className="text-muted-foreground">Barcode:</span> <span className="font-mono">{p.barcode || '—'}</span></p>
                    <p><span className="text-muted-foreground">Category:</span> <span className="font-semibold">{p.category?.name || '—'}</span></p>
                    <p><span className="text-muted-foreground">Min Stock:</span> <span className="font-semibold">{p.min_stock_threshold}</span></p>
                  </div>
                </div>
              </DetailCard>

              <DetailCard label="Pricing">
                <div className="space-y-2 text-xs">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Unit Cost</span>
                    <span className="font-semibold tabular-nums">{formatMoney(p.unit_cost)}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Unit Price</span>
                    <span className="font-semibold tabular-nums">{formatMoney(p.unit_price)}</span>
                  </div>
                  <div className="flex items-center justify-between border-t border-border pt-1.5">
                    <span className="text-muted-foreground">Margin</span>
                    <span className="font-bold tabular-nums text-emerald-600 dark:text-emerald-400">
                      {p.unit_price > 0 ? `${Math.round(((p.unit_price - (p.unit_cost || 0)) / p.unit_price) * 100)}%` : '—'}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Inventory Value</span>
                    <span className="font-bold tabular-nums">{formatMoney((p.total_stock || 0) * (p.unit_price || 0))}</span>
                  </div>
                </div>
              </DetailCard>

              <DetailCard label="Inventory Intelligence">
                <div className="space-y-2 text-xs">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Total Stock</span>
                    <span className={`font-bold tabular-nums ${(p.total_stock || 0) === 0 ? 'text-red-600 dark:text-red-400' : 'text-foreground'}`}>{p.total_stock ?? 0} units</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Warehouses</span>
                    <span className="font-semibold tabular-nums">{p.warehouse_count ?? 0}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Status</span>
                    <span className={`rounded-full px-1.5 py-0.5 text-[9px] font-bold ${status.color}`}>{status.label}</span>
                  </div>
                  {p.earliest_expiry && (
                    <div className="flex items-center justify-between">
                      <span className="text-muted-foreground">Earliest Expiry</span>
                      <span className={`font-semibold ${new Date(p.earliest_expiry) <= new Date() ? 'text-red-600 dark:text-red-400' : 'text-foreground'}`}>
                        {new Date(p.earliest_expiry).toLocaleDateString()}
                      </span>
                    </div>
                  )}
                </div>
              </DetailCard>

              <DetailCard label="Metadata">
                <div className="space-y-2 text-xs">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Created</span>
                    <span className="font-medium">{p.created_at ? new Date(p.created_at).toLocaleDateString() : '—'}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Last Updated</span>
                    <span className="font-medium">{timeAgo(p.updated_at)}</span>
                  </div>
                  {p.description && (
                    <div className="border-t border-border pt-1.5">
                      <span className="text-muted-foreground">Description</span>
                      <p className="mt-0.5 text-[11px] leading-relaxed text-foreground">{p.description}</p>
                    </div>
                  )}
                </div>
              </DetailCard>
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Product Create/Edit Modal
   ═══════════════════════════════════════════════════════════════ */

function ProductModal({ modal, form, setForm, formError, imageError, imagePreview, categories, canManage, skuLoading, saveMutation, createCategoryMutation, newCategoryName, setNewCategoryName, onClose, onSubmit, onImagePick, onImageRemove }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/20 p-3 backdrop-blur-sm">
      <div className="flex max-h-[92vh] w-full max-w-2xl flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl">

        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-5 py-3.5">
          <div>
            <h2 className="text-base font-semibold text-foreground">
              {modal.mode === 'create' ? 'Add New Product' : 'Edit Product'}
            </h2>
            <p className="mt-0.5 text-[11px] text-muted-foreground">
              {modal.mode === 'create' ? 'Create a new product entry in the catalog' : `Editing ${modal.product?.sku || ''}`}
            </p>
          </div>
          <button type="button" onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={onSubmit} className="flex-1 overflow-y-auto">
          <div className="space-y-5 px-5 py-4">

            {/* Section 1: Identity */}
            <div className="space-y-3">
              <SectionLabel icon={Package}>Product Identity</SectionLabel>

              {canManage && (
                <ProductImageField
                  previewSrc={imagePreview || resolveProductImageUrl(form.image_url)}
                  onPickFile={onImagePick} onRemove={onImageRemove}
                  error={imageError} disabled={saveMutation.isPending}
                />
              )}

              <label className="block text-xs font-medium text-foreground">
                Product Name <span className="text-red-500">*</span>
                <input required value={form.name}
                  onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                  className="wms-input mt-1" placeholder="e.g. Basmati Rice 25kg" />
              </label>
              <label className="block text-xs font-medium text-foreground">
                Description
                <textarea rows={2} value={form.description}
                  onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                  className="wms-input mt-1" placeholder="Optional product description…" />
              </label>
            </div>

            {/* Section 2: Classification */}
            <div className="space-y-3">
              <SectionLabel icon={Tag}>Classification</SectionLabel>
              <div className="grid gap-3 sm:grid-cols-2">
                <label className="block text-xs font-medium text-foreground">
                  Category <span className="text-red-500">*</span>
                  <select required value={form.category_id}
                    onChange={(e) => setForm((f) => ({ ...f, category_id: e.target.value }))}
                    className="wms-input mt-1">
                    <option value="">Select category…</option>
                    {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </label>
                <label className="block text-xs font-medium text-foreground">
                  SKU
                  <input
                    readOnly
                    value={skuLoading ? '' : form.sku}
                    placeholder={skuLoading ? 'Generating…' : 'Select a category'}
                    className="wms-input mt-1 cursor-not-allowed bg-muted/40 font-mono text-muted-foreground"
                    aria-readonly="true"
                  />
                  <p className="mt-1 text-[10px] text-muted-foreground">
                    {modal.mode === 'create'
                      ? 'Assigned automatically from the selected category'
                      : 'System identifier — cannot be changed'}
                  </p>
                </label>
              </div>
              <label className="block text-xs font-medium text-foreground">
                Barcode
                <input value={form.barcode}
                  onChange={(e) => setForm((f) => ({ ...f, barcode: e.target.value }))}
                  placeholder="EAN / UPC" className="wms-input mt-1 font-mono" />
              </label>
              {canManage && (
                <div className="flex gap-2 rounded-lg border border-dashed border-border bg-muted/20 p-2.5">
                  <input placeholder="New category name…" value={newCategoryName}
                    onChange={(e) => setNewCategoryName(e.target.value)}
                    className="flex-1 rounded-md border border-border bg-card px-2.5 py-1.5 text-xs text-foreground placeholder:text-muted-foreground" />
                  <button type="button"
                    disabled={!newCategoryName.trim() || createCategoryMutation.isPending}
                    onClick={() => createCategoryMutation.mutate(newCategoryName.trim())}
                    className="rounded-md bg-accent px-2.5 py-1.5 text-xs font-semibold text-white disabled:opacity-50">
                    Add
                  </button>
                </div>
              )}
            </div>

            {/* Section 3: Pricing & Policy */}
            <div className="space-y-3">
              <SectionLabel icon={DollarSign}>Pricing & Inventory Policy</SectionLabel>
              <div className="grid gap-3 sm:grid-cols-3">
                <label className="block text-xs font-medium text-foreground">
                  Unit Cost <span className="text-red-500">*</span>
                  <input type="number" min={0} step="0.01" required value={form.unit_cost}
                    onChange={(e) => setForm((f) => ({ ...f, unit_cost: e.target.value }))}
                    className="wms-input mt-1" placeholder="0.00" />
                </label>
                <label className="block text-xs font-medium text-foreground">
                  Unit Price <span className="text-red-500">*</span>
                  <input type="number" min={0} step="0.01" required value={form.unit_price}
                    onChange={(e) => setForm((f) => ({ ...f, unit_price: e.target.value }))}
                    className="wms-input mt-1" placeholder="0.00" />
                </label>
                <label className="block text-xs font-medium text-foreground">
                  Min Stock Threshold
                  <input type="number" min={0} required value={form.min_stock_threshold}
                    onChange={(e) => setForm((f) => ({ ...f, min_stock_threshold: e.target.value }))}
                    className="wms-input mt-1" placeholder="0" />
                </label>
              </div>
            </div>

            {formError && (
              <div className="flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                <AlertTriangle className="mt-0.5 h-3.5 w-3.5 shrink-0" /> {formError}
              </div>
            )}
          </div>

          <div className="flex items-center justify-end gap-2 border-t border-border px-5 py-3">
            <button type="button" onClick={onClose}
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-foreground hover:bg-muted">Cancel</button>
            <button type="submit" disabled={saveMutation.isPending}
              className="rounded-lg bg-accent px-4 py-1.5 text-xs font-semibold text-white disabled:opacity-50">
              {saveMutation.isPending ? 'Saving…' : modal.mode === 'create' ? 'Create Product' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Sub-components
   ═══════════════════════════════════════════════════════════════ */

function SectionLabel({ icon: Icon, children }) {
  return (
    <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
      {Icon && <Icon className="h-3 w-3 text-accent" />}
      {children}
    </p>
  );
}

function SortTh({ field, label, current, dir, onSort, right }) {
  const active = current === field;
  return (
    <th className={`px-3 py-2.5 ${right ? 'text-right' : ''}`}>
      <button type="button" onClick={() => onSort(field)}
        className={`inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider transition ${active ? 'text-accent' : 'text-muted-foreground hover:text-foreground'}`}>
        {label}
        <ArrowUpDown className={`h-2.5 w-2.5 ${active ? 'text-accent' : 'text-muted-foreground/50'}`} />
      </button>
    </th>
  );
}

function DetailCard({ label, children }) {
  return (
    <div className="rounded-lg border border-border bg-card p-3">
      <p className="mb-2 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">{label}</p>
      {children}
    </div>
  );
}
