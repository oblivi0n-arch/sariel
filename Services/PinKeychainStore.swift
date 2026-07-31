import Foundation
import Security
import CryptoKit
import LocalAuthentication

enum PinKeychainStore {
    private static let service = "com.oblivi0n-arch.sariel.pin"
    private static let account = "app-pin-hash"

    static func hash(_ pin: String) -> String {
        let digest = SHA256.hash(data: Data(pin.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func savePinHash(_ pin: String) -> Bool {
        let hashed = hash(pin)
        let data = Data(hashed.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data

        let status = SecItemAdd(newItem as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func verifyPin(_ pin: String) -> Bool {
        guard let storedHash = readPinHash() else { return false }
        return storedHash == hash(pin)
    }

    static func hasPinSet() -> Bool {
        readPinHash() != nil
    }

    static func removePin() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func readPinHash() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum BiometricAuth {
    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
}
