const Application = require('../../../shared/models/Application');
const AuditService = require('../../../shared/services/audit.service');

// @desc    Get Assignments + Pool
exports.getMyTasks = async (req, res) => {
    try {
        const tasks = await Application.find({
            $or: [
                { assignedTo: req.user.id },
                { status: 'PENDING', assignedTo: null }
            ]
        })
            .select('-payload')
            .populate('user', 'name email phone')
            .populate('assignedTo', 'name')
            .sort({ createdAt: -1 });

        res.json(tasks);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update Checklist Step
exports.updateStep = async (req, res) => {
    try {
        const { step, completed } = req.body;
        const app = await Application.findOne({ _id: req.params.id, assignedTo: req.user.id });
        if (!app) return res.status(404).json({ message: 'Task not found or authorized' });

        if (!app.processingSteps) app.processingSteps = [];

        const existingIndex = app.processingSteps.findIndex(s => s.step === step);
        if (existingIndex > -1) {
            app.processingSteps[existingIndex].completed = completed;
            app.processingSteps[existingIndex].completedAt = completed ? Date.now() : null;
        } else {
            app.processingSteps.push({
                step,
                completed,
                completedAt: completed ? Date.now() : null
            });
        }

        if (app.status === 'ASSIGNED') app.status = 'IN_PROGRESS';

        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Complete Task (Submit for Review)
exports.completeTask = async (req, res) => {
    try {
        const app = await Application.findOne({ _id: req.params.id, assignedTo: req.user.id });
        if (!app) return res.status(404).json({ message: 'Task not found or authorized' });

        app.status = 'IN_REVIEW'; // QC Flow
        // app.status = 'COMPLETED'; // Legacy Direct Complete
        app.completedAt = Date.now();

        await app.save();

        // Audit
        await AuditService.log({
            userId: req.user.id,
            action: 'STATUS_CHANGE',
            resource: app._id.toString(),
            description: 'Staff completed task',
            metadata: { newStatus: 'IN_REVIEW' },
            req
        });

        res.json(app);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Reject Assignment (Return to Pool/Reject)
exports.rejectTask = async (req, res) => {
    try {
        const { reason } = req.body;
        const app = await Application.findOne({ _id: req.params.id, assignedTo: req.user.id });
        if (!app) return res.status(404).json({ message: 'Task not found or authorized' });

        // Logic Review: Should staff strictly reject application? Or just unassign self?
        // Legacy: Sets status REJECTED. Keeping legacy behavior for now.
        app.status = 'REJECTED';
        app.adminNotes = reason;

        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Request Info from Client
exports.requestInput = async (req, res) => {
    try {
        const { message, type } = req.body;
        const app = await Application.findOne({ _id: req.params.id, assignedTo: req.user.id });
        if (!app) return res.status(404).json({ message: 'Task not found' });

        app.clientAction = {
            required: true,
            type: type || 'OTP',
            message: message || 'Please provide info',
            response: null
        };
        app.status = 'IN_PROGRESS';

        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
