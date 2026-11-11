import SwiftUI
import WidgetKit

struct ScheduleWidgetEntry: TimelineEntry {
    let date: Date
}

struct ScheduleTimelineProvider: TimelineProvider {
    private let engine = ScheduleEnvironment.engine

    func placeholder(in context: Context) -> ScheduleWidgetEntry {
        ScheduleWidgetEntry(date: engine.semesterStart.addingTimeInterval(8.5 * 60 * 60))
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleWidgetEntry) -> Void) {
        let previewDate = engine.semesterStart.addingTimeInterval(8.5 * 60 * 60)
        completion(ScheduleWidgetEntry(date: context.isPreview ? previewDate : .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleWidgetEntry>) -> Void) {
        let now = Date.now
        let calendar = engine.calendar
        let horizon = calendar.date(byAdding: .hour, value: 36, to: now)!
        let transitions = engine.widgetTimelineDates(after: now, until: horizon)
        let moments = [now] + transitions
        let entries = moments.map { ScheduleWidgetEntry(date: $0) }
        completion(Timeline(entries: entries, policy: .after(horizon)))
    }
}

struct CampusScheduleWidget: Widget {
    let kind = "CampusScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleTimelineProvider()) { entry in
            ScheduleWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
                .widgetURL(URL(string: "campusschedule://today"))
        }
        .configurationDisplayName("今日课表")
        .description("快速查看正在进行和接下来的课程。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct ScheduleWidgetView: View {
    let entry: ScheduleWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallScheduleWidget(date: entry.date)
        case .systemLarge:
            LargeScheduleWidget(date: entry.date)
        default:
            MediumScheduleWidget(date: entry.date)
        }
    }
}

private struct WidgetHeader: View {
    let date: Date
    let week: Int?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(date.campusMonthDay) \(date.campusShortWeekday)")
                .font(.headline)
            Spacer()
            if let week {
                Text("第\(week)周")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.indigo.opacity(0.12), in: Capsule())
            }
        }
    }
}

private struct SmallScheduleWidget: View {
    let date: Date
    private let engine = ScheduleEnvironment.engine

    private var state: ScheduleState { engine.state(at: date) }
    private var highlighted: CourseOccurrence? { state.current ?? state.next }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(date: date, week: engine.weekNumber(on: date))

            if let course = highlighted {
                HStack(spacing: 5) {
                    Circle()
                        .fill(course.course.tint)
                        .frame(width: 7, height: 7)
                    Text(statusLabel(for: course))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(course.course.tint)
                }

                Text(course.course.shortTitle)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                Label(course.start.formattedTime, systemImage: "clock.fill")
                    .font(.caption)
                Label(course.course.location, systemImage: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Spacer()
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                Text("暂无课程")
                    .font(.headline)
                Text("享受自己的时间")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private func statusLabel(for occurrence: CourseOccurrence) -> String {
        if state.current != nil { return "上课中" }
        return engine.calendar.isDate(occurrence.start, inSameDayAs: date) ? "下一节" : "下一次"
    }
}

private struct MediumScheduleWidget: View {
    let date: Date
    private let engine = ScheduleEnvironment.engine

    private var state: ScheduleState { engine.state(at: date) }
    private var visibleCourses: [CourseOccurrence] {
        Array(state.todaysCourses.filter { $0.end > date }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            WidgetHeader(date: date, week: engine.weekNumber(on: date))

            if visibleCourses.isEmpty {
                widgetEmptyState
            } else {
                ForEach(visibleCourses) { occurrence in
                    WidgetCourseRow(
                        occurrence: occurrence,
                        isCurrent: state.current?.id == occurrence.id
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var widgetEmptyState: some View {
        if let next = state.next {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.todaysCourses.isEmpty ? "今天没有课程" : "今天课程已结束")
                        .font(.headline)
                    Text("下一节：\(next.start.campusShortWeekday) \(next.start.formattedTime) · \(next.course.shortTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxHeight: .infinity)
        } else {
            EmptyWidgetMessage()
        }
    }
}

private struct LargeScheduleWidget: View {
    let date: Date
    private let engine = ScheduleEnvironment.engine

    private var state: ScheduleState { engine.state(at: date) }
    private var upcoming: [CourseOccurrence] {
        Array(
            state.todaysCourses
                .filter { $0.end > date && $0.id != state.current?.id }
                .prefix(5)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WidgetHeader(date: date, week: engine.weekNumber(on: date))

            if let current = state.current {
                HStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(current.course.tint, in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("正在上课")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(current.course.tint)
                        Text(current.course.shortTitle)
                            .font(.headline)
                        Text("\(current.end.formattedTime) 下课 · \(current.course.location)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(11)
                .background(current.course.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            }

            Text("接下来的安排")
                .font(.subheadline.bold())

            if upcoming.isEmpty {
                if let next = state.next {
                    NextWidgetMessage(next: next, finishedToday: !state.todaysCourses.isEmpty)
                } else {
                    EmptyWidgetMessage()
                }
            } else {
                ForEach(upcoming) { occurrence in
                    WidgetCourseRow(
                        occurrence: occurrence,
                        isCurrent: state.current?.id == occurrence.id
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct WidgetCourseRow: View {
    let occurrence: CourseOccurrence
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 9) {
            Text(occurrence.start.formattedTime)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .frame(width: 39, alignment: .leading)

            Capsule()
                .fill(occurrence.course.tint)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(occurrence.course.shortTitle)
                    .font(.subheadline.weight(isCurrent ? .bold : .semibold))
                    .lineLimit(1)
                Text(occurrence.course.location)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            if isCurrent {
                Text("进行中")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(occurrence.course.tint)
            }
        }
        .frame(minHeight: 30)
    }
}

private struct EmptyWidgetMessage: View {
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.indigo)
            Text("暂无更多课程")
                .font(.headline)
            Text("本学期安排已全部显示")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NextWidgetMessage: View {
    let next: CourseOccurrence
    let finishedToday: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(.indigo)
            VStack(alignment: .leading, spacing: 3) {
                Text(finishedToday ? "今天课程已结束" : "今天没有课程")
                    .font(.headline)
                Text("下一节 · \(next.start.campusMonthDay) \(next.start.campusShortWeekday) \(next.start.formattedTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(next.course.shortTitle) · \(next.course.location)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
