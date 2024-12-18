import HotwireNative
import WebKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Hotwire WebView
        Hotwire.config.makeCustomWebView = { configuration in
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.allowsLinkPreview = false
            Bridge.initialize(webView)
            return webView
        }
        
        configureHotwire()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func configureHotwire() {
        // Load the path configuration
        Hotwire.loadPathConfiguration(from: [
            .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
            .server(Demo.current.appending(path: "hotwire_native/v1/ios/path_configuration.json"))
        ])

        // Set an optional custom user agent application prefix.
        Hotwire.config.applicationUserAgentPrefix = "Hotwire Demo;"

        // Register bridge components
        Hotwire.registerBridgeComponents([
            FormComponent.self,
            MenuComponent.self,
            OverflowMenuComponent.self,
            ButtonComponent.self,
            NavComponent.self,
            ReviewPromptComponent.self
        ])

        // Set configuration options
        Hotwire.config.backButtonDisplayMode = .minimal
        Hotwire.config.showDoneButtonOnModals = true
#if DEBUG
        Hotwire.config.debugLoggingEnabled = true
#endif
    }
}
