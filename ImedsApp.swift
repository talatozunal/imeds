import SwiftUI

@main
struct ImedsApp: App {
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var dil = Yerellestirme.paylasilan

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(networkManager)
                .environmentObject(dil)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if os(tvOS)
        AppleTVView()
        #else
        ContentView()
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        #endif
    }
}
