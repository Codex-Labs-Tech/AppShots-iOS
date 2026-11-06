import SwiftUI

/// A self-contained SwiftUI host using the package in this checkout.
@main
struct TrailJournalApp: App {
    private let journal: Journal
    private let presentation: CapturePresentation

    init() {
        var journal = Journal()
        let presentation = CaptureSetup.prepare(journal: &journal)
        self.journal = journal
        self.presentation = presentation
    }

    var body: some Scene {
        WindowGroup {
            ContentView(journal: journal, presentation: presentation)
        }
    }
}
