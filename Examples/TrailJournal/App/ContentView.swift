import SwiftUI

/// Renders local entries using stable identifiers independent of the visible copy.
struct ContentView: View {
    let journal: Journal
    let presentation: CapturePresentation
    @State private var path: [String]

    init(journal: Journal, presentation: CapturePresentation) {
        self.journal = journal
        self.presentation = presentation
        let path: [String]
        switch presentation.route {
        case .journal: path = []
        case let .trail(id): path = [id]
        }
        _path = State(initialValue: path)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if let issue = presentation.fixtureIssue {
                    Text(issue).accessibilityIdentifier("journal.fixture-error")
                }
                if presentation.showsTip {
                    Text("Keep a note of the trails you want to return to.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("journal.tip")
                }
                if journal.trails.isEmpty {
                    Text("Your next walk starts here.")
                        .accessibilityIdentifier("journal.empty")
                } else {
                    Section("Weekend walks") {
                        ForEach(journal.trails) { trail in
                            NavigationLink(value: trail.id) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(trail.title).font(.headline)
                                    Text("\(trail.distance) · \(trail.duration)")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .accessibilityIdentifier("journal.trail.\(trail.id)")
                        }
                    }
                }
            }
            .navigationTitle("Trail Journal")
            .navigationDestination(for: String.self) { id in
                if let trail = journal.trails.first(where: { $0.id == id }) {
                    List {
                        Section {
                            Label(trail.distance, systemImage: "figure.walk")
                            Label(trail.duration, systemImage: "clock")
                        }
                        Section("Field notes") {
                            Text(trail.note)
                                .accessibilityIdentifier("trail.note.\(trail.id)")
                        }
                    }
                    .navigationTitle(trail.title)
                }
            }
        }
    }
}
