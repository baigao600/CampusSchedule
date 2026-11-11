import Foundation

struct ScheduleEngine {
    let schedule: ScheduleData
    let calendar: Calendar
    let semesterStart: Date

    init(schedule: ScheduleData, calendar: Calendar) {
        self.schedule = schedule
        self.calendar = calendar

        let parts = schedule.semester.startDate.split(separator: "-").compactMap { Int($0) }
        precondition(parts.count == 3, "Semester startDate must use yyyy-MM-dd")

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = 0
        components.minute = 0
        semesterStart = calendar.date(from: components)!
    }

    var semesterEnd: Date {
        calendar.date(byAdding: .day, value: schedule.semester.weekCount * 7, to: semesterStart)!
    }

    func weekNumber(on date: Date) -> Int? {
        let day = calendar.startOfDay(for: date)
        let offset = calendar.dateComponents([.day], from: semesterStart, to: day).day ?? -1
        guard offset >= 0, offset < schedule.semester.weekCount * 7 else { return nil }
        return offset / 7 + 1
    }

    func weekdayNumber(on date: Date) -> Int {
        let appleWeekday = calendar.component(.weekday, from: date)
        return (appleWeekday + 5) % 7 + 1
    }

    func courses(on date: Date) -> [CourseOccurrence] {
        guard let week = weekNumber(on: date) else { return [] }
        let weekday = weekdayNumber(on: date)

        return schedule.courses
            .filter { $0.weekday == weekday && $0.weeks.contains(week) }
            .compactMap { occurrence(for: $0, on: date) }
            .sorted { $0.start < $1.start }
    }

    func state(at date: Date) -> ScheduleState {
        let today = courses(on: date)
        let current = today.first { $0.start <= date && date < $0.end }
        let next = nextCourse(after: date)
        return ScheduleState(current: current, next: next, todaysCourses: today)
    }

    func nextCourse(after date: Date) -> CourseOccurrence? {
        guard date < semesterEnd else { return nil }

        var day = calendar.startOfDay(for: date)
        while day < semesterEnd {
            if let next = courses(on: day).first(where: { $0.start > date }) {
                return next
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return nil
    }

    func date(forWeek week: Int, weekday: Int) -> Date? {
        guard (1...schedule.semester.weekCount).contains(week), (1...7).contains(weekday) else {
            return nil
        }
        return calendar.date(
            byAdding: .day,
            value: (week - 1) * 7 + weekday - 1,
            to: semesterStart
        )
    }

    func dates(inWeek week: Int) -> [Date] {
        (1...7).compactMap { date(forWeek: week, weekday: $0) }
    }

    func timelineRefreshDates(after date: Date, until endDate: Date) -> [Date] {
        guard date < endDate else { return [] }
        var moments = Set<Date>()
        var day = calendar.startOfDay(for: date)

        while day <= endDate, day < semesterEnd {
            for occurrence in courses(on: day) {
                if occurrence.start > date, occurrence.start <= endDate {
                    moments.insert(occurrence.start)
                }
                if occurrence.end > date, occurrence.end <= endDate {
                    moments.insert(occurrence.end)
                }
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }

        return moments.sorted()
    }

    func widgetTimelineDates(after date: Date, until endDate: Date) -> [Date] {
        guard date < endDate else { return [] }
        var moments = Set(timelineRefreshDates(after: date, until: endDate))
        var midnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: date)
        )!

        while midnight <= endDate {
            moments.insert(midnight)
            midnight = calendar.date(byAdding: .day, value: 1, to: midnight)!
        }

        return moments.sorted()
    }

    private func occurrence(for course: Course, on date: Date) -> CourseOccurrence? {
        guard
            let firstPeriod = schedule.periods.first(where: { $0.number == course.startPeriod }),
            let lastPeriod = schedule.periods.first(where: { $0.number == course.endPeriod }),
            let start = date(on: date, at: firstPeriod.start),
            let end = date(on: date, at: lastPeriod.end)
        else {
            return nil
        }

        return CourseOccurrence(course: course, start: start, end: end)
    }

    private func date(on day: Date, at time: String) -> Date? {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }

        return calendar.date(
            bySettingHour: parts[0],
            minute: parts[1],
            second: 0,
            of: day
        )
    }
}
