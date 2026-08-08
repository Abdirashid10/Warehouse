const express = require('express');
const {
  listProducts,
  previewNextSku,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct,
  uploadProductImage,
} = require('../controllers/productController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');
const { uploadProductImage: uploadMiddleware, handleUploadError } = require('../middleware/productImageUpload');

const router = express.Router();

router.get('/', authenticate, listProducts);
router.get('/next-sku', authenticate, previewNextSku);
router.post(
  '/upload-image',
  authenticate,
  checkRole(['Admin', 'Supervisor']),
  uploadMiddleware,
  handleUploadError,
  uploadProductImage
);
router.get('/:id', authenticate, getProduct);
router.post('/', authenticate, checkRole(['Admin', 'Supervisor']), createProduct);
router.patch('/:id', authenticate, checkRole(['Admin', 'Supervisor']), updateProduct);
router.delete('/:id', authenticate, checkRole(['Admin', 'Supervisor']), deleteProduct);

module.exports = router;
