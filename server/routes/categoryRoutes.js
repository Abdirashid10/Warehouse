const express = require('express');
const { listCategories, createCategory } = require('../controllers/categoryController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', authenticate, listCategories);
router.post('/', authenticate, checkRole(['Admin', 'Supervisor']), createCategory);

module.exports = router;
