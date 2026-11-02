package com.scholarsync.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Map<String, Object>> handleApiException(ApiException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", ex.getMessage());
        return ResponseEntity.status(ex.getStatusCode()).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(fe ->
                fieldErrors.put(fe.getField(), fe.getDefaultMessage()));
        body.put("error", "Validation failed");
        body.put("fields", fieldErrors);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex) {
        log.error("Unhandled exception: ", ex);
        Map<String, Object> body = new LinkedHashMap<>();
        
        // Traverse exception chain to find real cause
        Throwable root = ex;
        while (root.getCause() != null && root != root.getCause()) {
            root = root.getCause();
        }
        
        String rootMsg = root.getMessage() != null ? root.getMessage() : "";
        if (rootMsg.contains("Access denied for user")) {
            body.put("error", "MySQL Access Denied! Please update spring.datasource.password in application.properties with your MySQL password.");
        } else if (rootMsg.contains("Unknown database")) {
            body.put("error", "Database 'course_registration' does not exist! Please run setup_database.bat to import the database.");
        } else if (rootMsg.contains("Table") && rootMsg.contains("doesn't exist")) {
            body.put("error", "Database tables are missing! Please run setup_database.bat to import the schema.");
        } else if (rootMsg.contains("Communications link failure") || rootMsg.contains("Connection refused")) {
            body.put("error", "Cannot connect to MySQL server on port 3306. Please ensure MySQL service is running.");
        } else {
            body.put("error", ex.getMessage() != null ? ex.getMessage() : "Internal server error");
        }
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}
