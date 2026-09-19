import WidgetKit
import SwiftUI

/// The entry point for the FlowHydrate widget extension.
///
/// This bundle registers all home screen and lock screen widgets provided by the app,
/// as well as the Live Activity widget for Dynamic Island and Lock Screen presentations.
@main
struct FlowHydrateWidgetBundle: WidgetBundle {
    /// The collection of widgets included in this extension.
    var body: some Widget {
        FocusWidget()
        HydrationWidget()
        CombinedWidget()
        FocusLockScreenWidget()
        HydrationLockScreenWidget()
        FocusLiveActivity()
    }
}
