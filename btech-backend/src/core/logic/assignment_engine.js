const User = require('../../shared/models/User');

/**
 * Finds the best available staff member for a task.
 * Logic: Online AND Lowest Load. Break ties with Rating/Random.
 * @returns {Promise<string|null>} User ID or null
 */
const findOptimalStaff = async () => {
    try {
        // Step 1: Query Online Staff
        // Note: Using 'staff' role. Adjust if you have specific 'cyber_staff' etc.
        const candidates = await User.find({ 
            role: 'staff', 
            isOnline: true,
            isActive: true 
        }).sort({ currentLoad: 1 }); // Step 2: Ascending Load

        if (!candidates || candidates.length === 0) {
            console.log('Assignment Engine: No online staff found.');
            return null;
        }

        // Step 3: Pick the first one (Lowest Load)
        // Future refinement: If ties, check rating (not yet implemented in User model)
        const selectedStaff = candidates[0];

        console.log(`Assignment Engine: Selected ${selectedStaff.name} (Load: ${selectedStaff.currentLoad})`);
        return selectedStaff._id;

    } catch (err) {
        console.error('Assignment Engine Error:', err.message);
        throw err;
    }
};

module.exports = { findOptimalStaff };
