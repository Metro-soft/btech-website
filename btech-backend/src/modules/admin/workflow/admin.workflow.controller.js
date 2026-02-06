const Application = require('../../../shared/models/Application');
const AuditService = require('../../../shared/services/audit.service');
// const NotificationListener = require('../../../core/events/listeners/notification_listener');

// @desc    View All Applications (Filtered)
// @route   GET /api/admin/workflow/applications
exports.getAllApplications = async (req, res) => {
    try {
        const { status, user, staffId } = req.query;
        let query = {};
        if (status) query.status = status;
        if (user) query.user = user;
        if (staffId) query['assignedTo'] = staffId;

        const applications = await Application.find(query)
            .select('-payload')
            .populate('user', 'name email')
            .populate('assignedTo', 'name')
            .sort({ createdAt: -1 });

        res.json(applications);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Assign Task to Staff
// @route   PUT /api/admin/workflow/applications/:id/assign
exports.assignTask = async (req, res) => {
    const { staffId } = req.body;
    try {
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Application not found' });

        app.assignedTo = staffId;
        app.status = 'ASSIGNED';
        await app.save();

        await AuditService.log({
            userId: req.user.id,
            action: 'ASSIGNMENT',
            resource: app._id.toString(),
            description: `Admin assigned task to staff ${staffId}`,
            req
        });

        // NotificationListener.emit('TASK_ASSIGNED', { staffId, orderId: app._id });

        res.json(app);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Reject Application
// @route   PUT /api/admin/workflow/applications/:id/reject
exports.rejectApplication = async (req, res) => {
    try {
        const { reason } = req.body;
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Order not found' });

        app.status = 'REJECTED';
        app.adminNotes = reason;
        await app.save();

        await AuditService.log({
            userId: req.user.id,
            action: 'STATUS_CHANGE',
            resource: app._id.toString(),
            description: 'Admin rejected application',
            metadata: { reason },
            req
        });
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Verify and Finalize Task
// @route   PUT /api/admin/workflow/applications/:id/verify
exports.verifyTask = async (req, res) => {
    try {
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Application not found' });

        app.status = 'COMPLETED';
        if (!app.metadata) app.metadata = new Map();
        app.metadata.set('verifiedBy', req.user.id);

        await app.save();

        await AuditService.log({
            userId: req.user.id,
            action: 'STATUS_CHANGE',
            resource: app._id.toString(),
            description: 'Admin Verified and Completed Task',
            req
        });

        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
