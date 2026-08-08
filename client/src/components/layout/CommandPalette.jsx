import { useEffect, useMemo, useState } from 'react';

import { useNavigate } from 'react-router-dom';

import { useQuery } from '@tanstack/react-query';

import { AnimatePresence, motion } from 'framer-motion';

import { Command, Search } from 'lucide-react';

import { api } from '../../api/client';

import { useAuth } from '../../context/AuthContext';

import { getNavItems } from '../../config/navigation';
import { orderMatchesSearchQuery } from '../../utils/orderHelpers';
import { cn } from '../../lib/utils';



export function CommandPalette({ open, onClose }) {

  const navigate = useNavigate();

  const { user } = useAuth();

  const [query, setQuery] = useState('');

  const isStaff = user?.role === 'Staff';



  const { data: productsData } = useQuery({

    queryKey: ['command', 'products'],

    queryFn: () => api.get('/products').then((r) => r.data),

    enabled: open && !isStaff,

  });

  const { data: ordersData } = useQuery({

    queryKey: ['command', 'orders'],

    queryFn: () => api.get('/orders').then((r) => r.data),

    enabled: open,

  });

  const { data: warehousesData } = useQuery({

    queryKey: ['command', 'warehouses'],

    queryFn: () => api.get('/inventory/warehouses').then((r) => r.data),

    enabled: open && !isStaff,

  });



  useEffect(() => {

    if (!open) setQuery('');

  }, [open]);



  const items = useMemo(() => {

    const q = query.trim().toLowerCase();

    const navItems = getNavItems(user)

      .filter((n) => !q || n.label.toLowerCase().includes(q))

      .map((n) => ({ type: 'nav', label: n.label, to: n.to, icon: n.icon }));



    if (isStaff) {

      const orders = (ordersData?.orders || [])

        .filter((o) => !q || orderMatchesSearchQuery(o, q) || (o.customer_name || '').toLowerCase().includes(q))

        .slice(0, 6)

        .map((o) => ({

          type: 'order',

          label: `${o.order_number} — ${o.customer_name}`,

          to: '/staff/orders',

          icon: navItems.find((n) => n.to === '/staff/orders')?.icon,

        }));

      return [...navItems, ...orders];

    }



    const products = (productsData?.products || [])

      .filter((p) => {

        const hay = `${p.sku} ${p.name}`.toLowerCase();

        return !q || hay.includes(q);

      })

      .slice(0, 6)

      .map((p) => ({

        type: 'product',

        label: `${p.sku} — ${p.name}`,

        to: '/products',

        icon: navItems.find((n) => n.to === '/products')?.icon,

      }));



    const orders = (ordersData?.orders || [])

      .filter((o) => !q || orderMatchesSearchQuery(o, q) || (o.customer_name || '').toLowerCase().includes(q))

      .slice(0, 6)

      .map((o) => ({

        type: 'order',

        label: `${o.order_number} — ${o.customer_name}`,

        to: `/orders/${o.id}`,

        icon: navItems.find((n) => n.to === '/orders')?.icon,

      }));



    const warehouses = (warehousesData?.warehouses || [])

      .filter((w) => {

        const hay = `${w.name} ${w.location || ''}`.toLowerCase();

        return !q || hay.includes(q);

      })

      .slice(0, 6)

      .map((w) => ({

        type: 'warehouse',

        label: w.name,

        to: '/warehouses',

        icon: navItems.find((n) => n.to === '/warehouses')?.icon,

      }));



    return [...navItems, ...products, ...orders, ...warehouses];

  }, [query, productsData, ordersData, warehousesData, user, isStaff]);



  function go(to) {

    navigate(to);

    onClose();

  }



  return (

    <AnimatePresence>

      {open ? (

        <motion.div

          className="fixed inset-0 z-[80] flex items-start justify-center bg-black/50 p-4 pt-[12vh] backdrop-blur-sm"

          initial={{ opacity: 0 }}

          animate={{ opacity: 1 }}

          exit={{ opacity: 0 }}

          onClick={onClose}

        >

          <motion.div

            initial={{ opacity: 0, y: 12, scale: 0.98 }}

            animate={{ opacity: 1, y: 0, scale: 1 }}

            exit={{ opacity: 0, y: 8, scale: 0.98 }}

            transition={{ duration: 0.18 }}

            className="w-full max-w-xl overflow-hidden rounded-2xl border border-border bg-card shadow-2xl"

            onClick={(e) => e.stopPropagation()}

          >

            <div className="flex items-center gap-2 border-b border-border px-4 py-3">

              <Search className="h-4 w-4 text-muted-foreground" />

              <input

                autoFocus

                value={query}

                onChange={(e) => setQuery(e.target.value)}

                placeholder={isStaff ? 'Search pages and orders…' : 'Search pages, products, orders, warehouses…'}

                className="w-full bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"

              />

              <kbd className="rounded-md border border-border bg-muted px-2 py-0.5 text-[10px] text-muted-foreground">

                ESC

              </kbd>

            </div>

            <div className="max-h-[50vh] overflow-y-auto p-2">

              {items.length === 0 ? (

                <p className="px-3 py-6 text-center text-sm text-muted-foreground">No results found.</p>

              ) : (

                items.map((item, idx) => {

                  const Icon = item.icon;

                  return (

                    <button

                      key={`${item.type}-${item.label}-${idx}`}

                      type="button"

                      onClick={() => go(item.to)}

                      className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-sm text-foreground transition hover:bg-muted"

                    >

                      {Icon ? <Icon className="h-4 w-4 text-accent" /> : null}

                      <span className="flex-1 truncate">{item.label}</span>

                      <span className="text-[10px] uppercase tracking-wide text-muted-foreground">

                        {item.type}

                      </span>

                    </button>

                  );

                })

              )}

            </div>

            <div className="flex items-center gap-2 border-t border-border px-4 py-2 text-[11px] text-muted-foreground">

              <Command className="h-3.5 w-3.5" />

              Quick navigation • Ctrl+K

            </div>

          </motion.div>

        </motion.div>

      ) : null}

    </AnimatePresence>

  );

}



export function useCommandPalette() {

  const [open, setOpen] = useState(false);



  useEffect(() => {

    function onKeyDown(e) {

      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {

        e.preventDefault();

        setOpen((v) => !v);

      }

      if (e.key === 'Escape') setOpen(false);

    }

    window.addEventListener('keydown', onKeyDown);

    return () => window.removeEventListener('keydown', onKeyDown);

  }, []);



  return { open, setOpen };

}


