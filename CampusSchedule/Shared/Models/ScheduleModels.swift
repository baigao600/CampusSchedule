import Foundation

struct ScheduleData: Codable, Equatable {
    let semester: Semester
    let periods: [ClassPeriod]
    let courses: [Course]
}

struct Semester: Codable, Equatable {
    let name: String
    let startDate: String
    let weekCount: Int
}

struct ClassPeriod: Codable, Equatable, Identifiable {
    let number: Int
    let start: String
    let end: String

    var id: Int { number }
}

struct Course: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let title: String
    let shortTitle: String
    let weekday: Int
    let startPeriod: Int
    let endPeriod: Int
    let location: String
    let color: String
    let weeks: [Int]

    var periodLabel: String {
        startPeriod == endPeriod ? "第\(startPeriod)节" : "第\(startPeriod)–\(endPeriod)节"
    }
}

struct CourseOccurrence: Equatable, Hashable, Identifiable {
    let course: Course
    let start: Date
    let end: Date

    var id: String {
        "\(course.id)-\(Int(start.timeIntervalSince1970))"
    }

    var timeLabel: String {
        "\(start.formattedTime)–\(end.formattedTime)"
    }
}

struct ScheduleState: Equatable {
    let current: CourseOccurrence?
    let next: CourseOccurrence?
    let todaysCourses: [CourseOccurrence]
}

extension Date {
    var formattedTime: String {
        campusFormatted("HH:mm")
    }

    var campusMonthDay: String { campusFormatted("M月d日") }
    var campusWeekday: String { campusFormatted("EEEE") }
    var campusShortWeekday: String { campusFormatted("EEE") }
    var campusMonthDayWeekday: String { campusFormatted("M月d日 EEEE") }
    var campusCompactDate: String { campusFormatted("M/d") }
    var campusDay: String { campusFormatted("d") }
    var campusLongDate: String { campusFormatted("yyyy年M月d日") }

    private func campusFormatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
