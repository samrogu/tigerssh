#!/bin/bash

# Script para construir y empaquetar TigerSSH en macOS

echo "🚀 Iniciando proceso de construcción para macOS..."

# 1. Verificar si create-dmg está instalado
if ! command -v create-dmg &> /dev/null
then
    echo "❌ Error: 'create-dmg' no está instalado."
    echo "Por favor instálalo ejecutando: brew install create-dmg"
    echo "O clonando el repositorio manualmente si tienes problemas de permisos."
    exit 1
fi

# 2. Compilar la aplicación en modo Release
echo "📦 Compilando TigerSSH en modo Release..."
flutter build macos --release

if [ $? -ne 0 ]; then
    echo "❌ Error: La compilación de Flutter falló."
    exit 1
fi

# 3. Preparar el entorno para el DMG
APP_PATH="build/macos/Build/Products/Release/TigerSSH.app"
STAGING_DIR="build/dmg_staging"
DMG_NAME="build/TigerSSH_Final.dmg"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: No se encontró la aplicación en $APP_PATH"
    exit 1
fi

echo "🧹 Limpiando compilaciones anteriores..."
rm -f "$DMG_NAME"
rm -rf "$STAGING_DIR"

echo "📁 Preparando carpeta de empaquetado (staging)..."
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

# 4. Crear el DMG
echo "💿 Generando instalador profesional..."
create-dmg \
  --volname "TigerSSH" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "TigerSSH.app" 150 190 \
  --hide-extension "TigerSSH.app" \
  --app-drop-link 450 190 \
  "$DMG_NAME" \
  "$STAGING_DIR/"

if [ $? -eq 0 ]; then
    echo "✅ ¡Instalador generado con éxito en: $DMG_NAME!"
else
    echo "❌ Error al generar el DMG."
fi

# 5. Limpieza
echo "🧹 Limpiando archivos temporales..."
rm -rf "$STAGING_DIR"

echo "🎉 Proceso finalizado."
