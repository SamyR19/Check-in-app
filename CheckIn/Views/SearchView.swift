import SwiftUI

/// Live search across family, itinerary, and check-in history,
/// with persisted recent searches — styled after the search reference.
struct SearchView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var focused: Bool

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }

    private var memberResults: [FamilyMember] {
        guard !trimmed.isEmpty else { return [] }
        return store.family.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var stopResults: [ItineraryStop] {
        guard !trimmed.isEmpty else { return [] }
        return store.stops.filter {
            $0.city.localizedCaseInsensitiveContains(trimmed)
                || $0.country.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var eventResults: [ActivityEvent] {
        guard !trimmed.isEmpty else { return [] }
        return store.events.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.detail.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var hasResults: Bool {
        !memberResults.isEmpty || !stopResults.isEmpty || !eventResults.isEmpty
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Search")
                        .font(.display(28, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Theme.surface))
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.85))
                }

                searchField

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if trimmed.isEmpty {
                            recentChips
                        } else if hasResults {
                            results
                        } else {
                            noResults
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .onAppear { focused = true }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
            TextField("People, places, check-ins…", text: $query)
                .font(.display(16, weight: .medium))
                .focused($focused)
                .autocorrectionDisabled()
                .onSubmit { store.addRecentSearch(trimmed) }
            if !query.isEmpty {
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { query = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            Capsule(style: .continuous)
                .fill(Theme.surface)
                .shadow(color: Theme.ink.opacity(0.05), radius: 8, y: 4)
        )
    }

    private var recentChips: some View {
        Group {
            if store.recentSearches.isEmpty {
                VStack(spacing: 8) {
                    Text("🔎")
                        .font(.system(size: 36))
                    Text("Find a person, a city,\nor a past check-in")
                        .font(.display(15, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT")
                        .font(.display(11, weight: .heavy))
                        .foregroundStyle(Theme.inkSecondary)
                        .kerning(1.2)
                    FlowChips(items: store.recentSearches) { item in
                        Haptics.tap()
                        query = item
                    }
                }
            }
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !memberResults.isEmpty {
                resultSection("Family") {
                    ForEach(memberResults) { member in
                        HStack(spacing: 12) {
                            EmojiAvatar(emoji: member.emoji, size: 42)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(member.isMe ? "You" : member.name)
                                    .font(.display(15, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("\(member.role) · seen \(member.lastSeenString)")
                                    .font(.display(13, weight: .medium))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                            Spacer()
                            StatusDot(status: member.status)
                        }
                        .padding(12)
                        .card(cornerRadius: 20)
                    }
                }
            }

            if !stopResults.isEmpty {
                resultSection("Itinerary") {
                    ForEach(stopResults) { stop in
                        HStack(spacing: 12) {
                            Text(stop.emoji).font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(stop.city)
                                    .font(.display(15, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("\(stop.country) · \(stop.dates)")
                                    .font(.display(13, weight: .medium))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                            Spacer()
                            if stop.isCurrent {
                                Text("HERE")
                                    .font(.display(9, weight: .heavy))
                                    .kerning(0.8)
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Theme.lime))
                            }
                        }
                        .padding(12)
                        .card(cornerRadius: 20)
                    }
                }
            }

            if !eventResults.isEmpty {
                resultSection("History") {
                    ForEach(eventResults) { event in
                        EventRow(event: event)
                    }
                }
            }
        }
    }

    private func resultSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.display(11, weight: .heavy))
                .foregroundStyle(Theme.inkSecondary)
                .kerning(1.2)
            VStack(spacing: 8, content: content)
        }
    }

    private var noResults: some View {
        VStack(spacing: 8) {
            Text("🪹")
                .font(.system(size: 36))
            Text("Nothing for “\(trimmed)”")
                .font(.display(15, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

/// Simple wrapping chip row for recent searches.
private struct FlowChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        FlexibleHStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    onTap(item)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.backward")
                            .font(.system(size: 10, weight: .semibold))
                        Text(item)
                            .font(.display(13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Theme.surface))
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
    }
}

/// Minimal wrapping layout (iOS 16+ Layout protocol).
private struct FlexibleHStack: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    SearchView()
        .environment(Store())
}
