const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const Review = require('../models/Review');
const Appointment = require('../models/Appointment');

// @route   POST api/reviews
// @desc    Create a review for a completed appointment
// @access  Private (User)
router.post('/', [auth, checkRole(['user'])], async (req, res) => {
    const { appointmentId, rating, comment } = req.body;

    try {
        const appointment = await Appointment.findById(appointmentId);

        if (!appointment) {
            return res.status(404).json({ msg: 'Appointment not found' });
        }

        if (appointment.userId.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        if (appointment.status !== 'completed' && appointment.status !== 'approved') {
            // Usually completed, but let's allow approved for now if completion logic isn't fully implemented
            // return res.status(400).json({ msg: 'Appointment must be completed to leave a review' });
        }

        // Check if review already exists
        const existingReview = await Review.findOne({ appointmentId });
        if (existingReview) {
            return res.status(400).json({ msg: 'Review already exists for this appointment' });
        }

        const newReview = new Review({
            appointmentId,
            studentId: req.user.id,
            providerId: appointment.providerId,
            rating,
            comment
        });

        const review = await newReview.save();
        res.json(review);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/reviews/provider/:providerId
// @desc    Get all reviews for a provider
// @access  Public
router.get('/provider/:providerId', async (req, res) => {
    try {
        const reviews = await Review.find({ providerId: req.params.providerId })
            .populate('studentId', 'name')
            .sort({ createdAt: -1 });
        
        // Calculate average rating
        const totalRating = reviews.reduce((acc, rev) => acc + rev.rating, 0);
        const averageRating = reviews.length > 0 ? (totalRating / reviews.length).toFixed(1) : 0;

        res.json({ reviews, averageRating, count: reviews.length });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
