import SwiftUI

public struct PreferencesView: View {
    @ObservedObject var settings: SettingsManager = .shared
    @ObservedObject var permissions: PermissionManager = .shared
    @ObservedObject var tracker: DockTracker = .shared

    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            // General Tab
            generalTab
                .tabItem {
                    Label("Genel", systemImage: "gearshape")
                }
                .tag(0)

            // Preview Tab
            previewTab
                .tabItem {
                    Label("Önizleme", systemImage: "macwindow.on.rectangle")
                }
                .tag(1)

            // Permissions Tab
            permissionsTab
                .tabItem {
                    Label("İzinler", systemImage: "lock.shield")
                }
                .tag(2)

            // About Tab
            aboutTab
                .tabItem {
                    Label("Hakkında", systemImage: "info.circle")
                }
                .tag(3)
        }
        .frame(width: 520, height: 420)
        .padding(16)
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section(header: Text("Çalışma Durumu").font(.headline)) {
                Toggle("Dock İzleme Aktif", isOn: Binding(
                    get: { tracker.isTrackingEnabled },
                    set: { enabled in
                        if enabled {
                            tracker.startTracking()
                        } else {
                            tracker.stopTracking()
                        }
                    }
                ))
                .toggleStyle(.switch)

                Text("Devre dışı bırakıldığında DockMate arkaplanda uyur ve fare hareketlerini izlemez.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Sistem Entegrasyonu").font(.headline)) {
                Toggle("Oturum Açıldığında Başlat", isOn: $settings.launchAtLogin)
                    .toggleStyle(.checkbox)
                Toggle("Uygulama Rozetlerini Göster", isOn: $settings.showAppIconBadge)
                    .toggleStyle(.checkbox)
            }

            Section(header: Text("Hızlı Test").font(.headline)) {
                Button(action: {
                    tracker.simulatePreviewForFrontmostApp()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Aktif Uygulama İçin Önizlemeyi Tetikle")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
    }

    // MARK: - Preview Tab
    private var previewTab: some View {
        Form {
            Section(header: Text("Önizleme Boyutu ve Düzeni").font(.headline)) {
                Picker("Önizleme Kartı Boyutu", selection: $settings.previewSizeRaw) {
                    ForEach(PreviewSize.allCases) { size in
                        Text(size.rawValue).tag(size.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Stepper("Maksimum Pencere Sayısı: \(settings.windowLimit)", value: $settings.windowLimit, in: 2...12)
            }

            Section(header: Text("Zamanlama ve Gecikmeler").font(.headline)) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Fare Bekleme Gecikmesi:")
                        Spacer()
                        Text("\(Int(settings.hoverDelay * 1000)) ms")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.hoverDelay, in: 0.05...0.80, step: 0.05)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Kapanma Gecikmesi:")
                        Spacer()
                        Text("\(Int(settings.dismissDelay * 1000)) ms")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.dismissDelay, in: 0.10...0.60, step: 0.05)
                }
            }

            Section(header: Text("Görünüm Seçenekleri").font(.headline)) {
                Toggle("Küçültülmüş Pencereleri Göster", isOn: $settings.showMinimizedWindows)
                    .toggleStyle(.checkbox)
                Toggle("Pencere Başlıklarını Göster", isOn: $settings.showWindowTitles)
                    .toggleStyle(.checkbox)
                Toggle("Apple Music & Spotify Medya Kontrolleri", isOn: $settings.enableMediaControls)
                    .toggleStyle(.checkbox)
            }
        }
        .padding(12)
    }

    // MARK: - Permissions Tab
    private var permissionsTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Gerekli macOS İzinleri")
                .font(.headline)

            Text("DockMate'in Dock simgelerini algılayabilmesi ve pencerelerin canlı önizlemelerini oluşturabilmesi için aşağıdaki sistem izinleri gereklidir:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Accessibility Status Card
            HStack(spacing: 12) {
                Image(systemName: permissions.isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(permissions.isAccessibilityGranted ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Erişilebilirlik (Accessibility)")
                        .font(.system(size: 13, weight: .semibold))
                    Text(permissions.isAccessibilityGranted ? "İzin verildi. Dock simgeleri ve pencere durumları izlenebiliyor." : "İzin gerekiyor. Dock simgelerini algılamak ve pencereleri yönetmek için gereklidir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !permissions.isAccessibilityGranted {
                    Button("İzin Ver") {
                        permissions.requestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            // Screen Recording Status Card
            HStack(spacing: 12) {
                Image(systemName: permissions.isScreenCaptureGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(permissions.isScreenCaptureGranted ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ekran Kaydı (Screen Recording)")
                        .font(.system(size: 13, weight: .semibold))
                    Text(permissions.isScreenCaptureGranted ? "İzin verildi. Canlı pencere küçük resimleri (thumbnails) yakalanıyor." : "İsteğe bağlı/önerilen. Canlı pencere önizlemeleri için gereklidir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !permissions.isScreenCaptureGranted {
                    Button("İzin Ver") {
                        permissions.requestScreenCapture()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            Spacer()

            HStack {
                Button("İzin Durumunu Yenile") {
                    permissions.refreshStatus()
                }
                Spacer()
                Button("macOS Güvenlik Ayarlarını Aç") {
                    permissions.openAccessibilitySettings()
                }
            }
        }
        .padding(16)
    }

    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "macwindow.on.rectangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text("DockMate for macOS")
                    .font(.title2.bold())
                Text("Sürüm 1.0.0 (Native Swift & SwiftUI)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("macOS Dock simgeleri üzerinde mouse ile gezindiğinizde canlı pencere önizlemeleri, pencere kontrolleri ve müzik kontrolleri sağlayan güçlü arkaplan aracı.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)

            Divider().padding(.horizontal, 40)

            VStack(spacing: 6) {
                Text("Gizlilik Odaklı: Verileriniz cihazınızda kalır, telemetri içermez.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("macOS Sonoma & Sequoia ile tam uyumlu.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.top, 24)
    }
}
