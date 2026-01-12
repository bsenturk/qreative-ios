import SwiftUI
import GoogleMobileAds

// MARK: - Ad Unit IDs
enum AdUnitID {
    static var banner: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        return "ca-app-pub-2545255000258244/3873748432"
        #endif
    }
}

// MARK: - Banner Ad View
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdUnitID.banner) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.backgroundColor = .clear

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }

        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// MARK: - Banner Container View
struct BannerContainerView: View {
    var body: some View {
        BannerAdView()
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.backgroundPrimary)
    }
}

// MARK: - Preview
#Preview {
    BannerContainerView()
}
