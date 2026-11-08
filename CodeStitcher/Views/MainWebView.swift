import SwiftUI
import WebKit
import SafariServices

/// High-performance WKWebView container for CodeStitcher on iOS.
struct MainWebView: UIViewRepresentable {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Disable pinch/double-tap zoom via UserScript
        let noZoomScript = """
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            document.head.appendChild(meta);
        }
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no';
        """
        let userScript = WKUserScript(source: noZoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)
        
        // Add native bridge
        config.userContentController.add(context.coordinator, name: "CodeStitcherNative")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1.0)
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        context.coordinator.webView = webView
        
        // Initial load
        context.coordinator.loadAppropriateContent()
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Handle reconnect if network changes
        if networkMonitor.isConnected && context.coordinator.isShowingDino {
            context.coordinator.loadAppropriateContent()
        }
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MainWebView
        weak var webView: WKWebView?
        var isShowingDino: Bool = false
        
        init(_ parent: MainWebView) {
            self.parent = parent
        }
        
        func loadAppropriateContent() {
            guard let webView = webView else { return }
            if NetworkMonitor.shared.isConnected {
                isShowingDino = false
                if let url = URL(string: "https://codestitcher-web.github.io/") {
                    webView.load(URLRequest(url: url))
                }
            } else {
                loadDinoGame()
            }
        }
        
        func loadDinoGame() {
            guard let webView = webView else { return }
            isShowingDino = true
            if let dinoURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "dino") ?? Bundle.main.url(forResource: "index", withExtension: "html") {
                webView.loadFileURL(dinoURL, allowingReadAccessTo: dinoURL.deletingLastPathComponent())
            }
        }
        
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            if NetworkMonitor.shared.isConnected {
                isShowingDino = false
                webView?.reload()
            } else {
                loadDinoGame()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                sender.endRefreshing()
            }
        }
        
        // Handle link routing
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let host = url.host?.lowercased() ?? ""
            let scheme = url.scheme?.lowercased() ?? ""
            
            if scheme == "retry" {
                loadAppropriateContent()
                decisionHandler(.cancel)
                return
            }
            
            // Allow internal domains and local bundle URLs
            if host == "codestitcher-web.github.io" || host.hasSuffix(".github.io") || url.isFileURL {
                decisionHandler(.allow)
                return
            }
            
            // Open external URLs in SFSafariViewController
            if scheme == "http" || scheme == "https" {
                let safariVC = SFSafariViewController(url: url)
                if let topVC = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                    .first {
                    topVC.present(safariVC, animated: true)
                }
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        // Handle failure to load
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if !isShowingDino {
                loadDinoGame()
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Native bridge message handler
        }
    }
}
