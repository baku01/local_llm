# 🚀 Sistema de Release Automatizado

Este projeto utiliza um sistema de release automatizado baseado em **Conventional Commits** que detecta automaticamente quando é necessário criar um novo release.

## 📋 Como Funciona

### 1. **Detecção Automática**
O sistema monitora commits na branch `main` e automaticamente detecta quando um release é necessário baseado nos tipos de commit:

- `feat:` → Release **minor** (1.0.0 → 1.1.0)
- `fix:` → Release **patch** (1.0.0 → 1.0.1)
- `perf:` → Release **patch** (1.0.0 → 1.0.1)
- `BREAKING CHANGE` → Release **major** (1.0.0 → 2.0.0)

### 2. **Workflows Integrados**

#### 🔄 Fluxo Automático
1. **CI/CD Pipeline** executa testes e builds
2. **Auto Release** verifica se release é necessário
3. **Release** cria automaticamente a nova versão

#### 📁 Arquivos de Workflow
- `.github/workflows/ci.yml` - Pipeline principal de CI/CD
- `.github/workflows/release.yml` - Workflow de release
- `.github/workflows/auto-release.yml` - Detecção automática de release

## 🛠️ Como Usar

### Release Automático (Recomendado)

1. **Faça commits usando Conventional Commits:**
   ```bash
   git commit -m "feat: adicionar nova funcionalidade X"
   git commit -m "fix: corrigir bug na funcionalidade Y"
   git commit -m "feat!: mudança que quebra compatibilidade"
   ```

2. **Push para main:**
   ```bash
   git push origin main
   ```

3. **O sistema automaticamente:**
   - Executa CI/CD
   - Detecta necessidade de release
   - Cria nova versão
   - Gera release no GitHub

### Release Manual

#### Via GitHub Actions
1. Vá para **Actions** → **Release**
2. Clique em **Run workflow**
3. Escolha o tipo de release ou versão específica
4. Clique **Run workflow**

#### Via Script Local
```bash
# Usar script helper
./scripts/release-helper.sh

# Ou forçar tipo específico
./scripts/release-helper.sh patch
./scripts/release-helper.sh minor
./scripts/release-helper.sh major
```

## 📝 Conventional Commits

### Formato
```
<tipo>[escopo opcional]: <descrição>

[corpo opcional]

[rodapé opcional]
```

### Tipos Principais
- **feat**: Nova funcionalidade
- **fix**: Correção de bug
- **perf**: Melhoria de performance
- **refactor**: Refatoração sem mudança de funcionalidade
- **style**: Mudanças de formatação/estilo
- **test**: Adição/modificação de testes
- **docs**: Documentação
- **build**: Sistema de build
- **ci**: Configuração de CI/CD
- **chore**: Tarefas de manutenção

### Exemplos
```bash
# Feature nova (minor release)
git commit -m "feat: adicionar suporte a novos modelos LLM"

# Bug fix (patch release)
git commit -m "fix: corrigir erro de conexão com Ollama"

# Breaking change (major release)
git commit -m "feat!: alterar API de configuração"

# Com escopo
git commit -m "feat(ui): adicionar tema escuro"
git commit -m "fix(api): corrigir timeout em requests"
```

## 🎯 Versionamento Semântico

O projeto segue **Semantic Versioning (semver)**:

- **MAJOR** (X.0.0): Mudanças incompatíveis
- **MINOR** (1.X.0): Novas funcionalidades compatíveis
- **PATCH** (1.0.X): Correções de bugs

## 📦 Processo de Release

Quando um release é criado, o sistema:

1. **Atualiza automaticamente** a versão no `pubspec.yaml`
2. **Cria tag** no Git (ex: v1.2.0)
3. **Executa builds** para todas as plataformas
4. **Gera changelog** automaticamente
5. **Cria release** no GitHub com:
   - Arquivos binários (macOS, Windows)
   - Changelog formatado
   - Notas de instalação

## 🔧 Configuração

### Arquivos de Configuração
- `.github/release-config.json` - Regras de release
- `scripts/release-helper.sh` - Script auxiliar

### Permissões Necessárias
O workflow precisa das seguintes permissões:
- `contents: write` - Para criar releases e tags
- `actions: write` - Para disparar workflows

## 🚨 Troubleshooting

### Release não foi criado
1. Verifique se os commits seguem Conventional Commits
2. Confirme que CI/CD passou com sucesso
3. Verifique se não há conflitos na branch main

### Erro de permissão
1. Verifique se `GITHUB_TOKEN` tem permissões adequadas
2. Confirme configurações do repositório

### Versão incorreta
1. Verifique se `pubspec.yaml` está sincronizado
2. Use script helper para corrigir: `./scripts/release-helper.sh`

## 📚 Exemplos de Uso

### Desenvolvimento Normal
```bash
# Feature development
git commit -m "feat: implementar busca avançada"

# Bug fixes
git commit -m "fix: resolver memory leak na interface"

# Push - release automático será criado
git push origin main
```

### Release de Emergência
```bash
# Fix crítico
git commit -m "fix: corrigir vulnerabilidade de segurança"
git push origin main

# Ou forçar release imediato via Actions
# GitHub → Actions → Release → Run workflow
```

### Preparação para Major Release
```bash
# Commits com breaking changes
git commit -m "feat!: reestruturar API de plugins"
git commit -m "feat!: alterar formato de configuração"

# Push - major release será criado automaticamente
git push origin main
```

---

## 📞 Suporte

Para dúvidas ou problemas com o sistema de release:
1. Verifique a documentação acima
2. Consulte os logs dos workflows no GitHub Actions
3. Abra uma issue no repositório