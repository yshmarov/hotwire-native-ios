import HotwireNative
import SafariServices
import UIKit
import WebKit

final class SceneController: UIResponder {
    var window: UIWindow?

    private let rootURL = Demo.current
    private lazy var navigator = Navigator(pathConfiguration: pathConfiguration, delegate: self)
    private lazy var navigators: [Navigator] = {
        (0..<3).map { _ in Navigator(pathConfiguration: pathConfiguration, delegate: self) }
    }()
    private lazy var tabBarController = TabBarController(navigators: navigators)

    // MARK: - Setup

    private func configureBridge() {
        Hotwire.registerBridgeComponents([
            FormComponent.self,
            MenuComponent.self,
            OverflowMenuComponent.self,
            ButtonComponent.self,
            NavComponent.self,
            ReviewPromptComponent.self
        ])
    }

    private func configureRootViewController() {
        guard let window = window else {
            fatalError()
        }
        UITabBar.configureWithOpaqueBackground()
        UINavigationBar.configureWithOpaqueBackground()
        window.rootViewController = tabBarController
    }

    // MARK: - Authentication

    private func promptForAuthentication() {
        let authURL = rootURL.appendingPathComponent("/signin")
        navigator.route(authURL)
    }

    // MARK: - Path Configuration

    private lazy var pathConfiguration = PathConfiguration(sources: [
        .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
        .server(rootURL.appending(path: "hotwire_native/v1/ios/path_configuration.json"))
    ])
}

extension SceneController: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()

        configureBridge()

        Hotwire.config.makeCustomWebView = { configuration in
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.allowsLinkPreview = false
            Bridge.initialize(webView)
            return webView
        }

        configureRootViewController()

        navigators[0].route(rootURL)
        navigators[1].route(rootURL.appendingPathComponent("posts"))
        navigators[2].route(rootURL.appendingPathComponent("playlists"))

    }
}

extension SceneController: NavigatorDelegate {
    func handle(proposal: VisitProposal) -> ProposalResult {
        switch proposal.viewController {
        case NumbersViewController.pathConfigurationIdentifier:
            return .acceptCustom(NumbersViewController(url: proposal.url, navigator: navigator))

        case "numbers_detail":
            let alertController = UIAlertController(title: "Number", message: "\(proposal.url.lastPathComponent)", preferredStyle: .alert)
            alertController.addAction(.init(title: "OK", style: .default, handler: nil))
            return .acceptCustom(alertController)

        default:
            return .acceptCustom(HotwireWebViewController(url: proposal.url))
        }
    }

    func visitableDidFailRequest(_ visitable: any Visitable, error: any Error, retryHandler: RetryBlock?) {
        if let turboError = error as? TurboError, case let .http(statusCode) = turboError, statusCode == 401 {
            promptForAuthentication()
        } else if let errorPresenter = visitable as? ErrorPresenter {
            errorPresenter.presentError(error) {
                retryHandler?()
            }
        } else {
            let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            navigator.rootViewController.present(alert, animated: true)
        }
    }
}

class TabBarController: UITabBarController {
    private let navigators: [Navigator]
    
    init(navigators: [Navigator]) {
        self.navigators = navigators
        super.init(nibName: nil, bundle: nil)
        
        viewControllers = navigators.map { $0.rootViewController }
        
        // Customize tab bar items
        viewControllers?[0].tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        viewControllers?[1].tabBarItem = UITabBarItem(title: "Posts", image: UIImage(systemName: "play.circle"), tag: 1)
        viewControllers?[2].tabBarItem = UITabBarItem(title: "Playlists", image: UIImage(systemName: "list.number"), tag: 2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
