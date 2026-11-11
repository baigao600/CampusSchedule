import SwiftUI

struct RootTabView: View {
    private enum Tab: Hashable {
        case today
        case schedule
        case info
    }

    @State private var selectedTab: Tab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "clock.fill")
                }
                .tag(Tab.today)

            WeekScheduleView()
                .tabItem {
                    Label("课表", systemImage: "calendar")
                }
                .tag(Tab.schedule)

            SemesterInfoView()
                .tabItem {
                    Label("信息", systemImage: "info.circle")
                }
                .tag(Tab.info)
        }
        .onOpenURL { url in
            if url.scheme == "campusschedule", url.host == "today" {
                selectedTab = .today
            }
        }
    }
}

#Preview {
    RootTabView()
}
