/**
 * Utility for robust IP address extraction
 * Helps decypher the real client IP behind proxies, load balancers, and Cloudflare.
 */
class IpUtils {
    /**
     * Get the client IP from the request object
     * @param {Object} req - Express request object
     * @returns {String} - The client IP address
     */
    static getClientIp(req) {
        if (!req) return 'Unknown';

        // 1. Check specific headers used by proxies/CDNs
        const headers = [
            'x-client-ip', // Standard
            'x-forwarded-for', // Standard (Comma separated, first one is original client)
            'cf-connecting-ip', // Cloudflare
            'fastly-client-ip', // Fastly
            'true-client-ip', // Akamai/Cloudflare
            'x-real-ip', // Nginx
            'x-cluster-client-ip', // Rackspace
            'x-forwarded',
            'forwarded-for',
            'fowarded'
        ];

        for (const header of headers) {
            if (req.headers[header]) {
                const value = req.headers[header];
                // If multiple IPs (e.g. x-forwarded-for: client, proxy1, proxy2), take the first one
                if (typeof value === 'string' && value.includes(',')) {
                    return value.split(',')[0].trim();
                }
                return value;
            }
        }

        // 2. Fallback to connection/socket remote address
        let ip = req.connection?.remoteAddress ||
            req.socket?.remoteAddress ||
            req.connection?.socket?.remoteAddress ||
            req.ip;

        // 3. Normalize IPv6 mapped IPv4 addresses (::ffff:127.0.0.1 -> 127.0.0.1)
        if (ip && ip.includes('::ffff:')) {
            ip = ip.split('::ffff:')[1];
        }

        // 4. Handle localhost IPv6
        if (ip === '::1') {
            return '127.0.0.1'; // Return standard localhost IPv4 for clarity
        }

        return ip || 'Unknown';
    }
}

module.exports = IpUtils;
