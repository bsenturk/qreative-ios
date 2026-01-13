import SwiftUI
import PhotosUI

// MARK: - Scan View
struct ScanView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showUI = false

    var body: some View {
        ZStack {
            if viewModel.cameraService.isAuthorized {
                cameraContent
            } else {
                permissionDeniedView
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showUI = true
            }
            if !appCoordinator.isPaywallPresented {
                viewModel.onAppear()
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: appCoordinator.isPaywallPresented) { _, isPresented in
            if !isPresented {
                viewModel.onAppear()
            }
        }
        .sheet(isPresented: $viewModel.showResult) {
            if let result = viewModel.scanResult {
                ScanResultSheet(
                    result: result,
                    onCopy: { viewModel.copyToClipboard() },
                    onOpen: { viewModel.openURL() },
                    onDismiss: { viewModel.dismissResult() }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            handleSelectedPhoto(newValue)
        }
        .onChange(of: viewModel.showResult) { _, isShowing in
            if isShowing {
                HapticManager.shared.success()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Camera Content
    private var cameraContent: some View {
        ZStack {
            CameraPreview(cameraService: viewModel.cameraService)
                .ignoresSafeArea()

            ViewfinderOverlay()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 60)
                    .padding(.horizontal, Theme.spacing.screen)
                    .opacity(showUI ? 1 : 0)
                    .offset(y: showUI ? 0 : -20)

                Spacer()

                bottomArea
                    .padding(.horizontal, Theme.spacing.screen)
                    .padding(.bottom, 120)
                    .opacity(showUI ? 1 : 0)
                    .offset(y: showUI ? 0 : 20)
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 16) {
            flashButton

            Spacer()

            zoomControl

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private var flashButton: some View {
        Button {
            HapticManager.shared.lightTap()
            viewModel.toggleFlash()
        } label: {
            Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(viewModel.isFlashOn ? Color.warning : Color.white)
                .frame(width: 44, height: 44)
                .glassCardSubtle(cornerRadius: 12)
                .scaleEffect(viewModel.isFlashOn ? 1.05 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isFlashOn)
        }
        .buttonStyle(PressableStyle())
    }

    private var zoomControl: some View {
        HStack(spacing: 8) {
            Text("1x")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))

            Slider(
                value: $viewModel.zoomLevel,
                in: 1.0...3.0,
                step: 0.1
            ) { editing in
                if !editing {
                    viewModel.setZoom(viewModel.zoomLevel)
                }
            }
            .tint(Color.accentPrimary)
            .frame(width: 100)

            Text("3x")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCardSubtle(cornerRadius: 20)
    }

    // MARK: - Bottom Area
    private var bottomArea: some View {
        let isProcessing = viewModel.isProcessingImage
        return PhotosPicker(
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: 10) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text("Select from Gallery")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard(cornerRadius: 16, opacity: 0.08)
        }
        .disabled(isProcessing)
    }

    // MARK: - Permission Denied View
    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("Camera Access Required")
                    .typography(.title2)

                Text("Please enable camera access in Settings to scan QR codes")
                    .typography(.body, color: .textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            PrimaryButton("Enable in Settings", icon: "gear") {
                viewModel.openSettings()
            }
            .frame(maxWidth: 280)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }

    // MARK: - Photo Selection
    private func handleSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.processGalleryImage(image)
            }
            selectedPhoto = nil
        }
    }
}

// MARK: - Scan Result Sheet
struct ScanResultSheet: View {
    let result: ScanResult
    let onCopy: () -> Void
    let onOpen: () -> Void
    let onDismiss: () -> Void

    @State private var isCopied: Bool = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentPrimary.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .scaleEffect(showContent ? 1 : 0.5)

                    Image(systemName: result.type.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentPrimary)
                        .scaleEffect(showContent ? 1 : 0)
                }

                Text(result.type.title)
                    .typography(.headline, color: .textSecondary)
                    .opacity(showContent ? 1 : 0)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showContent)

            VStack(spacing: 8) {
                Text("Scanned Content")
                    .typography(.caption1, color: .textTertiary)

                Text(result.content)
                    .typography(.body)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 20)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 12, opacity: 0.05)
            .padding(.horizontal, Theme.spacing.screen)

            VStack(spacing: 12) {
                if result.type == .url || result.type == .email || result.type == .phone {
                    PrimaryButton(result.type.actionTitle, icon: actionIcon) {
                        onOpen()
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        onCopy()
                        withAnimation {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isCopied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Copied!" : "Copy")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isCopied ? Color.success : Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .glassCard(cornerRadius: 12, opacity: 0.08)
                    }

                    ShareLink(item: result.content) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .glassCard(cornerRadius: 12, opacity: 0.08)
                    }
                }
            }
            .padding(.horizontal, Theme.spacing.screen)

            Button {
                onDismiss()
            } label: {
                Text("Scan Again")
                    .typography(.callout, color: .textSecondary)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }

    private var actionIcon: String {
        switch result.type {
        case .url: return "safari"
        case .email: return "envelope"
        case .phone: return "phone"
        default: return "arrow.right"
        }
    }
}

// MARK: - Preview
#Preview("Scan View") {
    ScanView()
}

#Preview("Result Sheet") {
    ScanResultSheet(
        result: ScanResult(content: "https://qreative.app"),
        onCopy: {},
        onOpen: {},
        onDismiss: {}
    )
}
