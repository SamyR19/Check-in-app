import XCTest

/// Launches the app once per screen (routed via the "-uiTestScreen" launch
/// argument) and attaches a screenshot of each. CI exports the attachments.
final class ScreenshotTests: XCTestCase {

    private let screens = [
        "01-welcome", "02-signup", "03-role", "04-trip", "05-schedule",
        "06-permissions", "07-invite", "08-dryrun", "09-pair",
        "10-expectations", "11-parent-alerts",
        "12-teen-home", "13-teen-trip", "14-teen-activity", "15-teen-profile",
        "16-checkin", "17-sos", "18-search",
        "19-parent-board", "20-ping", "21-parent-profile",
    ]

    func testCaptureAllScreens() {
        for screen in screens {
            let app = XCUIApplication()
            app.launchArguments = ["-uiTestScreen", screen]
            app.launch()
            // Let entrance animations settle and map tiles load.
            sleep(5)

            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = screen
            attachment.lifetime = .keepAlways
            add(attachment)

            app.terminate()
        }
    }
}
