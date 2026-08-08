const express = require('express');
const {
  listUsers,
  updateUser,
  deleteUser,
  promoteUser,
  setArchived,
  setStatus,
  resetUserPassword,
} = require('../controllers/userController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authenticate, checkRole(['Admin']));

router.get('/', listUsers);
router.patch('/:id/archive', setArchived);
router.patch('/:id/status', setStatus);
router.post('/:id/reset-password', resetUserPassword);
router.post('/:id/promote', promoteUser);
router.patch('/:id', updateUser);
router.delete('/:id', deleteUser);

module.exports = router;
