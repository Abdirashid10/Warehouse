import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar, MobileSidebarDrawer } from './Sidebar';
import { Navbar } from './Navbar';
import { SyncProfilePreferences } from '../profile/SyncProfilePreferences';

export function AppLayout() {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <div className="flex min-h-screen bg-background">
      <SyncProfilePreferences />
      <Sidebar />
      <MobileSidebarDrawer open={mobileOpen} onClose={() => setMobileOpen(false)} />
      <div className="flex min-w-0 flex-1 flex-col">
        <Navbar onOpenMobileSidebar={() => setMobileOpen(true)} />
        <main className="flex-1 overflow-auto bg-[radial-gradient(ellipse_at_top,rgb(var(--accent)/0.08),transparent_55%)] p-4 sm:p-6">
          <div className="mx-auto w-full max-w-[1600px]">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
