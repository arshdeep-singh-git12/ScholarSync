package com.scholarsync.controller;

import com.scholarsync.dto.AuthResponse;
import com.scholarsync.dto.LoginRequest;
import com.scholarsync.dto.RegisterRequest;
import com.scholarsync.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /** Public self-registration — always creates a STUDENT account. */
    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest req) {
        return authService.register(req);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest req) {
        return authService.login(req);
    }
}
