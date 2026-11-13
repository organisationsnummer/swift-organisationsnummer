# Organisationsnummer [![Build Status](https://github.com/organisationsnummer/swift-organisationsnummer/actions/workflows/swift.yml/badge.svg)](https://github.com/organisationsnummer/swift-organisationsnummer/actions/workflows/swift.yml)

Validate Swedish organization numbers. Follows version 1.1 of the [specification](https://github.com/organisationsnummer/meta#package-specification-v11).

## Installation

Add the package to `Package.swift`:

```swift
.package(url: "https://github.com/organisationsnummer/swift-organisationsnummer.git", from: "1.0.0")
```

Then add the product to your target:

```swift
.product(name: "Organisationsnummer", package: "swift-organisationsnummer")
```

## Usage

```swift
import Organisationsnummer

// Validate
Organisationsnummer.valid("556016-0680") // true

// Parse, throws OrganisationsnummerError if invalid
let org = try Organisationsnummer.parse("556016-0680")

org.format()                 // "556016-0680"
org.format(separator: false) // "5560160680"
org.type()                   // "Aktiebolag"
org.vatNumber()              // "SE556016068001"
```

The input may have a `-` or `+` separator and a leading `16`, so `5560160680`, `556016-0680` and `165560160680` are the same number.

`type()` returns the Swedish name of the organization type, or `Okänt` when the first digit has no known type.

### Personal identity numbers

A sole proprietorship (enskild firma) uses the owner's personal identity number as its organization number, so a valid personnummer is also a valid organisationsnummer. `personnummer()` returns the `Personnummer` from [personnummer/swift](https://github.com/personnummer/swift).

```swift
let org = try Organisationsnummer.parse("19510217-9974")

org.isPersonnummer()         // true
org.type()                   // "Enskild firma"
org.format()                 // "510217-9974"
org.vatNumber()              // "SE510217997401"
org.personnummer()?.getAge()
```

For any other number `isPersonnummer()` is `false` and `personnummer()` is `nil`.

## Repository name

SwiftPM identifies a package by the last part of its URL. [personnummer/swift](https://github.com/personnummer/swift) is a dependency and already has the identity `swift`, so this repository cannot be named `swift` like the other language repositories.

## In memoriam

Fredrik "Frozzare" Forsmo (1991-2026) was the initiator, co-founder and a core contributor of the organisationsnummer project. This library carries his work. He is missed.

## License

MIT
