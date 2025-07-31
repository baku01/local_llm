# Instruções de Build - LLM Local Desktop

## Pré-requisitos

### Para macOS:
- **Xcode completo** (não apenas Command Line Tools)
- CocoaPods: `sudo gem install cocoapods`

### Para Windows:
- Visual Studio 2019/2022 com workload "Desktop development with C++"
- Flutter Desktop habilitado: `flutter config --enable-windows-desktop`

## Build Commands

### macOS:
```bash
# Instalar dependências
flutter pub get

# Build para release
flutter build macos --release

# Build para debug
flutter build macos --debug

# Executar em modo desenvolvimento
flutter run -d macos
```

### Windows:
```bash
# Instalar dependências
flutter pub get

# Build para release
flutter build windows --release

# Build para debug  
flutter build windows --debug

# Executar em modo desenvolvimento
flutter run -d windows
```

## Estrutura dos Executáveis

### macOS:
- Debug: `build/macos/Build/Products/Debug/local_llm.app`
- Release: `build/macos/Build/Products/Release/local_llm.app`

### Windows:
- Debug: `build/windows/x64/runner/Debug/local_llm.exe`
- Release: `build/windows/x64/runner/Release/local_llm.exe`

## Resolução de Problemas

### macOS - Erro xcodebuild:
1. Instalar Xcode pela App Store
2. Executar: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. Executar: `sudo xcodebuild -runFirstLaunch`
4. Instalar CocoaPods: `sudo gem install cocoapods`

### Windows - Erro Visual Studio:
1. Instalar Visual Studio com workload C++
2. Habilitar desktop: `flutter config --enable-windows-desktop`
3. Verificar: `flutter doctor`

## Desenvolvimento Recomendado

Para desenvolvimento, recomendamos:
1. **Usar VS Code** com extensão Flutter
2. **Executar com**: `flutter run -d macos` ou `flutter run -d windows`
3. **Hot reload** funcionará normalmente

## Dependências do Sistema

O app requer que o **Ollama** esteja instalado e rodando:
- macOS: `brew install ollama`
- Windows: Baixar de https://ollama.ai/

Executar: `ollama serve` antes de usar o app.