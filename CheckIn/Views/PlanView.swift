import SwiftUI

/// Itinerary with "currently at" marker + spend tracker.
struct PlanView: View {
    @Environment(Store.self) private var store
    @State private var showAddExpense = false
    @State private var spendShown = false
    @State private var pulse = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                tripHeader
                    .appearStagger(0)
                itinerary
                    .appearStagger(1)
                spendTracker
                    .appearStagger(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet()
                .presentationDetents([.medium])
                .presentationCornerRadius(32)
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85).delay(0.3)) {
                spendShown = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var tripHeader: some View {
        let trip = store.trip ?? Seed.defaultTrip
        return VStack(alignment: .leading, spacing: 6) {
            Text(trip.destination.uppercased())
                .font(.display(10, weight: .heavy))
                .foregroundStyle(Theme.ink.opacity(0.5))
                .kerning(1.2)
            Text("\(trip.name) \(trip.emoji)")
                .font(.display(24, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("\(trip.dateRangeString) · \(store.stops.count) cities")
                .font(.display(13, weight: .semibold))
                .foregroundStyle(Theme.ink.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.heroGradient)
                .shadow(color: Theme.sky.opacity(0.3), radius: 14, y: 7)
        )
    }

    // MARK: - Itinerary timeline

    private var itinerary: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Itinerary")
            VStack(spacing: 0) {
                ForEach(Array(store.stops.enumerated()), id: \.element.id) { index, stop in
                    stopRow(stop, isLast: index == store.stops.count - 1)
                }
            }
            .padding(16)
            .card(cornerRadius: 26)
        }
    }

    private func stopRow(_ stop: ItineraryStop, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    if stop.isCurrent {
                        Circle()
                            .fill(Theme.lime.opacity(0.35))
                            .frame(width: 26, height: 26)
                            .scaleEffect(pulse ? 1.25 : 0.9)
                    }
                    Circle()
                        .fill(stop.isCurrent ? Theme.lime : Theme.ink.opacity(0.12))
                        .frame(width: 14, height: 14)
                }
                .frame(width: 26, height: 26)

                if !isLast {
                    Rectangle()
                        .fill(Theme.ink.opacity(0.08))
                        .frame(width: 2)
                        .frame(minHeight: 34)
                }
            }

            HStack(spacing: 12) {
                Text(stop.emoji).font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(stop.city)
                            .font(.display(16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        if stop.isCurrent {
                            Text("CURRENTLY HERE")
                                .font(.display(9, weight: .heavy))
                                .kerning(0.8)
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Theme.lime))
                        }
                    }
                    Text("\(stop.country) · \(stop.dates)")
                        .font(.display(13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
            }
            .padding(.bottom, isLast ? 0 : 18)
        }
    }

    // MARK: - Spend tracker

    private var spendTracker: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Spending", trailing: "Budget €\(Int(store.budget))")

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("€\(store.spentTotal, specifier: "%.0f")")
                        .font(.display(30, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                    Text("of €\(Int(store.budget))")
                        .font(.display(14, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                    Spacer()
                    Button {
                        Haptics.tap()
                        showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.lime))
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.85))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.skySoft.opacity(0.45))
                        Capsule()
                            .fill(Theme.skyGradient)
                            .frame(width: spendShown
                                   ? proxy.size.width * min(1, store.spentTotal / max(1, store.budget))
                                   : 0)
                    }
                }
                .frame(height: 16)

                VStack(spacing: 0) {
                    ForEach(store.expenses.prefix(5)) { expense in
                        HStack(spacing: 12) {
                            Text(expense.emoji).font(.system(size: 20))
                            Text(expense.title)
                                .font(.display(14, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("€\(expense.amount, specifier: "%.2f")")
                                .font(.display(14, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(Theme.ink)
                        }
                        .padding(.vertical, 9)

                        if expense.id != store.expenses.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(18)
            .card(cornerRadius: 26)
        }
    }
}

/// Quick local expense entry.
private struct AddExpenseSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var emoji = "🍽️"

    private let emojis = ["🍽️", "🛏️", "🚆", "🎟️", "🛍️", "☕️"]

    private var amountValue: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("Add expense")
                    .font(.display(24, weight: .bold))
                    .foregroundStyle(Theme.ink)

                HStack(spacing: 8) {
                    ForEach(emojis, id: \.self) { item in
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                emoji = item
                            }
                        } label: {
                            Text(item)
                                .font(.system(size: 22))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .fill(emoji == item ? Theme.limeSoft : Theme.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                .strokeBorder(emoji == item ? Theme.lime : .clear, lineWidth: 2)
                                        )
                                )
                        }
                        .buttonStyle(SquishyButtonStyle(scale: 0.85))
                    }
                }

                LabeledField(label: "What was it?", placeholder: "Dinner by the river", text: $title)
                LabeledField(label: "Amount (€)", placeholder: "0.00", text: $amount, keyboard: .decimalPad)

                Spacer()

                PrimaryButton(
                    title: "Add",
                    isEnabled: !title.trimmingCharacters(in: .whitespaces).isEmpty && (amountValue ?? 0) > 0
                ) {
                    if let value = amountValue {
                        store.addExpense(title: title, emoji: emoji, amount: value)
                    }
                    dismiss()
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        PlanView()
    }
    .environment(Store())
}
