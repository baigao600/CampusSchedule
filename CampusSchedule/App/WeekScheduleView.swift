import SwiftUI

struct WeekScheduleView: View {
    private let engine = ScheduleEnvironment.engine
    @State private var selectedWeek: Int
    @State private var selectedWeekday: Int
    @State private var selectedCourse: CourseOccurrence?

    init(now: Date = .now) {
        let engine = ScheduleEnvironment.engine
        let week: Int
        if let currentWeek = engine.weekNumber(on: now) {
            week = currentWeek
        } else {
            week = now >= engine.semesterEnd ? engine.schedule.semester.weekCount : 1
        }
        _selectedWeek = State(initialValue: week)
        _selectedWeekday = State(initialValue: engine.weekNumber(on: now) == nil ? 1 : engine.weekdayNumber(on: now))
    }

    private var weekDates: [Date] { engine.dates(inWeek: selectedWeek) }
    private var selectedDate: Date { weekDates[selectedWeekday - 1] }
    private var selectedCourses: [CourseOccurrence] { engine.courses(on: selectedDate) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    weekPicker
                    dayPicker

                    HStack {
                        Text(selectedDate.campusMonthDayWeekday)
                            .font(.title3.bold())
                        Spacer()
                        Text("\(selectedCourses.count) 段课程")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if selectedCourses.isEmpty {
                        EmptyScheduleView(
                            title: "当天没有课程",
                            message: "可以切换上方日期查看其他安排",
                            systemImage: "calendar.badge.checkmark"
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(selectedCourses) { occurrence in
                                Button {
                                    selectedCourse = occurrence
                                } label: {
                                    CourseTimelineRow(
                                        occurrence: occurrence,
                                        now: .distantPast
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, CourseBoardStyle.pagePadding)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("学期课表")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if let currentWeek = engine.weekNumber(on: .now), currentWeek != selectedWeek {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("回到本周") {
                            selectedWeek = currentWeek
                            selectedWeekday = engine.weekdayNumber(on: .now)
                        }
                    }
                }
            }
            .sheet(item: $selectedCourse) { occurrence in
                CourseDetailView(occurrence: occurrence)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var weekPicker: some View {
        HStack(spacing: 12) {
            Button {
                selectedWeek -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .disabled(selectedWeek == 1)

            VStack(spacing: 2) {
                Text("第 \(selectedWeek) 周")
                    .font(.headline)
                if let first = weekDates.first, let last = weekDates.last {
                    Text("\(first.campusCompactDate) – \(last.campusCompactDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                selectedWeek += 1
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .disabled(selectedWeek == engine.schedule.semester.weekCount)
        }
        .buttonStyle(.borderless)
        .padding(.top, 4)
    }

    private var dayPicker: some View {
        HStack(spacing: 6) {
            ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                let weekday = index + 1
                Button {
                    selectedWeekday = weekday
                } label: {
                    VStack(spacing: 7) {
                        Text(["一", "二", "三", "四", "五", "六", "日"][index])
                            .font(.caption)
                            .foregroundStyle(selectedWeekday == weekday ? .white.opacity(0.86) : .secondary)
                        Text(date.campusDay)
                            .font(.subheadline.bold())
                            .monospacedDigit()
                            .foregroundStyle(selectedWeekday == weekday ? .white : .primary)
                        Circle()
                            .fill(engine.courses(on: date).isEmpty ? .clear : (selectedWeekday == weekday ? Color.white : Color.indigo))
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedWeekday == weekday ? Color.indigo : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
