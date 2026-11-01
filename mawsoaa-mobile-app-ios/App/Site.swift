import Foundation

/// The website the app shows, and the parts of it the app keeps or hides.
enum Site {
    static let home = URL(string: "https://4nov.sharjah-encyclopedia.org/")!
    static let hosts: Set<String> = ["4nov.sharjah-encyclopedia.org", "sharjah-encyclopedia.org", "www.sharjah-encyclopedia.org"]

    /// Sections of the site that are not part of the app (no accounts, no saved items).
    static let blockedPrefixes = ["/saved", "/account", "/login", "/auth"]

    /// Sites the app never opens (the Academy's website).
    static func isIgnored(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "alashj.ae" || host.hasSuffix(".alashj.ae")
    }

    static func isInternal(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return hosts.contains(host)
    }

    static func isBlocked(_ url: URL) -> Bool {
        isInternal(url) && blockedPrefixes.contains { url.path == $0 || url.path.hasPrefix($0 + "/") }
    }

    static func url(path: String) -> URL {
        URL(string: path, relativeTo: home)!.absoluteURL
    }

    /// Injected into every page: hides the site's own bottom bar (the app draws its own) and every
    /// link to account / saved / login pages.
    static let injectedCSS = """
    .bottom-bar { display: none !important; }
    .result-newtab { display: none !important; }
    .views { display: none !important; }
    .site-ease-btn, [data-a11y-toggle], .a11y { display: none !important; }
    /* the app's own «الفهرس» replaces the site's menu; the header shows the Academy logo (right) and the encyclopedia's */
    .site-menu-btn, .menu-panel, .menu-scrim { display: none !important; }
    .site-academy { display: flex !important; align-items: center; flex-shrink: 0; min-height: 44px; }
    .site-academy-logo { height: 38px !important; width: auto !important; display: block !important; }
    .site-brand-logo { object-position: left center !important; }
    /* the Academy logo is shown, not linked: no link to alashj.ae in the app */
    a[href*="alashj.ae"] { pointer-events: none !important; cursor: default !important; }
    a[href*="alashj.ae"].prose-link { pointer-events: none !important; color: inherit !important; text-decoration: none !important; }
    /* search page: only the title «البحث في الموسوعة»; the hint under the field centred */
    .search-page .ui-hero-kicker, .search-page .ui-hero-lead { display: none !important; }
    .search-hint { text-align: center !important; width: 100% !important; margin-inline: auto !important; align-self: center !important; }
    a[href="/saved"], a[href^="/saved/"], a[href^="/saved?"],
    a[href="/account"], a[href^="/account/"], a[href^="/account?"],
    a[href="/login"], a[href^="/login?"], a[href^="/auth/"] { display: none !important; }
    .layout-welcome, .welcome-layout { padding-bottom: 0 !important; }
    """

    static let injectedJS = """
    (function () {
      var css = \(jsString(injectedCSS));
      function add() {
        if (document.getElementById('mawsoaa-app-css')) return;
        var s = document.createElement('style');
        s.id = 'mawsoaa-app-css';
        s.textContent = css;
        (document.head || document.documentElement).appendChild(s);
      }
      add();
      document.addEventListener('DOMContentLoaded', add);
      // Hide save buttons that some pages render only for signed-in readers, should one appear.
      new MutationObserver(function () {
        add();
        document.querySelectorAll('button[aria-label*="حفظ"], .save-btn, .term-save').forEach(function (b) { b.style.display = 'none'; });
      }).observe(document.documentElement, { childList: true, subtree: true });
    })();
    """

    /// SPA navigation through the site's own router (fast, no reload); falls back to a full load.
    static func routerPushJS(_ path: String) -> String {
        """
        (function () {
          try {
            var app = document.querySelector('#__nuxt') && document.querySelector('#__nuxt').__vue_app__;
            var router = app && app.config.globalProperties.$router;
            if (router) { router.push(\(jsString(path))); return true; }
          } catch (e) {}
          return false;
        })();
        """
    }

    private static func jsString(_ s: String) -> String {
        let data = try! JSONSerialization.data(withJSONObject: [s])
        let arr = String(data: data, encoding: .utf8)!
        return String(arr.dropFirst().dropLast())
    }
}
