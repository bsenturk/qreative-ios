import SwiftUI
import PhotosUI

// MARK: - QR Editor View

struct QREditorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel: QREditorViewModel
    @State private var selectedPhoto: PhotosPickerItem?

    init(template: QRTypeTemplate) {
        _viewModel = StateObject(wrappedValue: QREditorViewModel(template: template))
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                    .padding(.horizontal, Theme.spacing.screen)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Live Preview
                        livePreviewSection
                            .padding(.top, 24)

                        // Input Section
                        inputSection

                        Spacer(minLength: 200)
                    }
                    .padding(.horizontal, Theme.spacing.screen)
                }

                // Customization Panel
                customizationPanel
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.bind(appCoordinator: appCoordinator, tabCoordinator: tabCoordinator)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            handleSelectedPhoto(newValue)
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
                .presentationDetents([.large])
        }
        .alert("Saved!", isPresented: $viewModel.showSaveSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your QR code has been saved successfully.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button("Cancel") {
                viewModel.cancel()
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.accentPrimary)

            Spacer()

            Text(viewModel.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                Task {
                    await viewModel.save()
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(Color.accentPrimary)
                } else {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(viewModel.isValid ? Color.accentPrimary : Color.textTertiary)
                }
            }
            .disabled(!viewModel.isValid || viewModel.isSaving)
        }
        .frame(height: 44)
    }

    // MARK: - Live Preview Section

    private var livePreviewSection: some View {
        VStack(spacing: 0) {
            QRCodePreview(
                content: viewModel.qrContent.isEmpty ? "QReative" : viewModel.qrContent,
                size: 160,
                foregroundColor: viewModel.foregroundColor,
                backgroundColor: .white,
                shape: viewModel.selectedShape,
                logoImage: viewModel.logoImage,
                isGlowing: false
            )
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 20)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Input Section

    @ViewBuilder
    private var inputSection: some View {
        VStack(spacing: 16) {
            switch viewModel.template.id {
            case "wifi":
                wifiInputFields
            case "vcard":
                vcardInputFields
            case "email":
                emailInputFields
            case "sms":
                smsInputFields
            default:
                defaultInputField
            }
        }
    }

    private var defaultInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.template.title)
                .typography(.caption1, color: .textTertiary)

            HStack {
                TextField(viewModel.placeholder, text: $viewModel.content)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !viewModel.content.isEmpty {
                    Button {
                        viewModel.content = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16, opacity: 0.08)
        }
    }

    private var wifiInputFields: some View {
        VStack(spacing: 12) {
            // SSID
            inputField(
                label: "Network Name",
                placeholder: "WiFi Name",
                text: $viewModel.wifiSSID
            )

            // Password
            inputField(
                label: "Password",
                placeholder: "WiFi Password",
                text: $viewModel.wifiPassword,
                isSecure: true
            )

            // Security
            VStack(alignment: .leading, spacing: 8) {
                Text("Security")
                    .typography(.caption1, color: .textTertiary)

                HStack(spacing: 8) {
                    ForEach(WifiSecurity.allCases) { security in
                        SecurityButton(
                            title: security.displayName,
                            isSelected: viewModel.wifiSecurity == security
                        ) {
                            viewModel.wifiSecurity = security
                        }
                    }
                }
            }
        }
    }

    private var vcardInputFields: some View {
        VStack(spacing: 12) {
            inputField(label: "Name", placeholder: "John Doe", text: $viewModel.vcardName)
            inputField(label: "Phone", placeholder: "+1 234 567 8900", text: $viewModel.vcardPhone)
            inputField(label: "Email", placeholder: "john@example.com", text: $viewModel.vcardEmail)
            inputField(label: "Company", placeholder: "Company Name", text: $viewModel.vcardCompany)
        }
    }

    private var emailInputFields: some View {
        VStack(spacing: 12) {
            inputField(label: "Email Address", placeholder: "email@example.com", text: $viewModel.content)
            inputField(label: "Subject", placeholder: "Optional subject", text: $viewModel.emailSubject)
            inputField(label: "Body", placeholder: "Optional message", text: $viewModel.emailBody, isMultiline: true)
        }
    }

    private var smsInputFields: some View {
        VStack(spacing: 12) {
            inputField(label: "Phone Number", placeholder: "+1 234 567 8900", text: $viewModel.content)
            inputField(label: "Message", placeholder: "Optional message", text: $viewModel.smsMessage, isMultiline: true)
        }
    }

    @ViewBuilder
    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        isMultiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .typography(.caption1, color: .textTertiary)

            Group {
                if isMultiline {
                    TextField(placeholder, text: text, axis: .vertical)
                        .lineLimit(3...6)
                } else if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(16)
            .glassCard(cornerRadius: 16, opacity: 0.08)
        }
    }

    // MARK: - Customization Panel

    private var customizationPanel: some View {
        VStack(spacing: 20) {
            // Top border
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Color Picker
            colorPicker

            // Shape Selector
            shapeSelector

            // Add Logo Button
            addLogoButton
        }
        .padding(.horizontal, Theme.spacing.screen)
        .padding(.top, 16)
        .padding(.bottom, 100)
        .background(Color.backgroundSecondary)
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .typography(.caption1, color: .textTertiary)

            HStack(spacing: 12) {
                ForEach(QRColor.allCases) { color in
                    ColorButton(
                        color: color,
                        isSelected: viewModel.selectedColor == color
                    ) {
                        viewModel.selectColor(color)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Shape Selector

    private var shapeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shape")
                .typography(.caption1, color: .textTertiary)

            HStack(spacing: 8) {
                ForEach(QRShape.allCases, id: \.self) { shape in
                    ShapeButton(
                        shape: shape,
                        isSelected: viewModel.selectedShape == shape
                    ) {
                        viewModel.selectShape(shape)
                    }
                }
            }
        }
    }

    // MARK: - Add Logo Button

    private var addLogoButton: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Logo")
                    .typography(.caption1, color: .textTertiary)

                if !viewModel.canAddLogo {
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color.warning.opacity(0.15))
                    }
                }
            }

            if let logo = viewModel.logoImage {
                // Show logo with remove button
                HStack(spacing: 12) {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Logo added")
                            .typography(.callout)
                        Button("Remove") {
                            viewModel.removeLogo()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.danger)
                    }

                    Spacer()
                }
                .padding(12)
                .glassCard(cornerRadius: 16, opacity: 0.08)
            } else {
                // Add logo button
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Logo")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundStyle(Color.white.opacity(0.2))
                    }
                }
                .disabled(!viewModel.canAddLogo)
                .onTapGesture {
                    if !viewModel.canAddLogo {
                        viewModel.showPaywall = true
                    }
                }
            }
        }
    }

    // MARK: - Photo Selection

    private func handleSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.addLogo(image)
            }
            selectedPhoto = nil
        }
    }
}

// MARK: - Color Button

private struct ColorButton: View {
    let color: QRColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if color.colors.count > 1 {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.gradient)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.foregroundColor)
                }

                if color == .black {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            }
            .frame(width: 44, height: 44)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentTertiary, lineWidth: 3)
                }
            }
            .shadow(
                color: isSelected ? Color.accentTertiary.opacity(0.5) : .clear,
                radius: 8,
                x: 0,
                y: 0
            )
        }
    }
}

// MARK: - Shape Button

private struct ShapeButton: View {
    let shape: QRShape
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(shape.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentPrimary)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    }
                }
                .overlay {
                    Capsule()
                        .stroke(
                            isSelected ? Color.accentPrimary : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                }
        }
    }
}

// MARK: - Security Button

private struct SecurityButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentPrimary)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QREditorView(template: QRTypeTemplate.allTemplates[0])
            .environmentObject(AppCoordinator())
            .environmentObject(MainTabCoordinator())
    }
}
