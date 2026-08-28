//
//  MedicationNameCipher.swift
//  OneLoop
//
//  AES-256-GCM for medication names at rest (device files) and in Supabase.
//  Transport is HTTPS; fields are ciphertext so the database never stores
//  readable names. Legacy plaintext values are left as-is on read and
//  re-encrypted on the next save.
//

import CryptoKit
import Foundation
import Security

enum MedicationNameCrypto {
    static let prefix = "oln1."

    private static let salt = Data("OneLoop.medname.v1".utf8)
    private static let info = Data("name-field".utf8)

    static func accountKey(userId: String) -> SymmetricKey {
        let normalized = userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let ikm = SymmetricKey(data: Data(normalized.utf8))
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: ikm,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }

    static func encrypt(_ plaintext: String, key: SymmetricKey) -> String {
        if plaintext.hasPrefix(prefix) { return plaintext }
        guard let data = plaintext.data(using: .utf8) else { return plaintext }
        do {
            let sealed = try AES.GCM.seal(data, using: key)
            guard let combined = sealed.combined else { return plaintext }
            return prefix + combined.base64EncodedString()
        } catch {
            return plaintext
        }
    }

    static func decrypt(_ stored: String, key: SymmetricKey) -> String {
        guard stored.hasPrefix(prefix) else { return stored }
        let b64 = String(stored.dropFirst(prefix.count))
        guard let data = Data(base64Encoded: b64) else { return stored }
        do {
            let box = try AES.GCM.SealedBox(combined: data)
            let plain = try AES.GCM.open(box, using: key)
            return String(data: plain, encoding: .utf8) ?? stored
        } catch {
            return stored
        }
    }
}

enum MedicationNameCipher {
    static let shared = DeviceCipher()

    final class DeviceCipher: @unchecked Sendable {
        private let deviceKey: SymmetricKey

        init() {
            deviceKey = MedicationNameKeychain.loadOrCreate()
        }

        func encryptLocal(_ name: String) -> String {
            MedicationNameCrypto.encrypt(name, key: deviceKey)
        }

        func decryptLocal(_ name: String) -> String {
            MedicationNameCrypto.decrypt(name, key: deviceKey)
        }

        func encryptForAccount(_ name: String, userId: UUID) -> String {
            MedicationNameCrypto.encrypt(
                name,
                key: MedicationNameCrypto.accountKey(userId: userId.uuidString)
            )
        }

        func decryptForAccount(_ name: String, userId: UUID) -> String {
            MedicationNameCrypto.decrypt(
                name,
                key: MedicationNameCrypto.accountKey(userId: userId.uuidString)
            )
        }
    }
}

enum HealthDataConsent {
    static let defaultsKey = "hasConsentedHealthDataProcessing"

    static var isGranted: Bool {
        get { UserDefaults.standard.bool(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }
}

private enum MedicationNameKeychain {
    static let service = "com.davidcarranco.oneloop.medtracker.uiv2"
    static let account = "medication-name-device-key"

    static func loadOrCreate() -> SymmetricKey {
        if let data = load(), data.count == 32 {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        save(data)
        return key
    }

    static func load() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    static func save(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
}
