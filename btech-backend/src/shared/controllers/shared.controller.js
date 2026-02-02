const Service = require('../models/Service');
const Course = require('../models/Course');

// --- Services ---

exports.getServices = async (req, res) => {
    try {
        const services = await Service.find().sort({ name: 1 });
        res.json(services);
    } catch (err) {
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.getServiceById = async (req, res) => {
    try {
        const service = await Service.findById(req.params.id);
        if (!service) return res.status(404).json({ message: 'Service not found' });
        res.json(service);
    } catch (err) {
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.createService = async (req, res) => {
    try {
        const service = await Service.create(req.body);
        res.status(201).json(service);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.updateService = async (req, res) => {
    try {
        const service = await Service.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!service) return res.status(404).json({ message: 'Service not found' });
        res.json(service);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.deleteService = async (req, res) => {
    try {
        const service = await Service.findByIdAndDelete(req.params.id);
        if (!service) return res.status(404).json({ message: 'Service not found' });
        res.json({ message: 'Service removed' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// --- Courses ---

exports.getCourses = async (req, res) => {
    try {
        const courses = await Course.find().sort({ title: 1 });
        res.json(courses);
    } catch (err) {
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.getCourseById = async (req, res) => {
    try {
        const course = await Course.findById(req.params.id);
        if (!course) return res.status(404).json({ message: 'Course not found' });
        res.json(course);
    } catch (err) {
        res.status(500).json({ message: 'Server Error' });
    }
};
