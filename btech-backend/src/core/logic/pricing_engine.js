const Application = require('../../modules/client/orders/order.model'); // Placeholder path, needs generic App model

/**
 * Calculates dynamic price based on system load.
 * @param {number} basePrice - The standard service fee
 * @returns {Promise<number>} - Adjusted price
 */
const calculateDynamicPrice = async (basePrice) => {
    try {
        // Step 1: Count PENDING orders
        // Note: verify the Model import specific to your structure refactor
        const pendingCount = await Application.countDocuments({ status: 'PENDING' });

        // Step 2: Define Threshold
        const RUSH_THRESHOLD = 50;

        // Step 3: Apply Surge Pricing
        if (pendingCount > RUSH_THRESHOLD) {
            console.log(`Pricing Engine: Surge Active (Pending: ${pendingCount})`);
            return basePrice * 1.10; // 10% hike
        }

        return basePrice;

    } catch (err) {
        console.error('Pricing Engine Error:', err.message);
        return basePrice; // Fail safe: return base price
    }
};

module.exports = { calculateDynamicPrice };
