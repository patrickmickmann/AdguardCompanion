import SwiftUI

/// Makes clear that all values are sample data.
struct DemoNotice: View {
    var body: some View {
        Label {
            Text("Demo-Modus: Alle Werte sind Beispieldaten, es besteht keine Serververbindung.")
        } icon: {
            Image(systemName: "sparkles.rectangle.stack")
        }
        .font(.footnote)
        .foregroundStyle(AppColor.warning)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(AppColor.warning.opacity(0.12), in: .rect(cornerRadius: Radius.medium))
    }
}

/// Shown when a refresh failed but older data is still displayed.
struct StaleDataNotice: View {
    let error: APIError
    let fetchedAt: Date

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(error.title).font(.subheadline.weight(.semibold))
                Text("Angezeigt werden Daten von \(fetchedAt.formatted(date: .omitted, time: .shortened)).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColor.warning)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(AppColor.warning.opacity(0.12), in: .rect(cornerRadius: Radius.medium))
        .accessibilityElement(children: .combine)
    }
}

/// Time of the last successful update.
struct FreshnessFooter: View {
    let fetchedAt: Date

    var body: some View {
        Text("Zuletzt aktualisiert: \(fetchedAt.formatted(date: .omitted, time: .standard))")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.s)
    }
}
