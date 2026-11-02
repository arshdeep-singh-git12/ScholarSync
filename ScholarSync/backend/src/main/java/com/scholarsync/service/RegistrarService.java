package com.scholarsync.service;

import com.scholarsync.dao.CourseDao;
import com.scholarsync.dao.EnrollmentDao;
import com.scholarsync.exception.ApiException;
import com.scholarsync.model.Course;
import com.scholarsync.model.CourseStatus;
import com.scholarsync.model.Enrollment;
import com.scholarsync.model.EnrollmentStatus;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * The "controls the whole system" role: this is the only place a course
 * can be removed. Removing a course auto-drops any currently-approved
 * enrollments in it (marked DROPPED with an explanatory remark) so the
 * data stays consistent — students aren't left "approved" for a course
 * that no longer exists.
 */
@Service
public class RegistrarService {

    private final CourseDao courseDao;
    private final EnrollmentDao enrollmentDao;
    private final DataSource dataSource;

    public RegistrarService(CourseDao courseDao, EnrollmentDao enrollmentDao, DataSource dataSource) {
        this.courseDao = courseDao;
        this.enrollmentDao = enrollmentDao;
        this.dataSource = dataSource;
    }

    public void removeCourse(Long courseId, Long registrarId) {
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Course course = courseDao.findByIdForUpdate(conn, courseId)
                        .orElseThrow(() -> new ApiException(404, "Course not found"));

                if (course.status() == CourseStatus.REMOVED) {
                    throw new ApiException(409, "Course is already removed");
                }

                for (Enrollment e : enrollmentDao.findActiveByCourseForUpdate(conn, courseId)) {
                    enrollmentDao.recordDecision(conn, e.id(), EnrollmentStatus.DROPPED, registrarId,
                            "Auto-dropped: course was removed by the registrar");
                }

                courseDaoMarkRemoved(conn, courseId);
                conn.commit();
            } catch (RuntimeException | SQLException e) {
                conn.rollback();
                if (e instanceof RuntimeException re) throw re;
                throw new RuntimeException("Database error while removing course", e);
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error opening transaction", e);
        }
    }

    private void courseDaoMarkRemoved(Connection conn, Long courseId) throws SQLException {
        try (var ps = conn.prepareStatement("UPDATE courses SET status = 'REMOVED' WHERE id = ?")) {
            ps.setLong(1, courseId);
            ps.executeUpdate();
        }
    }
}
