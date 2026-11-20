import SwiftUI

/// Sectioned query list with endless scrolling, swipe actions and context menus.
struct QueryList: View {
    let model: ActivityModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            List {
                if model.filter != .all || model.isDemo {
                    QueryListHeader(filter: model.filter, isDemo: model.isDemo)
                        .listRowSeparator(.hidden)
                }
                ForEach(model.sections) { section in
                    Section {
                        ForEach(section.groups) { group in
                            NavigationLink {
                                QueryDetailScreen(group: group, model: model)
                            } label: {
                                QueryRow(group: group)
                            }
                            .queryRowActions(for: group.primary, model: model)
                        }
                    } header: {
                        QuerySectionHeader(minute: section.minute, now: context.date)
                    }
                }
                footer
            }
            .listStyle(.plain)
        }
        .refreshable { await model.reload() }
        .overlay(alignment: .top) {
            if model.isLoading { ProgressView().padding(.top, Spacing.s) }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let error = model.loadMoreError {
            Button {
                Task { await model.loadMore() }
            } label: {
                Label("\(error.title) – erneut laden", systemImage: "arrow.clockwise")
            }
        } else if model.hasMore {
            ProgressView()
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .task { await model.loadMore() }
        }
    }
}
