const express = require('express');
const { getValuation, getInventoryAudit } = require('../controllers/reportsController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');

const router = express.Router();

const { SUPERVISOR_ACCESS_ROLES } = require('../constants/roles');

router.use(authenticate, checkRole(SUPERVISOR_ACCESS_ROLES));

router.get('/valuation', getValuation);
router.get('/inventory-audit', getInventoryAudit);

module.exports = router;
