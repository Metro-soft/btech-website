const Application = require('../../../shared/models/Application');
const AssignmentEngine = require('../../../core/logic/assignment_engine');
const NotificationListener = require('../../../core/events/listeners/notification_listener');

exports.submitOrder = async (req, res) => {
  try {
    const { type, payload } = req.body;
    // ... (rest of logic)
    const bestStaffId = await AssignmentEngine.findOptimalStaff();

    const newOrder = await Application.create({
      type,
      payload,
      user: req.user.id,
      assignedTo: bestStaffId || null,
      status: bestStaffId ? 'ASSIGNED' : 'PENDING'
    });

    if (bestStaffId) {
        console.log(`Order Controller: Auto-Assigned Order #${newOrder._id} to Staff #${bestStaffId}`);
    }
    res.status(201).json(newOrder);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// @desc    Get All Applications (Filtered by Role)
exports.getOrders = async (req, res) => {
    try {
        let applications;
        if (req.user.role === 'admin') {
            applications = await Application.find()
                .select('-payload')
                .populate('user', 'name email')
                .populate('assignedTo', 'name')
                .sort({ createdAt: -1 });
        } else if (req.user.role === 'staff') {
            applications = await Application.find({
                $or: [{ status: 'PENDING' }, { assignedTo: req.user._id }] 
            })
            .select('-payload')
            .populate('user', 'name email')
            .populate('assignedTo', 'name')
            .sort({ createdAt: -1 });
        } else {
            applications = await Application.find({ user: req.user.id })
                .select('-payload')
                .populate('assignedTo', 'name')
                .sort({ createdAt: -1 });
        }
        res.json(applications);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Get Single Order
exports.getOrderById = async (req, res) => {
    try {
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Order not found' });
        
        // Access Control
        if (req.user.role !== 'admin' && req.user.role !== 'staff' && app.user.toString() !== req.user.id) {
            return res.status(403).json({ message: 'Not authorized' });
        }
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Process Payment
// @desc    Process Payment (Proxied to Finance Service)
exports.payOrder = async (req, res) => {
    try {
        const { amount, method, transactionId } = req.body;
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Order not found' });

        if (app.payment && app.payment.isPaid) {
            return res.status(400).json({ message: 'Already paid' });
        }

        // 1. Call Finance Service to Process Payment
        const FINANCE_URL = 'http://localhost:5001/api/wallet';
        const jwt = require('jsonwebtoken'); // Lazy load
        const axios = require('axios'); // Lazy load

        // Generate Service Token
        const token = jwt.sign({ id: req.user.id, role: req.user.role }, process.env.JWT_SECRET, { expiresIn: '1m' });
        const idempotencyKey = `PAY-${app._id}-${Date.now()}`;

        try {
            await axios.post(`${FINANCE_URL}/process-payment`, {
                amount,
                method,
                userId: req.user.id,
                reference: transactionId, // Use checkout-generated ID or fallback
                metadata: { applicationId: app._id.toString() }
            }, {
                headers: { 
                    Authorization: `Bearer ${token}`,
                    'Idempotency-Key': idempotencyKey
                }
            });
        } catch (financeError) {
            console.error('Finance Payment Failed:', financeError.message);
            return res.status(400).json({ 
                message: 'Payment processing failed. Please try again.',
                details: financeError.response?.data?.message || financeError.message
            });
        }

        // 2. If Successful, Update Local Order Status
        const txnFee = amount * 0.03;
        const staffPay = (amount - txnFee) * 0.70;

        app.payment = {
            method,
            transactionId,
            isPaid: true,
            staffPay: Math.round(staffPay),
            commissionStatus: 'UNPAID'
        };
        app.cost = { amount, currency: 'KES' };
        app.status = 'PAID';
        app.finalPrice = amount; 

        await app.save();
        res.json(app);
    } catch (err) {
        console.error('PayOrder Error:', err);
        res.status(500).json({ message: err.message });
    }
};

// @desc    Reject Order
exports.rejectOrder = async (req, res) => {
    try {
        const { reason } = req.body;
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Order not found' });

        app.status = 'REJECTED';
        app.adminNotes = reason;
        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Assign Application to Staff (Manual Override)
exports.assignTask = async (req, res) => {
    const { staffId } = req.body;
    try {
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Application not found' });

        if (app.assignedTo) {
             // 7-minute rule check could go here if enforcing strictly
            return res.status(400).json({ message: 'Application already assigned' });
        }

        app.assignedTo = staffId;
        app.status = 'ASSIGNED';
        await app.save();

        // NotificationListener.emit('TASK_ASSIGNED', { staffId, orderId: app._id });

        res.json(app);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Request Input from Client (Staff Only)
exports.requestInput = async (req, res) => {
    try {
        const { message, type } = req.body;
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Order not found' });

        app.clientAction = {
            required: true,
            type: type || 'OTP',
            message: message || 'Please provide the requested information',
            response: null // Reset previous response
        };
        app.status = 'IN_PROGRESS'; // Ensure it's active
        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Submit Input (Client Only)
exports.submitInput = async (req, res) => {
    try {
        const { response } = req.body;
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Order not found' });

        // Access Control
        if (app.user.toString() !== req.user.id) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        app.clientAction.response = response;
        app.clientAction.required = false; // Mark action as done
        // Potentially notify staff here
        
        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Mark Application as Completed
exports.completeTask = async (req, res) => {
    try {
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Application not found' });

        // Verify ownership (if staff)
        if (req.user.role === 'staff' && app.assignedTo.toString() !== req.user.id) {
            return res.status(403).json({ message: 'Not authorized to complete this task' });
        }

        app.status = 'COMPLETED';
        // app.completedAt = Date.now(); // If schema supports it
        await app.save();

        // Trigger Notification
        // NotificationListener.emit('ORDER_COMPLETED', { ... });

        res.json(app);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
