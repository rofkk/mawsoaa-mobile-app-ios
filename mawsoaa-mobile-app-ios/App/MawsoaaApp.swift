import SwiftUI
import CoreText

@main
struct MawsoaaApp: App {
    init() {
        // Scheherazade New (SIL OFL), the website's reading font, used by the native bottom bar.
        for name in ["ScheherazadeNew-Regular", "ScheherazadeNew-Bold"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            WebShellView()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
        }
    }
}
