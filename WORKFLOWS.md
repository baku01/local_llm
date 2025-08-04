# 🚀 Workflows de CI/CD

Este documento descreve os workflows de CI/CD implementados no projeto Local LLM.

## 📋 Workflows Disponíveis

### 1. 🔄 CI/CD Principal (`ci.yml`)

**Trigger**: Push e Pull Request para `main` e `develop`

**Jobs**:
- **Test & Analysis**: Executa testes, análise estática e verifica formatação
- **Build**: Compila para macOS e Windows
- **Integration**: Executa testes de integração (apenas em push para main)
- **Quality**: Verifica qualidade do código e métricas

**Funcionalidades**:
- ✅ Verificação de formatação de código
- ✅ Análise estática com `flutter analyze`
- ✅ Execução de testes unitários com cobertura
- ✅ Upload de cobertura para Codecov
- ✅ Build para múltiplas plataformas
- ✅ Testes de integração
- ✅ Métricas de qualidade de código

### 2. 📦 Gerenciamento de Dependências (`dependencies.yml`)

**Trigger**: 
- Agendado: Toda segunda-feira às 9h UTC
- Manual: Via workflow_dispatch

**Jobs**:
- **Update Dependencies**: Atualiza dependências e cria PR
- **Check Outdated**: Verifica pacotes desatualizados

**Funcionalidades**:
- ✅ Atualização automática do Flutter SDK
- ✅ Atualização de dependências do projeto
- ✅ Execução de testes após atualizações
- ✅ Verificação de vulnerabilidades de segurança
- ✅ Criação automática de Pull Request
- ✅ Relatório detalhado de mudanças

### 3. 🚀 Release (`release.yml`)

**Trigger**: 
- Push de tags `v*.*.*`
- Manual: Via workflow_dispatch

**Jobs**:
- **Prepare**: Valida versão e executa testes
- **Build**: Compila para todas as plataformas
- **Release**: Cria release no GitHub
- **Notify**: Notificações pós-release

**Funcionalidades**:
- ✅ Validação de versão entre tag e pubspec.yaml
- ✅ Build para macOS e Windows
- ✅ Criação de arquivos compactados
- ✅ Geração automática de changelog
- ✅ Upload de artifacts para GitHub Releases
- ✅ Documentação automática do release

### 4. 🔒 Segurança e Qualidade (`security.yml`)

**Trigger**: 
- Push e Pull Request para `main` e `develop`
- Agendado: Toda sexta-feira às 10h UTC
- Manual: Via workflow_dispatch

**Jobs**:
- **Security Scan**: Análise de segurança
- **Code Quality**: Análise de qualidade de código
- **License Check**: Verificação de licenças

**Funcionalidades**:
- ✅ Verificação de vulnerabilidades de segurança
- ✅ Detecção de secrets hardcoded
- ✅ Verificação de URLs inseguras
- ✅ Análise de permissões de arquivos
- ✅ Métricas de complexidade de código
- ✅ Verificação de conformidade de licenças
- ✅ Relatórios detalhados de segurança e qualidade

## 🛠️ Configuração

### Secrets Necessários

Para funcionamento completo dos workflows, configure os seguintes secrets no GitHub:

```bash
# Opcional: Para upload de cobertura
CODECOV_TOKEN=seu_token_codecov

# Automático: Token do GitHub (já disponível)
GITHUB_TOKEN=automático
```

### Variáveis de Ambiente

Os workflows usam as seguintes variáveis:

```yaml
FLUTTER_VERSION: '3.24.3'
FLUTTER_CHANNEL: 'stable'
```

## 📊 Monitoramento

### Status dos Workflows

Você pode monitorar o status dos workflows em:
- GitHub Actions tab no repositório
- Badges de status (se configurados)
- Notificações por email do GitHub

### Artifacts Gerados

Os workflows geram os seguintes artifacts:

1. **CI Principal**:
   - Relatórios de cobertura
   - Builds para macOS e Windows

2. **Dependências**:
   - Relatório de dependências desatualizadas
   - Changelog de atualizações

3. **Release**:
   - Aplicações compiladas (macOS e Windows)
   - Arquivos compactados para download

4. **Segurança**:
   - Relatório de segurança
   - Relatório de qualidade de código
   - Relatório de licenças

## 🔧 Manutenção

### Atualizações Regulares

1. **Flutter Version**: Atualizar `FLUTTER_VERSION` quando necessário
2. **Actions**: Manter actions do GitHub atualizadas
3. **Dependencies**: Revisar PRs automáticos de dependências

### Troubleshooting

#### Falhas Comuns

1. **Testes falhando**: Verificar logs detalhados no workflow
2. **Build falhando**: Verificar compatibilidade de dependências
3. **Release falhando**: Verificar se versão no pubspec.yaml está correta

#### Logs e Debug

```bash
# Para debug local, execute os mesmos comandos dos workflows:
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
```

## 📈 Métricas e Relatórios

### Cobertura de Código

- Upload automático para Codecov
- Relatórios disponíveis em cada execução
- Meta: Manter cobertura > 80%

### Qualidade de Código

- Análise estática automática
- Verificação de formatação
- Métricas de complexidade
- Relatórios semanais de segurança

### Performance

- Tempo médio de execução dos workflows
- Otimização contínua de cache
- Paralelização de jobs quando possível

## 🎯 Próximos Passos

1. **Integração com Codecov**: Configurar badges de cobertura
2. **Notificações**: Configurar notificações Slack/Discord
3. **Deploy Automático**: Implementar deploy para stores (se aplicável)
4. **Testes E2E**: Adicionar testes end-to-end
5. **Performance Testing**: Adicionar testes de performance

---

**Última atualização**: $(date +"%Y-%m-%d")  
**Versão dos workflows**: 1.0.0  
**Compatibilidade**: Flutter 3.24.3+