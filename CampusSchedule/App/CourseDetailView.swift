import SwiftUI

struct CourseDetailView: View {
    let occurrence: CourseOccurrence
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 13) {
                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(occurrence.course.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text(occurrence.course.title)
                        .font(.title2.bold())
                }

                detailRow(
                    icon: "clock.fill",
                    title: "\(occurrence.course.periodLabel) · \(occurrence.timeLabel)"
                )
                detailRow(icon: "location.fill", title: occurrence.course.location)
                detailRow(icon: "calendar", title: weekLabel)

                Spacer()
            }
            .padding(20)
            .navigationTitle("课程详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func detailRow(icon: String, title: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(occurrence.course.tint)
                .frame(width: 24)
            Text(title)
                .font(.body)
            Spacer()
        }
    }

    private var weekLabel: String {
        "第 \(compactRanges(occurrence.course.weeks)) 周"
    }

    private func compactRanges(_ weeks: [Int]) -> String {
        guard let first = weeks.sorted().first else { return "—" }
        let sorted = Array(Set(weeks)).sorted()
        var ranges: [String] = []
        var start = first
        var previous = first

        for week in sorted.dropFirst() {
            if week == previous + 1 {
                previous = week
                continue
            }
            ranges.append(start == previous ? "\(start)" : "\(start)–\(previous)")
            start = week
            previous = week
        }
        ranges.append(start == previous ? "\(start)" : "\(start)–\(previous)")
        return ranges.joined(separator: "、")
    }
}
