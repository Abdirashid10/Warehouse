const express = require('express');
const { listActivities, getRecentActivities } = require('../controllers/auditController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');
const { SUPERVISOR_ACCESS_ROLES } = require('../constants/roles');

const router = express.Router();

router.use(authenticate, checkRole(SUPERVISOR_ACCESS_ROLES));

router.get('/activities', listActivities);
router.get('/recent', getRecentActivities);

module.exports = router;
