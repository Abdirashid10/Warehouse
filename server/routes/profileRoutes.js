const express = require('express');
const {
  getMyProfile,
  updateMyProfile,
  updateMyAvatar,
  changeMyPassword,
  updateMyPreferences,
} = require('../controllers/profileController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authenticate);

router.get('/me', getMyProfile);
router.patch('/me', updateMyProfile);
router.patch('/avatar', updateMyAvatar);
router.patch('/password', changeMyPassword);
router.patch('/preferences', updateMyPreferences);

module.exports = router;
