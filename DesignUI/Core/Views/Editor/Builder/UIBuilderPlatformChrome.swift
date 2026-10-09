import SwiftUI

struct EditorShellCommands {
    let undo: () -> Void
    let redo: () -> Void
    let dismissEditor: () -> Void
    let toggleLayers: () -> Void
    let openCanvasSettings: () -> Void
    let openLayers: () -> Void
    let openAI: () -> Void
    let openCodePreview: () -> Void
    let saveScreenshot: () -> Void
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
                    }
                    .menuIndicator(.hidden)
                    .help("Add Component")
                    .accessibilityLabel("Add Component")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var contentToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            undoButton
            redoButton
        }

        ToolbarItemGroup(placement: .automatic) {
            deviceMenu()
            pageMenu()
            colorSchemeMenu()
        }

        ToolbarItemGroup(placement: .primaryAction) {
            exportMenu()
            duplicateButton
            deleteButton
            inspectorButton
        }
    }

    private var undoButton: some View {
        Button(action: commands.undo) {
            Image(systemName: "arrow.uturn.backward")
        }
        .keyboardShortcut("z", modifiers: .command)
        .disabled(!commands.canUndo)
        .help("Undo")
        .accessibilityLabel("Undo")
    }

    private var redoButton: some View {
        Button(action: commands.redo) {
            Image(systemName: "arrow.uturn.forward")
        }
        .keyboardShortcut("z", modifiers: [.command, .shift])
        .disabled(!commands.canRedo)
        .help("Redo")
        .accessibilityLabel("Redo")
    }

    private var duplicateButton: some View {
        Button(action: commands.duplicateSelection) {
            Label("Duplicate", systemImage: "doc.on.doc")
                .labelStyle(.iconOnly)
        }
        .disabled(!commands.canEditSelection)
        .help("Duplicate Component")
        .accessibilityLabel("Duplicate Component")
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: commands.deleteSelection) {
            Label("Delete", systemImage: "trash")
                .labelStyle(.iconOnly)
        }
        .disabled(!commands.canEditSelection)
        .help("Delete Component")
        .accessibilityLabel("Delete Component")
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
        .accessibilityLabel(showInspector ? "Hide Inspector" : "Show Inspector")
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
                        .padding(12)
                }

                Spacer(minLength: 0)

                if showProperties {
                    propertiesContent()
                        .frame(width: panelWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .padding(12)
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
            .accessibilityLabel("Back")

            Button(action: commands.toggleLayers) {
                Image(systemName: "sidebar.left")
            }
            .help(showSidebar ? "Hide Layers" : "Show Layers")
            .accessibilityLabel(showSidebar ? "Hide Layers" : "Show Layers")
        }

        ToolbarItemGroup(placement: .primaryAction) {
            deviceMenu()
            colorSchemeMenu()
            pageMenu()
            undoButton
            redoButton
            exportMenu()
        }
    }

    private var undoButton: some View {
        Button(action: commands.undo) {
            Image(systemName: "arrow.uturn.backward")
        }
        .disabled(!commands.canUndo)
        .accessibilityLabel("Undo")
    }

    private var redoButton: some View {
        Button(action: commands.redo) {
            Image(systemName: "arrow.uturn.forward")
        }
        .disabled(!commands.canRedo)
        .accessibilityLabel("Redo")
    }
}

struct PhoneEditorShell<CanvasContent: View, PageMenu: View>: View {
    let layersIcon: String
    let commands: EditorShellCommands
    let collapseHistory: Bool
    @ViewBuilder let canvasContent: () -> CanvasContent
    @ViewBuilder let pageMenu: () -> PageMenu
    @Environment(\.self) private var environment

    private var usesSideToolbar: Bool {
        if #available(iOS 27.1, *) {
            return environment.toolbarVerticalEdge != nil
        }
        return false
    }

    var body: some View {
        canvasContent()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button(action: commands.dismissEditor) {
                Image(systemName: "chevron.backward")
            }
            .accessibilityLabel("Back")

            if collapseHistory && !usesSideToolbar {
                Menu {
                    Button("Undo", systemImage: "arrow.uturn.backward", action: commands.undo)
                        .disabled(!commands.canUndo)
                    Button("Redo", systemImage: "arrow.uturn.forward", action: commands.redo)
                        .disabled(!commands.canRedo)
                } label: {
                    Label("Edit History", systemImage: "arrow.uturn.backward")
                }
                .disabled(!commands.canUndo && !commands.canRedo)
                .accessibilityLabel("Undo and Redo")
            } else {
                Button(action: commands.undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!commands.canUndo)
                .accessibilityLabel("Undo")

                Button(action: commands.redo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!commands.canRedo)
                .accessibilityLabel("Redo")
            }
        }

        if !usesSideToolbar {
            ToolbarItem(placement: .principal) {
                pageMenu()
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if usesSideToolbar {
                pageMenu()
            }

            Button(action: commands.openLayers) {
                Image(systemName: layersIcon)
            }
            .accessibilityLabel("Layers")

            Menu {
                Button("Ask AI", systemImage: "wand.and.stars", action: commands.openAI)
                Button("Canvas Settings", systemImage: "iphone", action: commands.openCanvasSettings)
                Divider()
                Button("View Code", systemImage: "swift", action: commands.openCodePreview)
                Button("Save as Screenshot", systemImage: "photo", action: commands.saveScreenshot)
            } label: {
                Label("More Editor Actions", systemImage: "ellipsis.circle")
            }
            .accessibilityLabel("More Editor Actions")
        }
    }
}
#endif
