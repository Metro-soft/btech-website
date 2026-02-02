const Application = require('../../../shared/models/Application');

// @desc    Upload Requirement File
exports.uploadFile = async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ message: 'No file uploaded' });

        // Logic to attach to an order if `applicationId` is passed, or just return URL
        const fileUrl = `${process.env.BASE_URL}/api/files/view/${req.file.filename}`;

        res.json({ message: 'File uploaded', fileUrl });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
