import SwiftUI

struct CanvasExportConfiguration {
    let deviceSize: CGSize
    let colorScheme: ColorScheme
    let statusBarVisible: Bool
    let statusBarTopSafeArea: Bool
    let devicePresetName: String
}

enum CanvasExportRenderer {
    static func configuration(
        devicePreset: DevicePreset,
        colorScheme: ColorScheme?,
        statusBarVisible: Bool,
        statusBarTopSafeArea: Bool
    ) -> CanvasExportConfiguration {
        let suppressStatusBar = devicePreset.category == .widget
        return CanvasExportConfiguration(
            deviceSize: devicePreset.size,
            colorScheme: colorScheme ?? .light,
            statusBarVisible: suppressStatusBar ? false : statusBarVisible,
            statusBarTopSafeArea: suppressStatusBar ? false : statusBarTopSafeArea,
            devicePresetName: devicePreset.rawValue
        )
    }

    @MainActor
    static func capturePNG(
        components: [UIComponent],
        configuration: CanvasExportConfiguration
    ) -> Data? {
        let screenshotView = CanvasScreenshotView(
            components: components,
            deviceSize: configuration.deviceSize,
            colorScheme: configuration.colorScheme,
            statusBarVisible: configuration.statusBarVisible,
            statusBarTopSafeArea: configuration.statusBarTopSafeArea
        )

        return ScreenshotUtility.shared.captureThumbnail(
            of: screenshotView,
            size: configuration.deviceSize,
            colorScheme: configuration.colorScheme
        )
    }

    @MainActor
    static func captureAndAssignThumbnail(
        components: [UIComponent],
        configuration: CanvasExportConfiguration,
        designFile: DesignFile,
        page: DesignPage?
    ) -> Data? {
        guard let thumbnailData = capturePNG(components: components, configuration: configuration) else {
            return nil
        }

        designFile.setThumbnail(thumbnailData, devicePreset: configuration.devicePresetName)
        page?.thumbnail = thumbnailData
        return thumbnailData
    }
}
