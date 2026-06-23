# Kasentra

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Menjalankan dengan Laravel lokal

Jika Laravel berjalan di mesin yang sama, gunakan host yang sesuai:

- Web (Chrome/Edge): `http://127.0.0.1:8000/api`
- Android emulator: `http://10.0.2.2:8000/api`
- iOS simulator: `http://127.0.0.1:8000/api`
- Android / iOS perangkat fisik: `http://<IP-PC>:8000/api`

Untuk perangkat fisik, jalankan dengan:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.2:8000/api
```

Ganti `192.168.1.2` dengan IP PC yang menjalankan server Laravel.

Jika ingin menjalankan di Chrome atau Edge, gunakan target browser:

```bash
flutter run -d chrome
flutter run -d edge
```
