import XCTest
@testable import CampusSchedule

final class ScheduleRepositoryTests: XCTestCase {
    // Catches malformed or incomplete bundled data that would leave the app with an empty timetable.
    func testBundledScheduleHasCompletePeriodAndCourseData() throws {
        let schedule = try ScheduleRepository.load(
            from: Bundle(for: ScheduleRepositoryTests.self),
            resource: "schedule"
        )

        XCTAssertEqual(schedule.semester.weekCount, 17)
        XCTAssertEqual(schedule.periods.map(\.number), Array(1...11))
        XCTAssertEqual(schedule.courses.count, 15)
        XCTAssertTrue(schedule.courses.allSatisfy { !$0.weeks.isEmpty })
        XCTAssertTrue(schedule.courses.allSatisfy { (1...7).contains($0.weekday) })
        XCTAssertTrue(schedule.courses.allSatisfy { $0.startPeriod <= $0.endPeriod })
    }

    // Catches a transcription regression in the two fields obscured near the screenshot edge.
    func testKnownLocationTranscriptionsRemainExplicit() throws {
        let schedule = try ScheduleRepository.load(
            from: Bundle(for: ScheduleRepositoryTests.self),
            resource: "schedule"
        )

        let lab = try XCTUnwrap(schedule.courses.first { $0.id == "programming-lab-tue" })
        XCTAssertEqual(lab.location, "园东区106栋201")

        let sport = try XCTUnwrap(schedule.courses.first { $0.id == "physical-education-thu" })
        XCTAssertEqual(sport.location, "场地未标注")
    }
}
