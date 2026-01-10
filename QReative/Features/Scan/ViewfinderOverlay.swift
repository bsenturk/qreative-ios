import SwiftUI

// MARK: - Viewfinder Overlay

struct ViewfinderOverlay: View {
    @State private var scanLineOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    let frameSize: CGFloat
    let bracketLength: CGFloat
    let bracketWidth: CGFloat

    init(
        frameSize: CGFloat = 260,
        bracketLength: CGFloat = 40,
        bracketWidth: CGFloat = 4
    ) {
        self.frameSize = frameSize
        self.bracketLength = bracketLength
        self.bracketWidth = bracketWidth
    }

    var body: some View {
        ZStack {
            // Dimmed background with cutout
            DimmedBackground(frameSize: frameSize)

            // Viewfinder frame
            ZStack {
                // Corner brackets
                cornerBrackets

                // Scanning line
                scanningLine

                // Center focus indicator
                centerFocus
            }
            .frame(width: frameSize, height: frameSize)
        }
        .onAppear {
            startScanAnimation()
        }
    }

    // MARK: - Corner Brackets

    private var cornerBrackets: some View {
        ZStack {
            // Top Left
            CornerBracket(length: bracketLength, width: bracketWidth, corner: .topLeft)
                .position(x: bracketWidth / 2, y: bracketWidth / 2)

            // Top Right
            CornerBracket(length: bracketLength, width: bracketWidth, corner: .topRight)
                .position(x: frameSize - bracketWidth / 2, y: bracketWidth / 2)

            // Bottom Left
            CornerBracket(length: bracketLength, width: bracketWidth, corner: .bottomLeft)
                .position(x: bracketWidth / 2, y: frameSize - bracketWidth / 2)

            // Bottom Right
            CornerBracket(length: bracketLength, width: bracketWidth, corner: .bottomRight)
                .position(x: frameSize - bracketWidth / 2, y: frameSize - bracketWidth / 2)
        }
    }

    // MARK: - Scanning Line

    private var scanningLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.accentTertiary.opacity(0.3),
                        Color.accentTertiary,
                        Color.accentTertiary.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: frameSize - 20, height: 2)
            .shadow(color: Color.accentTertiary.opacity(0.8), radius: 15, x: 0, y: 0)
            .offset(y: scanLineOffset)
    }

    // MARK: - Center Focus

    private var centerFocus: some View {
        Circle()
            .stroke(Color.white.opacity(0.5), lineWidth: 2)
            .frame(width: 8, height: 8)
    }

    // MARK: - Animation

    private func startScanAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        // Start from top
        scanLineOffset = -frameSize / 2 + 20

        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            scanLineOffset = frameSize / 2 - 20
        }
    }
}

// MARK: - Corner Bracket

private struct CornerBracket: View {
    let length: CGFloat
    let width: CGFloat
    let corner: Corner

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        Canvas { context, size in
            let path = bracketPath(in: size)

            // Glow shadow
            context.addFilter(.shadow(
                color: Color(hex: "6200EA").opacity(0.8),
                radius: 10,
                x: 0,
                y: 0
            ))

            // Gradient fill
            let gradient = Gradient(colors: [
                Color(hex: "6200EA"),
                Color(hex: "9C27B0")
            ])

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: gradientStart,
                    endPoint: gradientEnd
                ),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: length, height: length)
    }

    private func bracketPath(in size: CGSize) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 2

        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: length))
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: 0),
                control: CGPoint(x: 0, y: 0)
            )
            path.addLine(to: CGPoint(x: length, y: 0))

        case .topRight:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: length - cornerRadius, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: length, y: cornerRadius),
                control: CGPoint(x: length, y: 0)
            )
            path.addLine(to: CGPoint(x: length, y: length))

        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: length - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: length),
                control: CGPoint(x: 0, y: length)
            )
            path.addLine(to: CGPoint(x: length, y: length))

        case .bottomRight:
            path.move(to: CGPoint(x: length, y: 0))
            path.addLine(to: CGPoint(x: length, y: length - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: length - cornerRadius, y: length),
                control: CGPoint(x: length, y: length)
            )
            path.addLine(to: CGPoint(x: 0, y: length))
        }

        return path
    }

    private var gradientStart: CGPoint {
        switch corner {
        case .topLeft: return CGPoint(x: 0, y: length)
        case .topRight: return CGPoint(x: 0, y: 0)
        case .bottomLeft: return CGPoint(x: 0, y: 0)
        case .bottomRight: return CGPoint(x: length, y: 0)
        }
    }

    private var gradientEnd: CGPoint {
        switch corner {
        case .topLeft: return CGPoint(x: length, y: 0)
        case .topRight: return CGPoint(x: length, y: length)
        case .bottomLeft: return CGPoint(x: length, y: length)
        case .bottomRight: return CGPoint(x: 0, y: length)
        }
    }
}

// MARK: - Dimmed Background

private struct DimmedBackground: View {
    let frameSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let rect = CGRect(
                x: (geometry.size.width - frameSize) / 2,
                y: (geometry.size.height - frameSize) / 2,
                width: frameSize,
                height: frameSize
            )

            Rectangle()
                .fill(Color.black.opacity(0.6))
                .reverseMask {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: frameSize, height: frameSize)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
        }
    }
}

// MARK: - Reverse Mask Extension

extension View {
    @ViewBuilder
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}

// MARK: - Viewfinder Frame Shape

struct ViewfinderFrameShape: Shape {
    let cornerLength: CGFloat
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Top Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        // Top Right
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        // Bottom Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        // Bottom Left
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Simulated camera background
        LinearGradient(
            colors: [Color.backgroundSecondary, Color.backgroundPrimary],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ViewfinderOverlay()
    }
}
