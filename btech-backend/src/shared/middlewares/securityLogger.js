const rateLimit = require('express-rate-limit');
const AuditService = require('../services/audit.service');

// 1. Rate Limiter (DOS Protection)
const rateLimiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes default
    max: parseInt(process.env.RATE_LIMIT_MAX) || 100, // Limit each IP to 100 requests per windowMs
    handler: async (req, res, next, options) => {
        const ip = req.ip || req.connection.remoteAddress;

        // Log Critical DOS Attempt
        await AuditService.log({
            userId: null, // Unknown user
            topics: ['security', 'dos', 'critical'],
            message: `Rate Limit Exceeded: ${req.rateLimit.current} reqs`,
            resource: ip,
            buffer: 'db',
            req: req
        });

        res.status(options.statusCode).json({
            message: 'Too many requests, please try again later.'
        });
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// 2. SQL Injection Detector (Basic Pattern Matching)
// Patterns: UNION SELECT, DROP TABLE, OR 1=1, --
const sqlInjectionPattern = /(\b(UNION|SELECT|INSERT|UPDATE|DELETE|DROP|ALTER)\b)|(' OR ')|(1=1)|(--)/i;

const sqlInjectionDetector = async (req, res, next) => {
    try {
        const bodyStr = JSON.stringify(req.body || {});
        // const queryStr = JSON.stringify(req.query || {});
        const urlStr = req.originalUrl;



        // Check Body and URL
        if (sqlInjectionPattern.test(bodyStr) || sqlInjectionPattern.test(urlStr)) {
            const ip = req.ip || req.connection.remoteAddress;

            // Log Critical SQLi Attempt
            await AuditService.log({
                userId: req.user ? req.user.id : null,
                topics: ['security', 'sqli', 'critical'],
                message: `SQL Injection Detected in Request`,
                resource: urlStr,
                buffer: 'db',
                description: `Payload: ${bodyStr.substring(0, 100)}...`, // Truncate payload
                req: req
            });

            return res.status(403).json({ message: 'Malicious Request Blocked' });
        }

        next();
    } catch (err) {
        console.error('Security Middleware Error:', err);
        next(); // Don't block valid requests on error
    }
};

module.exports = { rateLimiter, sqlInjectionDetector };
