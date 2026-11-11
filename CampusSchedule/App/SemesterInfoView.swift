import SwiftUI

struct SemesterInfoView: View {
    private let engine = ScheduleEnvironment.engine

    var body: some View {
        NavigationStack {
            Form {
                Section("当前学期") {
                    LabeledContent("名称", value: engine.schedule.semester.name)
                    LabeledContent("第一周", value: engine.semesterStart.campusLongDate)
                    LabeledContent("教学周", value: "\(engine.schedule.semester.weekCount)周")
                }

                Section("数据") {
                    Label("课表已保存在设备内，无需网络", systemImage: "lock.shield.fill")
                    Label("桌面小组件会在上下课时间自动更新", systemImage: "rectangle.3.group.fill")
                }

                Section("录入说明") {
                    Text("课程周次严格按你提供的五组截图录入，不读取截图顶部显示的周数。")
                    Text("程序设计实验教室暂记为“园东区106栋201”；体育场地原图未标注。")
                }
                .foregroundStyle(.secondary)
            }
            .navigationTitle("课表信息")
        }
    }
}
