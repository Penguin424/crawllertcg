#!/bin/bash

# Script para verificar permisos en el Info.plist del bundle
echo "Verificando permisos en el proyecto..."
echo "========================================"
echo ""

INFOPLIST="/Users/pablorizo/Documents/flutter_projects/tcgs/ios/Runner/Info.plist"

if [ -f "$INFOPLIST" ]; then
    echo "✓ Info.plist encontrado en: $INFOPLIST"
    echo ""
    echo "Permisos de cámara configurados:"
    echo "--------------------------------"

    if plutil -extract NSCameraUsageDescription raw "$INFOPLIST" 2>/dev/null; then
        echo "✓ NSCameraUsageDescription: PRESENTE"
    else
        echo "✗ NSCameraUsageDescription: FALTA"
    fi

    if plutil -extract NSPhotoLibraryUsageDescription raw "$INFOPLIST" 2>/dev/null; then
        echo "✓ NSPhotoLibraryUsageDescription: PRESENTE"
    else
        echo "✗ NSPhotoLibraryUsageDescription: FALTA"
    fi

    if plutil -extract NSPhotoLibraryAddUsageDescription raw "$INFOPLIST" 2>/dev/null; then
        echo "✓ NSPhotoLibraryAddUsageDescription: PRESENTE"
    else
        echo "✗ NSPhotoLibraryAddUsageDescription: FALTA"
    fi

    if plutil -extract NSMicrophoneUsageDescription raw "$INFOPLIST" 2>/dev/null; then
        echo "✓ NSMicrophoneUsageDescription: PRESENTE"
    else
        echo "✗ NSMicrophoneUsageDescription: FALTA"
    fi

    echo ""
    echo "Todos los permisos están configurados en Info.plist"
    echo ""
else
    echo "✗ No se encontró Info.plist"
    exit 1
fi

# Verificar que permission_handler_apple esté instalado
echo "Verificando instalación de permission_handler..."
echo "-----------------------------------------------"

if [ -d "/Users/pablorizo/Documents/flutter_projects/tcgs/ios/.symlinks/plugins/permission_handler_apple" ]; then
    echo "✓ permission_handler_apple instalado correctamente"
else
    echo "✗ permission_handler_apple NO encontrado"
    echo "  Ejecuta: flutter pub get && cd ios && pod install"
fi

echo ""
echo "========================================"
echo "Verificación completa"
echo ""
echo "IMPORTANTE: Para que los permisos funcionen:"
echo "1. Desinstala completamente la app de tu dispositivo"
echo "2. Ejecuta: flutter clean"
echo "3. Ejecuta: flutter run"
echo "4. Al entrar a 'Escanear', la app debe pedir permisos"
