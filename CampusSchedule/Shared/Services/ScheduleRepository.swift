import Foundation

enum ScheduleRepositoryError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "找不到课表资源：\(name).json"
        }
    }
}

enum ScheduleRepository {
    static func load(
        from bundle: Bundle = .main,
        resource: String = "schedule"
    ) throws -> ScheduleData {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw ScheduleRepositoryError.missingResource(resource)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ScheduleData.self, from: data)
    }
}

enum ScheduleEnvironment {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return calendar
    }()

    static let data: ScheduleData = {
        (try? ScheduleRepository.load()) ?? ScheduleData(
            semester: Semester(name: "课表不可用", startDate: "2026-09-07", weekCount: 17),
            periods: [],
            courses: []
        )
    }()

    static let engine = ScheduleEngine(schedule: data, calendar: calendar)
}
