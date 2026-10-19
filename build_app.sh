#!/bin/bash
set -e

echo "🚀 DockMate derleme süreci başlatılıyor..."

# 1. Swift projesini Release modunda derle
swift build -c release

BIN_PATH=".build/release/DockMate"
APP_DIR="DockMate.app"

if [ ! -f "$BIN_PATH" ]; then
    echo "❌ Derleme başarısız oldu: $BIN_PATH bulunamadı!"
    exit 1
fi

echo "📦 macOS Uygulama Paketi (DockMate.app) hazırlanıyor..."

# 2. Bundle klasör yapısını oluştur
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 3. İkili dosyayı kopyala
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/DockMate"
chmod +x "$APP_DIR/Contents/MacOS/DockMate"

# 4. Info.plist ve ikon dosyasını kopyala
cp "Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# 5. İmzalama: sabit bir sertifika kullanılırsa macOS izinleri (Erişilebilirlik,
#    Ekran Kaydı) her derlemede sıfırlanmaz. Ad-hoc imza her build'de değişir.
IDENTITY="${DOCKMATE_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | grep 'Apple Development' | head -1 | awk '{print $2}')}"
if [ -n "$IDENTITY" ]; then
    echo "🔐 Sabit sertifika ile imzalanıyor: $IDENTITY"
    codesign --force --deep --options runtime -s "$IDENTITY" "$APP_DIR"
else
    echo "⚠️  Sertifika bulunamadı, ad-hoc imza kullanılıyor (izinler her build'de sıfırlanır)"
    codesign --force --deep -s - "$APP_DIR" 2>/dev/null || true
fi

# 6. /Applications içine kur (izinler sabit bir yola bağlanır, Sistem Ayarları'nda listelenir)
if pgrep -x DockMate >/dev/null; then pkill -x DockMate; sleep 0.5; fi
rm -rf "/Applications/$APP_DIR"
cp -R "$APP_DIR" "/Applications/$APP_DIR"

echo "✅ DockMate.app başarıyla oluşturuldu ve /Applications içine kuruldu!"
echo ""
echo "Çalıştırmak için:"
echo "  open /Applications/DockMate.app"
