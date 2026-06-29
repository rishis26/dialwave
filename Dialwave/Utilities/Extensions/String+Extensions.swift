import Foundation

/// String utilities for phone number formatting, validation, and text manipulation.
extension String {

    // MARK: - Phone Number Formatting

    /// Formats a raw digit string into a human-readable phone number.
    ///
    /// Handles common formats:
    /// - 10 digits: `(XXX) XXX-XXXX`
    /// - 11 digits with leading 1: `+1 (XXX) XXX-XXXX`
    /// - 12+ digits with country code: `+XX XXXXX XXXXX`
    /// - Otherwise returns the original string.
    ///
    /// - Returns: A formatted phone number string.
    func formatPhoneNumber() -> String {
        let digits = self.filter { $0.isNumber }

        switch digits.count {
        case 10:
            let area = digits.prefix(3)
            let middle = digits.dropFirst(3).prefix(3)
            let last = digits.suffix(4)
            return "(\(area)) \(middle)-\(last)"

        case 11 where digits.hasPrefix("1"):
            let area = digits.dropFirst(1).prefix(3)
            let middle = digits.dropFirst(4).prefix(3)
            let last = digits.suffix(4)
            return "+1 (\(area)) \(middle)-\(last)"

        case 12...:
            // International: +CC XXXXX XXXXX
            let countryCode = digits.prefix(2)
            let remaining = digits.dropFirst(2)
            let half = remaining.count / 2
            let first = remaining.prefix(half)
            let second = remaining.suffix(remaining.count - half)
            return "+\(countryCode) \(first) \(second)"

        default:
            return self
        }
    }

    /// Whether this string is a plausibly valid phone number.
    ///
    /// Accepts digits, spaces, dashes, parentheses, and an optional leading `+`.
    /// Must contain at least 7 digits.
    var isValidPhoneNumber: Bool {
        let digitsOnly = self.filter { $0.isNumber }
        guard digitsOnly.count >= 7 else { return false }

        let pattern = #"^[+]?[\d\s\-\(\)]{7,20}$"#
        return self.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Text Utilities

    /// Extracts initials from a full name string.
    ///
    /// Takes the first character of the first and last word.
    /// Single-word names return one character.
    ///
    /// - Returns: Uppercased initials (e.g., "Rishi Shah" → "RS").
    var initials: String {
        let components = self.split(separator: " ").map { String($0) }
        guard let first = components.first else { return "?" }

        let firstInitial = String(first.prefix(1)).uppercased()

        if components.count > 1, let last = components.last {
            let lastInitial = String(last.prefix(1)).uppercased()
            return firstInitial + lastInitial
        }

        return firstInitial
    }

    /// Returns a truncated version of the string with an ellipsis if it exceeds the given length.
    ///
    /// - Parameter length: The maximum number of characters before truncation.
    /// - Returns: The original string if shorter than `length`, otherwise truncated with `…`.
    func truncated(to length: Int) -> String {
        guard self.count > length else { return self }
        return String(self.prefix(length)) + "…"
    }
}
