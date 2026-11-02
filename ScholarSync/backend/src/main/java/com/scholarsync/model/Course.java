package com.scholarsync.model;

import java.time.LocalTime;

/**
 * Domain Entity: Course
 * 
 * Demonstrates OOP Principle: Encapsulation & Data Invariant Preservation
 * Represents an academic course offering with capacity tracking and lifecycle state.
 */
public record Course(
        Long id,
        String code,
        String title,
        String description,
        int credits,
        String instructorName,
        String dayOfWeek,
        LocalTime startTime,
        LocalTime endTime,
        String semester,
        int capacity,
        int seatsTaken,
        CourseStatus status
) {
    /**
     * Encapsulated business method calculating remaining open seats.
     */
    public int seatsAvailable() {
        return capacity - seatsTaken;
    }
}
