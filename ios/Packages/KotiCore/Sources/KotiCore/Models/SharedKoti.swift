import Foundation

/// The Sangha — a single shared koti the entire community writes into.
/// Append-only ledger, hard 1-crore ceiling, foundation-stewarded.
/// Mirrors `SHARED_KOTI` in design v2 shared-data.jsx.
public struct SharedKoti: Sendable, Hashable {
    public let name: String
    public let nameLocal: String
    public let target: Int64
    public let count: Int64
    public let uniqueWriters: Int
    public let countriesActive: Int
    public let startedOn: String
    public let custodian: String
    public let destination: String
    public let estimatedShipDate: String

    public init(
        name: String, nameLocal: String, target: Int64, count: Int64,
        uniqueWriters: Int, countriesActive: Int, startedOn: String,
        custodian: String, destination: String, estimatedShipDate: String
    ) {
        self.name = name; self.nameLocal = nameLocal
        self.target = target; self.count = count
        self.uniqueWriters = uniqueWriters; self.countriesActive = countriesActive
        self.startedOn = startedOn; self.custodian = custodian
        self.destination = destination; self.estimatedShipDate = estimatedShipDate
    }

    public var progress: Double {
        guard target > 0 else { return 0 }
        return Double(count) / Double(target)
    }

    public var remaining: Int64 { max(0, target - count) }
}

/// One row in the live ticker on the SharedHub screen.
public struct SharedWriter: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let place: String
    public let count: Int
    public let ago: String

    public init(name: String, place: String, count: Int, ago: String) {
        self.id = UUID()
        self.name = name; self.place = place; self.count = count; self.ago = ago
    }
}

/// One row in the "Most generous hands" leaderboard.
public struct SharedTopWriter: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let count: Int
    public let joined: String

    public init(name: String, count: Int, joined: String) {
        self.id = UUID()
        self.name = name; self.count = count; self.joined = joined
    }
}

/// One row in the "From across the world" countries breakdown.
public struct SharedCountryCount: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let country: String
    public let count: Int

    public init(country: String, count: Int) {
        self.id = UUID()
        self.country = country; self.count = count
    }
}

public enum SharedKotiCatalog {
    /// Sample shared koti — replace with backend fetch when /v1/shared/koti
    /// endpoint lands. Values mirror design v2 shared-data.jsx so the UI
    /// renders correctly in TestFlight while backend is being wired up.
    public static let sample = SharedKoti(
        name: "The Foundation Koti",
        nameLocal: "సర్వజన రామ కోటి",
        target: 10_000_000,
        count: 7_842_316,
        uniqueWriters: 14_627,
        countriesActive: 47,
        startedOn: "Sankranti · Jan 14, 2026",
        custodian: "Likhita Foundation",
        destination: "Sri Sita Ramachandra Swamy Temple, Bhadrachalam",
        estimatedShipDate: "Vaikuntha Ekadashi · Dec 31, 2026"
    )

    public static let recentWriters: [SharedWriter] = [
        .init(name: "Lakshmi P.", place: "Hyderabad",      count: 412,  ago: "2s"),
        .init(name: "Anonymous",  place: "Toronto",        count: 108,  ago: "14s"),
        .init(name: "Ravi K.",    place: "Bengaluru",      count: 51,   ago: "38s"),
        .init(name: "Sita N.",    place: "New Jersey",     count: 216,  ago: "1m"),
        .init(name: "Anonymous",  place: "Mumbai",         count: 1008, ago: "2m"),
        .init(name: "Hemanth R.", place: "Vijayawada",     count: 108,  ago: "3m"),
        .init(name: "Padmaja S.", place: "Chennai",        count: 27,   ago: "4m"),
        .init(name: "Anonymous",  place: "Singapore",      count: 324,  ago: "6m"),
        .init(name: "Krishna M.", place: "Bhadrachalam",   count: 1116, ago: "7m"),
        .init(name: "Vidya T.",   place: "London",         count: 108,  ago: "9m"),
        .init(name: "Surya P.",   place: "Tirupati",       count: 216,  ago: "11m"),
        .init(name: "Anonymous",  place: "San Francisco",  count: 51,   ago: "13m"),
    ]

    public static let topWriters: [SharedTopWriter] = [
        .init(name: "A devotee · Bhadrachalam",  count: 41_080, joined: "Jan 14"),
        .init(name: "Lakshmi P. · Hyderabad",    count: 31_752, joined: "Jan 14"),
        .init(name: "Krishna M. · Bhadrachalam", count: 28_116, joined: "Jan 18"),
        .init(name: "Anonymous · Toronto",       count: 22_500, joined: "Jan 22"),
        .init(name: "Padmaja S. · Chennai",      count: 18_900, joined: "Feb 02"),
        .init(name: "Hemanth R. · Vijayawada",   count: 14_580, joined: "Feb 11"),
    ]

    public static let countries: [SharedCountryCount] = [
        .init(country: "India",          count: 6_320_414),
        .init(country: "United States",  count:   812_430),
        .init(country: "Canada",         count:   214_600),
        .init(country: "Singapore",      count:   118_200),
        .init(country: "United Kingdom", count:    97_812),
        .init(country: "Australia",      count:    62_080),
        .init(country: "UAE",            count:    58_900),
        .init(country: "+ 40 others",    count:   157_880),
    ]
}
