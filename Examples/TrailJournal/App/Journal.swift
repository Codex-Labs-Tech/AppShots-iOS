import Foundation

/// A local journal; an ordinary launch starts empty and does not contact a service.
struct Journal {
    /// An entry with an identifier that does not depend on its displayed title.
    struct Trail: Identifiable, Equatable {
        let id: String
        let title: String
        let distance: String
        let duration: String
        let note: String
    }

    var trails: [Trail] = []

    #if DEBUG
    /// Replaces local data only for a recognized fixture. Unknown names leave data untouched.
    @discardableResult
    mutating func loadFixture(named name: String) -> Bool {
        guard name == "weekend-hikes" else { return false }
        trails = [
            Trail(id: "cedar-loop", title: "Cedar Loop", distance: "4.8 km", duration: "1 hr 20 min",
                  note: "A shaded climb to the ridge, with a quiet spot for lunch beside the creek."),
            Trail(id: "willow-lake", title: "Willow Lake", distance: "7.2 km", duration: "2 hr 10 min",
                  note: "An easy lakeside walk. Bring a light layer for the breeze on the north shore."),
            Trail(id: "meadow-path", title: "Meadow Path", distance: "3.1 km", duration: "50 min",
                  note: "A gentle afternoon route through open grassland and early wildflowers.")
        ]
        return true
    }
    #endif
}

/// Destinations shared by ordinary navigation and the debug capture adapter.
enum JournalRoute: Equatable {
    case journal
    case trail(String)

    #if DEBUG
    /// Accepts only the two documented URL shapes and existing local trail identifiers.
    init?(url: URL, journal: Journal) {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "trailjournal", parts.user == nil, parts.password == nil,
              parts.port == nil, parts.query == nil, parts.fragment == nil else { return nil }
        switch (parts.host, parts.percentEncodedPath) {
        case ("journal", ""):
            self = .journal
        case ("trail", let path):
            guard let trail = journal.trails.first(where: { "/" + $0.id == path }) else { return nil }
            self = .trail(trail.id)
        default:
            return nil
        }
    }
    #endif
}
