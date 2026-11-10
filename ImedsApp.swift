import SwiftUI

@main
struct ImedsApp: App {
    @StateObject private var networkManager = NetworkManager()

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if os(tvOS)
        AppleTVView()
            .environmentObject(networkManager)
        #else
        ContentView()
            .environmentObject(networkManager)
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        #endif
    }
}
