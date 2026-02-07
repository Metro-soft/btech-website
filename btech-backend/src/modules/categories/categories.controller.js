const Category = require('./Category');
const fs = require('fs');
const path = require('path');
const AuditService = require('../../shared/services/audit.service');

// Helper: Save Base64 Image
const saveBase64Image = (base64String, categoryName) => {
    try {
        if (!base64String || !base64String.startsWith('data:image')) return base64String;

        const matches = base64String.match(/^data:image\/([a-zA-Z0-9]+);base64,(.+)$/);
        if (!matches || matches.length !== 3) {
            return base64String; // Return original if not valid base64 image
        }

        const ext = matches[1];
        const data = matches[2];
        const buffer = Buffer.from(data, 'base64');

        const filename = `category_${categoryName.replace(/\s+/g, '_').toLowerCase()}_${Date.now()}.${ext}`;
        const uploadDir = path.join(__dirname, '../../uploads');
        const filepath = path.join(uploadDir, filename);

        // Ensure directory exists
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        fs.writeFileSync(filepath, buffer);

        // Return relative path for API
        return `/api/files/view/${filename}`;
    } catch (error) {
        console.error("Base64 Save Error:", error);
        return base64String; // Fallback to raw string if save fails
    }
};

// @desc    Get all categories
// @route   GET /api/categories
exports.getAllCategories = async (req, res) => {
    try {
        const categories = await Category.find({ isActive: true }).sort('code'); // Default show active
        // If admin, maybe show all? For now, public API just shows active.
        res.json(categories);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Get all categories (Admin)
// @route   GET /api/categories/admin
exports.getAllCategoriesAdmin = async (req, res) => {
    try {
        const categories = await Category.find({}).sort('code');
        res.json(categories);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Get single category by code
// @route   GET /api/categories/:code
exports.getCategoryByCode = async (req, res) => {
    try {
        const category = await Category.findOne({ code: req.params.code.toUpperCase() });
        if (!category) return res.status(404).json({ message: 'Category not found' });
        res.json(category);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Create new category
// @route   POST /api/categories
exports.createCategory = async (req, res) => {
    try {
        const { code, name, tagline, description, heroImage, themeColor, announcements } = req.body;

        // Process Base64 Image
        let imageUrl = heroImage;
        if (heroImage && heroImage.startsWith('data:image')) {
            imageUrl = saveBase64Image(heroImage, code);
        }

        const category = new Category({
            code,
            name,
            tagline,
            description,
            heroImage: imageUrl,
            themeColor,
            announcements
        });

        const savedCategory = await category.save();

        // Audit Log (Create)
        if (req.user) {
            await AuditService.log({
                userId: req.user.id,
                action: 'CATEGORY_CREATE',
                topics: ['admin', 'categories', 'create'],
                description: `Created category: ${savedCategory.name}`,
                resource: savedCategory.name,
                req
            });
        }

        res.status(201).json(savedCategory);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
};

// @desc    Update category
// @route   PUT /api/categories/:id
exports.updateCategory = async (req, res) => {
    try {
        const { name, tagline, description, heroImage, themeColor, announcements, isActive } = req.body;

        let category = await Category.findById(req.params.id);
        if (!category) return res.status(404).json({ message: 'Category not found' });

        // Process Base64 Image
        let imageUrl = heroImage;
        if (heroImage && heroImage.startsWith('data:image')) {
            imageUrl = saveBase64Image(heroImage, category.code);
        }

        category.name = name || category.name;
        category.tagline = tagline || category.tagline;
        category.description = description || category.description;
        if (imageUrl) category.heroImage = imageUrl; // Only update if provided
        category.themeColor = themeColor || category.themeColor;
        category.announcements = announcements || category.announcements;
        if (typeof isActive === 'boolean') category.isActive = isActive;

        const updatedCategory = await category.save();

        // Audit Log (Update)
        if (req.user) {
            let desc = `Updated category: ${updatedCategory.name}`;
            if (name && name !== category.name) desc = `Renamed category: ${updatedCategory.name}`;
            if (typeof isActive === 'boolean') desc = isActive ? `Enabled category: ${updatedCategory.name}` : `Disabled category: ${updatedCategory.name}`;

            await AuditService.log({
                userId: req.user.id,
                action: 'CATEGORY_UPDATE',
                topics: ['admin', 'categories', 'update'],
                description: desc,
                resource: updatedCategory.name,
                req
            });
        }

        res.json(updatedCategory);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
};

// @desc    Delete category
// @route   DELETE /api/categories/:id
exports.deleteCategory = async (req, res) => {
    try {
        const category = await Category.findById(req.params.id);
        if (!category) return res.status(404).json({ message: 'Category not found' });

        await category.deleteOne();

        // Audit Log (Delete)
        if (req.user) {
            await AuditService.log({
                userId: req.user.id,
                action: 'CATEGORY_DELETE',
                topics: ['admin', 'categories', 'delete'],
                description: `Deleted category: ${category.name}`,
                resource: category.name,
                req
            });
        }

        res.json({ message: 'Category removed' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
