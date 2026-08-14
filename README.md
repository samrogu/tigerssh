# TigerSSH

TigerSSH is a secure, encrypted SSH client and credential vault built with Flutter. It provides a safe and convenient way to manage your remote server connections and SSH keys across multiple platforms.

## Description

TigerSSH acts as a secure vault for your SSH credentials. It uses industry-standard encryption to protect your sensitive data (such as passwords and private keys) in a local database. The application requires a Master Password to unlock the vault, ensuring that your server access remains secure even if your device is compromised. 

Once unlocked, you can initiate SSH sessions directly within the app using its built-in terminal emulator, providing a seamless workflow from credential management to server administration.

## Key Features

*   **Encrypted Credential Vault:** Securely stores SSH connection details, passwords, and private keys using a local encrypted database (SQLCipher).
*   **Master Password Protection:** Access to the application and your stored credentials is protected by a strong Master Password.
*   **Built-in Terminal Emulator:** Connect to your servers directly within the app using a fully functional, integrated terminal (`xterm` and `dartssh2`).
*   **Auto-Lock Mechanism:** The vault automatically locks after a period of inactivity to prevent unauthorized access.
*   **Cross-Platform:** Built with Flutter, TigerSSH is designed to run seamlessly on multiple platforms.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
