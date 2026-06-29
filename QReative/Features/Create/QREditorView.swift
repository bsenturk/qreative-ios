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

    init(viewModel: QREditorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.horizontal, Theme.spacing.screen)
                    .padding(.top, 8)

                previewHero
                    .padding(.horizontal, Theme.spacing.screen)
                    .padding(.top, 14)
                    .padding(.bottom, 22)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        inputSection
                        colorPicker
                        shapeSelector
                        addLogoButton
                        addEmojiButton
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, Theme.spacing.screen)
                    .padding(.bottom, 24)
                    .contentShape(Rectangle())
                    .onTapHideKeyboard()
                }
                .scrollDismissesKeyboard(.interactively)

                saveBar
            }
        }
        .onTapHideKeyboard()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.bind(appCoordinator: appCoordinator, tabCoordinator: tabCoordinator)
            if !appCoordinator.isPremiumUser {
                InterstitialAdManager.shared.loadAd()
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            handleSelectedPhoto(newValue)
        }
        .onChange(of: appCoordinator.isPremiumUser) { _, isPremium in
            // Once the user upgrades, close the paywall opened from this screen.
            if isPremium {
                viewModel.showPaywall = false
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.showEmojiPicker) {
            EmojiPickerSheet { emoji in
                viewModel.addEmoji(emoji)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
            Button {
                viewModel.cancel()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.9))

            Spacer()

            Text(viewModel.title)
                .font(.system(size: 16, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            // Balances the back button so the title stays centered.
            Color.clear.frame(width: 44, height: 44)
        }
        .frame(height: 44)
    }

    // MARK: - Preview Hero (pinned, always visible for live edits)
    private var previewHero: some View {
        QRCodePreview(
            content: viewModel.qrContent.isEmpty ? "QReative" : viewModel.qrContent,
            size: 200,
            foregroundColor: viewModel.foregroundColor,
            backgroundColor: .white,
            shape: viewModel.selectedShape,
            logoImage: viewModel.overlayImage,
            isGlowing: false,
            gradientColors: viewModel.selectedColor.isGradient ? viewModel.selectedColor.colors : nil
        )
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.lineColor, lineWidth: 1)
        }
        .shadow(color: Color.ink.opacity(0.05), radius: 4, x: 0, y: 2)
        .shadow(color: Color.ink.opacity(0.10), radius: 24, x: 0, y: 12)
    }

    // MARK: - Save Bar (primary CTA, thumb zone)
    private var saveBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)

            Button {
                Task { await viewModel.save() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Save to Photos")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(viewModel.isValid ? Color.ink : Color.ink.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(PressableStyle(scale: 0.98))
            .disabled(!viewModel.isValid || viewModel.isSaving)
            .padding(.horizontal, Theme.spacing.screen)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Color.backgroundPrimary)
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
            case "whatsapp":
                whatsappInputField
            default:
                defaultInputField
            }
        }
    }

    private var defaultInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.template.title)
                .font(.system(size: 11.5, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(Color.ink3)
                .textCase(.uppercase)

            HStack {
                TextField("", text: $viewModel.content, prompt: Text(viewModel.placeholder).foregroundColor(Color.ink3))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !viewModel.content.isEmpty {
                    Button {
                        viewModel.content = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.ink3)
                    }
                }
            }
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
        }
    }

    private var wifiInputFields: some View {
        VStack(spacing: 12) {
            inputField(label: "Network Name", placeholder: "WiFi Name", text: $viewModel.wifiSSID)
            inputField(label: "Password", placeholder: "WiFi Password", text: $viewModel.wifiPassword, isSecure: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Security")
                    .font(.system(size: 11.5, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(Color.ink3)
                    .textCase(.uppercase)

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

    private var whatsappInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WhatsApp Number")
                .font(.system(size: 11.5, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(Color.ink3)
                .textCase(.uppercase)

            HStack {
                TextField("", text: $viewModel.content, prompt: Text("+1 234 567 8900").foregroundColor(Color.ink3))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.phonePad)

                if !viewModel.content.isEmpty {
                    Button {
                        viewModel.content = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.ink3)
                    }
                }
            }
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lineColor, lineWidth: 1)
            }

            Text("Include country code (e.g., +1 for USA)")
                .font(.system(size: 12))
                .foregroundStyle(Color.ink3)
                .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func inputField(
        label: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        isSecure: Bool = false,
        isMultiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(Color.ink3)
                .textCase(.uppercase)

            Group {
                if isMultiline {
                    TextField("", text: text, prompt: Text(placeholder).foregroundColor(Color.ink3), axis: .vertical)
                        .lineLimit(3...6)
                } else if isSecure {
                    SecureField("", text: text, prompt: Text(placeholder).foregroundColor(Color.ink3))
                } else {
                    TextField("", text: text, prompt: Text(placeholder).foregroundColor(Color.ink3))
                }
            }
            .font(.system(size: 16))
            .foregroundStyle(Color.textPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
        }
    }

    // MARK: - Color Picker
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Color", locked: !appCoordinator.isPremiumUser)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QRColor.allCases) { color in
                        ColorButton(
                            color: color,
                            isSelected: viewModel.selectedColor == color,
                            isLocked: color.isPremium && !appCoordinator.isPremiumUser
                        ) {
                            viewModel.selectColor(color)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacing.screen)
                .padding(.vertical, 6)
            }
            .padding(.horizontal, -Theme.spacing.screen)
        }
    }

    // MARK: - Shape Selector
    private var shapeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Shape", locked: !appCoordinator.isPremiumUser)

            HStack(spacing: 8) {
                ForEach(QRShape.allCases, id: \.self) { shape in
                    ShapeButton(
                        shape: shape,
                        isSelected: viewModel.selectedShape == shape,
                        isLocked: shape.isPremium && !appCoordinator.isPremiumUser
                    ) {
                        viewModel.selectShape(shape)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: LocalizedStringKey, locked: Bool) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(Color.ink3)
                .textCase(.uppercase)

            if locked {
                proBadge
            }
        }
    }

    // MARK: - PRO Badge
    private var proBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("PRO")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(Color.accentPrimary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.accentPrimary.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Add Logo Button
    private var addLogoButton: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Logo", locked: !appCoordinator.isPremiumUser)

            if let logo = viewModel.logoImage {
                HStack(spacing: 12) {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Logo added")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                        Button("Remove") {
                            viewModel.removeLogo()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.danger)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lineColor, lineWidth: 1)
                }
            } else if viewModel.isLoadingLogo {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(Color.accentPrimary)
                        .scaleEffect(0.9)
                    Text("Loading logo...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.ink2)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(Color.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lineColor, lineWidth: 1)
                }
            } else {
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
                    .foregroundStyle(Color.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [6])
                            )
                            .foregroundStyle(Color.lineStrong)
                    }
                }
                .disabled(!appCoordinator.isPremiumUser)
                .onTapGesture {
                    if !appCoordinator.isPremiumUser {
                        viewModel.logoGateTapped()
                    }
                }
            }
        }
    }

    // MARK: - Add Emoji Button
    private var addEmojiButton: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Emoji", locked: !appCoordinator.isPremiumUser)

            if let emoji = viewModel.selectedEmoji {
                HStack(spacing: 12) {
                    Text(emoji)
                        .font(.system(size: 34))
                        .frame(width: 56, height: 56)
                        .background(Color.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Emoji added")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                        Button("Remove") {
                            viewModel.removeEmoji()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.danger)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lineColor, lineWidth: 1)
                }
            } else {
                Button {
                    viewModel.requestAddEmoji()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Emoji")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [6])
                            )
                            .foregroundStyle(Color.lineStrong)
                    }
                }
            }
        }
    }

    // MARK: - Photo Selection
    private func handleSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        viewModel.isLoadingLogo = true
        Task {
            defer {
                viewModel.isLoadingLogo = false
                selectedPhoto = nil
            }
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.addLogo(image)
            }
        }
    }
}

// MARK: - Color Button
private struct ColorButton: View {
    let color: QRColor
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if color.colors.count > 1 {
                    RoundedRectangle(cornerRadius: 12).fill(color.gradient)
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(color.foregroundColor)
                }

                if color == .black {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.lineColor, lineWidth: 1)
                }

                if isLocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                }
            }
            .frame(width: 44, height: 44)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ink, lineWidth: 3)
                }
            }
            .shadow(
                color: isSelected ? Color.ink.opacity(0.25) : .clear,
                radius: 8, x: 0, y: 0
            )
        }
    }
}

// MARK: - Shape Button
private struct ShapeButton: View {
    let shape: QRShape
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(shape.displayName)
                    .font(.system(size: 14, weight: .medium))
                if isLocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .foregroundStyle(isSelected ? .white : Color.ink2)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule().fill(Color.ink)
                } else {
                    Capsule().fill(Color.backgroundPrimary)
                }
            }
            .overlay {
                Capsule()
                    .stroke(
                        isSelected ? Color.ink : Color.lineStrong,
                        lineWidth: 1
                    )
            }
        }
    }
}

// MARK: - Emoji Category
private struct EmojiCategory: Identifiable {
    let id = UUID()
    let symbol: String
    let emojis: [String]
}

// MARK: - Emoji Picker Sheet
struct EmojiPickerSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: Int = 0

    private let categories = EmojiData.categories
    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            header
            categoryChips
            emojiGrid
        }
        .background(Color.backgroundPrimary)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Choose an Emoji")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ink3)
                    .frame(width: 30, height: 30)
                    .background(Color.surface2)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Category Chips
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedIndex = index
                        }
                    } label: {
                        Image(systemName: category.symbol)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(selectedIndex == index ? .white : Color.ink2)
                            .frame(width: 44, height: 38)
                            .background {
                                if selectedIndex == index {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.accentPrimary)
                                } else {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.surface2)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Emoji Grid
    private var emojiGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(categories[selectedIndex].emojis, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(Color.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .id(selectedIndex)
    }
}

// MARK: - Emoji Data
private enum EmojiData {
    static let categories: [EmojiCategory] = [
        EmojiCategory(symbol: "face.smiling", emojis: [
            "😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","🫠","😉","😊","😇","🥰","😍","🤩","😘","😗","☺️","😚","😙","🥲","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🫢","🫣","🤫","🤔","🫡","🤐","🤨","😐","😑","😶","🫥","😶‍🌫️","😏","😒","🙄","😬","😮‍💨","🤥","😌","😔","😪","🤤","😴","😷","🤒","🤕","🤢","🤮","🤧","🥵","🥶","🥴","😵","😵‍💫","🤯","🤠","🥳","🥸","😎","🤓","🧐","😕","🫤","😟","🙁","☹️","😮","😯","😲","😳","🥺","🥹","😦","😧","😨","😰","😥","😢","😭","😱","😖","😣","😞","😓","😩","😫","🥱","😤","😡","😠","🤬","😈","👿","💀","☠️","💩","🤡","👹","👺","👻","👽","👾","🤖","😺","😸","😹","😻","😼","😽","🙀","😿","😾"
        ]),
        EmojiCategory(symbol: "hand.raised", emojis: [
            "👋","🤚","🖐","✋","🖖","👌","🤌","🤏","✌️","🤞","🫰","🤟","🤘","🤙","🫵","🫱","🫲","🫳","🫴","👈","👉","👆","🖕","👇","☝️","👍","👎","✊","👊","🤛","🤜","👏","🙌","🫶","👐","🤲","🤝","🙏","✍️","💅","🤳","💪","🦾","🦿","🦵","🦶","👂","🦻","👃","🧠","🫀","🫁","🦷","🦴","👀","👁","👅","👄","🫦","👶","🧒","👦","👧","🧑","👱","👨","🧔","👩","🧓","👴","👵","🙍","🙎","🙅","🙆","💁","🙋","🧏","🙇","🤦","🤷","👮","🕵️","💂","👷","🤴","👸","👳","👲","🧕","🤵","👰","🤰","🤱","👼","🎅","🤶","🦸","🦹","🧙","🧚","🧛","🧜","🧝","🧞","🧟","💆","💇","🚶","🧍","🧎","🏃","💃","🕺","🕴","👯","🧖","🧗","🤺","🏇","🏌️","🏄","🚣","🏊","⛹️","🏋️","🚴","🚵","🤸","🤼","🤽","🤾","🤹","🧘","🛀","🛌"
        ]),
        EmojiCategory(symbol: "pawprint", emojis: [
            "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐻‍❄️","🐨","🐯","🦁","🐮","🐷","🐽","🐸","🐵","🙈","🙉","🙊","🐒","🐔","🐧","🐦","🐤","🐣","🐥","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🪱","🐛","🦋","🐌","🐞","🐜","🪰","🪲","🪳","🦟","🦗","🕷","🕸","🦂","🐢","🐍","🦎","🦖","🦕","🐙","🦑","🦐","🦞","🦀","🐡","🐠","🐟","🐬","🐳","🐋","🦈","🐊","🐅","🐆","🦓","🦍","🦧","🦣","🐘","🦛","🦏","🐪","🐫","🦒","🦘","🦬","🐃","🐂","🐄","🐎","🐖","🐏","🐑","🦙","🐐","🦌","🐕","🐩","🦮","🐈","🐈‍⬛","🐓","🦃","🦤","🦚","🦜","🦢","🦩","🕊","🐇","🦝","🦨","🦡","🦫","🦦","🦥","🐁","🐀","🐿","🦔","🐾","🐉","🐲","🌵","🎄","🌲","🌳","🌴","🪵","🌱","🌿","☘️","🍀","🎍","🪴","🎋","🍃","🍂","🍁","🍄","🐚","🪨","🌾","💐","🌷","🌹","🥀","🌺","🌸","🌼","🌻","🌞","🌝","🌚","🌕","🌖","🌗","🌘","🌑","🌒","🌓","🌔","🌙","🌎","🌍","🌏","🪐","💫","⭐️","🌟","✨","⚡️","☄️","💥","🔥","🌪","🌈","☀️","🌤","⛅️","🌥","☁️","🌦","🌧","⛈","🌩","🌨","❄️","☃️","⛄️","🌬","💨","💧","💦","☔️","☂️","🌊","🌫"
        ]),
        EmojiCategory(symbol: "fork.knife", emojis: [
            "🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥬","🥒","🌶","🫑","🌽","🥕","🫒","🧄","🧅","🥔","🍠","🥐","🥯","🍞","🥖","🥨","🧀","🥚","🍳","🧈","🥞","🧇","🥓","🥩","🍗","🍖","🦴","🌭","🍔","🍟","🍕","🫓","🥪","🥙","🧆","🌮","🌯","🫔","🥗","🥘","🫕","🥫","🍝","🍜","🍲","🍛","🍣","🍱","🥟","🦪","🍤","🍙","🍚","🍘","🍥","🥠","🥮","🍢","🍡","🍧","🍨","🍦","🥧","🧁","🍰","🎂","🍮","🍭","🍬","🍫","🍿","🍩","🍪","🌰","🥜","🍯","🥛","🍼","🫖","☕️","🍵","🧃","🥤","🧋","🍶","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🧉","🍾","🧊","🥄","🍴","🍽","🥣","🥡","🥢","🧂"
        ]),
        EmojiCategory(symbol: "sportscourt", emojis: [
            "⚽️","🏀","🏈","⚾️","🥎","🎾","🏐","🏉","🥏","🎱","🪀","🏓","🏸","🏒","🏑","🥍","🏏","🪃","🥅","⛳️","🪁","🏹","🎣","🤿","🥊","🥋","🎽","🛹","🛼","🛷","⛸","🥌","🎿","⛷","🏂","🏋️","🤼","🤸","⛹️","🤺","🤾","🏌️","🏇","🧘","🏄","🏊","🤽","🚣","🧗","🚵","🚴","🏆","🥇","🥈","🥉","🏅","🎖","🏵","🎗","🎫","🎟","🎪","🤹","🎭","🩰","🎨","🎬","🎤","🎧","🎼","🎹","🥁","🪘","🎷","🎺","🪗","🎸","🪕","🎻","🎲","♟","🎯","🎳","🎮","🎰","🧩"
        ]),
        EmojiCategory(symbol: "airplane", emojis: [
            "🚗","🚕","🚙","🚌","🚎","🏎","🚓","🚑","🚒","🚐","🛻","🚚","🚛","🚜","🦯","🦽","🦼","🛴","🚲","🛵","🏍","🛺","🚨","🚔","🚍","🚘","🚖","🚡","🚠","🚟","🚃","🚋","🚞","🚝","🚄","🚅","🚈","🚂","🚆","🚇","🚊","🚉","✈️","🛫","🛬","🛩","💺","🛰","🚀","🛸","🚁","🛶","⛵️","🚤","🛥","🛳","⛴","🚢","⚓️","⛽️","🚧","🚦","🚥","🚏","🗺","🗿","🗽","🗼","🏰","🏯","🏟","🎡","🎢","🎠","⛲️","⛱","🏖","🏝","🏜","🌋","⛰","🏔","🗻","🏕","⛺️","🛖","🏠","🏡","🏘","🏚","🏗","🏭","🏢","🏬","🏣","🏤","🏥","🏦","🏨","🏪","🏫","🏩","💒","🏛","⛪️","🕌","🕍","🛕","🕋","⛩","🗾","🎑","🏞","🌅","🌄","🌠","🎇","🎆","🌇","🌆","🏙","🌃","🌌","🌉","🌁"
        ]),
        EmojiCategory(symbol: "lightbulb", emojis: [
            "⌚️","📱","📲","💻","⌨️","🖥","🖨","🖱","🖲","🕹","🗜","💽","💾","💿","📀","📼","📷","📸","📹","🎥","📽","🎞","📞","☎️","📟","📠","📺","📻","🎙","🎚","🎛","🧭","⏱","⏲","⏰","🕰","⌛️","⏳","📡","🔋","🪫","🔌","💡","🔦","🕯","🪔","🧯","🛢","💸","💵","💴","💶","💷","🪙","💰","💳","💎","⚖️","🪜","🧰","🪛","🔧","🔨","⚒","🛠","⛏","🪚","🔩","⚙️","🪤","🧱","⛓","🧲","🔫","💣","🧨","🪓","🔪","🗡","⚔️","🛡","🚬","⚰️","🪦","⚱️","🏺","🔮","📿","🧿","💈","⚗️","🔭","🔬","🕳","🩹","🩺","💊","💉","🩸","🧬","🦠","🧫","🧪","🌡","🧹","🪠","🧺","🧻","🚽","🚰","🚿","🛁","🧼","🪥","🪒","🧽","🪣","🧴","🛎","🔑","🗝","🚪","🪑","🛋","🛏","🧸","🪆","🖼","🪞","🪟","🛍","🛒","🎁","🎈","🎏","🎀","🪄","🪅","🎊","🎉","🎎","🏮","🎐","🧧","✉️","📩","📨","📧","💌","📥","📤","📦","🏷","🪧","📪","📫","📬","📭","📮","📜","📃","📄","📑","🧾","📊","📈","📉","🗒","🗓","📆","📅","🗑","📇","🗃","🗳","🗄","📋","📁","📂","🗂","🗞","📰","📓","📔","📒","📕","📗","📘","📙","📚","📖","🔖","🧷","🔗","📎","🖇","📐","📏","🧮","📌","📍","✂️","🖊","🖋","✒️","🖌","🖍","📝","✏️","🔍","🔎","🔏","🔐","🔒","🔓"
        ]),
        EmojiCategory(symbol: "heart.fill", emojis: [
            "❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟","☮️","✝️","☪️","🕉","☸️","✡️","🔯","🕎","☯️","☦️","🛐","⛎","♈️","♉️","♊️","♋️","♌️","♍️","♎️","♏️","♐️","♑️","♒️","♓️","🆔","⚛️","🉑","☢️","☣️","📴","📳","🈶","🈚️","🈸","🈺","🈷️","✴️","🆚","💮","🉐","㊙️","㊗️","🈴","🈵","🈹","🈲","🅰️","🅱️","🆎","🆑","🅾️","🆘","❌","⭕️","🛑","⛔️","📛","🚫","💯","💢","♨️","🚷","🚯","🚳","🚱","🔞","📵","🚭","❗️","❕","❓","❔","‼️","⁉️","🔅","🔆","〽️","⚠️","🚸","🔱","⚜️","🔰","♻️","✅","🈯️","💹","❇️","✳️","❎","🌐","💠","Ⓜ️","🌀","💤","🏧","🚾","♿️","🅿️","🛗","🈳","🈂️","🛂","🛃","🛄","🛅","🚹","🚺","🚼","🚻","🚮","🎦","📶","🈁","🔣","ℹ️","🔤","🔡","🔠","🆖","🆗","🆙","🆒","🆕","🆓","0️⃣","1️⃣","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣","🔟","🔢","#️⃣","*️⃣","▶️","⏸","⏯","⏹","⏺","⏭","⏮","⏩","⏪","⏫","⏬","◀️","🔼","🔽","➡️","⬅️","⬆️","⬇️","↗️","↘️","↙️","↖️","↕️","↔️","↪️","↩️","⤴️","⤵️","🔀","🔁","🔂","🔄","🔃","🎵","🎶","➕","➖","➗","✖️","🟰","♾","💲","💱","™️","©️","®️","🔚","🔙","🔛","🔝","🔜","〰️","➰","➿","✔️","☑️","🔘","🔴","🟠","🟡","🟢","🔵","🟣","⚫️","⚪️","🟤","🔺","🔻","🔸","🔹","🔶","🔷","🔳","🔲","▪️","▫️","◾️","◽️","◼️","◻️","🟥","🟧","🟨","🟩","🟦","🟪","⬛️","⬜️","🟫","🔈","🔇","🔉","🔊","🔔","🔕","📣","📢","💬","💭","🗯","♠️","♣️","♥️","♦️","🃏","🎴","🀄️","🕐","🕑","🕒","🕓","🕔","🕕","🕖","🕗","🕘","🕙","🕚","🕛"
        ]),
        EmojiCategory(symbol: "flag.fill", emojis: [
            "🏁","🚩","🎌","🏴","🏳️","🏳️‍🌈","🏳️‍⚧️","🏴‍☠️","🇹🇷","🇺🇸","🇬🇧","🇩🇪","🇫🇷","🇮🇹","🇪🇸","🇳🇱","🇷🇺","🇨🇳","🇯🇵","🇰🇷","🇮🇳","🇧🇷","🇨🇦","🇦🇺","🇲🇽","🇸🇦","🇦🇪","🇶🇦","🇸🇪","🇳🇴","🇩🇰","🇫🇮","🇵🇱","🇵🇹","🇬🇷","🇨🇭","🇧🇪","🇦🇹","🇮🇪","🇨🇿","🇭🇺","🇺🇦","🇿🇦","🇪🇬","🇮🇩","🇹🇭","🇻🇳","🇵🇭","🇲🇾","🇸🇬","🇵🇰","🇧🇩","🇳🇬","🇰🇪","🇦🇷","🇨🇱","🇨🇴","🇵🇪","🇻🇪"
        ])
    ]
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
                .foregroundStyle(isSelected ? .white : Color.ink2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule().fill(Color.ink)
                    } else {
                        Capsule().fill(Color.backgroundPrimary)
                    }
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.ink : Color.lineStrong, lineWidth: 1)
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
