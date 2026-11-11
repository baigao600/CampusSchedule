import XCTest
@testable import CampusSchedule

final class ScheduleEngineTests: XCTestCase {
    private var calendar: Calendar!
    private var schedule: ScheduleData!
    private var engine: ScheduleEngine!

    override func setUpWithError() throws {
        calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))

        schedule = try ScheduleRepository.load(
            from: Bundle(for: ScheduleEngineTests.self),
            resource: "schedule"
        )
        engine = ScheduleEngine(schedule: schedule, calendar: calendar)
    }

    // Catches an off-by-one error at the beginning or end of the 17-week term.
    func testWeekNumberUsesMondayBoundariesAndRejectsDatesOutsideTerm() throws {
        XCTAssertEqual(engine.weekNumber(on: date("2026-09-07 00:00")), 1)
        XCTAssertEqual(engine.weekNumber(on: date("2026-11-02 12:00")), 9)
        XCTAssertEqual(engine.weekNumber(on: date("2027-01-03 23:59")), 17)
        XCTAssertNil(engine.weekNumber(on: date("2026-09-06 23:59")))
        XCTAssertNil(engine.weekNumber(on: date("2027-01-04 00:00")))
    }

    // Catches applying the screenshot's visible week label instead of the user's mapping.
    func testUserSpecifiedWeekGroupsDriveCourseVariations() throws {
        XCTAssertEqual(
            engine.courses(on: date("2026-09-07 12:00")).map(\.course.title),
            ["高等数学一（I）", "大学英语", "微观经济学"]
        )

        XCTAssertEqual(
            engine.courses(on: date("2026-11-03 12:00")).map(\.course.title),
            ["程序设计基础（含实验）", "程序设计基础（含实验）"]
        )

        XCTAssertEqual(
            engine.courses(on: date("2026-11-09 12:00")).map(\.course.title),
            ["高等数学一（I）", "大学英语", "大学物理（工）上", "微观经济学"]
        )

        XCTAssertEqual(
            engine.courses(on: date("2026-12-03 12:00")).map(\.course.title),
            ["心理健康教育（上）", "体育"]
        )

        XCTAssertEqual(
            engine.courses(on: date("2026-12-11 12:00")).map(\.course.title),
            ["会计学原理"]
        )
    }

    // Catches treating a break between classes as an active course or skipping the real next class.
    func testStateDistinguishesCurrentCourseFromNextCourse() throws {
        let duringFirstClass = engine.state(at: date("2026-09-07 08:30"))
        XCTAssertEqual(duringFirstClass.current?.course.title, "高等数学一（I）")
        XCTAssertEqual(duringFirstClass.next?.course.title, "大学英语")

        let duringBreak = engine.state(at: date("2026-09-07 09:50"))
        XCTAssertNil(duringBreak.current)
        XCTAssertEqual(duringBreak.next?.course.title, "大学英语")

        let afterLastClass = engine.state(at: date("2026-09-07 21:36"))
        XCTAssertNil(afterLastClass.current)
        XCTAssertEqual(afterLastClass.next?.course.title, "线性代数")
        XCTAssertEqual(afterLastClass.next?.start, date("2026-09-08 08:00"))
    }

    // Catches stale widgets that fail to update exactly when a class starts or ends.
    func testTimelineRefreshDatesIncludeCourseTransitions() throws {
        let refreshes = engine.timelineRefreshDates(
            after: date("2026-09-07 07:50"),
            until: date("2026-09-07 10:20")
        )

        XCTAssertEqual(refreshes, [
            date("2026-09-07 08:00"),
            date("2026-09-07 09:40"),
            date("2026-09-07 10:10")
        ])
    }

    // Catches a widget retaining yesterday's date when a 36-hour timeline crosses two midnights.
    func testWidgetTimelineDatesIncludeEveryMidnightInHorizon() throws {
        let refreshes = engine.widgetTimelineDates(
            after: date("2026-09-07 23:50"),
            until: date("2026-09-09 11:50")
        )

        XCTAssertTrue(refreshes.contains(date("2026-09-08 00:00")))
        XCTAssertTrue(refreshes.contains(date("2026-09-09 00:00")))
    }

    // Catches formatting course times in the device time zone while the engine uses campus time.
    func testCourseTimeFormattingAlwaysUsesShanghaiTimeZone() throws {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let instant = try XCTUnwrap(utcCalendar.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 7,
            hour: 0,
            minute: 0
        )))

        XCTAssertEqual(instant.formattedTime, "08:00")
        XCTAssertEqual(instant.campusWeekday, "星期一")
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: value)!
    }
}
