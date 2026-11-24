package com.securevault.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "vaults")
public class VaultDocument {
    @Id
    private String id;
    private String userId;
    private String encryptedBlob;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getEncryptedBlob() { return encryptedBlob; }
    public void setEncryptedBlob(String encryptedBlob) { this.encryptedBlob = encryptedBlob; }
}