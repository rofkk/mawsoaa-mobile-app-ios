import SwiftUI
import WebKit
import SafariServices

// MARK: - Tabs

enum AppTab: CaseIterable, Hashable {
    case home, search, index

    var title: String {
        switch self {
        case .home: "الرئيسية"
        case .search: "البحث"
        case .index: "الفهرس"
        }
    }

    /// Page the tab opens (the index is a sheet, not a page).
    var path: String? {
        switch self {
        case .home: "/"
        case .search: "/search"
        case .index: nil
        }
    }

    /// Same rule as the website's bottom bar: Home only on "/", the others on their section.
    static func active(for url: URL?) -> AppTab? {
        guard let url, Site.isInternal(url) else { return nil }
        let p = url.path
        if p == "/" || p.isEmpty { return .home }
        if p.hasPrefix("/search") { return .search }
        return nil
    }
}

// MARK: - Screen

struct WebShellView: View {
    @State private var web = WebController()
    @State private var showIndex = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack(alignment: .top) {
            WebViewRepresentable(controller: web)
                .ignoresSafeArea(edges: .top)   // the site pads for the notch itself (viewport-fit=cover)

            if web.isLoading && web.hasLoadedOnce {
                ProgressView(value: web.progress)
                    .progressViewStyle(.linear)
                    .tint(Brand.gold)
                    .frame(height: 2)
                    .transition(.opacity)
            }

            if !web.hasLoadedOnce && web.error == nil {
                SplashView()
            }

            if let error = web.error {
                ErrorView(message: error) { web.retry() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar(active: showIndex ? .index : AppTab.active(for: web.currentURL)) { tab in
                if let path = tab.path { web.open(path: path) } else { showIndex = true }
            }
        }
        .background(Brand.parchment.ignoresSafeArea())
        .sheet(item: $web.externalURL) { url in
            SafariView(url: url).ignoresSafeArea()
        }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        .sheet(isPresented: $showIndex) {
            IndexSheet { web.open(path: $0) }
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
        }
        .animation(.easeInOut(duration: 0.2), value: web.isLoading)
        #if DEBUG
        .task {   // testing: `-index YES` opens الفهرس after launch
            if UserDefaults.standard.bool(forKey: "privacy") {
                try? await Task.sleep(for: .seconds(3)); showPrivacy = true
            }
            if UserDefaults.standard.bool(forKey: "index") {
                try? await Task.sleep(for: .seconds(4)); showIndex = true
            }
        }
        #endif
    }
}

// MARK: - Web controller

@Observable
final class WebController: NSObject {
    var isLoading = true
    var progress: Double = 0
    var hasLoadedOnce = false
    var error: String?
    var currentURL: URL?
    var externalURL: URL?

    @ObservationIgnored private(set) lazy var webView: WKWebView = makeWebView()
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []

    private func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.userContentController.addUserScript(
            WKUserScript(source: Site.injectedJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let bridge = ScriptBridge(self)
        config.userContentController.add(bridge, name: "share")
        config.userContentController.add(bridge, name: "visit")

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true
        web.allowsLinkPreview = false
        web.isOpaque = false
        web.backgroundColor = UIColor(Brand.parchment)
        web.scrollView.backgroundColor = UIColor(Brand.parchment)
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.customUserAgent = nil

        let refresh = UIRefreshControl()
        refresh.tintColor = UIColor(Brand.ox)
        refresh.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        web.scrollView.refreshControl = refresh

        observations = [
            web.observe(\.estimatedProgress, options: [.new]) { [weak self] w, _ in
                MainActor.assumeIsolated { self?.progress = w.estimatedProgress }
            },
            web.observe(\.url, options: [.new]) { [weak self] w, _ in   // also fires on SPA (pushState) navigation
                MainActor.assumeIsolated { self?.currentURL = w.url }
            },
            web.observe(\.isLoading, options: [.new]) { [weak self] w, _ in
                MainActor.assumeIsolated { self?.isLoading = w.isLoading }
            },
        ]
        var start = Site.home
        #if DEBUG
        // Screenshots / testing: `xcrun simctl launch <udid> <bundle> -path /search`
        if let path = UserDefaults.standard.string(forKey: "path") { start = Site.url(path: path) }
        #endif
        web.load(Self.request(start))
        return web
    }

    static func request(_ url: URL) -> URLRequest {
        URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
    }

    /// Go to a page of the site (through the site's router when possible, so it's instant).
    func open(path: String) {
        error = nil
        guard hasLoadedOnce, webView.url.map(Site.isInternal) == true else {
            webView.load(Self.request(Site.url(path: path)))
            return
        }
        webView.evaluateJavaScript(Site.routerPushJS(path)) { [weak self] result, _ in
            if (result as? Bool) != true {
                self?.webView.load(Self.request(Site.url(path: path)))
            }
            self?.webView.scrollView.setContentOffset(.zero, animated: false)
        }
    }

    func retry() {
        error = nil
        if let url = webView.url, Site.isInternal(url) {
            webView.reload()
        } else {
            webView.load(Self.request(Site.home))
        }
    }

    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        retry()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { sender.endRefreshing() }
    }

    /// Messages from the page: native share sheet, and entries read (for «آخر ما قرأت»).
    fileprivate func handle(_ message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        switch message.name {
        case "share":
            let urlString = body["url"] as? String ?? webView.url?.absoluteString ?? Site.home.absoluteString
            let title = (body["title"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            var items: [Any] = []
            if !title.isEmpty { items.append(title) }
            items.append(URL(string: urlString) ?? Site.home)
            presentShareSheet(items)
        case "visit":
            if let path = body["path"] as? String, let title = body["title"] as? String {
                ReadingHistory.shared.record(path: path, title: title)
            }
        default: break
        }
    }

    private func presentShareSheet(_ items: [Any]) {
        guard let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else { return }
        var top = root
        while let p = top.presentedViewController { top = p }
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = top.view
        top.present(sheet, animated: true)
    }

    fileprivate func show(_ error: Error) {
        let ns = error as NSError
        // Cancelled loads (fast taps, SPA navigation) and interrupted frame loads are not errors.
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
        if ns.domain == "WebKitErrorDomain" && ns.code == 102 { return }
        switch ns.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorDataNotAllowed:
            self.error = "لا يوجد اتصال بالإنترنت.\nتحقّق من الاتصال ثم أعد المحاولة."
        case NSURLErrorTimedOut:
            self.error = "استغرق التحميل وقتًا أطول من المعتاد.\nأعد المحاولة بعد قليل."
        default:
            self.error = "تعذّر تحميل الموسوعة.\nأعد المحاولة بعد قليل."
        }
    }
}

extension WebController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { return decisionHandler(.allow) }

        // Links to the Academy's website do nothing in the app.
        if Site.isIgnored(url) { return decisionHandler(.cancel) }

        // Account / saved / login are not part of the app.
        if Site.isBlocked(url) {
            decisionHandler(.cancel)
            webView.load(Self.request(Site.home))
            return
        }

        switch url.scheme?.lowercased() {
        case "http", "https":
            if Site.isInternal(url) || action.targetFrame?.isMainFrame == false {
                decisionHandler(.allow)
            } else {
                // Other websites (the Academy, the 3D library…) open in an in-app Safari sheet.
                decisionHandler(.cancel)
                externalURL = url
            }
        case "mailto", "tel":
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
        case "about", "blob", "data":
            decisionHandler(.allow)
        default:
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        #if DEBUG
        // Testing: `-js "<script>"` runs once after the first page load (e.g. open the menu for a screenshot).
        if !hasLoadedOnce, let js = UserDefaults.standard.string(forKey: "js") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { webView.evaluateJavaScript(js) }
        }
        #endif
        hasLoadedOnce = true
        error = nil
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        show(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        show(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

extension WebController: WKUIDelegate {
    /// Links with target="_blank" / window.open: internal ones load here, external ones in Safari.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url {
            if Site.isBlocked(url) || Site.isIgnored(url) { return nil }
            if Site.isInternal(url) { webView.load(action.request) } else { externalURL = url }
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor () -> Void) {
        present(message, actions: [("حسنًا", .default, { completionHandler() })]) { completionHandler() }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor (Bool) -> Void) {
        present(message, actions: [("إلغاء", .cancel, { completionHandler(false) }),
                                   ("موافق", .default, { completionHandler(true) })]) { completionHandler(false) }
    }

    private func present(_ message: String, actions: [(String, UIAlertAction.Style, () -> Void)], fallback: () -> Void) {
        guard let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else {
            return fallback()
        }
        var top = root
        while let p = top.presentedViewController { top = p }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        for (title, style, handler) in actions { alert.addAction(UIAlertAction(title: title, style: style) { _ in handler() }) }
        top.present(alert, animated: true)
    }
}

/// Weak bridge so the web view's script handlers don't keep the controller alive.
final class ScriptBridge: NSObject, WKScriptMessageHandler {
    private weak var controller: WebController?
    init(_ controller: WebController) { self.controller = controller }
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        controller?.handle(message)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let controller: WebController
    func makeUIView(context: Context) -> WKWebView { controller.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Supporting views

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(Brand.ox)
        return vc
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

/// Shown until the first page has loaded.
struct SplashView: View {
    var body: some View {
        // Same as the system launch screen (Config/Info.plist: LaunchBackground + LaunchLogo), so it continues seamlessly.
        ZStack {
            Brand.ox.ignoresSafeArea()
            Image("LaunchLogo")
                .resizable().scaledToFit()
                .frame(width: 340)
            ProgressView().tint(Brand.goldLight)
                .offset(y: 120)
        }
        .accessibilityLabel("جارٍ تحميل الموسوعة")
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Brand.gold)
            Text(message)
                .font(.custom("ScheherazadeNew-Bold", size: 22, relativeTo: .title3))
                .foregroundStyle(Brand.ink)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text("إعادة المحاولة")
                    .font(.headline)
                    .foregroundStyle(Brand.oxDeep)
                    .padding(.horizontal, 26).padding(.vertical, 11)
                    .background(Capsule().fill(Brand.leaf))
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.parchment.ignoresSafeArea())
    }
}

/// Port of the website's phone bottom bar (BottomNavigation.vue) with the app's three sections.
struct BottomBar: View {
    let active: AppTab?
    let select: (AppTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isActive = active == tab
                Button { select(tab) } label: {
                    Text(tab.title)
                        .font(.custom("ScheherazadeNew-Bold", size: 16.8, relativeTo: .subheadline))
                        .foregroundStyle(isActive ? Brand.ox : Brand.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .overlay(alignment: .top) {
                            if isActive {
                                GeometryReader { g in
                                    UnevenRoundedRectangle(bottomLeadingRadius: 3, bottomTrailingRadius: 3)
                                        .fill(Brand.leaf)
                                        .frame(width: g.size.width * 0.56, height: 3)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(height: 3)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if isActive {
                                Rectangle().fill(Brand.gold)
                                    .frame(width: 5, height: 5)
                                    .rotationEffect(.degrees(45))
                                    .padding(.bottom, 7.2)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .padding(.horizontal, 4)
        .background(alignment: .top) {
            ZStack(alignment: .top) {
                LinearGradient(colors: [Brand.vellum, Brand.parchment], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                Rectangle().fill(Brand.leaf).frame(height: 1).opacity(0.85)
            }
            .shadow(color: Brand.ox.opacity(0.14), radius: 3, y: -2)
        }
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("التنقل السريع")
    }
}

/// Colours from the website (app/assets/css/ui.css). The site has no dark theme, so neither does the shell.
enum Brand {
    static let ox = Color(red: 0x4A / 255, green: 0x15 / 255, blue: 0x0F / 255)
    static let oxDeep = Color(red: 0x24 / 255, green: 0x0A / 255, blue: 0x07 / 255)
    static let oxMid = Color(red: 0x6A / 255, green: 0x21 / 255, blue: 0x17 / 255)
    static let gold = Color(red: 0xC9 / 255, green: 0xA1 / 255, blue: 0x4A / 255)
    static let goldLight = Color(red: 0xF1 / 255, green: 0xD5 / 255, blue: 0x8C / 255)
    static let ink = Color(red: 0x2B / 255, green: 0x1B / 255, blue: 0x14 / 255)
    static let inkSoft = Color(red: 0x4A / 255, green: 0x34 / 255, blue: 0x26 / 255)
    static let parchment = Color(red: 0xF5 / 255, green: 0xE6 / 255, blue: 0xD3 / 255)
    static let vellum = Color(red: 0xFF / 255, green: 0xFB / 255, blue: 0xF2 / 255)
    static let goldPale = Color(red: 0xFB / 255, green: 0xE7 / 255, blue: 0xB0 / 255)
    static let sepia = Color(red: 0x8A / 255, green: 0x3B / 255, blue: 0x12 / 255)
    static let muted = Color(red: 0x7A / 255, green: 0x5A / 255, blue: 0x3A / 255)
    static let line = Color(red: 0xA6 / 255, green: 0x78 / 255, blue: 0x30 / 255).opacity(0.32)

    static let leaf = LinearGradient(
        stops: [
            .init(color: Color(red: 0xA6 / 255, green: 0x78 / 255, blue: 0x30 / 255), location: 0),
            .init(color: goldLight, location: 0.28),
            .init(color: gold, location: 0.52),
            .init(color: Color(red: 0xFB / 255, green: 0xE7 / 255, blue: 0xB0 / 255), location: 0.74),
            .init(color: Color(red: 0xA6 / 255, green: 0x78 / 255, blue: 0x30 / 255), location: 1),
        ],
        startPoint: .leading, endPoint: .trailing)

    static let band = LinearGradient(colors: [oxMid, ox, oxDeep], startPoint: .top, endPoint: .bottom)
}
