# Cerberus Secure Vault - Build Guide

Esta guía explica cómo generar los ejecutables (binarios) de la aplicación para los diferentes sistemas operativos de escritorio: **macOS**, **Windows** y **Linux**.

Dado que esta es una aplicación construida con Flutter, el proceso de compilación es muy sencillo a través de su CLI.

## Prerrequisitos Comunes

1. **Flutter SDK**: Asegúrate de tener instalado el [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. **Dependencias**: Antes de intentar compilar, descarga todas las dependencias ejecutando:
   ```bash
   flutter pub get
   ```
3. **Plataformas habilitadas**: Asegúrate de tener habilitado el soporte para escritorio en tu entorno de Flutter. Puedes verificar el estado ejecutando:
   ```bash
   flutter doctor
   ```

---

## 🍏 Compilar para macOS

Para compilar la aplicación para macOS, debes estar utilizando una computadora Mac con **Xcode** instalado.

### Comandos:
```bash
# Limpiar builds anteriores
flutter clean
flutter pub get

# Construir la versión de lanzamiento
flutter build macos --release
```

### Ubicación del Ejecutable (.app)
La aplicación y sus recursos se generarán en la siguiente ruta:
`build/macos/Build/Products/Release/TigerSSH.app`

En macOS, los archivos `.app` no son un solo archivo binario, sino una **carpeta especial** (Bundle) que macOS reconoce como una aplicación. 

### Empaquetar en un Instalador Único (.dmg)
Para distribuir la app de macOS como un solo archivo instalador (`.dmg`), puedes usar la utilidad nativa de macOS `hdiutil` desde la terminal de tu Mac:

```bash
# Crea un archivo .dmg a partir de la carpeta .app
hdiutil create -volname "TigerSSH" -srcfolder build/macos/Build/Products/Release/TigerSSH.app -ov -format UDZO build/TigerSSH.dmg
```
Esto generará el archivo `build/TigerSSH.dmg` listo para ser compartido.

---

## 📱 Compilar para Android (.apk)

Para Android, Flutter **sí** genera un único archivo instalable de forma nativa. Necesitas tener instalado Android Studio y configurado el SDK de Android.

### Comandos:
```bash
# Construir la versión de lanzamiento
flutter build apk --release
```

### Ubicación del Ejecutable (.apk):
A diferencia de los sistemas de escritorio, este comando genera un **único archivo** listo para instalar o compartir:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🪟 Compilar para Windows

Para compilar la aplicación para Windows, debes ejecutar estos comandos desde una computadora con Windows que tenga instalado **Visual Studio** con la carga de trabajo "Desarrollo para el escritorio con C++".

### Comandos:
```bash
# Limpiar builds anteriores
flutter clean
flutter pub get

# Construir la versión de lanzamiento
flutter build windows --release
```

### Ubicación del Ejecutable:
Los archivos ejecutables y sus dependencias (DLLs y assets) se generarán en la siguiente ruta:
`build\windows\x64\runner\Release\`

Para distribuir la app, debes compartir la **carpeta completa** `Release`, ya que el archivo `.exe` depende de los archivos adicionales que se encuentran en ese directorio. Opcionalmente puedes usar Inno Setup o MSIX para crear un instalador.

---

## 🐧 Compilar para Linux

Para compilar la aplicación para Linux, necesitas un entorno de Linux (ej. Ubuntu) con las bibliotecas de desarrollo de GTK y CMake instaladas.
Puedes instalarlas ejecutando: `sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev`

### Comandos:
```bash
# Limpiar builds anteriores
flutter clean
flutter pub get

# Construir la versión de lanzamiento
flutter build linux --release
```

### Ubicación del Ejecutable:
El binario y los archivos necesarios se generarán en la siguiente ruta:
`build/linux/x64/release/bundle/`

Al igual que en Windows, para distribuir la app debes empaquetar toda la carpeta `bundle`, ya que contiene los assets necesarios para la ejecución del binario.
