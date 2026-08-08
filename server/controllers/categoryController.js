const { Category } = require('../models');

async function listCategories(_req, res) {
  try {
    const categories = await Category.find().sort({ name: 1 }).lean();
    return res.json({
      categories: categories.map((c) => ({
        id: c._id.toString(),
        name: c.name,
        description: c.description ?? '',
        created_at: c.createdAt,
        updated_at: c.updatedAt,
      })),
    });
  } catch (err) {
    console.error('listCategories error:', err.message);
    return res.status(500).json({ message: 'Failed to load categories' });
  }
}

async function createCategory(req, res) {
  try {
    const { name, description } = req.body;
    if (!name || typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ message: 'name is required' });
    }

    const category = await Category.create({
      name: name.trim(),
      description: description != null ? String(description).trim() : '',
    });

    return res.status(201).json({
      category: {
        id: category._id.toString(),
        name: category.name,
        description: category.description,
        created_at: category.createdAt,
        updated_at: category.updatedAt,
      },
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'Category name already exists' });
    }
    console.error('createCategory error:', err.message);
    return res.status(500).json({ message: 'Failed to create category' });
  }
}

module.exports = { listCategories, createCategory };
