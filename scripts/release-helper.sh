#!/bin/bash

# Release Helper Script
# Este script ajuda na criação de releases automáticos

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para obter versão atual
get_current_version() {
    grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//'
}

# Função para incrementar versão
increment_version() {
    local version=$1
    local type=$2
    
    IFS='.' read -r major minor patch <<< "$version"
    
    case $type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            log_error "Tipo de versão inválido: $type"
            exit 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Função para analisar commits
analyze_commits() {
    local last_tag=$1
    local commits
    
    if [ -z "$last_tag" ]; then
        commits=$(git log HEAD~10..HEAD --pretty=format:"%s")
    else
        commits=$(git log "$last_tag"..HEAD --pretty=format:"%s")
    fi
    
    local should_release="false"
    local version_bump="patch"
    
    # Verificar se há commits convencionais
    if echo "$commits" | grep -qE "^(feat|fix|perf|refactor)(\(.+\))?: .+"; then
        should_release="true"
        
        # Determinar tipo de bump
        if echo "$commits" | grep -qE "^feat(\(.+\))?: .+"; then
            version_bump="minor"
        fi
        
        if echo "$commits" | grep -qE "BREAKING CHANGE|^feat(\(.+\))?!: |^fix(\(.+\))?!: "; then
            version_bump="major"
        fi
    fi
    
    echo "$should_release:$version_bump"
}

# Função para gerar changelog
generate_changelog() {
    local last_tag=$1
    local version=$2
    
    log_info "Gerando changelog para versão $version..."
    
    local commits
    if [ -z "$last_tag" ]; then
        commits=$(git log HEAD~10..HEAD --pretty=format:"- %s")
    else
        commits=$(git log "$last_tag"..HEAD --pretty=format:"- %s")
    fi
    
    cat > CHANGELOG.tmp << EOF
## 🚀 Local LLM v$version

### 📱 Aplicação Desktop para LLMs Locais

Esta versão inclui:

### 🔄 Mudanças:
$commits

### 📦 Downloads Disponíveis:
- **macOS**: local_llm-macos.zip
- **Windows**: local_llm-windows.zip

### 📋 Requisitos do Sistema:
- **macOS**: macOS 10.14 ou superior
- **Windows**: Windows 10 ou superior
- **Ollama**: Necessário para executar modelos LLM locais

### 🛠️ Instalação:
1. Baixe o arquivo correspondente ao seu sistema operacional
2. Extraia o arquivo
3. Execute o aplicativo
4. Certifique-se de que o Ollama está instalado e rodando

---

**Versão completa**: v$version  
**Data de build**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")  
**Commit**: $(git rev-parse HEAD)
EOF
    
    log_success "Changelog gerado em CHANGELOG.tmp"
}

# Função principal
main() {
    log_info "🚀 Release Helper - Local LLM"
    echo
    
    # Verificar se estamos na raiz do projeto
    if [ ! -f "pubspec.yaml" ]; then
        log_error "Este script deve ser executado na raiz do projeto Flutter"
        exit 1
    fi
    
    # Obter versão atual
    local current_version
    current_version=$(get_current_version)
    log_info "Versão atual: $current_version"
    
    # Obter último tag
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$last_tag" ]; then
        log_info "Último tag: $last_tag"
    else
        log_warning "Nenhum tag encontrado"
    fi
    
    # Analisar commits
    local analysis
    analysis=$(analyze_commits "$last_tag")
    IFS=':' read -r should_release version_bump <<< "$analysis"
    
    if [ "$should_release" = "false" ]; then
        log_warning "Nenhuma mudança significativa detectada para release"
        echo
        log_info "Para forçar um release, use um dos seguintes comandos:"
        echo "  $0 patch   # Incrementa versão patch (1.0.0 -> 1.0.1)"
        echo "  $0 minor   # Incrementa versão minor (1.0.0 -> 1.1.0)"
        echo "  $0 major   # Incrementa versão major (1.0.0 -> 2.0.0)"
        exit 0
    fi
    
    # Permitir override do tipo de bump
    if [ $# -gt 0 ]; then
        version_bump=$1
    fi
    
    # Calcular nova versão
    local new_version
    new_version=$(increment_version "$current_version" "$version_bump")
    
    log_info "Tipo de release detectado: $version_bump"
    log_info "Nova versão será: $new_version"
    echo
    
    # Confirmar com usuário
    read -p "Continuar com o release? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Release cancelado pelo usuário"
        exit 0
    fi
    
    # Gerar changelog
    generate_changelog "$last_tag" "$new_version"
    
    # Atualizar pubspec.yaml
    log_info "Atualizando pubspec.yaml..."
    sed -i "s/^version: .*/version: $new_version+1/" pubspec.yaml
    log_success "pubspec.yaml atualizado"
    
    # Commit e tag
    log_info "Criando commit e tag..."
    git add pubspec.yaml
    git commit -m "chore(release): bump version to $new_version"
    git tag -a "v$new_version" -m "Release v$new_version"
    
    log_success "Commit e tag criados"
    echo
    log_info "Para completar o release, execute:"
    echo "  git push origin main"
    echo "  git push origin v$new_version"
    echo
    log_info "Ou use o GitHub Actions para release automático"
    
    # Cleanup
    rm -f CHANGELOG.tmp
}

# Executar função principal
main "$@"