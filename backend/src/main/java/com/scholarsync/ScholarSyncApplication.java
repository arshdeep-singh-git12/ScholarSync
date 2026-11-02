package com.scholarsync;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * ScholarSync: Enterprise Academic Course Registration and Learning Management System
 * 
 * Object-Oriented Programming System (OOPS) Capstone Project
 * Architecture: 3-Tier Enterprise Layered Architecture
 * (Presentation / Controller Layer -> Service Business Logic Layer -> JDBC DAO Layer -> Relational Database)
 */
@SpringBootApplication
public class ScholarSyncApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScholarSyncApplication.class, args);
    }
}
