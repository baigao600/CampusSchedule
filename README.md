# 课序（CampusSchedule）

一款为当前学期定制的原生 iPhone 课表 App，包含今日课程、17 周浏览、课程详情，以及小号/中号/大号桌面小组件。数据完全保存在 App 内，不需要账号、服务器或网络权限。

## 在 Mac 上运行

1. 在 Mac 上登录有仓库访问权限的 GitHub 账号，从仓库的 **Code** 菜单克隆项目，或下载 ZIP 后解压。
2. 用 Xcode 15 或更新版本打开 `CampusSchedule.xcodeproj`，选择 `CampusSchedule` 方案。
3. 在 iOS 17 或更新版本的模拟器上运行，按 `⌘U` 可以运行测试。
4. 如需安装到 iPhone，在 **Signing & Capabilities** 中为 `CampusSchedule` 和 `CampusScheduleWidgetExtension` 两个目标选择同一个 Apple Team。如果 Xcode 提示 Bundle Identifier 被占用，给 App 换一个唯一标识，并把 Widget 标识设为新标识加 `.widget`。
5. 选中 iPhone 后运行并启动 App 一次，然后在主屏幕长按，搜索并添加“今日课表”小组件。

也可以先在终端执行不需要签名的构建检查：

```bash
bash scripts/verify-mac.sh
```

若要同时运行单元测试，传入你 Mac 上已有的模拟器名称：

```bash
bash scripts/verify-mac.sh 'platform=iOS Simulator,name=iPhone 16 Pro'
```

项目不使用 App Group，因此使用免费 Apple ID 签名时也更简单。课表作为资源同时打包进 App 和 Widget；如需修改课程，只要编辑 `CampusSchedule/Resources/schedule.json` 后重新运行即可。

## 已实现

- 今日状态：上课中、课间、下一节、今日已结束
- 当前课程进度与下一节倒计时
- 第 1–17 周逐日浏览
- 课程详情、节次、时间、教室及周次区间
- 小号、中号、大号 WidgetKit 小组件
- 上课/下课和跨日自动更新时间线
- 深色模式、动态字体、系统语义颜色
- 完整课表数据与 XCTest 行为测试

## 数据说明

- `CampusSchedule/Resources/schedule.json` 含个人课程时间和教室，仓库宜保持私有。
- 第一周起始日：2026 年 9 月 7 日
- 周次按用户指定分组录入，忽略原截图顶部的周数
- 程序设计实验教室的截图末尾被截断，当前采用“园东区106栋201”
- 体育课截图未显示场地，当前采用“场地未标注”

## 在 Mac 上验证

先在 Xcode 里选择一个 iOS 17 以上模拟器，然后按 `⌘U` 运行单元测试。也可以在终端运行：

```bash
xcodebuild \
  -project CampusSchedule.xcodeproj \
  -scheme CampusSchedule \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

如果你的模拟器名称不同，请把 `iPhone 16` 换成 Xcode 中已有的设备名称。

`project.yml` 是工程结构的备用定义。如果手工工程文件被误改，可安装 XcodeGen 后在项目目录运行 `xcodegen generate` 重新生成。
