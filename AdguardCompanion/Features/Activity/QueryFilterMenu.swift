import SwiftUI

/// Toolbar filter like Mail's filter button; filled while a filter is active.
struct QueryFilterMenu: View {
    @Binding var selection: QueryLogFilter

    var body: some View {
        Menu {
            Picker("Filter", selection: $selection) {
                ForEach(QueryLogFilter.allCases) { filter in
                    Label(filter.title, systemImage: filter.systemImage).tag(filter)
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: selection == .all
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .accessibilityValue(Text(selection.title))
    }
}

/// Section header that keeps the active filter and demo state visible.
struct QueryListHeader: View {
    let filter: QueryLogFilter
    let isDemo: Bool

    var body: some View {
        HStack(spacing: Spacing.s) {
            if filter != .all {
                Label(filter.title, systemImage: filter.systemImage)
            }
            Spacer(minLength: 0)
            if isDemo {
                Text("Demo · Beispieldaten")
                    .foregroundStyle(AppColor.warning)
            }
        }
        .font(.footnote.weight(.semibold))
    }
}
