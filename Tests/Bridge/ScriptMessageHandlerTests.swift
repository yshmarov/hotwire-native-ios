@testable import HotwireNative
import WebKit
import XCTest

final class ScriptMessageHandlerTests: XCTestCase {
    @MainActor
    func test_onlyMainFrameCanSendNativeMessages() async {
        let main = expectation(description: "Main frame reached the native handler")
        let childRan = expectation(description: "Child frame executed its script")
        let delegate = RecordingDelegate { body in
            if body == "main" { main.fulfill() }
            if body == "child-ran" { childRan.fulfill() }
        }
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(ScriptMessageHandler(delegate: delegate), name: "testBridge")
        // Inject into both frames to model a page directly calling the registered
        // WebKit endpoint, independently of the library's main-frame-only script.
        configuration.userContentController.addUserScript(WKUserScript(source: """
            if (window === window.top) {
                window.addEventListener("message", event => {
                    if (event.data === "child-ran") window.webkit.messageHandlers.testBridge.postMessage(event.data);
                });
                window.webkit.messageHandlers.testBridge.postMessage("main");
            } else {
                window.webkit.messageHandlers.testBridge.postMessage("subframe");
                parent.postMessage("child-ran", "*");
            }
            """, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: configuration)
        webView.loadHTMLString("<iframe sandbox='allow-scripts' srcdoc='<p>Child</p>'></iframe>", baseURL: nil)

        await fulfillment(of: [main, childRan], timeout: 10)
        XCTAssertEqual(delegate.messages, ["main", "child-ran"])
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "testBridge")
    }

    private final class RecordingDelegate: ScriptMessageHandlerDelegate {
        private let receive: (String) -> Void
        private(set) var messages: [String] = []

        init(receive: @escaping (String) -> Void) {
            self.receive = receive
        }

        func scriptMessageHandlerDidReceiveMessage(_ scriptMessage: WKScriptMessage) {
            guard let body = scriptMessage.body as? String else { return }
            messages.append(body)
            receive(body)
        }
    }
}
