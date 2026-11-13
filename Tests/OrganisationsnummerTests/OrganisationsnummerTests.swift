import XCTest
import Organisationsnummer

private struct TestItem: Decodable {
	let input: String
	/// With separator, `NNNNNN-NNNN`.
	let long_format: String
	/// Without separator, `NNNNNNNNNN`.
	let short_format: String
	let valid: Bool
	let type: String
	let vat_number: String
}

private func loadTestdata() throws -> [TestItem] {
	let url = URL(string: "https://raw.githubusercontent.com/organisationsnummer/meta/HEAD/testdata/list.json")!
	return try JSONDecoder().decode([TestItem].self, from: Data(contentsOf: url))
}

/// Appends the Luhn check digit to nine digits.
private func withCheckDigit(_ digits: String) -> String {
	var sum = 0
	for (i, c) in digits.enumerated() {
		var v = c.wholeNumberValue! * (2 - i % 2)
		if v > 9 { v -= 9 }
		sum += v
	}
	return digits + String((10 - sum % 10) % 10)
}

class OrganisationsnummerTests: XCTestCase {
	private static var list: [TestItem] = []

	override class func setUp() {
		list = (try? loadTestdata()) ?? []
	}

	override func setUpWithError() throws {
		XCTAssertFalse(Self.list.isEmpty, "could not load testdata")
	}

	func testValid() {
		for item in Self.list {
			for input in [item.input, item.long_format, item.short_format] {
				XCTAssertEqual(item.valid, Organisationsnummer.valid(input), input)
			}
		}
	}

	func testParseThrows() {
		for item in Self.list where !item.valid {
			for input in [item.input, item.long_format, item.short_format] {
				XCTAssertThrowsError(try Organisationsnummer.parse(input), input) {
					XCTAssertTrue($0 is OrganisationsnummerError)
				}
				XCTAssertThrowsError(try Organisationsnummer(input), input)
			}
		}
	}

	func testFormat() throws {
		for item in Self.list where item.valid {
			// `short_format` is left out as input, a personnummer without
			// separator has an ambiguous century.
			for input in [item.input, item.long_format] {
				let org = try Organisationsnummer.parse(input)
				XCTAssertEqual(item.long_format, org.format(), input)
				XCTAssertEqual(item.long_format, org.format(separator: true), input)
				XCTAssertEqual(item.short_format, org.format(separator: false), input)
			}
		}
	}

	func testType() throws {
		for item in Self.list where item.valid {
			XCTAssertEqual(item.type, try Organisationsnummer.parse(item.input).type(), item.input)
		}
	}

	func testTypeByFirstDigit() throws {
		let types = [
			"1": "Dödsbon",
			"2": "Stat, landsting, kommun eller församling",
			"3": "Utländska företag som bedriver näringsverksamhet eller äger fastigheter i Sverige",
			"4": "Okänt",
			"5": "Aktiebolag",
			"6": "Enkelt bolag",
			"7": "Ekonomisk förening eller bostadsrättsförening",
			"8": "Ideella förening och stiftelse",
			"9": "Handelsbolag, kommanditbolag och enkelt bolag",
		]
		for (digit, type) in types {
			let number = withCheckDigit(digit + "02100548")
			let org = try Organisationsnummer.parse(number)
			XCTAssertEqual(type, org.type(), number)
			XCTAssertFalse(org.isPersonnummer(), number)
			XCTAssertNil(org.personnummer(), number)
		}
	}

	func testVatNumber() throws {
		for item in Self.list where item.valid {
			XCTAssertEqual(item.vat_number, try Organisationsnummer.parse(item.input).vatNumber(), item.input)
		}
	}

	func testPersonnummer() throws {
		for item in Self.list where item.valid {
			let org = try Organisationsnummer.parse(item.input)
			let isPersonnummer = item.type == "Enskild firma"
			XCTAssertEqual(isPersonnummer, org.isPersonnummer(), item.input)
			XCTAssertEqual(isPersonnummer, org.personnummer() != nil, item.input)
			if let pnr = org.personnummer() {
				XCTAssertEqual(item.long_format, pnr.format(), item.input)
			}
		}
	}

	func testCenturyPrefix() {
		XCTAssertTrue(Organisationsnummer.valid("165560160680"))
		XCTAssertTrue(Organisationsnummer.valid("16556016-0680"))
		// An organization number may only be prefixed with 16.
		for prefix in ["15", "17", "18", "19", "20", "00"] {
			XCTAssertFalse(Organisationsnummer.valid(prefix + "5560160680"), prefix)
		}
	}

	func testInvalidInput() {
		let inputs = [
			"",
			"-",
			"556016068",
			"55601606800",
			"556016--0680",
			"556016 0680",
			" 5560160680",
			"5560160680\n",
			"556016-068A",
			"0560160680",
			"0000000000",
			"1234567890",
			// Arabic-Indic digits.
			"٥٥٦٠١٦٠٦٨٠",
			"١٢١٢١٢١٢١٢",
		]
		for input in inputs {
			XCTAssertFalse(Organisationsnummer.valid(input), input)
		}
	}
}
