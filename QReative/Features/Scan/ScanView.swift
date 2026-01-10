import SwiftUI
import PhotosUI

// MARK: - Scan View

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            if viewModel.cameraService.isAuthorized {
                // Camera content
                cameraContent
            } else {
                // Permission denied state
                permissionDeniedView
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Camera Content

    private var cameraContent: some View {
        ZStack {
            // Camera Preview
            CameraPreview(cameraService: viewModel.cameraService)
                .ignoresSafeArea()

            // Viewfinder Overlay
            ViewfinderOverlay()

            // UI Overlays
            VStack(spacing: 0) {
                // Top Bar
                topBar
                    .padding(.top, 60)
                    .padding(.horizontal, Theme.spacing.screen)

                Spacer()

                // Instruction Text
                instructionText
                    .padding(.bottom, 40)

                // Bottom Area
                bottomArea
                    .padding(.horizontal, Theme.spacing.screen)
                    .padding(.bottom, 120) // Tab bar + padding
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
            // Flash Button
            flashButton

            Spacer()

            // Zoom Slider
            zoomControl

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private var flashButton: some View {
        Button {
            viewModel.toggleFlash()
        } label: {
            Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(viewModel.isFlashOn ? Color.warning : Color.white)
                .frame(width: 44, height: 44)
                .glassCardSubtle(cornerRadius: 12)
        }
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

    // MARK: - Instruction Text

    private var instructionText: some View {
        Text("Position QR code within the frame")
            .font(.system(size: 15))
            .foregroundStyle(Color.white.opacity(0.7))
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: 10) {
                if viewModel.isProcessingImage {
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
        .disabled(viewModel.isProcessingImage)
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

    var body: some View {
        VStack(spacing: 24) {
            // Handle indicator area
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Result Icon & Type
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentPrimary.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: result.type.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentPrimary)
                }

                Text(result.type.title)
                    .typography(.headline, color: .textSecondary)
            }

            // Content
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

            // Action Buttons
            VStack(spacing: 12) {
                // Primary action based on type
                if result.type == .url || result.type == .email || result.type == .phone {
                    PrimaryButton(result.type.actionTitle, icon: actionIcon) {
                        onOpen()
                    }
                }

                // Copy & Share row
                HStack(spacing: 12) {
                    // Copy Button
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

                    // Share Button
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

            // Scan Again Button
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
