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
            DimmedBackground(frameSize: frameSize)

            ZStack {
                cornerBrackets

                scanningLine
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
            CornerBracket(length: bracketLength, width: bracketWidth, corner: .topLeft)
                .position(x: bracketWidth / 2, y: bracketWidth / 2)

            CornerBracket(length: bracketLength, width: bracketWidth, corner: .topRight)
                .position(x: frameSize - bracketWidth / 2, y: bracketWidth / 2)

            CornerBracket(length: bracketLength, width: bracketWidth, corner: .bottomLeft)
                .position(x: bracketWidth / 2, y: frameSize - bracketWidth / 2)

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
                        Color.accentPrimary.opacity(0.3),
                        Color.accentPrimary,
                        Color.accentPrimary.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: frameSize - 20, height: 2)
            .shadow(color: Color.accentPrimary.opacity(0.8), radius: 15, x: 0, y: 0)
            .offset(y: scanLineOffset)
    }

    // MARK: - Animation
    private func startScanAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

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

            context.addFilter(.shadow(
                color: Color.black.opacity(0.35),
                radius: 4,
                x: 0,
                y: 0
            ))

            context.stroke(
                path,
                with: .color(.white),
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
}

// MARK: - Dimmed Background
private struct DimmedBackground: View {
    let frameSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
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

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.backgroundSecondary, Color.backgroundPrimary],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ViewfinderOverlay()
    }
}
