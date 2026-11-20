import SwiftUI

/// One user rule: what it does at a glance, the exact rule below.
struct UserRuleRow: View {
    let rule: String

    private var kind: UserRuleKind { UserRuleKind(rule) }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let title {
                    Text(DomainDisplayParts.wrappable(title))
                        .accessibilityLabel(title)
                }
                Text(DomainDisplayParts.wrappable(rule))
                    .font(AppFont.technicalSmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .accessibilityLabel(rule)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(accessibilityKind)
    }

    private var title: String? {
        switch kind {
        case let .block(domain), let .allow(domain): domain
        case .comment, .other: nil
        }
    }

    private var symbol: String {
        switch kind {
        case .block: "hand.raised.fill"
        case .allow: "checkmark.shield.fill"
        case .comment: "text.bubble"
        case .other: "slider.horizontal.3"
        }
    }

    private var tint: Color {
        switch kind {
        case .block: AppColor.blocked
        case .allow: AppColor.protection
        case .comment, .other: .secondary
        }
    }

    private var accessibilityKind: String {
        switch kind {
        case .block: String(localized: "Sperrregel")
        case .allow: String(localized: "Ausnahme")
        case .comment: String(localized: "Kommentar")
        case .other: String(localized: "Regel")
        }
    }
}
