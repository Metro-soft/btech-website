const Template = require('./template.model');

// @desc    Get all templates
// @route   GET /api/notifications/templates
exports.getTemplates = async (req, res) => {
    try {
        const templates = await Template.find().sort({ createdAt: -1 });
        res.json(templates);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Create a new template
// @route   POST /api/notifications/templates
exports.createTemplate = async (req, res) => {
    try {
        const { title, category, body, action } = req.body;

        const template = await Template.create({
            title,
            category,
            body,
            action,
            createdBy: req.user.id
        });

        res.status(201).json(template);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Update a template
// @route   PUT /api/notifications/templates/:id
exports.updateTemplate = async (req, res) => {
    try {
        let template = await Template.findById(req.params.id);
        if (!template) {
            return res.status(404).json({ message: 'Template not found' });
        }

        template = await Template.findByIdAndUpdate(req.params.id, req.body, {
            new: true,
            runValidators: true
        });

        res.json(template);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Delete a template
// @route   DELETE /api/notifications/templates/:id
exports.deleteTemplate = async (req, res) => {
    try {
        const template = await Template.findById(req.params.id);
        if (!template) {
            return res.status(404).json({ message: 'Template not found' });
        }

        await template.deleteOne();
        res.json({ message: 'Template removed' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Send a broadcast notification
// @route   POST /api/notifications/broadcast
exports.sendBroadcast = async (req, res) => {
    try {
        const { audience, title, message, templateId, type } = req.body;
        const NotificationService = require('../../shared/services/notification.service');
        const User = require('../../shared/models/User');

        let query = {};

        // 1. Determine Audience
        switch (audience) {
            case 'CLIENTS':
                query = { role: 'client' };
                break;
            case 'STAFF':
                query = { role: 'staff' }; // Assuming 'staff' role exists or check specific staff roles
                break;
            case 'ACTIVE':
                query = { isActive: true };
                break;
            case 'ALL_USERS':
            default:
                query = {}; // All users
                break;
        }

        const users = await User.find(query).select('_id');
        console.log(`Broadcasting to ${users.length} users (Audience: ${audience})`);

        // 2. Send in batches (basic implementation)
        // In production, use a queue (BullMQ) for large broadcasts
        let count = 0;
        for (const user of users) {
            // For now, simple loop. Detailed interpolation logic can be added here.
            let finalMessage = message;
            // if (templateId) { ... logic to fetch template and merge ... }

            await NotificationService.send(
                user._id,
                type || 'SYSTEM',
                title,
                finalMessage,
                { priority: 'NORMAL' } // Default priority
            );
            count++;
        }

        res.json({ message: `Broadcast queued for ${count} users` });
    } catch (error) {
        console.error('Broadcast Error Details:', error);
        console.error('Stack Trace:', error.stack);
        res.status(500).json({ message: 'Broadcast Failed: ' + error.message });
    }
};
