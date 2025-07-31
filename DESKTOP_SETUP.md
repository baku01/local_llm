# Setup Desktop - LLM Local

## ✅ Configuração Atual

Aplicação configurada **APENAS** para desktop nativo:
- ✅ **macOS** desktop habilitado
- ✅ **Windows** desktop habilitado  
- ❌ **Web** desabilitado
- ❌ **Mobile** removido

## 🚀 Para executar agora

### Sem Xcode (limitado):
```bash
# Verificar configuração
flutter doctor

# Executar em modo debug (pode não funcionar sem Xcode)
flutter run -d macos --debug
```

### Com Xcode completo:
1. **Instalar Xcode:**
   - Via App Store (recomendado)
   - Ou baixar de https://developer.apple.com/xcode/

2. **Configurar:**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   sudo gem install cocoapods
   ```

3. **Executar:**
   ```bash
   flutter run -d macos
   ```

## 🎯 Executável final

### macOS:
```bash
flutter build macos --release
# Resultado: build/macos/Build/Products/Release/local_llm.app
```

### Windows (em máquina Windows):
```bash
flutter build windows --release  
# Resultado: build/windows/x64/runner/Release/local_llm.exe
```

## 📋 Pré-requisitos do Sistema

Para que o app funcione, você precisa do **Ollama** rodando:

### macOS:
```bash
brew install ollama
ollama serve
```

### Windows:
```bash
# Baixar de https://ollama.ai/
# Executar ollama.exe serve
```

## 🔍 Status Atual

- ✅ Código limpo (flutter analyze)
- ✅ Testes passando (flutter test)
- ✅ Dependências otimizadas
- ⚠️ Precisa Xcode para build macOS
- ✅ Pronto para Windows (com Visual Studio)

## 🛠️ Alternativas de Desenvolvimento

Se não quiser instalar Xcode agora:
1. **Desenvolver no Windows** com Visual Studio
2. **Usar GitHub Actions** para build macOS
3. **Docker** com ambiente Flutter configurado