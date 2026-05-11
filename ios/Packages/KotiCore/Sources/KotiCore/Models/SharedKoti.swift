import Foundation

/// The Sangha — a single shared koti the entire community writes into.
/// Append-only ledger, hard 1-crore ceiling, foundation-stewarded.
/// Live data — populated by `LikhitaService.getSharedHub()` against
/// `/api/v1/shared/koti`. The previous design-time `SharedKotiCatalog`
/// has been removed; all values now come from the server.
public struct SharedKoti: Sendable, Hashable {
    public let id: String
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
        id: String, name: String, nameLocal: String, target: Int64, count: Int64,
        uniqueWriters: Int, countriesActive: Int, startedOn: String,
        custodian: String, destination: String, estimatedShipDate: String
    ) {
        self.id = id; self.name = name; self.nameLocal = nameLocal
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
