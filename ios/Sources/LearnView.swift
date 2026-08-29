import SwiftUI

struct Lesson: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let track: String
    let pages: [String]
    let reward = 20
}

extension Lesson {
    static let all: [Lesson] = [
        Lesson(id: "fin-1", emoji: "💸", title: "Why compound interest wins", track: "Personal finance", pages: [
            "Compound interest means you earn interest on your interest. Money grows faster the longer it sits.",
            "Example: $1,000 at 8% per year. Year 1 you earn $80. Year 2 you earn $86 — because now the $80 is earning too.",
            "The rule of 72: divide 72 by the interest rate to see how many years it takes to double. At 8%, that's 9 years.",
            "The takeaway: starting at 18 instead of 28 can roughly double what you end up with. Time matters more than amount.",
        ]),
        Lesson(id: "fin-2", emoji: "🧾", title: "Your first budget in 4 lines", track: "Personal finance", pages: [
            "A budget is just a plan for money before you spend it. Four lines is enough to start.",
            "50% needs, 30% wants, 20% savings. That's the 50/30/20 rule. It's a default, not a law.",
            "Track one month first. Most people are shocked by one category. That category is your lever.",
            "Automate the savings part. If it moves on payday, you never have to be disciplined.",
        ]),
        Lesson(id: "phil-1", emoji: "🏛️", title: "Stoicism: control what you can", track: "Philosophy", pages: [
            "Stoics split the world in two: things you control (your effort, your reactions) and things you don't (grades already posted, other people).",
            "Epictetus: suffering comes from wanting to control the second group.",
            "Practical version: before stressing, ask 'is this in my control?' If no, let it go. If yes, act on it today.",
            "This is why the app pays for finishing tasks, not for grades. Effort is yours. Outcomes are only partly yours.",
        ]),
        Lesson(id: "phil-2", emoji: "🤔", title: "The Socratic method", track: "Philosophy", pages: [
            "Socrates taught by asking questions, not giving answers. Each question exposes what you assumed.",
            "Try it on yourself: 'Why do I believe this?' three times in a row. Most beliefs run out of floor at question two.",
            "It works on studying too: asking 'why is this the answer?' beats rereading notes.",
        ]),
        Lesson(id: "study-1", emoji: "🧠", title: "Spaced practice beats cramming", track: "Study skills", pages: [
            "Ten minutes a day for six days beats one 60-minute cram. Same time, much more sticks.",
            "Why: your brain strengthens a memory every time it almost forgets it, then recalls it.",
            "Practice testing yourself is the strongest form. Rereading feels good and does almost nothing.",
        ]),
    ]
}

struct LearnView: View {
    @EnvironmentObject var state: AppState

    private var tracks: [(String, [Lesson])] {
        Dictionary(grouping: Lesson.all, by: \.track)
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(tracks, id: \.0) { track, lessons in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(track).font(.headline).foregroundStyle(Theme.ink)
                            ForEach(lessons) { lesson in
                                NavigationLink { LessonView(lesson: lesson) } label: {
                                    row(lesson)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 104)
            }
            .background(Theme.paper)
            .navigationTitle("Learn")
        }
    }

    private func row(_ lesson: Lesson) -> some View {
        let done = state.completedLessons.contains(lesson.id)
        return HStack(spacing: 12) {
            Text(lesson.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                Text("\(lesson.pages.count) cards · 2 min").font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            if done {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.mint)
            } else {
                Text("+\(lesson.reward)").font(.subheadline.bold()).foregroundStyle(Theme.coral)
            }
        }
        .card()
    }
}

struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $page) {
                ForEach(Array(lesson.pages.enumerated()), id: \.offset) { i, text in
                    VStack(spacing: 16) {
                        Text(lesson.emoji).font(.system(size: 44))
                        Text(text)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .card()
                    .padding(.horizontal, 20)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            if page == lesson.pages.count - 1 {
                Button {
                    state.completeLesson(id: lesson.id, reward: lesson.reward)
                    dismiss()
                } label: {
                    Text(state.completedLessons.contains(lesson.id) ? "Done" : "Finish · +\(lesson.reward) coins")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.coral))
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Theme.paper)
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
    }
}
