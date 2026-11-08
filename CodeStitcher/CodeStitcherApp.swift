import SwiftUI

@main
struct CodeStitcherApp: App {
    @State private var showSplash: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if showSplash {
                    IntroSplashView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    MainWebView()
                        .ignoresSafeArea(.all, edges: .bottom)
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
