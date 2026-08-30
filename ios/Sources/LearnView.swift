import SwiftUI

struct LearnView: View {
    @EnvironmentObject var state: AppState

    private var tracks: [(String, [Lesson])] {
        Dictionary(grouping: Catalog.lessons, by: \.track)
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
