package com.securevault.controller;

import com.securevault.model.UserDocument;
import com.securevault.model.VaultDocument;
import com.securevault.repository.UserRepository;
import com.securevault.repository.VaultRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/auth")
public class AuthController {
    private final UserRepository userRepo;
    private final VaultRepository vaultRepo;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public AuthController(UserRepository userRepo, VaultRepository vaultRepo) {
        this.userRepo = userRepo;
        this.vaultRepo = vaultRepo;
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody Map<String, String> body) {
        String email = (body.getOrDefault("email", "")).trim().toLowerCase();
        String password = body.getOrDefault("password", "");

        if (email.isEmpty() || !email.contains("@")) {
            return ResponseEntity.badRequest()
                    .body(Map.of("ok", false, "error", "Ingresa un correo electrónico válido."));
        }
        if (password.length() < 6) {
            return ResponseEntity.badRequest()
                    .body(Map.of("ok", false, "error", "La contraseña debe tener al menos 6 caracteres."));
        }
        if (userRepo.existsByEmail(email)) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("ok", false, "error", "Este correo ya está registrado."));
        }

        UserDocument user = new UserDocument();
        user.setEmail(email);
        user.setPasswordHash(encoder.encode(password));
        user.setCreatedAt(Instant.now().toString());
        userRepo.save(user);

        if (vaultRepo.findByUserId(email).isEmpty()) {
            VaultDocument vault = new VaultDocument();
            vault.setUserId(email);
            vault.setEncryptedBlob("{\"version\":1,\"clients\":[]}");
            vaultRepo.save(vault);
        }

        return ResponseEntity.ok(Map.of(
                "ok", true,
                "email", email,
                "token", UUID.randomUUID().toString()
        ));
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        String email = (body.getOrDefault("email", "")).trim().toLowerCase();
        String password = body.getOrDefault("password", "");

        if (email.isEmpty() || password.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("ok", false, "error", "Ingresa correo y contraseña."));
        }

        var userOpt = userRepo.findByEmail(email);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("ok", false, "error", "Cuenta no registrada. Crea una cuenta primero."));
        }

        UserDocument user = userOpt.get();
        if (!encoder.matches(password, user.getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("ok", false, "error", "Contraseña incorrecta."));
        }

        return ResponseEntity.ok(Map.of(
                "ok", true,
                "email", email,
                "token", UUID.randomUUID().toString()
        ));
    }
}
