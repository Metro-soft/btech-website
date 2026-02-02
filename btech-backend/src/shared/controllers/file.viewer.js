const fs = require('fs');
const path = require('path');
const Jimp = require('jimp');
const AuditService = require('../services/audit.service');

// @desc    Secure View (Watermarked)
exports.viewFile = async (req, res) => {
    try {
        const filename = req.params.filename;
        const filepath = path.join(__dirname, '../../../uploads', filename);

        // Audit Log
        if (req.user) {
            await AuditService.log({
                userId: req.user.id,
                action: 'VIEW_DOCUMENT',
                topics: ['file', 'view', 'access'],
                resource: filename,
                description: 'File accessed',
                req
            });
        }

        if (!fs.existsSync(filepath)) {
            return res.status(404).send('File not found');
        }

        const ext = path.extname(filename).toLowerCase();
        if (['.jpg', '.jpeg', '.png', '.bmp'].includes(ext)) {
            try {
                const image = await Jimp.read(filepath);
                const font = await Jimp.loadFont(Jimp.FONT_SANS_32_WHITE);
                const watermarkText = `VIEW ONLY - ${req.user ? req.user.name : 'GUEST'} - ${new Date().toLocaleTimeString()}`;

                image.print(font, 20, 20, watermarkText, image.bitmap.width);
                image.quality(60);

                const buffer = await image.getBufferAsync(Jimp.MIME_JPEG);
                res.set('Content-Type', 'image/jpeg');
                res.send(buffer);
            } catch (imgErr) {
                res.status(500).send('Error processing secure image');
            }
        } else {
            res.sendFile(filepath);
        }
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
};
