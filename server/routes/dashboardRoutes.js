const express = require('express');
const { getDashboardStats, getDashboardWidgets } = require('../controllers/dashboardController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/stats', authenticate, getDashboardStats);
router.get('/widgets', authenticate, getDashboardWidgets);

module.exports = router;
