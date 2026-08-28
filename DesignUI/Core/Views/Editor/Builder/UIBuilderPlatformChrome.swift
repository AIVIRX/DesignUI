import SwiftUI

struct EditorShellCommands {
    let undo: () -> Void
    let redo: () -> Void
    let dismissEditor: () -> Void
    let toggleLayers: () -> Void
    let openCanvasSettings: () -> Void
    let openLayers: () -> Void
    let duplicateSelection: () -> Void
    let deleteSelection: () -> Void
    let toggleInspector: () -> Void
    let addComponent: (ComponentType) -> Void
    let canUndo: Bool
    let canRedo: Bool
    let canEditSelection: Bool
}

#if os(macOS)
struct MacEditorShell<
    CanvasContent: View,
    SidebarContent: View,
    InspectorContent: View,
    DeviceMenu: View,
    PageMenu: View,
    ColorSchemeMenu: View,
    ExportMenu: View
>: View {
    @Binding var showInspector: Bool
    let commands: EditorShellCommands
    @ViewBuilder let canvasContent: () -> CanvasContent
    @ViewBuilder let sidebarContent: () -> SidebarContent
    @ViewBuilder let inspectorContent: () -> InspectorContent
    @ViewBuilder let deviceMenu: () -> DeviceMenu
    @ViewBuilder let pageMenu: () -> PageMenu
    @ViewBuilder let colorSchemeMenu: () -> ColorSchemeMenu
    @ViewBuilder let exportMenu: () -> ExportMenu

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 380)
        } detail: {
            NavigationStack {
                canvasContent()
                    .toolbar { contentToolbar }
                    .inspector(isPresented: $showInspector) {
                        inspectorContent()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .inspectorColumnWidth(min: 280, ideal: 320, max: 440)
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        sidebarContent()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(ComponentLibraryCatalog.availableComponents) { componentType in
                            Button {
                                commands.addComponent(componentType)
                            } label: {
                                Label(componentType.rawValue, systemImage: componentType.icon)
                            }
                        }
                    } label: {
                        Label("Add Component", systemImage: "plus")
                            .labelStyle(.iconOnly)
                            .frame(width: 28, height: 28)
                    }
                    .menuIndicator(.hidden)
                    .help("Add Component")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var contentToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            undoButton
            redoButton
            deviceMenu()
            pageMenu()
            colorSchemeMenu()
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Spacer()
            exportMenu()
            duplicateButton
            deleteButton
            inspectorButton
        }
    }

    private var undoButton: some View {
        Button(action: commands.undo) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 14, weight: .medium))
        }
        .keyboardShortcut("z", modifiers: .command)
        .disabled(!commands.canUndo)
        .help("Undo")
    }

    private var redoButton: some View {
        Button(action: commands.redo) {
            Image(systemName: "arrow.uturn.forward")
                .font(.system(size: 14, weight: .medium))
        }
        .keyboardShortcut("z", modifiers: [.command, .shift])
        .disabled(!commands.canRedo)
        .help("Redo")
    }

    private var duplicateButton: some View {
        Button(action: commands.duplicateSelection) {
            Label("Duplicate", systemImage: "doc.on.doc")
                .labelStyle(.iconOnly)
        }
        .disabled(!commands.canEditSelection)
        .help("Duplicate Component")
    }

    private var deleteButton: some View {
        Button(action: commands.deleteSelection) {
            Label("Delete", systemImage: "trash")
                .labelStyle(.iconOnly)
        }
        .disabled(!commands.canEditSelection)
        .help("Delete Component")
    }

    private var inspectorButton: some View {
        Button(action: commands.toggleInspector) {
            Label(
                showInspector ? "Hide Inspector" : "Show Inspector",
                systemImage: "sidebar.right"
            )
            .labelStyle(.iconOnly)
        }
        .help(showInspector ? "Hide Inspector" : "Show Inspector")
        .keyboardShortcut("i", modifiers: [.command, .option])
    }
}
#endif

#if os(iOS)
struct PadEditorShell<
    CanvasContent: View,
    SidebarContent: View,
    PropertiesContent: View,
    DeviceMenu: View,
    PageMenu: View,
    ColorSchemeMenu: View,
    ExportMenu: View
>: View {
    let designName: String
    let panelWidth: CGFloat
    let showSidebar: Bool
    let showProperties: Bool
    let commands: EditorShellCommands
    @ViewBuilder let canvasContent: () -> CanvasContent
    @ViewBuilder let sidebarContent: () -> SidebarContent
    @ViewBuilder let propertiesContent: () -> PropertiesContent
    @ViewBuilder let deviceMenu: () -> DeviceMenu
    @ViewBuilder let pageMenu: () -> PageMenu
    @ViewBuilder let colorSchemeMenu: () -> ColorSchemeMenu
    @ViewBuilder let exportMenu: () -> ExportMenu

    var body: some View {
        ZStack {
            canvasContent()

            HStack(spacing: 0) {
                if showSidebar {
                    sidebarContent()
                        .frame(width: panelWidth)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .padding()
                }

                Spacer()

                if showProperties {
                    propertiesContent()
                        .frame(width: panelWidth)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(designName)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button(action: commands.dismissEditor) {
                Image(systemName: "chevron.left")
            }

            Button(action: commands.toggleLayers) {
                Image(systemName: "sidebar.left")
            }
            .help(showSidebar ? "Hide Layers Panel" : "Show Layers Panel")
        }

        ToolbarItemGroup(placement: .primaryAction) {
            deviceMenu()
            colorSchemeMenu()
            pageMenu()
            undoButton
            redoButton
        }

        ToolbarItemGroup(placement: .primaryAction) {
            exportMenu()
        }

        ToolbarItem(placement: .principal) {
            Text(designName)
                .font(.system(size: 14, weight: .semibold))
        }
    }

    private var undoButton: some View {
        Button(action: commands.undo) {
            Image(systemName: "arrow.uturn.backward")
        }
        .disabled(!commands.canUndo)
    }

    private var redoButton: some View {
        Button(action: commands.redo) {
            Image(systemName: "arrow.uturn.forward")
        }
        .disabled(!commands.canRedo)
    }
}

struct PhoneEditorShell<CanvasContent: View, PageMenu: View>: View {
    let layersIcon: String
    let commands: EditorShellCommands
    @ViewBuilder let canvasContent: () -> CanvasContent
    @ViewBuilder let pageMenu: () -> PageMenu

    var body: some View {
        GeometryReader { _ in
            ZStack {
                canvasContent()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button(action: commands.undo) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!commands.canUndo)

            Button(action: commands.redo) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!commands.canRedo)
        }

        ToolbarItem(placement: .principal) {
            pageMenu()
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: commands.openCanvasSettings) {
                Image(systemName: "iphone")
            }

            Button(action: commands.openLayers) {
                Image(systemName: layersIcon)
            }
        }
    }
}
#endif
