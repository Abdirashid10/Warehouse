const express = require('express');
const {
  login,
  register,
  bootstrapFirstAdmin,
  getBootstrapStatus,
} = require('../controllers/authController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/bootstrap-status', getBootstrapStatus);
router.post('/bootstrap', bootstrapFirstAdmin);
router.post('/login', login);
router.post('/register', authenticate, checkRole(['Admin']), register);

module.exports = router;

