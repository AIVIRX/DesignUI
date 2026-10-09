
import SwiftUI
import Charts
import MapKit

extension ComponentRenderer {
    private func stringComponentProperty(_ key: String, defaultValue: String = "") -> String {
        component.getProperty(key: key) as? String ?? defaultValue
    }

    private func isSearchTextField() -> Bool {
        let placeholder = stringComponentProperty("placeholder").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let text = stringComponentProperty("text").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return placeholder.contains("search") || text.contains("search")
    }

    private func updateComponentProperty(_ key: String, value: Any) {
        if let canvasManager = canvasManager {
            canvasManager.updateComponentProperty(for: component, key: key, value: value)
        } else {
            component.setProperty(key: key, value: value)
        }
    }
    func renderText() -> some View {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        return Text(text)
    }
    
    private func iosFont(for fontSize: String, weight: Font.Weight, deviceSize: CGSize? = nil) -> Font {
        return createIOSFont(for: fontSize, weight: weight, design: .default, deviceSize: deviceSize ?? self.deviceSize)
    }
    
    func renderShape() -> some View {
        let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"

        switch shapeType {
        case "Circle":
            return AnyView(Circle().foregroundStyle(.primary))
        case "Capsule":
            return AnyView(Capsule().foregroundStyle(.primary))
        case "Ellipse":
            return AnyView(Ellipse().foregroundStyle(.primary))
        case "Rounded Rectangle":
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return AnyView(RoundedRectangle(cornerRadius: radius).foregroundStyle(.primary))
        default:
            return AnyView(Rectangle().foregroundStyle(.primary))
        }
    }
    
    func renderImage() -> some View {
        let config = imageRenderConfig()
        let imageName = resolvedImageName()

        if isLocalGalleryImage(named: imageName) {
            return AnyView(
                ImageComponentView(
                    imageName: imageName,
                    resizable: config.resizable,
                    aspectRatio: config.aspectRatio,
                    deviceSize: deviceSize
                )
            )
        }

        if let remoteURL = remoteImageURL(from: imageName) {
            return AnyView(
                RemoteImageComponentView(
                    url: remoteURL,
                    resizable: config.resizable,
                    aspectRatio: config.aspectRatio,
                    deviceSize: deviceSize
                )
            )
        }

        if let base64View = renderBase64Image(resizable: config.resizable, aspectRatio: config.aspectRatio) {
            return base64View
        }

        return imagePlaceholderView()
    }

    private func imageRenderConfig() -> (resizable: Bool, aspectRatio: String) {
        (
            resizable: component.getProperty(key: "resizable") as? Bool ?? true,
            aspectRatio: component.getProperty(key: "aspectRatio") as? String ?? "fit"
        )
    }

    private func resolvedImageName() -> String {
        let imageName = component.getProperty(key: "imageName") as? String ?? ""
        guard imageName.isEmpty else { return imageName }

        let imageData = component.getProperty(key: "imageData") as? String ?? ""
        guard !imageData.isEmpty else { return "" }

        if isImageFilename(imageData) || ImageGalleryManager.shared.getAllImageFilenames().contains(imageData) {
            return imageData
        }

        return ""
    }

    private func isImageFilename(_ value: String) -> Bool {
        value.hasSuffix(".jpg")
            || value.hasSuffix(".jpeg")
            || value.hasSuffix(".png")
            || value.hasSuffix(".gif")
            || value.hasSuffix(".heic")
    }

    private func isLocalGalleryImage(named imageName: String) -> Bool {
        !imageName.isEmpty && ImageGalleryManager.shared.imageExists(filename: imageName)
    }

    private func remoteImageURL(from imageName: String) -> URL? {
        guard let remoteURL = URL(string: imageName),
              let scheme = remoteURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }

        return remoteURL
    }

    private func renderBase64Image(resizable: Bool, aspectRatio: String) -> AnyView? {
        guard let imageDataString = component.getProperty(key: "imageData") as? String,
              !imageDataString.isEmpty,
              let imageData = Data(base64Encoded: imageDataString, options: .ignoreUnknownCharacters),
              !imageData.isEmpty,
              let image = createImage(from: imageData) else {
            return nil
        }

        return renderedDecodedImage(image, resizable: resizable, aspectRatio: aspectRatio)
    }

    #if os(macOS)
    private func renderedDecodedImage(_ image: NSImage, resizable: Bool, aspectRatio: String) -> AnyView {
        let intrinsicSize = getImageSize(image)
        let imageAspectRatio = intrinsicAspectRatio(for: intrinsicSize)
        var view: AnyView = AnyView(Image(nsImage: image).resizableIfNeeded(resizable))
        view = applyImageAspectRatio(to: view, aspectRatio: aspectRatio, imageAspectRatio: imageAspectRatio, clipsFill: false)
        return applyResolvedImageFrame(to: view, intrinsicSize: intrinsicSize)
    }
    #else
    private func renderedDecodedImage(_ image: UIImage, resizable: Bool, aspectRatio: String) -> AnyView {
        let intrinsicSize = getImageSize(image)
        let imageAspectRatio = intrinsicAspectRatio(for: intrinsicSize)
        var view: AnyView = AnyView(Image(uiImage: image).resizableIfNeeded(resizable))
        view = applyImageAspectRatio(to: view, aspectRatio: aspectRatio, imageAspectRatio: imageAspectRatio, clipsFill: true)
        return applyResolvedImageFrame(to: view, intrinsicSize: intrinsicSize)
    }
    #endif

    private func intrinsicAspectRatio(for intrinsicSize: CGSize) -> CGFloat? {
        guard intrinsicSize.width > 0 && intrinsicSize.height > 0 else { return nil }
        return intrinsicSize.width / intrinsicSize.height
    }

    private func applyImageAspectRatio(
        to view: AnyView,
        aspectRatio: String,
        imageAspectRatio: CGFloat?,
        clipsFill: Bool
    ) -> AnyView {
        guard aspectRatio != "none" else { return view }

        if let imageAspectRatio {
            switch aspectRatio {
            case "fit":
                return AnyView(view.aspectRatio(imageAspectRatio, contentMode: .fit))
            case "fill":
                let filledView = AnyView(view.aspectRatio(imageAspectRatio, contentMode: .fill))
                return clipsFill ? AnyView(filledView.clipped()) : filledView
            default:
                return AnyView(view.aspectRatio(imageAspectRatio, contentMode: .fit))
            }
        }

        switch aspectRatio {
        case "fit":
            return AnyView(view.aspectRatio(contentMode: .fit))
        case "fill":
            let filledView = AnyView(view.aspectRatio(contentMode: .fill))
            return clipsFill ? AnyView(filledView.clipped()) : filledView
        default:
            return view
        }
    }

    private func applyResolvedImageFrame(to view: AnyView, intrinsicSize: CGSize) -> AnyView {
        if let fallbackSize = resolvedImageFrameSize(for: intrinsicSize) {
            return AnyView(view.frame(width: fallbackSize.width, height: fallbackSize.height))
        }

        return AnyView(view.frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height))
    }

    private func imagePlaceholderView() -> AnyView {
        let defaultSize: CGFloat = 100

        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("Select Image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: defaultSize, height: defaultSize)
        )
    }

    #if os(macOS)
    private func createImage(from data: Data) -> NSImage? {
        guard !data.isEmpty else {
            debugLog("⚠️ Image data is empty")
            return nil
        }
        
        guard let image = NSImage(data: data) else {
            debugLog("⚠️ Failed to create NSImage from data")
            return nil
        }
        
        guard image.isValid else {
            debugLog("⚠️ NSImage is invalid")
            return nil
        }
        
        return image
    }
    #else
    private func createImage(from data: Data) -> UIImage? {
        guard !data.isEmpty else {
            debugLog("⚠️ Image data is empty")
            return nil
        }
        
        guard let image = UIImage(data: data) else {
            debugLog("⚠️ Failed to create UIImage from data")
            return nil
        }
        
        guard image.size.width > 0 && image.size.height > 0 else {
            debugLog("⚠️ UIImage has invalid size")
            return nil
        }
        
        return image
    }
    #endif
    
    #if os(macOS)
    private func getImageSize(_ image: NSImage) -> CGSize {
        return image.size
    }
    #else
    private func getImageSize(_ image: UIImage) -> CGSize {
        return image.size
    }
    #endif

    private func resolvedImageFrameSize(for intrinsicSize: CGSize) -> CGSize? {
        guard deviceSize == nil else { return nil }
        guard intrinsicSize.width > 0, intrinsicSize.height > 0 else { return CGSize(width: 100, height: 100) }
        return intrinsicSize
    }
    
    func renderButton() -> some View {
        let buttonStyle = component.getProperty(key: "buttonStyle") as? String ?? "borderedProminent"
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        return AnyView(
            Button(action: {}) {
                if contentChildren.isEmpty {
                    EmptyView()
                } else {
                    ForEach(contentChildren, id: \.id) { child in
                        ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                            onSelectChild?(child, additive)
                        }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                    }
                }
            }
            .applyButtonStyle(buttonStyle)
        )
    }
    
    func renderGauge() -> some View {
        let config = gaugeRenderConfig()

        switch config.type {
        case "linear":
            return linearGaugeView(config: config)
        case "circular":
            return circularGaugeView(config: config)
        case "circular range":
            return circularRangeGaugeView(config: config)
        default:
            return defaultGaugeView(config: config)
        }
    }

    private func gaugeRenderConfig() -> (type: String, value: Double, minValue: Double, maxValue: Double, showValue: Bool) {
        let gaugeType = component.getProperty(key: "gaugeType") as? String ?? "circular"
        let rawValue = doubleComponentProperty("value", defaultValue: 50)
        let rawMin = doubleComponentProperty("min", defaultValue: 0)
        let rawMax = doubleComponentProperty("max", defaultValue: 100)
        let showValue = component.getProperty(key: "showValue") as? Bool ?? true

        let minValue = Swift.min(rawMin, rawMax)
        let maxValue = Swift.max(rawMin, rawMax)
        let safeValue = rawValue.isFinite ? rawValue : minValue
        let clampedValue = Swift.min(Swift.max(safeValue, minValue), maxValue)

        return (
            type: gaugeType,
            value: clampedValue,
            minValue: minValue,
            maxValue: maxValue,
            showValue: showValue
        )
    }

    private func doubleComponentProperty(_ key: String, defaultValue: Double) -> Double {
        (component.getProperty(key: key) as? Double)
            ?? (component.getProperty(key: key) as? Int).map(Double.init)
            ?? defaultValue
    }

    private struct ParsedMapMarker: Identifiable {
        let id: String
        let latitude: Double
        let longitude: Double
        let title: String
        let tint: String?

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    private struct DecodedMapMarker: Decodable {
        let latitude: Double
        let longitude: Double
        let title: String?
        let tint: String?
    }

    private func parsedMapMarkers(centerLatitude: Double, centerLongitude: Double, fallbackTitle: String) -> [ParsedMapMarker] {
        if let rawMarkers = component.getProperty(key: "markers") {
            if let markerArray = rawMarkers as? [[String: Any]] {
                let parsed = markerArray.compactMap { markerDict -> ParsedMapMarker? in
                    guard
                        let latitude = numericValue(markerDict["latitude"]),
                        let longitude = numericValue(markerDict["longitude"])
                    else { return nil }

                    let title = (markerDict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let tint = markerDict["tint"] as? String
                    let id = "\(latitude),\(longitude),\(title),\(tint ?? "")"
                    return ParsedMapMarker(id: id, latitude: latitude, longitude: longitude, title: title, tint: tint)
                }
                if !parsed.isEmpty {
                    return parsed
                }
            }

            if let markerString = rawMarkers as? String {
                let trimmed = markerString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty, let data = trimmed.data(using: .utf8) {
                    if let decoded = try? JSONDecoder().decode([DecodedMapMarker].self, from: data) {
                        let parsed = decoded.map { marker in
                            ParsedMapMarker(
                                id: "\(marker.latitude),\(marker.longitude),\(marker.title ?? ""),\(marker.tint ?? "")",
                                latitude: marker.latitude,
                                longitude: marker.longitude,
                                title: marker.title ?? "",
                                tint: marker.tint
                            )
                        }
                        if !parsed.isEmpty {
                            return parsed
                        }
                    }
                }
            }
        }

        let trimmedTitle = fallbackTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return [] }
        return []
    }

    private func numericValue(_ raw: Any?) -> Double? {
        if let doubleValue = raw as? Double { return doubleValue }
        if let intValue = raw as? Int { return Double(intValue) }
        if let stringValue = raw as? String { return Double(stringValue) }
        return nil
    }

    private func mapInteractionModes(from rawValue: String) -> MapInteractionModes {
        let normalized = rawValue
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "none":
            return []
        case "pan":
            return .pan
        case "zoom":
            return .zoom
        case "rotate":
            return .rotate
        case "pitch":
            return .pitch
        case "pan+zoom":
            return [.pan, .zoom]
        case "pan+zoom+rotate":
            return [.pan, .zoom, .rotate]
        case "pan+zoom+rotate+pitch":
            return [.pan, .zoom, .rotate, .pitch]
        default:
            return .all
        }
    }

    private func mapMarkerTint(_ tint: String?) -> Color {
        guard let tint, !tint.isEmpty else { return .red }
        return ComponentProperty.colorStringToColor(tint)
    }

    @ViewBuilder
    private func mapMarkerView(_ marker: ParsedMapMarker) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(mapMarkerTint(marker.tint))
                    .frame(width: 18, height: 18)

                Circle()
                    .fill(.white.opacity(0.95))
                    .frame(width: 6, height: 6)
            }

            if !marker.title.isEmpty {
                Text(marker.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
    }

    func renderMap() -> some View {
        let latitude = doubleComponentProperty("latitude", defaultValue: 37.3346)
        let longitude = doubleComponentProperty("longitude", defaultValue: -122.0090)
        let latitudeDelta = max(doubleComponentProperty("latitudeDelta", defaultValue: 0.018), 0.001)
        let longitudeDelta = max(doubleComponentProperty("longitudeDelta", defaultValue: 0.018), 0.001)
        let interactionModes = mapInteractionModes(from: component.getProperty(key: "interactionModes") as? String ?? "all")
        let showsCompass = component.getBoolProperty(key: "showsCompass", defaultValue: true)
        let showsScale = component.getBoolProperty(key: "showsScale", defaultValue: false)
        let showsPitchToggle = component.getBoolProperty(key: "showsPitchToggle", defaultValue: false)
        let showsUserLocationButton = component.getBoolProperty(key: "showsUserLocationButton", defaultValue: false)
        let showsTraffic = component.getBoolProperty(key: "showsTraffic", defaultValue: false)
        let mapStyle = (component.getProperty(key: "mapStyle") as? String ?? "standard").lowercased()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
        // `initialPosition` is read only when Map is created. Change only the map's
        // identity when its saved camera changes so presets move the camera without
        // fighting user pan/zoom gestures.
        let mapCameraIdentity = "\(latitude)|\(longitude)|\(latitudeDelta)|\(longitudeDelta)|\(mapStyle)"

        if isScreenshotCapture {
            return AnyView(
                ScreenshotMapSnapshotView(
                    region: region,
                    mapStyle: mapStyle,
                    colorScheme: colorScheme ?? .light
                )
            )
        }

        if #available(iOS 17.0, macOS 14.0, *) {
            return AnyView(
                Map(initialPosition: .region(region), interactionModes: interactionModes) {
                    ForEach(parsedMapMarkers(centerLatitude: latitude, centerLongitude: longitude, fallbackTitle: "")) { marker in
                        Marker(marker.title, coordinate: marker.coordinate)
                            .tint(ComponentProperty.colorStringToColor(marker.tint ?? "red:1.0"))
                    }
                    if component.getBoolProperty(key: "showsUserLocation", defaultValue: false) {
                        UserAnnotation()
                    }
                }
                    .mapStyle(resolvedMapStyle(mapStyle, showsTraffic: showsTraffic))
                    .mapControls {
                        if showsCompass {
                            MapCompass()
                        }
                        if showsScale {
                            MapScaleView()
                        }
                        if showsPitchToggle {
                            MapPitchToggle()
                        }
                        if showsUserLocationButton {
                            MapUserLocationButton()
                        }
                    }
                    .id(mapCameraIdentity)
            )
        }

        return AnyView(
            Map(initialPosition: .region(region), interactionModes: interactionModes)
                .id(mapCameraIdentity)
        )
    }

    private func resolvedMapStyle(_ style: String, showsTraffic: Bool) -> MapStyle {
        switch style {
        case "imagery":
            return .imagery(elevation: .realistic)
        case "hybrid":
            return .hybrid(elevation: .realistic, showsTraffic: showsTraffic)
        default:
            return .standard(elevation: .realistic, showsTraffic: showsTraffic)
        }
    }

    private func gaugeValueText(_ value: Double) -> String {
        String(Int(value))
    }

    private func gaugeValueLabel(_ value: Double, showValue: Bool) -> AnyView {
        guard showValue else { return AnyView(EmptyView()) }
        return AnyView(Text(gaugeValueText(value)))
    }

    private func linearGaugeView(config: (type: String, value: Double, minValue: Double, maxValue: Double, showValue: Bool)) -> AnyView {
        AnyView(
            Gauge(value: config.value, in: config.minValue...config.maxValue) {
                if config.showValue {
                    Text(gaugeValueText(config.value))
                }
            }
            .gaugeStyle(.linearCapacity)
        )
    }

    private func circularGaugeView(config: (type: String, value: Double, minValue: Double, maxValue: Double, showValue: Bool)) -> AnyView {
        AnyView(
            Gauge(value: config.value, in: config.minValue...config.maxValue) {
                if config.showValue {
                    Text(gaugeValueText(config.value))
                } else {
                    EmptyView()
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
        )
    }

    private func circularRangeGaugeView(config: (type: String, value: Double, minValue: Double, maxValue: Double, showValue: Bool)) -> AnyView {
        AnyView(
            Gauge(value: config.value, in: config.minValue...config.maxValue) {
                EmptyView()
            } currentValueLabel: {
                if config.showValue {
                    Text(gaugeValueText(config.value))
                } else {
                    EmptyView()
                }
            } minimumValueLabel: {
                Text(gaugeValueText(config.minValue))
            } maximumValueLabel: {
                Text(gaugeValueText(config.maxValue))
            }
            .gaugeStyle(.accessoryCircular)
        )
    }

    private func defaultGaugeView(config: (type: String, value: Double, minValue: Double, maxValue: Double, showValue: Bool)) -> AnyView {
        AnyView(
            Gauge(value: config.value, in: config.minValue...config.maxValue) {}
                .gaugeStyle(.accessoryCircularCapacity)
        )
    }

    func renderVStack() -> some View {
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = VStack(alignment: horizontalAlignmentFromString(alignment), spacing: spacing) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: contentChildren.map { $0.id })
        return base
    }

    func renderStack() -> some View {
        let stackType = (component.getProperty(key: "stackType") as? String ?? "vertical").lowercased()
        switch stackType {
        case "horizontal":
            return AnyView(renderHStack())
        case "z":
            return AnyView(renderZStack())
        default:
            return AnyView(renderVStack())
        }
    }
    
    func renderHStack() -> some View {
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = HStack(alignment: verticalAlignmentFromString(alignment), spacing: spacing) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: contentChildren.map { $0.id })
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base)
    }
    
    func renderZStack() -> some View {
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = ZStack(alignment: alignmentFromString(alignment)) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: contentChildren.map { $0.id })
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base)
    }
    
    func renderSpacer() -> some View {
        return Spacer()
    }
    
    func renderDivider() -> some View {
        return Divider()
    }
    
    func renderRectangle() -> some View {
        return AnyView(Rectangle().foregroundStyle(.primary))
    }
    
    func renderCircle() -> some View {
        return AnyView(Circle().foregroundStyle(.primary))
    }
    
    func renderRoundedRectangle() -> some View {
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
        return AnyView(RoundedRectangle(cornerRadius: cornerRadius).foregroundStyle(.primary))
    }
    
    func renderCapsule() -> some View {
        return AnyView(Capsule().foregroundStyle(.primary))
    }
    
    func renderEllipse() -> some View {
        return AnyView(Ellipse().foregroundStyle(.primary))
    }
    
    func renderLinearGradient() -> some View {
        let colors = component.getProperty(key: "colors") as? [String] ?? ["blue", "green"]
        let startPointStr = component.getProperty(key: "startPoint") as? String ?? "top"
        let endPointStr = component.getProperty(key: "endPoint") as? String ?? "bottom"
        
        let gradientColors = colors.map { colorStr -> Color in
            let parts = colorStr.split(separator: ":")
            let colorName = parts.count >= 1 ? String(parts[0]) : "blue"
            let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
            return ComponentProperty.colorStringToColor(colorName).opacity(opacity)
        }
        
        let startPoint = unitPointFromString(startPointStr)
        let endPoint = unitPointFromString(endPointStr)
        
        return LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: startPoint, endPoint: endPoint)
    }
    
    func renderScrollView() -> some View {
        let axesString = component.getProperty(key: "axis") as? String ?? "vertical"
        let showsIndicators = component.getBoolProperty(key: "showsIndicators", defaultValue: true)
        
        let axes: Axis.Set = axesString == "horizontal" ? .horizontal : .vertical
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        let content = scrollContent(children: contentChildren, axes: axes)

        // For fixed-size screenshot captures, keep real ScrollView behavior so sibling
        // overlays (like bottom nav bars) remain visible within device bounds.
        // Only expand scroll content in content-adaptive screenshot mode.
        if isScreenshotCapture && deviceSize == nil {
            return screenshotScrollContent(children: contentChildren, axes: axes)
        }
        
        let base: AnyView = AnyView(
            ScrollView(axes, showsIndicators: showsIndicators) {
                content
            }
            #if os(macOS)
            .onHover { isHovering in
                canvasManager?.isHoveringScrollable = isHovering
            }
            #endif
        )
        
        if hasExplicitFrame {
            return AnyView(base.frame(width: component.frame.width, height: component.frame.height))
        }
        
        // In fixed-size screenshot capture, vertical feeds often rely on "full" frame
        // modifiers (not component.frame). Force fill so the content doesn't collapse.
        if isScreenshotCapture && deviceSize != nil && axes == .vertical {
            return AnyView(base.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top))
        }
        
        if axes == .horizontal {
            return AnyView(base.frame(minWidth: 160))
        } else {
            return AnyView(base.frame(minWidth: 120, minHeight: 160))
        }
    }
    
    @ViewBuilder
    private func scrollContent(children: [UIComponent], axes: Axis.Set) -> some View {
        if axes == .horizontal {
            HStack(spacing: 8) {
                scrollChildren(children)
            }
        } else {
            VStack(alignment: .center, spacing: 8) {
                scrollChildren(children)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private func screenshotScrollContent(children: [UIComponent], axes: Axis.Set) -> AnyView {
        if axes == .horizontal {
            return AnyView(
                HStack(spacing: 8) {
                    scrollChildren(children)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        } else {
            return AnyView(
                VStack(alignment: .center, spacing: 8) {
                    scrollChildren(children)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            )
        }
    }
    
    @ViewBuilder
    private func scrollChildren(_ children: [UIComponent]) -> some View {
        ForEach(children, id: \.id) { child in
            ComponentRenderer(
                component: child,
                deviceSize: deviceSize,
                colorScheme: colorScheme,
                onTap: { additive in
                    onSelectChild?(child, additive)
                },
                onSelectChild: onSelectChild,
                selectedComponentIds: selectedComponentIds,
                isScreenshotCapture: isScreenshotCapture,
                canvasManager: canvasManager
            )
        }
    }
    
    func renderSFSymbol() -> some View {
        let rawSymbolName = component.getProperty(key: "symbolName") as? String ?? "star"
        let symbolName = sfSymbolExists(rawSymbolName) ? rawSymbolName : "questionmark.circle"
        
        // Do not force local font/color fallback here.
        // This allows parent container modifiers (e.g. Font on VStack) to inherit correctly.
        return AnyView(
            Image(systemName: symbolName)
                .symbolRenderingMode(.monochrome)
        )
    }
    
    private func sfSymbolExists(_ name: String) -> Bool {
        #if os(macOS)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #else
        return UIImage(systemName: name) != nil
        #endif
    }
    
    func renderTextField() -> some View {
        let placeholder = stringComponentProperty("placeholder", defaultValue: "Placeholder")
        let isSearchField = isSearchTextField()
        let binding = Binding<String>(
            get: { stringComponentProperty("text") },
            set: { newValue in
                updateComponentProperty("text", value: newValue)
            }
        )

        return TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .foregroundColor(.primary)
            .autocorrectionDisabled(isSearchField)
            #if os(iOS)
            .textInputAutocapitalization(isSearchField ? .never : .sentences)
            #endif
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(textFieldBackground)
            .padding(4)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    onTap?(false)
                }
            )
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            .background(textFieldBackgroundFill)
    }
    
    private var textFieldBackgroundFill: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color.white.opacity(0.8))
    }
    
    func renderToggle() -> some View {
        let isOn = component.getProperty(key: "isOn") as? Bool ?? true
        
        let binding = Binding<Bool>(
            get: { isOn },
            set: { newValue in
                if let canvasManager = canvasManager {
                    canvasManager.updateComponentProperty(for: component, key: "isOn", value: newValue)
                } else {
                    self.component.setProperty(key: "isOn", value: newValue)
                }
            }
        )
        
        return CustomSwitchView(isOn: binding)
            .padding(4)
    }
    
    func renderSlider() -> some View {
        let value = component.getProperty(key: "value") as? Double ?? 0.5
        let min = component.getProperty(key: "min") as? Double ?? 0.0
        let max = component.getProperty(key: "max") as? Double ?? 1.0
        
        let binding = Binding<Double>(
            get: { value },
            set: { newValue in
                if let canvasManager = canvasManager {
                    canvasManager.updateComponentProperty(for: component, key: "value", value: newValue)
                } else {
                    self.component.setProperty(key: "value", value: newValue)
                }
            }
        )
        
        return CustomSliderView(value: binding, range: min...max)
            .padding(.horizontal)
    }
    
    func renderProgressView() -> some View {
        let value = component.getProperty(key: "value") as? Double ?? 0.6
        let total = component.getProperty(key: "total") as? Double ?? 1.0
        let safeTotal = total > 0 ? total : 1.0
        let safeValue = min(max(value, 0), safeTotal)

        return AnyView(
            ProgressView(value: safeValue, total: safeTotal)
                .progressViewStyle(.linear)
                .frame(minWidth: 120)
                .padding(.horizontal, 4)
        )
    }

    func renderPlaceholder() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack {
                    Image(systemName: "questionmark")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text(component.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
    }
    
    private func unitPointFromString(_ string: String) -> UnitPoint {
        switch string {
        case "top": return .top
        case "bottom": return .bottom
        case "leading": return .leading
        case "trailing": return .trailing
        case "center": return .center
        case "topLeading": return .topLeading
        case "topTrailing": return .topTrailing
        case "bottomLeading": return .bottomLeading
        case "bottomTrailing": return .bottomTrailing
        default: return .top
        }
    }

}

private extension Image {
    func resizableIfNeeded(_ needed: Bool) -> some View {
        needed ? AnyView(self.resizable()) : AnyView(self)
    }
}

extension View {
    func applyOverlayChildren(_ overlayChildren: [UIComponent], deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> some View {
        var view = AnyView(self)
        
        for overlayChild in overlayChildren {
            let overlayView = ComponentRenderer(
                component: overlayChild,
                deviceSize: deviceSize,
                colorScheme: colorScheme,
                onTap: { additive in
                    onSelectChild?(overlayChild, additive)
                },
                onSelectChild: onSelectChild,
                selectedComponentIds: selectedComponentIds
            )
            
            let alignment = Alignment.topTrailing
            view = AnyView(view.overlay(overlayView, alignment: alignment))
        }
        
        return view
    }
    
    func applyModifiers(_ modifiers: [ComponentModifier], component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>, isScreenshotCapture: Bool = false) -> some View {
        var view = AnyView(self)

        for modifier in orderedModifiersForRendering(modifiers, component: component) {
            view = AnyView(applyModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture))
        }
        
        return view
    }

    private func orderedModifiersForRendering(_ modifiers: [ComponentModifier], component: UIComponent) -> [ComponentModifier] {
        let effectTypes: Set<ModifierType> = [.opacity, .shadow, .blur, .glassEffect, .clipShape]
        let fillTypes: Set<ModifierType> = [.fill, .foregroundColor, .tint]
        let layoutTypes: Set<ModifierType> = [.frame, .padding, .rotation, .offset]
        let prioritizeShapeFrame = isShapeLikeSizingComponent(component)

        return modifiers
            .enumerated()
            .sorted { lhs, rhs in
                let lhsPriority = modifierRenderPriority(lhs.element.type, fillTypes: fillTypes, layoutTypes: layoutTypes, effectTypes: effectTypes, prioritizeShapeFrame: prioritizeShapeFrame)
                let rhsPriority = modifierRenderPriority(rhs.element.type, fillTypes: fillTypes, layoutTypes: layoutTypes, effectTypes: effectTypes, prioritizeShapeFrame: prioritizeShapeFrame)
                if lhsPriority == rhsPriority {
                    return lhs.offset < rhs.offset
                }
                return lhsPriority < rhsPriority
            }
            .map(\.element)
    }

    private func isShapeLikeSizingComponent(_ component: UIComponent) -> Bool {
        switch component.type {
        case .rectangle, .circle, .roundedRectangle, .capsule, .ellipse, .shape:
            return true
        default:
            return false
        }
    }

    private func modifierRenderPriority(
        _ type: ModifierType,
        fillTypes: Set<ModifierType>,
        layoutTypes: Set<ModifierType>,
        effectTypes: Set<ModifierType>,
        prioritizeShapeFrame: Bool
    ) -> Int {
        if fillTypes.contains(type) { return 0 }
        if prioritizeShapeFrame && type == .frame { return 1 }
        if prioritizeShapeFrame && type == .padding { return 2 }
        if layoutTypes.contains(type) { return 1 }
        if type == .backgroundColor { return 2 }
        if type == .cornerRadius { return 3 }
        if effectTypes.contains(type) { return 4 }
        return 2
    }
    
    private func parseColorWithOpacity(modifier: ComponentModifier) -> (Color, Double) {
        if let colorData = modifier.properties["color"] as? String {
            let parts = colorData.split(separator: ":")
            let colorName = parts.count >= 1 ? String(parts[0]) : "primary"
            let color = ComponentProperty.colorStringToColor(colorName)
            let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
            return (color, opacity)
        }
        return (.primary, 1.0)
    }
    
    private func resolveStrokeCornerRadius(for component: UIComponent) -> CGFloat {
        if let radius = component.getProperty(key: "cornerRadius") as? CGFloat {
            return radius
        }
        if let radius = component.getProperty(key: "cornerRadius") as? Double {
            return CGFloat(radius)
        }
        if let radiusModifier = component.modifiers.first(where: { $0.type == .cornerRadius }) {
            return radiusModifier.getCGFloat(key: "radius", defaultValue: 0)
        }
        return 0
    }
    
    private func strokeShapeView(for component: UIComponent, color: Color, lineWidth: CGFloat) -> AnyView {
        if component.type == .shape {
            let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"
            switch shapeType {
            case "Circle":
                return AnyView(Circle().stroke(color, lineWidth: lineWidth))
            case "Capsule":
                return AnyView(Capsule().stroke(color, lineWidth: lineWidth))
            case "Ellipse":
                return AnyView(Ellipse().stroke(color, lineWidth: lineWidth))
            case "Rounded Rectangle":
                let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
                return AnyView(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: lineWidth))
            default:
                return AnyView(Rectangle().stroke(color, lineWidth: lineWidth))
            }
        }
        
        switch component.type {
        case .roundedRectangle:
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return AnyView(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: lineWidth))
        case .circle:
            return AnyView(Circle().stroke(color, lineWidth: lineWidth))
        case .capsule:
            return AnyView(Capsule().stroke(color, lineWidth: lineWidth))
        case .ellipse:
            return AnyView(Ellipse().stroke(color, lineWidth: lineWidth))
        case .rectangle:
            return AnyView(Rectangle().stroke(color, lineWidth: lineWidth))
        default:
            let cornerRadius = resolveStrokeCornerRadius(for: component)
            if cornerRadius > 0 {
                return AnyView(RoundedRectangle(cornerRadius: cornerRadius).stroke(color, lineWidth: lineWidth))
            }
            return AnyView(Rectangle().stroke(color, lineWidth: lineWidth))
        }
    }
    
    private func applyModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>, isScreenshotCapture: Bool = false) -> AnyView {
        switch modifier.type {
        case .frame:
            return applyFrameModifier(modifier, to: view, component: component, deviceSize: deviceSize)
            
        case .padding:
            return applyPaddingModifier(modifier, to: view)
            
        case .background:
            return applyBackgroundModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
            
        case .backgroundColor:
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.background(gradient))
            }
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.background(color.opacity(opacity)))
            
        case .foregroundColor:
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.foregroundStyle(gradient))
            }
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.foregroundStyle(color.opacity(opacity)))
            
        case .font:
            return applyFontModifier(modifier, to: view, deviceSize: deviceSize)
            
        case .fill:
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.foregroundStyle(gradient))
            }
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.foregroundStyle(color.opacity(opacity)))
        case .tint:
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.tint(color.opacity(opacity)))
            
        case .cornerRadius:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.cornerRadius(radius))

        case .shadow:
            return applyShadowModifier(modifier, to: view)
            
        case .opacity:
            let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            return AnyView(view.opacity(opacity))
            
        case .rotation:
            let angle = modifier.getDouble(key: "angle", defaultValue: 0)
            return AnyView(view.rotationEffect(.degrees(angle)))
            
        case .offset:
            return applyOffsetModifier(modifier, to: view)

        case .blur:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.blur(radius: radius))
            
        case .overlay:
            return applyOverlayModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
            
        case .border:
            let width = modifier.getCGFloat(key: "width", defaultValue: 1)
            let color = modifier.getColor(key: "color", defaultValue: .primary)
            return AnyView(view.border(color, width: width))
            
        case .stroke:
            let lineWidth = modifier.getCGFloat(key: "lineWidth", defaultValue: 1)
            let color = modifier.getColor(key: "color", defaultValue: .primary)
            return AnyView(
                view.overlay(
                    strokeShapeView(for: component, color: color, lineWidth: lineWidth)
                )
            )
            
        case .clipShape:
            return applyClipShapeModifier(modifier, to: view)
            
        case .mask:
            return applyMaskModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
            
        case .textAlignment:
            let alignment = modifier.properties["alignment"] as? String ?? "leading"
            let textAlignment = multilineTextAlignmentFromString(alignment)
            return AnyView(view.multilineTextAlignment(textAlignment))

        case .glassEffect:
            return applyGlassEffectModifier(modifier, to: view, component: component, colorScheme: colorScheme, isScreenshotCapture: isScreenshotCapture)
        }
    }

    private func screenshotGlassEffectView(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, colorScheme: ColorScheme?) -> AnyView {
                let hasExplicitTextColor = component.modifiers.contains { mod in
                    mod.type == .fill || mod.type == .foregroundColor || mod.type == .tint
                }
                let screenshotBaseView: AnyView
                if component.type == .text && !hasExplicitTextColor {
                    let canvasPrimaryColor: Color = (colorScheme == .dark) ? .white : .black
                    screenshotBaseView = AnyView(view.foregroundStyle(canvasPrimaryColor))
                } else {
                    screenshotBaseView = view
                }

                let shapeName = normalizedGlassShapeName(from: modifier)
                let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 10)
                let tintString = (modifier.properties["tint"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let tintColor = tintString.isEmpty
                    ? Color.white
                    : ComponentProperty.colorStringToColor(tintString)
                let screenshotMaterialOpacity = (colorScheme == .dark) ? 0.82 : 0.9
                let screenshotGradientOpacity = (colorScheme == .dark) ? 0.34 : 0.42
                // Keep the fallback glass edge-free; native Liquid Glass supplies its
                // own optical edge without a drawn outline.
                let screenshotStrokeWidth: CGFloat = 0
                let screenshotShadowOpacity = (colorScheme == .dark) ? 0.28 : 0.18
                let screenshotShadowRadius = max(radius, 14)

                switch shapeName {
                case "Circle":
                    return AnyView(
                        screenshotBaseView
                            .glass(
                                radius: max(radius, 999),
                                color: tintColor,
                                material: .regularMaterial,
                                materialOpacity: screenshotMaterialOpacity,
                                gradientOpacity: screenshotGradientOpacity,
                                strokeWidth: screenshotStrokeWidth,
                                shadowColor: .white,
                                shadowOpacity: screenshotShadowOpacity,
                                shadowRadius: screenshotShadowRadius,
                                shadowX: 0,
                                shadowY: 6
                            )
                            .clipShape(Circle())
                            .contentShape(Circle())
                    )
                case "Capsule":
                    return AnyView(
                        screenshotBaseView
                            .glass(
                                radius: max(radius, 999),
                                color: tintColor,
                                material: .regularMaterial,
                                materialOpacity: screenshotMaterialOpacity,
                                gradientOpacity: screenshotGradientOpacity,
                                strokeWidth: screenshotStrokeWidth,
                                shadowColor: .white,
                                shadowOpacity: screenshotShadowOpacity,
                                shadowRadius: screenshotShadowRadius,
                                shadowX: 0,
                                shadowY: 6
                            )
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                    )
                case "RoundedRectangle":
                    return AnyView(
                        screenshotBaseView
                            .glass(
                                radius: radius,
                                color: tintColor,
                                material: .regularMaterial,
                                materialOpacity: screenshotMaterialOpacity,
                                gradientOpacity: screenshotGradientOpacity,
                                strokeWidth: screenshotStrokeWidth,
                                shadowColor: .white,
                                shadowOpacity: screenshotShadowOpacity,
                                shadowRadius: screenshotShadowRadius,
                                shadowX: 0,
                                shadowY: 6
                            )
                            .clipShape(RoundedRectangle(cornerRadius: radius))
                            .contentShape(RoundedRectangle(cornerRadius: radius))
                    )
                case "Ellipse":
                    return AnyView(
                        screenshotBaseView
                            .glass(
                                radius: max(radius, 999),
                                color: tintColor,
                                material: .regularMaterial,
                                materialOpacity: screenshotMaterialOpacity,
                                gradientOpacity: screenshotGradientOpacity,
                                strokeWidth: screenshotStrokeWidth,
                                shadowColor: .white,
                                shadowOpacity: screenshotShadowOpacity,
                                shadowRadius: screenshotShadowRadius,
                                shadowX: 0,
                                shadowY: 6
                            )
                            .clipShape(Ellipse())
                            .contentShape(Ellipse())
                    )
                case "Rectangle":
                    return AnyView(
                        screenshotBaseView
                            .glass(
                                radius: 0,
                                color: tintColor,
                                material: .regularMaterial,
                                materialOpacity: screenshotMaterialOpacity,
                                gradientOpacity: screenshotGradientOpacity,
                                strokeWidth: screenshotStrokeWidth,
                                shadowColor: .white,
                                shadowOpacity: screenshotShadowOpacity,
                                shadowRadius: screenshotShadowRadius,
                                shadowX: 0,
                                shadowY: 6
                            )
                            .clipShape(Rectangle())
                            .contentShape(Rectangle())
                    )
                default:
                    return AnyView(
                        screenshotBaseView
                            .glass(
                                radius: 10,
                                color: tintColor,
                                material: .regularMaterial,
                                materialOpacity: screenshotMaterialOpacity,
                                gradientOpacity: screenshotGradientOpacity,
                                strokeWidth: screenshotStrokeWidth,
                                shadowColor: .white,
                                shadowOpacity: screenshotShadowOpacity,
                                shadowRadius: screenshotShadowRadius,
                                shadowX: 0,
                                shadowY: 6
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                    )
                }
            }

    private func applyGlassEffectModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, colorScheme: ColorScheme?, isScreenshotCapture: Bool) -> AnyView {
        if isScreenshotCapture {
            return screenshotGlassEffectView(modifier, to: view, component: component, colorScheme: colorScheme)
        }

            if #available(iOS 26.0, macOS 26.0, *) {
                let hasExplicitTextColor = component.modifiers.contains { mod in
                    mod.type == .fill || mod.type == .foregroundColor || mod.type == .tint
                }
                let baseView: AnyView
                if component.type == .text && !hasExplicitTextColor {
                    let canvasPrimaryColor: Color = (colorScheme == .dark) ? .white : .black
                    baseView = AnyView(view.foregroundStyle(canvasPrimaryColor))
                } else {
                    baseView = view
                }

                let shapeName = normalizedGlassShapeName(from: modifier)
                let tintString = (modifier.properties["tint"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                switch shapeName {
                case "Circle":
                    return glassEffectRenderedView(baseView: baseView, shape: Circle(), useOverlayForShape: component.type == .shape, colorScheme: colorScheme, componentType: component.type, tintString: tintString)
                case "Capsule":
                    return glassEffectRenderedView(baseView: baseView, shape: Capsule(), useOverlayForShape: component.type == .shape, colorScheme: colorScheme, componentType: component.type, tintString: tintString)
                case "RoundedRectangle":
                    let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 10)
                    return glassEffectRenderedView(baseView: baseView, shape: RoundedRectangle(cornerRadius: radius), useOverlayForShape: component.type == .shape, colorScheme: colorScheme, componentType: component.type, tintString: tintString)
                case "Ellipse":
                    return glassEffectRenderedView(baseView: baseView, shape: Ellipse(), useOverlayForShape: component.type == .shape, colorScheme: colorScheme, componentType: component.type, tintString: tintString)
                case "Rectangle":
                    return glassEffectRenderedView(baseView: baseView, shape: Rectangle(), useOverlayForShape: component.type == .shape, colorScheme: colorScheme, componentType: component.type, tintString: tintString)
                default:
                    return glassEffectRenderedView(baseView: baseView, shape: RoundedRectangle(cornerRadius: 10), useOverlayForShape: false, colorScheme: colorScheme, componentType: component.type, tintString: tintString)
                }
            }
            return view
    }

    private func glassEffectRenderedView<S: Shape>(baseView: AnyView, shape: S, useOverlayForShape: Bool, colorScheme: ColorScheme?, componentType: ComponentType, tintString: String) -> AnyView {
        if #available(iOS 26.0, macOS 26.0, *) {
            let isDarkMode = colorScheme == .dark
            let isContainer = [.stack, .vstack, .hstack, .zstack, .scrollView].contains(componentType)
            let tintColor = tintString.isEmpty ? Color.gray.opacity(0.45) : ComponentProperty.colorStringToColor(tintString)
            let rendered: AnyView

            if isDarkMode {
                let glassView = tintString.isEmpty
                    ? Color.clear.glassEffect(.regular.interactive(), in: shape)
                    : Color.clear.glassEffect(.regular.tint(tintColor).interactive(), in: shape)
                if useOverlayForShape {
                    rendered = AnyView(baseView.overlay(glassView))
                } else if isContainer {
                    rendered = AnyView(baseView.background(glassView))
                } else {
                    rendered = tintString.isEmpty
                        ? AnyView(baseView.glassEffect(.regular.interactive(), in: shape))
                        : AnyView(baseView.glassEffect(.regular.tint(tintColor).interactive(), in: shape))
                }
            } else {
                let glassView = Color.clear.glassEffect(.regular.tint(tintColor).interactive(), in: shape)
                if useOverlayForShape {
                    rendered = AnyView(baseView.overlay(glassView))
                } else if isContainer {
                    rendered = AnyView(baseView.background(glassView))
                } else {
                    rendered = AnyView(baseView.glassEffect(.regular.tint(tintColor).interactive(), in: shape))
                }
            }
            return AnyView(
                rendered
                    .contentShape(shape)
                    .shadow(color: .black.opacity(isDarkMode ? 0.12 : 0.08), radius: 10, y: 2)
            )
        } else {
            return baseView
        }
    }


    private func applyFrameModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?) -> AnyView {
        let values = frameModifierValues(from: modifier)
        guard values.widthType != "Default" || values.heightType != "Default" else {
            return view
        }

        let limits = frameDeviceLimits(deviceSize: deviceSize)
        var modifiedView = view
        modifiedView = applyFrameWidth(values: values, limits: limits, component: component, to: modifiedView)
        modifiedView = applyFrameHeight(values: values, limits: limits, to: modifiedView)
        return modifiedView
    }
    
    private func frameModifierValues(from modifier: ComponentModifier) -> (widthType: String, heightType: String, width: CGFloat, height: CGFloat) {
        (
            widthType: normalizedFrameType(modifier.properties["widthType"] as? String),
            heightType: normalizedFrameType(modifier.properties["heightType"] as? String),
            width: modifier.getCGFloat(key: "width", defaultValue: 100),
            height: modifier.getCGFloat(key: "height", defaultValue: 100)
        )
    }

    private func normalizedFrameType(_ value: String?) -> String {
        ["Default", "Full", "Custom"].contains(value ?? "") ? (value ?? "Default") : "Default"
    }
    
    private func frameDeviceLimits(deviceSize: CGSize?) -> (maxWidth: CGFloat, maxHeight: CGFloat, isContentAdaptive: Bool) {
        let width = deviceSize?.width ?? 1000
        let height = deviceSize?.height ?? 1000
        let isContentAdaptive = deviceSize == nil || (width == 0 && height == 0)
        return (maxWidth: width, maxHeight: height, isContentAdaptive: isContentAdaptive)
    }
    
    private func applyFrameWidth(
        values: (widthType: String, heightType: String, width: CGFloat, height: CGFloat),
        limits: (maxWidth: CGFloat, maxHeight: CGFloat, isContentAdaptive: Bool),
        component: UIComponent,
        to view: AnyView
    ) -> AnyView {
        let alignment = horizontalFrameAlignment(for: component)
        switch values.widthType {
        case "Full":
            let maxWidth = limits.isContentAdaptive ? CGFloat.infinity : limits.maxWidth
            return AnyView(view.frame(maxWidth: maxWidth, alignment: alignment))
        case "Custom":
            let width = limits.isContentAdaptive ? values.width : min(values.width, limits.maxWidth)
            return AnyView(view.frame(width: width, alignment: alignment))
        default:
            return view
        }
    }

    private func horizontalFrameAlignment(for component: UIComponent) -> Alignment {
        let rawAlignment = (component.getProperty(key: "alignment") as? String ?? "").lowercased()
        switch rawAlignment {
        case "leading":
            return .leading
        case "trailing":
            return .trailing
        case "center":
            return .center
        default:
            break
        }

        if component.type == .text,
           let modifier = component.modifiers.first(where: { $0.type == .textAlignment }) {
            let rawTextAlignment = (modifier.properties["alignment"] as? String ?? "leading").lowercased()
            switch rawTextAlignment {
            case "center":
                return .center
            case "trailing":
                return .trailing
            default:
                return .leading
            }
        }
        return .center
    }
    
    private func applyFrameHeight(
        values: (widthType: String, heightType: String, width: CGFloat, height: CGFloat),
        limits: (maxWidth: CGFloat, maxHeight: CGFloat, isContentAdaptive: Bool),
        to view: AnyView
    ) -> AnyView {
        switch values.heightType {
        case "Full":
            let maxHeight = limits.isContentAdaptive ? CGFloat.infinity : limits.maxHeight
            return AnyView(view.frame(maxHeight: maxHeight))
        case "Custom":
            let height = limits.isContentAdaptive ? values.height : min(values.height, limits.maxHeight)
            return AnyView(view.frame(height: height))
        default:
            return view
        }
    }
    
    private func applyPaddingModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let amount = modifier.getCGFloat(key: "amount", defaultValue: 0)
        let location = modifier.properties["location"] as? String ?? "all"

        switch location {
        case "all":
            return AnyView(view.padding(amount))
        case "leading":
            return AnyView(view.padding(.leading, amount))
        case "trailing":
            return AnyView(view.padding(.trailing, amount))
        case "top":
            return AnyView(view.padding(.top, amount))
        case "bottom":
            return AnyView(view.padding(.bottom, amount))
        case "horizontal":
            return AnyView(view.padding(.horizontal, amount))
        case "vertical":
            return AnyView(view.padding(.vertical, amount))
        default:
            return AnyView(view.padding(amount))
        }
    }

    private func applyBackgroundModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView {
        guard let attachedView = attachedComponentView(for: modifier, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds) else {
            return AnyView(view)
        }
        return AnyView(view.background(attachedView))
    }

    private func applyOverlayModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView {
        guard let attachedView = attachedComponentView(for: modifier, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds) else {
            return view
        }
        let alignment = alignmentFromString(modifier.properties["alignment"] as? String ?? "center")
        return AnyView(view.overlay(attachedView, alignment: alignment))
    }

    private func applyMaskModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView {
        if let attachedView = attachedComponentView(for: modifier, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds) {
            return AnyView(view.mask(attachedView))
        }

        let shapeName = modifier.properties["shape"] as? String ?? "Rectangle"
        switch shapeName {
        case "Circle":
            return AnyView(view.mask(Circle()))
        case "Capsule":
            return AnyView(view.mask(Capsule()))
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return AnyView(view.mask(RoundedRectangle(cornerRadius: radius)))
        default:
            return AnyView(view.mask(Rectangle()))
        }
    }

    private func attachedComponentView(for modifier: ComponentModifier, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView? {
        guard let parentComponent = component.getParentComponentForModifier(modifier.id) else { return nil }

        let renderer = ComponentRenderer(
            component: parentComponent,
            deviceSize: deviceSize,
            colorScheme: colorScheme,
            onTap: { additive in
                onSelectChild?(parentComponent, additive)
            },
            onSelectChild: onSelectChild,
            selectedComponentIds: selectedComponentIds
        )
        return AnyView(renderer)
    }

    private func applyFontModifier(_ modifier: ComponentModifier, to view: AnyView, deviceSize: CGSize?) -> AnyView {
        let size = modifier.properties["fontSize"]
        let weight = modifier.properties["fontWeight"] as? String ?? "regular"
        let design = modifier.properties["fontDesign"] as? String
        let fontWeight = fontWeightFromString(weight)
        let fontDesign = fontDesignFromString(design)

        if let sizeStr = size as? String, let customSize = Double(sizeStr) {
            let effectiveSize = max(1.0, customSize)
            let font = Font.system(size: effectiveSize, weight: fontWeight, design: fontDesign)
            return AnyView(view.font(font))
        }

        let namedSize = (size as? String) ?? "body"
        let font = createIOSFont(for: namedSize, weight: fontWeight, design: fontDesign, deviceSize: deviceSize)
        return AnyView(view.font(font))
    }

    private func applyShadowModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
        let x = getModifierCGFloat(modifier, primaryKey: "offsetX", fallbackKey: "x", defaultValue: 0)
        let y = getModifierCGFloat(modifier, primaryKey: "offsetY", fallbackKey: "y", defaultValue: 0)

        var color = modifier.getColor(key: "color", defaultValue: .black)
        if let opacity = modifier.properties["opacity"] as? Double {
            color = color.opacity(opacity)
        }

        return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
    }

    private func applyOffsetModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let x = getModifierCGFloat(modifier, primaryKey: "offsetX", fallbackKey: "x", defaultValue: 0)
        let y = getModifierCGFloat(modifier, primaryKey: "offsetY", fallbackKey: "y", defaultValue: 0)
        return AnyView(view.offset(x: x, y: y))
    }

    private func applyClipShapeModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let shapeName = normalizedClipShapeName(from: modifier)
        switch shapeName {
        case "Circle":
            return AnyView(view.clipShape(Circle()))
        case "Capsule":
            return AnyView(view.clipShape(Capsule()))
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return AnyView(view.clipShape(RoundedRectangle(cornerRadius: radius)))
        case "Ellipse":
            return AnyView(view.clipShape(Ellipse()))
        default:
            return AnyView(view.clipShape(Rectangle()))
        }
    }

    private func normalizedClipShapeName(from modifier: ComponentModifier) -> String {
        let rawShape = (modifier.properties["shape"] as? String)
            ?? (modifier.properties["shapeType"] as? String)
            ?? "Rectangle"
        if rawShape.lowercased() == "roundedrectangle" {
            return "RoundedRectangle"
        }
        return rawShape.prefix(1).uppercased() + rawShape.dropFirst()
    }


    private func normalizedGlassShapeName(from modifier: ComponentModifier) -> String {
        guard let rawShape = (modifier.properties["shape"] as? String) ?? (modifier.properties["shapeType"] as? String),
              !rawShape.isEmpty else {
            return ""
        }

        if rawShape.lowercased() == "roundedrectangle" {
            return "RoundedRectangle"
        }
        return rawShape.prefix(1).uppercased() + rawShape.dropFirst()
    }

    private func multilineTextAlignmentFromString(_ alignment: String) -> TextAlignment {
        switch alignment {
        case "leading":
            return .leading
        case "center":
            return .center
        case "trailing":
            return .trailing
        default:
            return .leading
        }
    }

    private func getModifierCGFloat(_ modifier: ComponentModifier, primaryKey: String, fallbackKey: String, defaultValue: CGFloat) -> CGFloat {
        if let value = modifier.properties[primaryKey] as? CGFloat {
            return value
        }
        if let value = modifier.properties[primaryKey] as? Double {
            return CGFloat(value)
        }
        return modifier.getCGFloat(key: fallbackKey, defaultValue: defaultValue)
    }
    
}

fileprivate func fontWeightFromString(_ weight: String) -> Font.Weight {
    switch weight {
    case "ultraLight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return .regular
    }
}

fileprivate func alignmentFromString(_ alignment: String) -> Alignment {
    switch alignment {
    case "topLeading": return .topLeading
    case "top": return .top
    case "topTrailing": return .topTrailing
    case "leading": return .leading
    case "center": return .center
    case "trailing": return .trailing
    case "bottomLeading": return .bottomLeading
    case "bottom": return .bottom
    case "bottomTrailing": return .bottomTrailing
    default: return .center
    }
}

fileprivate func horizontalAlignmentFromString(_ alignment: String) -> HorizontalAlignment {
    switch alignment {
    case "leading": return .leading
    case "trailing": return .trailing
    case "center": return .center
    default: return .center
    }
}

fileprivate func verticalAlignmentFromString(_ alignment: String) -> VerticalAlignment {
    switch alignment {
    case "top": return .top
    case "bottom": return .bottom
    case "center": return .center
    case "firstTextBaseline": return .firstTextBaseline
    case "lastTextBaseline": return .lastTextBaseline
    default: return .center
    }
}

fileprivate func createIOSFont(for fontSize: String, weight: Font.Weight, design: Font.Design, deviceSize: CGSize?) -> Font {
    let deviceWidth = deviceSize?.width ?? 393 // Default to iPhone
    let isiPad = deviceWidth >= 700 && deviceWidth < 1200 // iPad range: 834-1024
    let isMac = deviceWidth >= 1200 // Mac: 1280+
    
    let size: CGFloat
    switch fontSize {
    case "largeTitle":
        if isMac { size = 40 } // macOS Large Title: 40pt
        else if isiPad { size = 40 } // iPad Large Title: 40pt
        else { size = 34 } // iOS Large Title: 34pt
    case "title":
        if isMac { size = 32 } // macOS Title 1: 32pt
        else if isiPad { size = 34 } // iPad Title 1: 34pt
        else { size = 28 } // iOS Title 1: 28pt
    case "title2":
        if isMac { size = 24 } // macOS Title 2: 24pt
        else if isiPad { size = 28 } // iPad Title 2: 28pt
        else { size = 22 } // iOS Title 2: 22pt
    case "title3":
        if isMac { size = 20 } // macOS Title 3: 20pt
        else if isiPad { size = 22 } // iPad Title 3: 22pt
        else { size = 20 } // iOS Title 3: 20pt
    case "headline":
        size = isMac ? 18 : 17 // macOS: 18pt, iOS/iPad: 17pt (default semibold, but overridable)
        return .system(size: size, weight: weight, design: design)
    case "body":
        size = isMac ? 15 : 17 // macOS: 15pt, iOS/iPad: 17pt
    case "callout":
        size = isMac ? 14 : 16 // macOS: 14pt, iOS/iPad: 16pt
    case "subheadline":
        size = isMac ? 13 : 15 // macOS: 13pt, iOS/iPad: 15pt
    case "footnote":
        size = isMac ? 12 : 13 // macOS: 12pt, iOS/iPad: 13pt
    case "caption":
        size = isMac ? 11 : 12 // macOS: 11pt, iOS/iPad: 12pt
    case "caption2":
        size = isMac ? 10 : 11 // macOS: 10pt, iOS/iPad: 11pt
    default:
        size = isMac ? 15 : 17 // Default to body
    }
    
    return .system(size: size, weight: weight, design: design)
}

struct RemoteImageComponentView: View {
    let url: URL
    let resizable: Bool
    let aspectRatio: String
    let deviceSize: CGSize?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.25))
                    .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
            case .failure(_):
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.22))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.7))
                    )
                    .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
            case .success(let image):
                let base = resizable ? image.resizable() : image
                Group {
                    if aspectRatio == "fit" {
                        if let fallbackSize = intrinsicFallbackFrameSize {
                            base.aspectRatio(contentMode: .fit)
                                .frame(width: fallbackSize.width, height: fallbackSize.height)
                        } else {
                            base.aspectRatio(contentMode: .fit)
                                .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                        }
                    } else if aspectRatio == "fill" {
                        if let fallbackSize = intrinsicFallbackFrameSize {
                            base.aspectRatio(contentMode: .fill)
                                .frame(width: fallbackSize.width, height: fallbackSize.height)
                                .clipped()
                        } else {
                            base.aspectRatio(contentMode: .fill)
                                .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                                .clipped()
                        }
                    } else {
                        if let fallbackSize = intrinsicFallbackFrameSize {
                            base.frame(width: fallbackSize.width, height: fallbackSize.height)
                        } else {
                            base.frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                        }
                    }
                }
            @unknown default:
                EmptyView()
            }
        }
    }

    private var intrinsicFallbackFrameSize: CGSize? {
        guard deviceSize == nil else { return nil }
        return CGSize(width: 180, height: 180)
    }
}

struct ImageComponentView: View {
    let imageName: String
    let resizable: Bool
    let aspectRatio: String
    let deviceSize: CGSize?
    
    var body: some View {
        if !imageName.isEmpty, let platformImage = ImageGalleryManager.shared.loadImage(filename: imageName) {
            #if os(macOS)
            let imageView = Image(nsImage: platformImage)
            let intrinsicSize = platformImage.size
            #else
            let imageView = Image(uiImage: platformImage)
            let intrinsicSize = platformImage.size
            #endif
            
            let modifiedImage = resizable ? imageView.resizable() : imageView
            
            Group {
                if aspectRatio == "fit" {
                    if let fallbackSize = intrinsicImageFrameSize(for: intrinsicSize) {
                        modifiedImage
                            .aspectRatio(contentMode: .fit)
                            .frame(width: fallbackSize.width, height: fallbackSize.height)
                    } else {
                        modifiedImage
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                    }
                } else if aspectRatio == "fill" {
                    if let fallbackSize = intrinsicImageFrameSize(for: intrinsicSize) {
                        modifiedImage
                            .aspectRatio(contentMode: .fill)
                            .frame(width: fallbackSize.width, height: fallbackSize.height)
                            .clipped()
                    } else {
                        modifiedImage
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                            .clipped()
                    }
                } else {
                    if let fallbackSize = intrinsicImageFrameSize(for: intrinsicSize) {
                        modifiedImage
                            .frame(width: fallbackSize.width, height: fallbackSize.height)
                    } else {
                        modifiedImage
                            .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    private func intrinsicImageFrameSize(for intrinsicSize: CGSize) -> CGSize? {
        guard deviceSize == nil else { return nil }
        guard intrinsicSize.width > 0, intrinsicSize.height > 0 else { return CGSize(width: 100, height: 100) }
        return intrinsicSize
    }
}

fileprivate struct CustomSwitchView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Capsule()
            .fill(isOn ? Color.green : Color.gray.opacity(0.5))
            .frame(width: 51, height: 31)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .padding(2)
                    .offset(x: isOn ? 10 : -10)
            )
            .animation(.spring(response: 0.3), value: isOn)
            .onTapGesture {
                withAnimation {
                    isOn.toggle()
                }
            }
    }
}

fileprivate struct CustomSliderView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let denominator = range.upperBound - range.lowerBound
            let percentage = denominator == 0 ? 0 : (value - range.lowerBound) / denominator
            let thumbX = width * CGFloat(percentage)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                Capsule()
                    .fill(Color.blue)
                    .frame(width: thumbX, height: 4)
                
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .frame(width: 20, height: 20)
                    .offset(x: thumbX - 10)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gestureValue in
                                let x = gestureValue.location.x
                                let newPercentage = min(max(x / width, 0), 1)
                                self.value = range.lowerBound + (newPercentage * (range.upperBound - range.lowerBound))
                            }
                    )
            }
            .frame(height: 30, alignment: .center)
        }
        .frame(height: 30)
    }
}

private struct ScreenshotMapSnapshotView: View {
    let region: MKCoordinateRegion
    let mapStyle: String
    let colorScheme: ColorScheme

    var body: some View {
        GeometryReader { geometry in
            let size = CGSize(
                width: max(geometry.size.width, 1),
                height: max(geometry.size.height, 1)
            )

            Group {
                if let image = makeSnapshot(size: size) {
#if os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
#else
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
#endif
                } else {
                    fallbackMapPlaceholder
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    private var fallbackMapPlaceholder: some View {
        let top = colorScheme == .dark ? Color(red: 0.16, green: 0.19, blue: 0.23) : Color(red: 0.90, green: 0.94, blue: 0.97)
        let bottom = colorScheme == .dark ? Color(red: 0.10, green: 0.12, blue: 0.15) : Color(red: 0.82, green: 0.88, blue: 0.93)
        let road = colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
        let accent = colorScheme == .dark ? Color(red: 0.25, green: 0.58, blue: 0.95) : Color(red: 0.12, green: 0.46, blue: 0.92)

        return ZStack {
            LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)

            Path { path in
                path.move(to: CGPoint(x: 0, y: 28))
                path.addLine(to: CGPoint(x: 320, y: 160))
                path.move(to: CGPoint(x: 24, y: 220))
                path.addLine(to: CGPoint(x: 280, y: 8))
                path.move(to: CGPoint(x: 84, y: 0))
                path.addLine(to: CGPoint(x: 200, y: 280))
            }
            .stroke(road, style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))

            Circle()
                .fill(accent)
                .frame(width: 14, height: 14)

            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 26, height: 26)
        }
    }

    private func makeSnapshot(size: CGSize) -> PlatformImage? {
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size

#if os(macOS)
        options.appearance = colorScheme == .dark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
#else
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
#endif

        switch mapStyle {
        case "imagery":
            options.mapType = .satelliteFlyover
        case "hybrid":
            options.mapType = .hybridFlyover
        default:
            options.mapType = .standard
        }

        let snapshotter = MKMapSnapshotter(options: options)
        let semaphore = DispatchSemaphore(value: 0)
        var renderedImage: PlatformImage?

        snapshotter.start(with: DispatchQueue.global(qos: .userInitiated)) { snapshot, _ in
            renderedImage = snapshot?.image
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 2.0)
        return renderedImage
    }

}

fileprivate func fontDesignFromString(_ design: String?) -> Font.Design {
    switch design {
    case "default": return .default
    case "serif": return .serif
    case "rounded": return .rounded
    case "monospaced": return .monospaced
    default: return .default
    }
}

extension View {
    @ViewBuilder
    func applyButtonStyle(_ style: String) -> some View {
        switch style {
        case "bordered":
            self.buttonStyle(.bordered)
        case "borderedProminent":
            self.buttonStyle(.borderedProminent)
        case "borderless":
            self.buttonStyle(.borderless)
        case "plain":
            self.buttonStyle(.plain)
        default:
            self.buttonStyle(.borderedProminent)
        }
    }
}
