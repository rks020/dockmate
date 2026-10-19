import SwiftUI

public struct OnboardingView: View {
    @ObservedObject var permissions: PermissionManager = .shared
    public let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.system(size: 52))
                    .foregroundColor(.accentColor)

                Text("DockMate'e Hoş Geldiniz")
                    .font(.title.bold())

                Text("Dock simgeleri üzerinde canlı pencere önizlemelerini etkinleştirmek için 2 küçük sistem iznine ihtiyaç duyuyoruz.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 16)

            Divider()

            // Steps
            VStack(spacing: 16) {
                // Step 1: Accessibility
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: permissions.isAccessibilityGranted ? "checkmark.circle.fill" : "1.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(permissions.isAccessibilityGranted ? .green : .accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Erişilebilirlik İzni (Accessibility)")
                            .font(.headline)
                        Text("Dock simgelerinin konumunu tespit etmek ve pencereyi öne getirmek/kapatmak için gereklidir.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !permissions.isAccessibilityGranted {
                            Button("Erişilebilirlik İznini Aç") {
                                permissions.requestAccessibility()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        } else {
                            Text("✓ İzin Verildi")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                // Step 2: Screen Recording
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: permissions.isScreenCaptureGranted ? "checkmark.circle.fill" : "2.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(permissions.isScreenCaptureGranted ? .green : .accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("2. Ekran Kaydı İzni (Screen Recording)")
                            .font(.headline)
                        Text("Açık pencerelerin canlı küçük resim önizlemelerini (live preview) göstermek için gereklidir.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !permissions.isScreenCaptureGranted {
                            Button("Ekran Kaydı İznini Aç") {
                                permissions.requestScreenCapture()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        } else {
                            Text("✓ İzin Verildi")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 16)

            Spacer()

            // Footer
            HStack {
                Button("İzin Durumunu Yenile") {
                    permissions.refreshStatus()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button("DockMate'i Başlat") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 520, height: 490)
    }
}
