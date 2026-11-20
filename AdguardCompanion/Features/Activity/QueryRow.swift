import SwiftUI

/// Mail-style row for one combined request: badge, domain, device and types.
/// The exact time lives in the section header and the detail view.
struct QueryRow: View {
    let group: QueryLogGroup

    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 32

    private var entry: QueryLogEntry { group.primary }

    var body: some View {
        HStack(spacing: Spacing.m) {
            OutcomeBadge(outcome: entry.outcome, size: badgeSize)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                DomainText(domain: entry.domain)
                    .font(.body.weight(.medium))
                detailLine
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.domain), \(entry.outcome.title)")
        .accessibilityValue("\(entry.client.displayName), \(entry.date.formatted(date: .omitted, time: .standard))")
    }

    private var detailLine: Text {
        var parts = [Text(entry.client.displayName)]
        if !group.queryTypes.isEmpty {
            parts.append(Text(group.queryTypes.joined(separator: " + ")))
        }
        if entry.outcome != .allowed {
            parts.append(Text(entry.outcome.title).foregroundStyle(entry.outcome.tint))
        }
        return parts.dropFirst().reduce(parts[0]) { line, part in Text("\(line) · \(part)") }
    }
}

/// Domain with a de-emphasized subdomain. Truncates at the head so the
/// registrable domain ("datadoghq.com") always stays visible.
struct DomainText: View {
    let domain: String

    var body: some View {
        let parts = DomainDisplayParts(domain: domain)
        Text("\(Text(parts.prefix).foregroundStyle(.secondary))\(Text(parts.base))")
            .lineLimit(1)
            .truncationMode(.head)
    }
}

/// Section header: "Gerade eben", "13:41" or "19. Nov., 13:41".
struct QuerySectionHeader: View {
    let minute: Date
    let now: Date

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .accessibilityAddTraits(.isHeader)
    }

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDate(minute, equalTo: now, toGranularity: .minute) {
            return String(localized: "Gerade eben")
        }
        return calendar.isDateInToday(minute)
            ? minute.formatted(.dateTime.hour().minute())
            : minute.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }
}
