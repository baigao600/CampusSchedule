import SwiftUI

struct TodayView: View {
    private let engine = ScheduleEnvironment.engine
    @State private var selectedCourse: CourseOccurrence?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                ScrollView {
                    TodayContent(
                        now: context.date,
                        engine: engine,
                        selectedCourse: $selectedCourse
                    )
                    .padding(.horizontal, CourseBoardStyle.pagePadding)
                    .padding(.bottom, 24)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("今日课表")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedCourse) { occurrence in
                CourseDetailView(occurrence: occurrence)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct TodayContent: View {
    let now: Date
    let engine: ScheduleEngine
    @Binding var selectedCourse: CourseOccurrence?

    private var state: ScheduleState { engine.state(at: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            dateHeader
            StatusHeroView(now: now, state: state, engine: engine)

            HStack {
                Text("今日安排")
                    .font(.title3.bold())
                Spacer()
                Text("\(state.todaysCourses.count) 段课程")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if state.todaysCourses.isEmpty {
                EmptyScheduleView(
                    title: "今天没有课程",
                    message: emptyMessage,
                    systemImage: "calendar.badge.checkmark"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(state.todaysCourses) { occurrence in
                        Button {
                            selectedCourse = occurrence
                        } label: {
                            CourseTimelineRow(
                                occurrence: occurrence,
                                now: now,
                                isCurrent: state.current?.id == occurrence.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dateHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(now.campusMonthDay)
                    .font(.title2.bold())
                Text(now.campusWeekday)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let week = engine.weekNumber(on: now) {
                Text("第 \(week) 周")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.indigo.opacity(0.12), in: Capsule())
            }
        }
        .padding(.top, 4)
    }

    private var emptyMessage: String {
        if let next = state.next {
            return "下一节：\(next.start.campusMonthDay) \(next.start.campusShortWeekday) \(next.start.formattedTime)"
        }
        return "本学期暂时没有更多课程"
    }
}

private struct StatusHeroView: View {
    let now: Date
    let state: ScheduleState
    let engine: ScheduleEngine

    private var highlighted: CourseOccurrence? { state.current ?? state.next }
    private var tint: Color { highlighted?.course.tint ?? .indigo }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 7) {
                Image(systemName: state.current == nil ? "sparkles" : "book.fill")
                Text(statusTitle)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)

            if let course = highlighted {
                Text(heroTitle(for: course))
                    .font(.title2.bold())
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text("\(course.timeLabel) · \(course.course.periodLabel)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                    Text(course.course.location)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if state.current != nil {
                    ProgressView(value: progress(for: course))
                        .tint(tint)
                }
            } else {
                Text(fallbackTitle)
                    .font(.title2.bold())
                Text(fallbackMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.20), tint.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        }
    }

    private var statusTitle: String {
        if state.current != nil { return "正在上课" }
        guard let next = state.next else { return "今日状态" }
        if engine.calendar.isDate(next.start, inSameDayAs: now) {
            let minutes = max(0, Int(next.start.timeIntervalSince(now) / 60))
            if minutes < 60 { return "下一节 · 还有 \(minutes) 分钟" }
            return "下一节 · 还有 \(minutes / 60) 小时 \(minutes % 60) 分钟"
        }
        return state.todaysCourses.isEmpty ? "下一次上课" : "今天课程已结束"
    }

    private func heroTitle(for occurrence: CourseOccurrence) -> String {
        if state.current != nil { return occurrence.course.title }
        if engine.calendar.isDate(occurrence.start, inSameDayAs: now) { return occurrence.course.title }
        return "\(occurrence.start.campusWeekday) · \(occurrence.course.title)"
    }

    private func progress(for occurrence: CourseOccurrence) -> Double {
        let duration = occurrence.end.timeIntervalSince(occurrence.start)
        guard duration > 0 else { return 0 }
        return min(max(now.timeIntervalSince(occurrence.start) / duration, 0), 1)
    }

    private var fallbackTitle: String {
        if now < engine.semesterStart { return "学期尚未开始" }
        if now >= engine.semesterEnd { return "本学期已结束" }
        return "今天没有课程"
    }

    private var fallbackMessage: String {
        now < engine.semesterStart ? "第一周从 \(engine.semesterStart.campusMonthDay) 开始" : "好好休息，安排一点自己的时间"
    }
}

struct CourseTimelineRow: View {
    let occurrence: CourseOccurrence
    let now: Date
    var isCurrent = false

    private var isFinished: Bool { occurrence.end <= now }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(occurrence.start.formattedTime)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(occurrence.end.formattedTime)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)

            Capsule()
                .fill(occurrence.course.tint)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(occurrence.course.title)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(occurrence.course.periodLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Label(occurrence.course.location, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(13)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: CourseBoardStyle.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CourseBoardStyle.cardRadius, style: .continuous)
                .stroke(isCurrent ? occurrence.course.tint : .clear, lineWidth: 1.5)
        }
        .opacity(isFinished && !isCurrent ? 0.52 : 1)
        .contentShape(Rectangle())
    }
}

struct EmptyScheduleView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.indigo)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: CourseBoardStyle.cardRadius, style: .continuous))
    }
}
