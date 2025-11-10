# cargoquintest

Proyecto desarrollado como parte del proceso de aplicación para la vacante de **Desarrollador Móvil** en **Grupo CQ / 3PL**.  
La app es 100% offline (sin Firebase ni backend) y utiliza datasources en memoria (solo para una lista default de categorias) para facilitar la revisión por lo que al cerrar la app
se "reinician" los datos. 

## Requisitos
- **Flutter 3.16+ / Dart 3+**
- **Android Studio** o **Xcode**
- **iOS**: requiere configurar *Signing & Capabilities* para compilar en dispositivo/simulator.
- No se requieren claves, archivos `.env` ni servicios externos.

## Cómo ejecutar

Clona el repo e instala dependencias:
```bash
git clone https://github.com/MartinCabrera137/McCargoQuinTest.git
cd McCargoQuinTest
flutter pub get
flutter run --release
