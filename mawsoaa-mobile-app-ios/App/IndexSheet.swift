import SwiftUI

/// «الفهرس»: the encyclopedia's index (section › field › science), drawn natively in the website's style,
/// with the Academy and encyclopedia logos on top. Choosing a science opens its page in the web view.
struct IndexSheet: View {
    let open: (String) -> Void          // site path to load
    @Environment(\.dismiss) private var dismiss
    @State private var model = IndexModel()
    @State private var expanded: Set<Int> = []
    @State private var history = ReadingHistory.shared
    @State private var showPrivacy = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    recentlyRead
                    quickLinks
                    Rectangle().fill(Brand.line).frame(height: 1).padding(.vertical, 8)
                    Text("فهرس الموسوعة")
                        .font(.custom("ScheherazadeNew-Bold", size: 20, relativeTo: .headline))
                        .foregroundStyle(Brand.sepia)
                        .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 6)
                    content
                }
                .padding(.bottom, 32)
            }
            .refreshable { await model.load(force: true) }
        }
        .background(Brand.parchment.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .task { await model.load() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    // Oxblood band: Academy logo (right) and the encyclopedia's gold logo, close button on the left.
    private var header: some View {
        ZStack {
            Brand.band
            HStack(alignment: .center, spacing: 14) {
                Brand.goldLight
                    .mask(Image("AcademyLogoMask").resizable().scaledToFit())
                    .aspectRatio(410 / 128, contentMode: .fit)
                    .frame(height: 50)
                    .accessibilityLabel("مجمع اللغة العربية في الشارقة")
                Brand.leaf
                    .mask(Image("LogoFull").resizable().scaledToFit())
                    .aspectRatio(668.19 / 235.2, contentMode: .fit)
                    .frame(height: 46)
                    .accessibilityLabel("الموسوعة العربية الشاملة")
                Spacer(minLength: 8)
                Button { dismiss() } label: {
                    Text("إغلاق")
                        .font(.custom("ScheherazadeNew-Bold", size: 17, relativeTo: .body))
                        .foregroundStyle(Brand.goldPale)
                        .padding(.horizontal, 16).frame(minHeight: 40)
                        .overlay(Capsule().stroke(Brand.gold.opacity(0.7), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .bottom) { Rectangle().fill(Brand.leaf).frame(height: 1) }
    }

    private var quickLinks: some View {
        VStack(spacing: 0) {
            linkRow("الإحصائيات", path: "/statistics")
            linkRow("عن الموسوعة", path: "/about")
            Button { showPrivacy = true } label: {
                HStack {
                    Text("سياسة الخصوصية")
                        .font(.custom("ScheherazadeNew-Bold", size: 22, relativeTo: .title3))
                        .foregroundStyle(Brand.ink)
                    Spacer()
                    Image(systemName: "chevron.left").font(.footnote.weight(.semibold)).foregroundStyle(Brand.gold)
                }
                .padding(.horizontal, 20).frame(minHeight: 54)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    /// «آخر ما قرأت»: the last entries opened, stored on this phone only.
    @ViewBuilder private var recentlyRead: some View {
        let items = Array(history.items.prefix(5))
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("آخر ما قرأت")
                        .font(.custom("ScheherazadeNew-Bold", size: 20, relativeTo: .headline))
                        .foregroundStyle(Brand.sepia)
                    Spacer()
                    Button("مسح") { withAnimation { history.clear() } }
                        .font(.custom("ScheherazadeNew-Regular", size: 16, relativeTo: .footnote))
                        .foregroundStyle(Brand.muted)
                        .accessibilityLabel("مسح سجلّ القراءة")
                }
                .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 6)

                VStack(spacing: 0) {
                    ForEach(items) { item in
                        Button { go(item.path) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.footnote).foregroundStyle(Brand.gold)
                                Text(item.title)
                                    .font(.custom("ScheherazadeNew-Regular", size: 20, relativeTo: .body))
                                    .foregroundStyle(Brand.ink)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 18).frame(minHeight: 46)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if item.id != items.last?.id {
                            Rectangle().fill(Brand.line).frame(height: 1).padding(.horizontal, 18)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Brand.vellum))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.line, lineWidth: 1))
                .padding(.horizontal, 16)

                Rectangle().fill(Brand.line).frame(height: 1).padding(.top, 16)
            }
        }
    }

    private func linkRow(_ title: String, path: String) -> some View {
        Button { go(path) } label: {
            HStack {
                Text(title)
                    .font(.custom("ScheherazadeNew-Bold", size: 22, relativeTo: .title3))
                    .foregroundStyle(Brand.ink)
                Spacer()
                Image(systemName: "chevron.left").font(.footnote.weight(.semibold)).foregroundStyle(Brand.gold)
            }
            .padding(.horizontal, 20).frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var content: some View {
        if model.domains.isEmpty && model.isLoading {
            ProgressView().tint(Brand.ox).frame(maxWidth: .infinity).padding(40)
        } else if model.domains.isEmpty, model.failed {
            VStack(spacing: 12) {
                Text("تعذّر تحميل الفهرس.").font(.custom("ScheherazadeNew-Bold", size: 19, relativeTo: .body)).foregroundStyle(Brand.ink)
                Button("إعادة المحاولة") { Task { await model.load(force: true) } }.tint(Brand.ox)
            }
            .frame(maxWidth: .infinity).padding(32)
        } else {
            ForEach(model.domains) { domain in
                domainRow(domain)
            }
        }
    }

    private func domainRow(_ d: IndexDomain) -> some View {
        let isOpen = expanded.contains(d.id)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isOpen { expanded.remove(d.id) } else { expanded.insert(d.id) }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "diamond.fill").font(.system(size: 7)).foregroundStyle(Brand.gold)
                    Text(d.name)
                        .font(.custom("ScheherazadeNew-Bold", size: 21, relativeTo: .title3))
                        .foregroundStyle(isOpen ? Brand.ox : Brand.ink)
                    Spacer()
                    Text("\(d.arts.count)")
                        .font(.custom("ScheherazadeNew-Regular", size: 16, relativeTo: .footnote))
                        .foregroundStyle(Brand.muted)
                        .monospacedDigit()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.gold)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(.horizontal, 20).frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOpen ? "طيّ" : "عرض العلوم")

            if isOpen {
                VStack(spacing: 0) {
                    ForEach(d.arts) { art in
                        Button { go("/art/\(art.id)") } label: {
                            HStack {
                                Text(art.name)
                                    .font(.custom("ScheherazadeNew-Regular", size: 20, relativeTo: .body))
                                    .foregroundStyle(Brand.ink)
                                Spacer()
                                Text(Self.termsCount(art.cards))
                                    .font(.custom("ScheherazadeNew-Regular", size: 15, relativeTo: .footnote))
                                    .foregroundStyle(Brand.muted)
                            }
                            .padding(.horizontal, 18).frame(minHeight: 46)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if art.id != d.arts.last?.id {
                            Rectangle().fill(Brand.line).frame(height: 1).padding(.horizontal, 18)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Brand.vellum))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.line, lineWidth: 1))
                .padding(.horizontal, 16).padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func go(_ path: String) {
        dismiss()
        open(path)
    }

    /// «27 مصطلحًا» (the site's Arabic number agreement, Western digits).
    static func termsCount(_ n: Int) -> String {
        let f = NumberFormatter(); f.locale = Locale(identifier: "en_US"); f.numberStyle = .decimal
        let num = f.string(from: NSNumber(value: n)) ?? "\(n)"
        if n == 1 { return "مصطلح واحد" }
        if n == 2 { return "مصطلحان" }
        let m = n % 100
        if (3...10).contains(m) { return "\(num) مصطلحات" }
        if m >= 11 { return "\(num) مصطلحًا" }
        return "\(num) مصطلحٍ"
    }
}

// MARK: - Data (the site's public API)

struct IndexDomain: Identifiable { let id: Int; let name: String; let arts: [IndexArt] }
struct IndexArt: Identifiable { let id: Int; let name: String; let cards: Int }

@Observable
final class IndexModel {
    var domains: [IndexDomain] = []
    var isLoading = false
    var failed = false

    private struct Category: Decodable {
        let slug: String; let category_type: String; let subcategories: [Sub]
        struct Sub: Decodable { let id: Int; let name_ar: String; let order: Int?; let is_active: Bool?; let visibility_status: String? }
    }
    private struct Mappings: Decodable {
        let results: [M]
        struct M: Decodable {
            let art: A; let public_subcategory: S?; let display_name: String?; let display_order: Int?; let visible_cards_count: Int?
            struct A: Decodable { let id: Int; let name: String }
            struct S: Decodable { let id: Int }
        }
    }

    func load(force: Bool = false) async {
        if !force && !domains.isEmpty { return }
        isLoading = true; failed = false
        defer { isLoading = false }
        do {
            async let cats: [Category] = fetch("public-categories")
            async let maps: Mappings = fetch("all-mappings")
            let (categories, mappings) = try await (cats, maps)
            // Same scope as the website's index: the sciences (biographies are held back for now).
            let subs = categories
                .filter { $0.category_type == "terminologies" }
                .flatMap(\.subcategories)
                .filter { ($0.is_active ?? true) && $0.visibility_status != "hidden" }
                .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            domains = subs.compactMap { sub in
                let arts = mappings.results
                    .filter { $0.public_subcategory?.id == sub.id && ($0.visible_cards_count ?? 0) > 0 }
                    .sorted { ($0.display_order ?? 1000) < ($1.display_order ?? 1000) }
                    .map { m in
                        let shown = (m.display_name ?? "").trimmingCharacters(in: .whitespaces)
                        return IndexArt(id: m.art.id, name: shown.isEmpty ? m.art.name : shown, cards: m.visible_cards_count ?? 0)
                    }
                return arts.isEmpty ? nil : IndexDomain(id: sub.id, name: sub.name_ar, arts: arts)
            }
        } catch {
            failed = true
        }
    }

    private func fetch<T: Decodable>(_ path: String) async throws -> T {
        let url = Site.home.appendingPathComponent("api").appendingPathComponent(path)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
