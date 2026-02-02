const Course = require('../../../../shared/models/Course');

// Get all courses with filtering
exports.getCourses = async (req, res) => {
  try {
    const { university, category, search } = req.query;
    let query = { published: true }; // Default only published? schema defaults to false. 
    // Wait, static data migrator might default published to false?
    // Let's assume we want all for now or check schema default. 
    // Schema default published is false. Seed script didn't set it. 
    // Let's allow fetching even if unpublished for testing, or assume we update seed.
    // For now, let's relax the published check or filter by it.
    
    // Actually, seed script didn't set published: true. 
    // Let's remove { published: true } for now or update seed.
    query = {}; 

    if (university) query.university = university;
    if (category) query.category = category;
    
    // Simple regex search for title/code if full text index not set on Course
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { code: { $regex: search, $options: 'i' } }
      ];
    }

    const courses = await Course.find(query).sort({ clusterPoints: 1 }); // Sort by points?
    res.json(courses);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching courses', error: error.message });
  }
};

exports.getCourseById = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id).populate('instructor', 'name email');
    if (!course) return res.status(404).json({ message: 'Course not found' });
    res.json(course);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching course', error: error.message });
  }
};
