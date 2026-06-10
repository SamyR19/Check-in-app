import SwiftUI

/// Timeline of everything proof-related, plus the evening recap composer.
struct ActivityView: View {
    @Environment(Store.self) private var store

    @State private var recapText = ""
    @State private var recapSent = false
    @FocusState private var recapFocused: Bool

    private var todayEvents: [ActivityEvent] {
        store.events.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var earlierEvents: [ActivityEvent] {
        store.events.filter { !Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                    .appearStagger(0)
                recapComposer
                    .appearStagger(1)
                if !todayEvents.isEmpty {
                    feedSection(title: "Today", events: todayEvents, startIndex: 2)
                }
                if !earlierEvents.isEmpty {
                    feedSection(title: "Earlier", events: earlierEvents, startIndex: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        HStack {
            Text("Activity")
                .font(.display(28, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            HStack(spacing: 5) {
                Text("🔥")
                    .font(.system(size: 13))
                Text("\(store.streakDays)-day streak")
                    .font(.display(13, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.surface))
        }
    }

    // MARK: - Daily recap

    private var recapComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                EmojiAvatar(emoji: "📸", size: 40, tint: Color(hex: 0xF1E3CD))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Evening recap")
                        .font(.display(16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("One line + a photo, bundled into your parents' digest")
                        .font(.display(12, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            HStack(spacing: 10) {
                TextField("How was today?", text: $recapText)
                    .font(.display(15, weight: .medium))
                    .focused($recapFocused)
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.canvas)
                    )

                Button {
                    Haptics.tap()
                } label: {
                    Image(systemName: "camera")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.canvas)
                        )
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.88))

                Button {
                    sendRecap()
                } label: {
                    Image(systemName: recapSent ? "checkmark" : "arrow.up")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(recapSent ? Theme.ink : .white)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(recapSent ? Theme.lime : Theme.ink)
                        )
                        .symbolEffect(.bounce, value: recapSent)
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.88))
                .disabled(recapText.trimmingCharacters(in: .whitespaces).isEmpty && !recapSent)
            }
        }
        .padding(16)
        .card(cornerRadius: 26)
    }

    private func sendRecap() {
        let text = recapText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        Haptics.success()
        store.sendRecap(text)
        recapText = ""
        recapFocused = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            recapSent = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { recapSent = false }
        }
    }

    // MARK: - Feed

    private func feedSection(title: String, events: [ActivityEvent], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: title)
            VStack(spacing: 10) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    EventRow(event: event)
                        .appearStagger(startIndex + index)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        ActivityView()
    }
    .environment(Store())
}
