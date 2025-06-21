#  TestingAlarmKit

## Overview - AlarmKit Demonstration App

Build this using Xcode 26 Beta.

This project showcases the capabilities of AlarmKit, a new framework introduced at WWDC25 that enables developers to schedule and manage alarms and timers in iOS.

To enable full functionality, update the bundle identifier under the *Signing & Capabilities* section for both the main app target and the widget extension. This project also uses **App Groups** to share data via SwiftData between the main app and the widget, so you’ll need to configure your own **App Group** accordingly.

This example builds upon Apple’s official sample project, *SchedulingAnAlarmWithAlarmKit*, and extends it to include a countdown timer displayed in the main content view. The app also includes support for Live Activities, featuring a Dynamic Island progress ring that visually tracks timer progress and reflects pause/resume actions in real time.
