
import XCTest

final class QReativeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testTakeScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-UITestScreenshotMode"]
        app.launch()

        // Tab order is fixed (Scan, Create, History, Settings); tapping by index
        // avoids depending on localized tab titles across languages. Accessibility
        // identifiers (not text) drive the rest for the same reason.
        let tabBar = app.tabBars.firstMatch
        snapshot("01ScanQR")

        app.buttons["scanMode.barcode"].tap()
        snapshot("02ScanBarcode")

        tabBar.buttons.element(boundBy: 1).tap()
        snapshot("03Create")

        app.buttons["qrType.website"].tap()

        // "Ocean" is a blue gradient swatch that's within the first screen's
        // width without needing to scroll the horizontal color picker — avoids
        // flaky off-screen-element scrolling across 10 locales (incl. RTL Arabic,
        // where the swatch order visually mirrors and offsets shift).
        app.buttons["qrColor.ocean"].tap()
        app.buttons["qrShape.rounded"].tap()
        app.buttons["addEmojiButton"].tap()
        app.buttons["emojiCategory.heart.fill"].tap()
        app.buttons["❤️"].tap()
        snapshot("04Customize")

        app.buttons["editorBackButton"].tap()
        tabBar.buttons.element(boundBy: 2).tap()
        snapshot("05History")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
