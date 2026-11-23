@testable import HotwireNative
import WebKit
import XCTest

final class WebViewBridgeTeardownTests: XCTestCase {
    @MainActor
    func test_finalBackgroundReleaseRemovesHandlerOnMainThread() async {
        let removed = expectation(description: "script handler removed")
        let controller = ObservedContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let reference = BridgeReference(WebViewBridge(webView: webView))
        controller.onRemoval = { isMainThread in
            XCTAssertTrue(isMainThread)
            removed.fulfill()
        }

        DispatchQueue.global().async {
            reference.value = nil
        }
        await fulfillment(of: [removed], timeout: 5)
        withExtendedLifetime(webView) {}
    }

    @MainActor
    func test_finalMainReleaseRemovesHandlerSynchronously() {
        let controller = ObservedContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let reference = BridgeReference(WebViewBridge(webView: webView))
        var removalCount = 0
        controller.onRemoval = { isMainThread in
            XCTAssertTrue(isMainThread)
            removalCount += 1
        }

        reference.value = nil

        XCTAssertEqual(removalCount, 1)
        withExtendedLifetime(webView) {}
    }
}

private final class BridgeReference: @unchecked Sendable {
    var value: WebViewBridge?

    init(_ value: WebViewBridge) {
        self.value = value
    }
}

private final class ObservedContentController: WKUserContentController {
    var onRemoval: ((Bool) -> Void)?

    override func removeScriptMessageHandler(forName name: String) {
        onRemoval?(Thread.isMainThread)
        if Thread.isMainThread {
            super.removeScriptMessageHandler(forName: name)
        }
    }
}
