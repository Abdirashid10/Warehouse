import { useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { CreatedByCell } from '../CreatedByCell';
import { formatMoney } from '../../utils/productHelpers';
import { fetchNextSkuForCategory } from '../../utils/skuHelpers';
import { Pencil, Plus, Search, Tag, Trash2, X } from 'lucide-react';

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
  unit_cost: '',
  unit_price: '',
  min_stock_threshold: '0',
};

export function ProductCatalogTab() {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const canManage = user?.role === 'Admin' || user?.role === 'Supervisor';

  const [search, setSearch] = useState('');
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [formError, setFormError] = useState('');
  const [newCategoryName, setNewCategoryName] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [skuLoading, setSkuLoading] = useState(false);

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

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['products'] });
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
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
    mutationFn: ({ id, body }) =>
      id ? api.patch(`/products/${id}`, body) : api.post('/products', body),
    onSuccess: () => {
      invalidate();
      setModal(null);
      setForm(emptyForm);
      setFormError('');
    },
    onError: (err) => {
      setFormError(err.response?.data?.message || err.message || 'Save failed');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/products/${id}`),
    onSuccess: () => {
      invalidate();
      setDeleteTarget(null);
    },
    onError: (err) => {
      setFormError(err.response?.data?.message || err.message || 'Delete failed');
    },
  });

  function openCreate() {
    setFormError('');
    setForm({ ...emptyForm, category_id: categories[0]?.id || '' });
    setModal({ mode: 'create' });
  }

  function openEdit(p) {
    setFormError('');
    setForm({
      sku: p.sku,
      name: p.name,
      description: p.description || '',
      category_id: p.category_id || '',
      unit_cost: String(p.unit_cost ?? ''),
      unit_price: String(p.unit_price ?? ''),
      min_stock_threshold: String(p.min_stock_threshold ?? 0),
    });
    setModal({ mode: 'edit', id: p.id });
  }

  function submitForm(e) {
    e.preventDefault();
    setFormError('');
    if (!form.category_id) {
      setFormError('Select a category.');
      return;
    }
    const body = {
      name: form.name.trim(),
      description: form.description,
      category_id: form.category_id,
      unit_cost: Number(form.unit_cost),
      unit_price: Number(form.unit_price),
      min_stock_threshold: Number(form.min_stock_threshold) || 0,
    };
    saveMutation.mutate({
      id: modal?.mode === 'edit' ? modal.id : null,
      body,
    });
  }

  const stats = useMemo(
    () => ({ total: products.length, categories: categories.length }),
    [products, categories]
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <p className="max-w-2xl text-sm text-slate-400">
          Register product metadata only — no quantity on creation. Add stock from the Live
          Warehouse Stock tab via inbound movements.
        </p>
        {canManage ? (
          <button
            type="button"
            onClick={openCreate}
            className="inline-flex items-center gap-2 rounded-lg bg-sky-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-sky-500"
          >
            <Plus className="h-4 w-4" />
            New product
          </button>
        ) : null}
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="rounded-xl border border-slate-800 bg-slate-900/50 px-4 py-3">
          <p className="text-xs uppercase text-slate-500">Products</p>
          <p className="mt-1 text-2xl font-semibold text-white">{stats.total}</p>
        </div>
        <div className="rounded-xl border border-slate-800 bg-slate-900/50 px-4 py-3">
          <p className="text-xs uppercase text-slate-500">Categories</p>
          <p className="mt-1 text-2xl font-semibold text-white">{stats.categories}</p>
        </div>
        <div className="rounded-xl border border-slate-800 bg-slate-900/50 px-4 py-3">
          <p className="text-xs uppercase text-slate-500">Access</p>
          <p className="mt-1 text-sm font-medium text-slate-300">
            {canManage ? 'Create & edit' : 'View only'}
          </p>
        </div>
      </div>

      <div className="relative max-w-md">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
        <input
          type="search"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search SKU, name…"
          className="w-full rounded-lg border border-slate-700 bg-slate-900 py-2.5 pl-10 pr-3 text-sm text-white outline-none focus:ring-2 focus:ring-sky-500/50"
        />
      </div>

      {isLoading ? (
        <div className="text-slate-400">Loading products…</div>
      ) : isError ? (
        <div className="text-red-400">
          {error?.response?.data?.message || 'Failed to load products.'}
        </div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-slate-800 bg-slate-900/40">
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-950/90 text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                  <th className="px-4 py-3.5">SKU</th>
                  <th className="px-4 py-3.5">Name</th>
                  <th className="px-4 py-3.5">Category</th>
                  <th className="px-4 py-3.5 text-right">Unit cost</th>
                  <th className="px-4 py-3.5 text-right">Unit price</th>
                  <th className="px-4 py-3.5 text-right">Min stock</th>
                  {canManage ? <th className="px-4 py-3.5 text-right">Actions</th> : null}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/90">
                {products.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-800/30">
                    <td className="px-4 py-3 font-mono text-sky-300/90">{p.sku}</td>
                    <td className="px-4 py-3">
                      <div className="font-medium text-slate-100">{p.name}</div>
                      {p.description ? (
                        <p className="mt-0.5 max-w-xs truncate text-xs text-slate-500">
                          {p.description}
                        </p>
                      ) : null}
                    </td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center gap-1 rounded-md bg-slate-800 px-2 py-1 text-xs text-slate-300">
                        <Tag className="h-3 w-3" />
                        {p.category?.name || '—'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums">{formatMoney(p.unit_cost)}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{formatMoney(p.unit_price)}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{p.min_stock_threshold}</td>
                    {canManage ? (
                      <td className="px-4 py-3 text-right">
                        <div className="flex justify-end gap-1.5">
                          <button
                            type="button"
                            onClick={() => openEdit(p)}
                            className="inline-flex items-center gap-1 rounded-md border border-slate-600 bg-slate-800/50 px-2 py-1 text-xs text-slate-200 hover:border-sky-500/40"
                          >
                            <Pencil className="h-3.5 w-3.5" />
                            Edit
                          </button>
                          <button
                            type="button"
                            onClick={() => setDeleteTarget(p)}
                            className="inline-flex items-center gap-1 rounded-md border border-red-900/40 bg-red-950/20 px-2 py-1 text-xs text-red-300"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                            Delete
                          </button>
                        </div>
                      </td>
                    ) : null}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {products.length === 0 ? (
            <p className="px-6 py-12 text-center text-sm text-slate-500">
              No products yet. Create a product, then add stock from Live Warehouse Stock.
            </p>
          ) : null}
        </div>
      )}

      {modal ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm">
          <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl border border-slate-700 bg-slate-900 p-6">
            <div className="flex items-start justify-between">
              <h2 className="text-lg font-semibold text-white">
                {modal.mode === 'create' ? 'New product' : 'Edit product'}
              </h2>
              <button type="button" onClick={() => setModal(null)} className="text-slate-500">
                <X className="h-5 w-5" />
              </button>
            </div>
            <form onSubmit={submitForm} className="mt-5 space-y-4">
              <label className="block text-sm text-slate-300">
                Name
                <input
                  required
                  value={form.name}
                  onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                  className="mt-1.5 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                />
              </label>
              <label className="block text-sm text-slate-300">
                Description
                <textarea
                  rows={2}
                  value={form.description}
                  onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                  className="mt-1.5 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                />
              </label>
              <label className="block text-sm text-slate-300">
                Category
                <select
                  required
                  value={form.category_id}
                  onChange={(e) => setForm((f) => ({ ...f, category_id: e.target.value }))}
                  className="mt-1.5 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                >
                  <option value="">Select…</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block text-sm text-slate-300">
                SKU
                <input
                  readOnly
                  value={skuLoading ? '' : form.sku}
                  placeholder={skuLoading ? 'Generating…' : 'Select a category'}
                  className="mt-1.5 w-full cursor-not-allowed rounded-lg border border-slate-700 bg-slate-800/80 px-3 py-2 font-mono text-slate-300"
                  aria-readonly="true"
                />
                <span className="mt-1 block text-xs text-slate-500">
                  {modal.mode === 'create'
                    ? 'Assigned automatically from the selected category'
                    : 'System identifier — cannot be changed'}
                </span>
              </label>
              {canManage ? (
                <div className="flex gap-2 rounded-lg border border-dashed border-slate-700 p-3">
                  <input
                    placeholder="New category"
                    value={newCategoryName}
                    onChange={(e) => setNewCategoryName(e.target.value)}
                    className="flex-1 rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white"
                  />
                  <button
                    type="button"
                    disabled={!newCategoryName.trim() || createCategoryMutation.isPending}
                    onClick={() => createCategoryMutation.mutate(newCategoryName.trim())}
                    className="rounded-lg bg-slate-700 px-3 py-2 text-xs text-white"
                  >
                    Add
                  </button>
                </div>
              ) : null}
              <div className="grid gap-4 sm:grid-cols-3">
                <label className="block text-sm text-slate-300">
                  Unit cost
                  <input
                    type="number"
                    min={0}
                    step="0.01"
                    required
                    value={form.unit_cost}
                    onChange={(e) => setForm((f) => ({ ...f, unit_cost: e.target.value }))}
                    className="mt-1.5 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                  />
                </label>
                <label className="block text-sm text-slate-300">
                  Unit price
                  <input
                    type="number"
                    min={0}
                    step="0.01"
                    required
                    value={form.unit_price}
                    onChange={(e) => setForm((f) => ({ ...f, unit_price: e.target.value }))}
                    className="mt-1.5 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                  />
                </label>
                <label className="block text-sm text-slate-300">
                  Min stock threshold
                  <input
                    type="number"
                    min={0}
                    required
                    value={form.min_stock_threshold}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, min_stock_threshold: e.target.value }))
                    }
                    className="mt-1.5 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                  />
                </label>
              </div>
              {formError ? <p className="text-sm text-red-400">{formError}</p> : null}
              <div className="flex justify-end gap-2">
                <button type="button" onClick={() => setModal(null)} className="text-slate-400">
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saveMutation.isPending}
                  className="rounded-lg bg-sky-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
                >
                  Save
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}

      {deleteTarget ? (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/70 p-4">
          <div className="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6">
            <h2 className="text-lg font-semibold text-white">Delete product?</h2>
            <p className="mt-2 text-sm text-slate-400">SKU: {deleteTarget.sku}</p>
            <div className="mt-6 flex justify-end gap-2">
              <button type="button" onClick={() => setDeleteTarget(null)} className="text-slate-400">
                Cancel
              </button>
              <button
                type="button"
                disabled={deleteMutation.isPending}
                onClick={() => deleteMutation.mutate(deleteTarget.id)}
                className="rounded-lg bg-red-600 px-4 py-2 text-sm text-white"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
