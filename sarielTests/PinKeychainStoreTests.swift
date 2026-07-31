import Testing
@testable import sariel

struct PinKeychainStoreTests {

    @Test func hashIsDeterministicForSameInput() {
        let first = PinKeychainStore.hash("1234")
        let second = PinKeychainStore.hash("1234")
        #expect(first == second)
    }

    @Test func hashDiffersForDifferentInput() {
        let first = PinKeychainStore.hash("1234")
        let second = PinKeychainStore.hash("4321")
        #expect(first != second)
    }

    @Test func hashProducesSixtyFourCharacterHexString() {
        let result = PinKeychainStore.hash("0000")
        #expect(result.count == 64)
        #expect(result.allSatisfy { $0.isHexDigit })
    }

    @Test func hashOfEmptyStringIsStillValid() {
        let result = PinKeychainStore.hash("")
        #expect(result.count == 64)
    }
}
