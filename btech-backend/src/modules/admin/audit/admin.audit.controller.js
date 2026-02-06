const AuditLog = require('../../../shared/models/AuditLog');

// @desc    Get system audit logs
// @route   GET /api/admin/audit
// @access  Admin
exports.getLogs = async (req, res) => {
    try {
        const { userId, topic, buffer, limit = 50, page = 1 } = req.query;

        const query = {};

        // Filter by User
        if (userId) {
            query.user = userId;
        }

        // Filter by Topic (Partial Match or Exact)
        if (topic) {
            query.topics = topic; // Mongo checks if array contains this value
        }

        // Filter by Buffer
        if (buffer) {
            query.buffer = buffer;
        }

        const count = await AuditLog.countDocuments(query);
        const logs = await AuditLog.find(query)
            .populate('user', 'name email role')
            .sort({ timestamp: -1 })
            .limit(parseInt(limit))
            .skip((parseInt(page) - 1) * parseInt(limit));

        res.json({
            count,
            pages: Math.ceil(count / limit),
            currentPage: parseInt(page),
            logs
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
};
