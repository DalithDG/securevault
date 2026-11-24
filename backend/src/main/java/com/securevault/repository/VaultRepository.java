package com.securevault.repository;

import com.securevault.model.VaultDocument;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface VaultRepository extends MongoRepository<VaultDocument, String> {
    Optional<VaultDocument> findByUserId(String userId);
}