package com.securevault.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.securevault.model.VaultDocument;
import com.securevault.repository.VaultRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api")
public class VaultController {
    private final VaultRepository repo;
    private final ObjectMapper mapper = new ObjectMapper();

    public VaultController(VaultRepository repo) {
        this.repo = repo;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of("ok", true, "service", "securevault-api"));
    }

    @GetMapping("/vault/{userId}")
    public ResponseEntity<String> get(@PathVariable String userId) {
        return repo.findByUserId(userId)
                .map(v -> ResponseEntity.ok(v.getEncryptedBlob()))
                .orElse(ResponseEntity.ok("{\"version\":1,\"clients\":[]}"));
    }

    @PostMapping("/vault/{userId}")
    public ResponseEntity<Void> save(@PathVariable String userId, @RequestBody String blob) {
        VaultDocument doc = repo.findByUserId(userId).orElse(new VaultDocument());
        doc.setUserId(userId);
        doc.setEncryptedBlob(blob);
        repo.save(doc);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/vault/{userId}/extension/save")
    public ResponseEntity<Map<String, Object>> saveFromExtension(
            @PathVariable String userId,
            @RequestBody Map<String, Object> payload
    ) throws Exception {
        String cc = String.valueOf(payload.getOrDefault("cc", "")).trim();
        String nombre = String.valueOf(payload.getOrDefault("nombre", "")).trim();
        String url = String.valueOf(payload.getOrDefault("url", "")).trim();
        String username = String.valueOf(payload.getOrDefault("username", "")).trim();
        String password = String.valueOf(payload.getOrDefault("password", ""));
        String siteName = String.valueOf(payload.getOrDefault("siteName", "")).trim();

        if (url.isEmpty() || username.isEmpty() || password.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "error", "URL, usuario y password requeridos"));
        }

        VaultDocument doc = repo.findByUserId(userId).orElse(new VaultDocument());
        doc.setUserId(userId);

        Map<String, Object> root = new LinkedHashMap<>();
        List<Map<String, Object>> clients = new ArrayList<>();
        if (doc.getEncryptedBlob() != null && !doc.getEncryptedBlob().isBlank()) {
            try {
                root = mapper.readValue(doc.getEncryptedBlob(), new TypeReference<>() {});
                Object rawClients = root.get("clients");
                if (rawClients instanceof List<?> list) {
                    for (Object item : list) {
                        if (item instanceof Map<?, ?> m) {
                            Map<String, Object> copy = new LinkedHashMap<>();
                            m.forEach((k, v) -> copy.put(String.valueOf(k), v));
                            clients.add(copy);
                        }
                    }
                }
            } catch (Exception ignored) {
            }
        }

        String now = Instant.now().toString();
        Map<String, Object> newPage = new LinkedHashMap<>();
        newPage.put("id", UUID.randomUUID().toString());
        newPage.put("siteName", siteName);
        newPage.put("url", url);
        newPage.put("username", username);
        newPage.put("password", password);
        newPage.put("notes", "");
        newPage.put("updatedAt", now);

        Map<String, Object> targetClient = null;
        for (Map<String, Object> c : clients) {
            String cCc = String.valueOf(c.getOrDefault("cc", "")).trim();
            String cNombre = String.valueOf(c.getOrDefault("nombre", "")).trim();
            if ((!cc.isEmpty() && cc.equalsIgnoreCase(cCc)) ||
                (cc.isEmpty() && !nombre.isEmpty() && nombre.equalsIgnoreCase(cNombre))) {
                targetClient = c;
                break;
            }
        }

        if (targetClient == null) {
            targetClient = new LinkedHashMap<>();
            targetClient.put("id", UUID.randomUUID().toString());
            targetClient.put("cc", cc.isEmpty() ? "S/N" : cc);
            targetClient.put("nombre", nombre.isEmpty() ? "Cliente sin nombre" : nombre);
            targetClient.put("pages", new ArrayList<>(List.of(newPage)));
            targetClient.put("createdAt", now);
            targetClient.put("updatedAt", now);
            clients.add(0, targetClient);
        } else {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> pages = targetClient.get("pages") instanceof List<?>
                    ? new ArrayList<>((List<Map<String, Object>>) targetClient.get("pages"))
                    : new ArrayList<>();
            pages.add(0, newPage);
            targetClient.put("pages", pages);
            targetClient.put("updatedAt", now);
        }

        root.put("version", 1);
        root.put("updatedAt", now);
        root.put("clients", clients);

        doc.setEncryptedBlob(mapper.writeValueAsString(root));
        repo.save(doc);

        return ResponseEntity.ok(Map.of(
                "ok", true,
                "client", targetClient,
                "clients", clients
        ));
    }
}
