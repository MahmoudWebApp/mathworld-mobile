#!/bin/bash
# Build script for MathWorld Flutter app

echo "🚀 بناء تطبيق MathWorld..."

# Android Build
echo "📱 بناء APK..."
flutter build apk --release

# iOS Build
echo "🍎 بناء iOS..."
flutter build ios --release

echo "✅ تم إكمال البناء بنجاح!"
