import SwiftUI

/// The privacy policy of the iOS app (not the whole platform): the app has no accounts and keeps nothing about the reader
/// except the «آخر ما قرأت» list on the phone. Same text as AppStore/privacy-policy/index.html (the public URL).
enum PrivacyPolicy {
    static let updated = "1 نوفمبر 2026"

    struct Section: Identifiable {
        let title: String
        let paragraphs: [String]
        var id: String { title }
    }

    static let intro = "توضّح هذه السياسة كيفية تعامل تطبيق «الموسوعة العربية الشاملة» على أجهزة iPhone مع خصوصيتك. التطبيق من مجمع اللغة العربية في الشارقة، وهو مجاني ولا يتطلب إنشاء حساب أو تسجيل دخول."

    static let sections: [Section] = [
        Section(title: "لا نجمع معلومات شخصية", paragraphs: [
            "لا يطلب التطبيق اسمك أو بريدك الإلكتروني أو رقم هاتفك أو أي معلومات شخصية، ولا يحتوي على حسابات مستخدمين.",
            "لا يصل التطبيق إلى موقعك الجغرافي أو الكاميرا أو الميكروفون أو جهات الاتصال أو الصور.",
            "لا يحتوي التطبيق على إعلانات، ولا يتتبّعك عبر التطبيقات أو المواقع الأخرى، ولا نبيع أي بيانات أو نشاركها لأغراض إعلانية.",
        ]),
        Section(title: "ما يُحفظ على جهازك فقط", paragraphs: [
            "قائمة «آخر ما قرأت»: عناوين آخر عشرين مصطلحًا فتحتها، لتعود إليها بسرعة. تُحفظ هذه القائمة على جهازك فقط، ولا تُرسل إلينا أو إلى أي جهة.",
            "يمكنك مسحها في أي وقت من «الفهرس» ← «آخر ما قرأت» ← «مسح»، وتُحذف تلقائيًا عند حذف التطبيق.",
        ]),
        Section(title: "محتوى الموسوعة والاتصال بالإنترنت", paragraphs: [
            "يعرض التطبيق محتوى الموسوعة من موقعها sharjah-encyclopedia.org، لذا يحتاج إلى اتصال بالإنترنت.",
            "عند تحميل الصفحات، يتلقّى خادم الموسوعة معلومات تقنية معتادة في أي اتصال بالإنترنت، مثل عنوان IP ونوع الجهاز والمتصفح، وتُستخدم لتشغيل الخدمة وحمايتها.",
            "يستخدم موقع الموسوعة خدمة Google Analytics لإحصاءات استخدام مجمّعة وغير معرِّفة (مثل عدد زيارات الصفحات)، بهدف تحسين المحتوى. لا تُربط هذه الإحصاءات بهويتك، ولا تُستخدم للإعلانات أو للتتبّع.",
            "قد يحفظ عرض الصفحات داخل التطبيق ملفات تعريف ارتباط (Cookies) وذاكرة مؤقتة على جهازك لتسريع التحميل، وتُحذف بحذف التطبيق.",
        ]),
        Section(title: "المشاركة والروابط الخارجية", paragraphs: [
            "عند الضغط على «مشاركة البطاقة» تظهر قائمة المشاركة في iOS، ولا تُرسل أي معلومات إلا إلى الوجهة التي تختارها أنت.",
            "تُفتح الروابط إلى المواقع الأخرى في متصفح Safari داخل التطبيق، وتخضع لسياسات الخصوصية الخاصة بتلك المواقع.",
        ]),
        Section(title: "الأطفال", paragraphs: [
            "التطبيق مناسب لجميع الأعمار، ولا يجمع أي معلومات شخصية من أي مستخدم، بما في ذلك الأطفال.",
        ]),
        Section(title: "التحديثات", paragraphs: [
            "قد نحدّث هذه السياسة عند تغيّر خصائص التطبيق، وسيظهر تاريخ آخر تحديث أعلى هذه الصفحة.",
        ]),
        Section(title: "للتواصل", paragraphs: [
            "مجمع اللغة العربية في الشارقة، المدينة الجامعية، الشارقة، الإمارات العربية المتحدة.",
            "البريد الإلكتروني: info@alashj.ae",
            "الهاتف: ‎+971 6 516 0400",
        ]),
    ]
}

/// Native screen for the app's privacy policy (opened from «الفهرس»).
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Brand.band
                HStack {
                    Text("سياسة الخصوصية")
                        .font(.custom("ScheherazadeNew-Bold", size: 26, relativeTo: .title2))
                        .foregroundStyle(Brand.goldLight)
                    Spacer()
                    Button { dismiss() } label: {
                        Text("إغلاق")
                            .font(.custom("ScheherazadeNew-Bold", size: 17, relativeTo: .body))
                            .foregroundStyle(Brand.goldPale)
                            .padding(.horizontal, 16).frame(minHeight: 40)
                            .overlay(Capsule().stroke(Brand.gold.opacity(0.7), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.vertical, 18)
            }
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .bottom) { Rectangle().fill(Brand.leaf).frame(height: 1) }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("تطبيق الموسوعة العربية الشاملة · آخر تحديث: \(PrivacyPolicy.updated)")
                        .font(.custom("ScheherazadeNew-Regular", size: 15, relativeTo: .footnote))
                        .foregroundStyle(Brand.muted)
                    Text(PrivacyPolicy.intro).modifier(BodyText())
                    ForEach(PrivacyPolicy.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "diamond.fill").font(.system(size: 7)).foregroundStyle(Brand.gold)
                                Text(section.title)
                                    .font(.custom("ScheherazadeNew-Bold", size: 22, relativeTo: .title3))
                                    .foregroundStyle(Brand.ox)
                            }
                            ForEach(section.paragraphs, id: \.self) { Text($0).modifier(BodyText()) }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Brand.parchment.ignoresSafeArea())
        .environment(\.colorScheme, .light)
    }

    private struct BodyText: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.custom("ScheherazadeNew-Regular", size: 19, relativeTo: .body))
                .foregroundStyle(Brand.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
