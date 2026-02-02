const Service = require('../../../../shared/models/Service');

// Get all services or filter by category
exports.getServices = async (req, res) => {
  try {
    const { category, subcategory, search } = req.query;
    let query = { isActive: true };

    if (category) query.category = category;
    if (subcategory) query.subcategory = subcategory;
    
    // Text search if 'search' query param is provided
    if (search) {
      query.$text = { $search: search };
    }

    const services = await Service.find(query).sort({ title: 1 });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching services', error: error.message });
  }
};

// Get single service by ID
exports.getServiceById = async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) return res.status(404).json({ message: 'Service not found' });
    res.json(service);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching service', error: error.message });
  }
};

// Create a new service (Admin only - to be protected by middleware)
exports.createService = async (req, res) => {
  try {
    const service = new Service(req.body);
    await service.save();
    res.status(201).json(service);
  } catch (error) {
    res.status(400).json({ message: 'Error creating service', error: error.message });
  }
};
