import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';



import { AppLayout } from './components/layout/AppLayout';



import { AdminRoute } from './components/AdminRoute';



import { NonStaffRoute } from './components/NonStaffRoute';



import { ManagementRoute } from './components/ManagementRoute';



import { InventoryRedirect } from './components/InventoryRedirect';



import { ProtectedRoute } from './components/ProtectedRoute';



import { LoginPage } from './pages/LoginPage';



import { DashboardRouter } from './pages/DashboardRouter';



import { ProductsPage } from './pages/ProductsPage';



import { InventoryTrackingPage } from './pages/InventoryTrackingPage';



import { StockMovementsPage } from './pages/StockMovementsPage';



import { WarehousesPage } from './pages/WarehousesPage';



import { ReportsPage } from './pages/ReportsPage';



import { UsersPage } from './pages/UsersPage';



import { OrdersPage } from './pages/OrdersPage';



import { OrderDetailPage } from './pages/OrderDetailPage';

import { ProfilePage } from './pages/ProfilePage';

import { TasksPage } from './pages/TasksPage';

import { TaskDetailPage } from './pages/TaskDetailPage';

import { NotificationsPage } from './pages/NotificationsPage';

import { StaffOrdersPage } from './pages/StaffOrdersPage';

import { StaffInventoryPage } from './pages/StaffInventoryPage';

import { ExpiryManagementPage } from './pages/ExpiryManagementPage';

import { AuditLogsPage } from './pages/AuditLogsPage';







export default function App() {



  return (



    <BrowserRouter>



      <Routes>



        <Route path="/login" element={<LoginPage />} />



        <Route



          element={



            <ProtectedRoute>



              <AppLayout />



            </ProtectedRoute>



          }



        >



          <Route index element={<Navigate to="/dashboard" replace />} />



          <Route path="dashboard" element={<DashboardRouter />} />



          <Route

            path="products"

            element={

              <ManagementRoute>

                <ProductsPage />

              </ManagementRoute>

            }

          />



          <Route

            path="inventory-tracking"

            element={

              <ManagementRoute>

                <InventoryTrackingPage />

              </ManagementRoute>

            }

          />



          <Route path="stock-movements" element={<StockMovementsPage />} />



          <Route path="inventory-control" element={<Navigate to="/products" replace />} />



          <Route path="inventory" element={<InventoryRedirect />} />



          <Route path="movements" element={<Navigate to="/stock-movements" replace />} />



          <Route

            path="warehouses"

            element={

              <ManagementRoute>

                <WarehousesPage />

              </ManagementRoute>

            }

          />



          <Route

            path="expiry-management"

            element={

              <NonStaffRoute>

                <ExpiryManagementPage />

              </NonStaffRoute>

            }

          />



          <Route

            path="audit-logs"

            element={

              <NonStaffRoute>

                <AuditLogsPage />

              </NonStaffRoute>

            }

          />



          <Route

            path="orders"

            element={

              <ManagementRoute>

                <OrdersPage />

              </ManagementRoute>

            }

          />



          <Route

            path="orders/:id"

            element={

              <ManagementRoute>

                <OrderDetailPage />

              </ManagementRoute>

            }

          />



          <Route path="tasks" element={<TasksPage />} />

          <Route path="tasks/:id" element={<TaskDetailPage />} />



          <Route path="staff/orders" element={<StaffOrdersPage />} />

          <Route path="staff/inventory" element={<StaffInventoryPage />} />



          <Route path="notifications" element={<NotificationsPage />} />



          <Route path="profile" element={<ProfilePage />} />



          <Route



            path="users"



            element={



              <AdminRoute>



                <UsersPage />



              </AdminRoute>



            }



          />



          <Route



            path="reports"



            element={



              <NonStaffRoute>



                <ReportsPage />



              </NonStaffRoute>



            }



          />



        </Route>



        <Route path="*" element={<Navigate to="/dashboard" replace />} />



      </Routes>



    </BrowserRouter>



  );



}


