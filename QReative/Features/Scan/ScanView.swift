import SwiftUI
import PhotosUI

// MARK: - Scan View
struct ScanView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showUI = false
    @State private var photoPickerID = UUID()
    @State private var showHint = false
    @AppStorage("qreative.hasSeenScanHint") private var hasSeenScanHint = false

    var body: some View {
        ZStack {
            if viewModel.isCameraAuthorized {
                cameraContent
            } else {
                permissionDeniedView
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            viewModel.bind(coordinator: appCoordinator)
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showUI = true
            }
            if viewModel.isCameraAuthorized {
                presentHintIfFirstTime()
            }
            Task {
                if !appCoordinator.isPaywallPresented {
                    viewModel.onAppear()
                }
            }
        }
        .onChange(of: viewModel.isCameraAuthorized) { _, authorized in
            if authorized {
                presentHintIfFirstTime()
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: appCoordinator.isPaywallPresented) { _, isPresented in
            Task {
                if !isPresented {
                    viewModel.onAppear()
                }
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
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.backgroundPrimary)
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            handleSelectedPhoto(newValue)
        }
        .onChange(of: viewModel.showResult) { _, isShowing in
            if isShowing {
                HapticManager.shared.success()
            } else {
                selectedPhoto = nil
                photoPickerID = UUID()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                selectedPhoto = nil
                photoPickerID = UUID()
            }
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

            // First-time guidance hint, just below the viewfinder.
            if showHint {
                scanHint
                    .offset(y: 150)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

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

    // MARK: - First-time Hint
    private var scanHint: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentPrimary)
                .frame(width: 7, height: 7)
            Text("Point at a QR code to scan")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func presentHintIfFirstTime() {
        guard !hasSeenScanHint else { return }
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            showHint = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeIn(duration: 0.4)) {
                showHint = false
            }
            hasSeenScanHint = true
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 16) {
            flashButton

            Spacer()
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
                .darkCard(cornerRadius: 14)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isFlashOn)
        }
        .buttonStyle(PressableStyle())
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
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text("Scan from a photo")
                    .font(.system(size: 15.5, weight: .semibold))
                    .tracking(-0.2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.1))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
        }
        .disabled(isProcessing)
        .id(photoPickerID)
    }

    // MARK: - Permission Denied View
    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.surface2)
                    .frame(width: 88, height: 88)

                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.textPrimary)
            }

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
        guard let item else {
            photoPickerID = UUID()
            return
        }

        Task {
            defer {
                selectedPhoto = nil
                photoPickerID = UUID()
            }

            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.processGalleryImage(image)
            }
        }
    }
}

// MARK: - Scan Result Sheet (warm light style)
struct ScanResultSheet: View {
    let result: ScanResult
    let onCopy: () -> Void
    let onOpen: () -> Void
    let onDismiss: () -> Void

    @State private var isCopied: Bool = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.lineStrong)
                .frame(width: 38, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                // Type icon + label
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.ink)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: result.type.icon)
                                .font(.system(size: 26, weight: .regular))
                                .foregroundStyle(Color.backgroundPrimary)
                        }
                        .scaleEffect(showContent ? 1 : 0.7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showContent)

                    Text("\(result.type.title) detected")
                        .font(.system(size: 12.5, weight: .semibold))
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.ink3)
                }
                .padding(.top, 6)

                // Scanned content card
                VStack(spacing: 6) {
                    Text("Scanned content")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(Color.ink3)

                    Text(result.content)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.3)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.lineColor, lineWidth: 1)
                }
                .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
                .padding(.top, 16)

                // Primary action
                if result.type == .url || result.type == .email || result.type == .phone {
                    PrimaryButton(result.type.actionTitle, icon: "arrow.up.right") {
                        onOpen()
                    }
                    .padding(.top, 14)
                }

                // Secondary actions
                HStack(spacing: 10) {
                    Button {
                        onCopy()
                        withAnimation { isCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isCopied = false }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Copied" : "Copy")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isCopied ? Color.success : Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.lineColor, lineWidth: 1)
                        }
                    }

                    ShareLink(item: result.content) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.lineColor, lineWidth: 1)
                        }
                    }
                }
                .padding(.top, 10)

                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                        Text("Saved to history")
                            .font(.system(size: 14.5, weight: .medium))
                    }
                    .foregroundStyle(Color.ink3)
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Previews
#Preview("Scan View") {
    ScanView()
}
