package com.scholarsync.model;

import java.time.LocalDateTime;

/**
 * Domain Entity: User
 * 
 * Demonstrates OOP Principle: Encapsulation
 * Represents an institutional user principal (Student, Admin, or Registrar)
 * with immutable field state.
 */
public record User(
        Long id,
        String username,
        String passwordHash,
        String fullName,
        String email,
        Role role,
        LocalDateTime createdAt
) {}
