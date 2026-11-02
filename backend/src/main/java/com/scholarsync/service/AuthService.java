package com.scholarsync.service;

import com.scholarsync.dao.UserDao;
import com.scholarsync.dto.AuthResponse;
import com.scholarsync.dto.LoginRequest;
import com.scholarsync.dto.RegisterRequest;
import com.scholarsync.exception.ApiException;
import com.scholarsync.model.Role;
import com.scholarsync.model.User;
import com.scholarsync.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserDao userDao;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserDao userDao, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userDao = userDao;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    /** Public self-registration always creates a STUDENT. Admin/Registrar accounts are seeded, not signed up. */
    public AuthResponse register(RegisterRequest req) {
        String hash = passwordEncoder.encode(req.password());
        User user = userDao.insert(req.username(), hash, req.fullName(), req.email(), Role.STUDENT);
        String token = jwtUtil.generateToken(user.id(), user.username(), user.role().name());
        return new AuthResponse(token, user.id(), user.username(), user.fullName(), user.role().name());
    }

    public AuthResponse login(LoginRequest req) {
        User user = userDao.findByUsername(req.username())
                .orElseThrow(() -> new ApiException(401, "Invalid username or password"));

        if (!passwordEncoder.matches(req.password(), user.passwordHash())) {
            throw new ApiException(401, "Invalid username or password");
        }

        String token = jwtUtil.generateToken(user.id(), user.username(), user.role().name());
        return new AuthResponse(token, user.id(), user.username(), user.fullName(), user.role().name());
    }
}
