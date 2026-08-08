const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const {
  UPLOAD_DIR,
  ensureUploadDir,
  isAllowedMime,
  MAX_BYTES,
} = require('../utils/productImageStorage');

ensureUploadDir();

const storage = multer.diskStorage({
  destination(_req, _file, cb) {
    cb(null, UPLOAD_DIR);
  },
  filename(_req, file, cb) {
    const extByMime = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/webp': '.webp',
    };
    const ext = extByMime[file.mimetype] || path.extname(file.originalname).toLowerCase() || '.jpg';
    const name = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${ext}`;
    cb(null, name);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: MAX_BYTES },
  fileFilter(_req, file, cb) {
    if (!isAllowedMime(file.mimetype)) {
      return cb(new Error('Only JPEG, PNG, and WebP images are allowed'));
    }
    return cb(null, true);
  },
});

function handleUploadError(err, req, res, next) {
  if (!err) return next();
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ message: 'Image must be smaller than 2MB' });
  }
  return res.status(400).json({ message: err.message || 'Invalid image upload' });
}

module.exports = {
  uploadProductImage: upload.single('image'),
  handleUploadError,
};
