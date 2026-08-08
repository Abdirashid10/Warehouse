const express = require('express');
const {
  getNextOrderNumber,
  listOrders,
  getOrder,
  createOrder,
  updateOrder,
  deleteOrder,
  updateOrderStatus,
} = require('../controllers/orderController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');
const { SUPERVISOR_ACCESS_ROLES } = require('../constants/roles');

const router = express.Router();
const manageRoles = SUPERVISOR_ACCESS_ROLES;

router.get('/', authenticate, listOrders);
router.get('/next-number', authenticate, checkRole(manageRoles), getNextOrderNumber);
router.get('/:id', authenticate, getOrder);
router.post('/', authenticate, checkRole(manageRoles), createOrder);
router.patch('/:id', authenticate, checkRole(manageRoles), updateOrder);
router.delete('/:id', authenticate, checkRole(manageRoles), deleteOrder);
router.put('/:id/status', authenticate, updateOrderStatus);

module.exports = router;
