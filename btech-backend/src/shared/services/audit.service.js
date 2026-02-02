const AuditLog = require('../models/AuditLog');
const IpUtils = require('../utils/ip.utils');

/**
 * Service to handle system-wide audit logging
 */
class AuditService {
    /**
     * Log an action
     * @param {Object} params
     * @param {String} params.userId - User performing the action
     * @param {String} params.action - Legacy Action Enum (optional if topics provided)
     * @param {Array} [params.topics] - New Tagging System (e.g. ['auth', 'login'])
     * @param {String} [params.buffer] - Storage context (default: 'db')
     * @param {String} params.resource - Resource ID or Name
     * @param {String} [params.description] - Human readable description
     * @param {Object} [params.metadata] - Additional data (e.g. old vs new status)
     * @param {Object} [params.req] - Express Request object (to extract IP/Agent)
     */
    static async log({ userId, action, topics, buffer, resource, description, metadata, req }) {
        try {
            // Backward Compatibility: If no topics, create from action
            let finalTopics = topics || [];
            if (finalTopics.length === 0 && action) {
                finalTopics = ['legacy', action.toLowerCase(), 'info'];
            }

            const entry = {
                user: userId,
                action, // Keep for legacy enum validation if needed, or null
                topics: finalTopics,
                buffer: buffer || 'db',
                resource,
                description,
                metadata: metadata || {}
            };

            if (req) {
                entry.ipAddress = IpUtils.getClientIp(req);
                entry.userAgent = req.get('User-Agent');

                // FORENSIC DATA: Capture Headers & Connection Info
                entry.metadata = {
                    ...entry.metadata,
                    requestDetails: {
                        method: req.method,
                        url: req.originalUrl,
                        headers: req.headers, // Capture full headers for fingerprinting
                        query: req.query,
                        ip_stack: req.ips // For parsing X-Forwarded-For
                    }
                };
            }

            const newLog = await AuditLog.create(entry);
            if (global.io) {
                global.io.emit('audit_log', newLog);
            }
            // console.log(`[Audit] ${action} on ${resource} by ${userId}`);
        } catch (err) {
            console.error('Audit Log Failed:', err.message);
            // Non-blocking: don't throw, just log error
        }
    }
}

module.exports = AuditService;
