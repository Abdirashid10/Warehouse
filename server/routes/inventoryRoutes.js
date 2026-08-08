const express = require('express');
const {
  getInventory,
  getInventoryTracking,
  handleMovement,
  seedSampleStock,
  listWarehouses,
  listWarehouseStaffCandidates,
  createWarehouse,
  updateWarehouse,
  listMovements,
  getWarehouseStock,
  getProductAvailability,
} = require('../controllers/inventoryController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', authenticate, getInventory);
router.get('/tracking', authenticate, getInventoryTracking);
router.post(
  '/seed-sample',
  authenticate,
  checkRole(['Admin', 'Supervisor']),
  seedSampleStock
);
router.get(
  '/warehouses/staff-candidates',
  authenticate,
  checkRole(['Admin', 'Supervisor']),
  listWarehouseStaffCandidates
);
router.get('/warehouses', authenticate, listWarehouses);
router.post(
  '/warehouses',
  authenticate,
  checkRole(['Admin', 'Supervisor']),
  createWarehouse
);
router.patch(
  '/warehouses/:id',
  authenticate,
  checkRole(['Admin', 'Supervisor']),
  updateWarehouse
);
router.get('/product-availability', authenticate, getProductAvailability);
router.get('/stock-lookup', authenticate, checkRole(['Admin', 'Supervisor']), getWarehouseStock);
router.get('/movements', authenticate, listMovements);
router.post('/movements', authenticate, handleMovement);

module.exports = router;
