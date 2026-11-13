import Foundation
import Personnummer

/// Thrown when a string is not a valid Swedish organization number.
public struct OrganisationsnummerError: Error, CustomStringConvertible {
	public let description = "Invalid swedish organization number"
}

/**
	Parse, validate and format Swedish organization numbers (organisationsnummer).

	Follows the organisationsnummer package specification v1.1:
	https://github.com/organisationsnummer/meta#package-specification-v11

	```
	let org = try Organisationsnummer.parse("556016-0680")
	org.format()                 // "556016-0680"
	org.format(separator: false) // "5560160680"
	org.type()                   // "Aktiebolag"
	org.vatNumber()              // "SE556016068001"

	Organisationsnummer.valid("556016-0680") // true
	```
*/
public struct Organisationsnummer {

	/// The ten digits of the number, without century prefix and separator.
	private let number: String
	/// Set when the number is a personal identity number (sole proprietorship).
	private let pnr: Personnummer?

	// ASCII digits only and `\z` instead of `$`, so that other Unicode digits
	// and a trailing newline are rejected.
	private static let regex = try! NSRegularExpression(
		pattern: "^([0-9]{2})?([0-9]{2})([0-9]{2})([0-9]{2})[-+]?([0-9]{4})\\z"
	)

	public init(_ org: String) throws {
		guard let match = Self.regex.firstMatch(in: org, range: NSRange(org.startIndex..., in: org)) else {
			throw OrganisationsnummerError()
		}
		func group(_ i: Int) -> String? {
			Range(match.range(at: i), in: org).map { String(org[$0]) }
		}

		let prefix = group(1)
		let first = group(2)!
		let second = group(3)!
		let number = first + second + group(4)! + group(5)!

		// May only be prefixed with 16, may not start with a leading zero and
		// the third and fourth digit must be 20 or more.
		if prefix == nil || prefix == "16", Int(first)! >= 10, Int(second)! >= 20, Self.luhn(number) {
			self.number = number
			pnr = nil
			return
		}

		// A personal identity number is also a valid organization number.
		guard let pnr = try? Personnummer.parse(org) else {
			throw OrganisationsnummerError()
		}
		self.number = pnr.year + pnr.month + pnr.day + pnr.num + pnr.check
		self.pnr = pnr
	}

	public static func parse(_ org: String) throws -> Organisationsnummer {
		try Organisationsnummer(org)
	}

	public static func valid(_ org: String) -> Bool {
		(try? parse(org)) != nil
	}

	/// With separator the format is `NNNNNN-NNNN`, without it is `NNNNNNNNNN`.
	/// A personal identity number of someone 100 years or older gets `+` as separator.
	public func format(separator: Bool = true) -> String {
		guard separator else { return number }
		if let pnr = pnr { return pnr.format() }
		return number.prefix(6) + "-" + number.suffix(4)
	}

	public func isPersonnummer() -> Bool {
		pnr != nil
	}

	/// The personal identity number, or `nil` when the number belongs to a legal entity.
	public func personnummer() -> Personnummer? {
		pnr
	}

	/// The type of organization, in Swedish.
	public func type() -> String {
		if isPersonnummer() { return "Enskild firma" }

		switch number.first {
		case "1": return "Dödsbon"
		case "2": return "Stat, landsting, kommun eller församling"
		case "3": return "Utländska företag som bedriver näringsverksamhet eller äger fastigheter i Sverige"
		case "5": return "Aktiebolag"
		case "6": return "Enkelt bolag"
		case "7": return "Ekonomisk förening eller bostadsrättsförening"
		case "8": return "Ideella förening och stiftelse"
		case "9": return "Handelsbolag, kommanditbolag och enkelt bolag"
		default: return "Okänt"
		}
	}

	public func vatNumber() -> String {
		"SE" + number + "01"
	}

	/// Returns true when the last digit of `digits` is a valid Luhn check digit.
	private static func luhn(_ digits: String) -> Bool {
		var sum = 0
		for (i, c) in digits.enumerated() {
			var v = c.wholeNumberValue! * (2 - i % 2)
			if v > 9 { v -= 9 }
			sum += v
		}
		return sum % 10 == 0
	}
}
