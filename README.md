# Local LLM Desktop Client

![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1-blue?style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)

## 1. Visão Geral do Projeto

O Local LLM é uma aplicação de desktop nativa, desenvolvida com o framework Flutter, projetada para fornecer uma interface de usuário elegante e performática para interação com Grandes Modelos de Linguagem (LLMs) executados localmente através do
[Ollama](https://ollama.ai/).

Este projeto foi concebido para oferecer aos usuários uma maneira segura, privada e eficiente de interagir com diversos modelos de IA sem depender de serviços em nuvem.
Ao se conectar a uma instância local do Ollama, a aplicação garante que todos os dados permaneçam na máquina do usuário,
proporcionando total privacidade e operação offline.
A arquitetura foi planejada para ser robusta e escalável,
utilizando as melhores práticas do ecossistema Flutter para desenvolvimento desktop em macOS e Windows.

## 2. Principais Funcionalidades

- **Interface de Usuário Adaptativa:** Construída com um design responsivo que se ajusta perfeitamente a diferentes resoluções e tamanhos de tela,
garantindo uma experiência de usuário consistente e otimizada.
- **Renderização Avançada de Markdown:** Suporte completo para a sintaxe Markdown nas respostas do modelo,
incluindo renderização de tabelas, listas e blocos de código com destaque de sintaxe (`syntax highlighting`).
- **Temas Claro e Escuro:** Suporte nativo para temas claro e escuro,
com transição suave e adaptação automática às preferências do sistema operacional.
- **Animações Fluidas:** A interface é enriquecida com animações sutis e significativas que melhoram a usabilidade
e proporcionam uma experiência mais agradável.
- **Gerenciamento de Janela Personalizado:** Controles de janela customizados (`minimize`, `maximize`, `close`)
que se integram ao design da aplicação, oferecendo uma aparência coesa e nativa.
- **Comunicação Direta com Ollama:** A interação com a API do Ollama é feita localmente,
o que assegura baixa latência, alta velocidade de resposta e independência de conexão com a internet.

## 3. Guia de Instalação e Execução

Para compilar e executar o projeto em seu ambiente de desenvolvimento,
siga os passos abaixo.

### 3.1. Pré-requisitos

Certifique-se de que os seguintes componentes estão instalados e configurados em sua máquina:

- **Flutter SDK:** Versão `3.24.0` ou superior.
- **Ollama:** A plataforma [Ollama](https://ollama.ai/) deve estar instalada e em execução.
- **IDE:** Um editor de código como Visual Studio Code ou Android Studio.

### 3.2. Passos de Instalação



## 4. Arquitetura e Tecnologias

O projeto é estruturado em torno de um conjunto de pacotes de alta qualidade do ecossistema Flutter,
selecionados para garantir performance e manutenibilidade.

- **Gerenciamento de Estado:** `provider` é utilizado para o gerenciamento de estado de forma simples e reativa.
- **Comunicação de Rede:** `dio` é responsável por realizar as chamadas HTTP para a API do Ollama de forma eficiente e confiável.
- **Interface e Experiência do Usuário:**
  - `responsive_framework`: Facilita a criação de layouts responsivos.
  - `adaptive_theme`: Gerencia os temas claro e escuro da aplicação.
  - `google_fonts`: Fornece uma vasta gama de fontes para uma tipografia elegante.
  - `flutter_animate`: Utilizado para a criação de animações complexas de forma declarativa.
- **Processamento de Texto e Código:**
  - `markdown_widget`: Renderiza o conteúdo Markdown recebido dos modelos.
  - `code_text_field`: Oferece um campo de texto com destaque de sintaxe para visualização de código.
- **Integração com Desktop:** `window_manager` permite a personalização e o controle do comportamento da janela da aplicação.
Uma lista exaustiva de todas as dependências pode ser encontrada no arquivo `pubspec.yaml`.

## 5. Roadmap de Desenvolvimento

### **Infraestrutura e Qualidade**

#### Core System
- [ ] Implementar sistema de logging estruturado com rotação de arquivos
- [ ] Configurar sistema centralizado de tratamento de exceções
- [ ] Implementar retry patterns para operações de rede críticas
- [ ] Adicionar sistema de cache inteligente para configurações e dados frequentemente acessados
- [ ] Otimizar inicialização da aplicação com lazy loading de dependências

#### Testing & Quality Assurance
- [ ] Expandir cobertura de testes unitários para repositórios e casos de uso
- [ ] Implementar testes de integração para fluxos críticos da aplicação
- [ ] Configurar testes automatizados para componentes de UI
- [ ] Estabelecer pipeline de CI/CD com análise de qualidade de código
- [ ] Implementar testes de performance para operações custosas

#### Error Handling & Monitoring
- [ ] Desenvolver sistema unificado de apresentação de erros ao usuário
- [ ] Implementar fallback mechanisms para falhas de conectividade
- [ ] Adicionar monitoramento de performance em tempo real
- [ ] Configurar crash reporting para builds de produção

### **Funcionalidades do Domínio**

#### Model Management
- [ ] Criar interface para listagem e gerenciamento de modelos Ollama instalados
- [ ] Implementar funcionalidade de download/instalação de modelos via UI
- [ ] Adicionar visualização de informações detalhadas dos modelos (tamanho, versão, capabilities)
- [ ] Desenvolver sistema de exclusão segura de modelos não utilizados
- [ ] Implementar configurações avançadas por modelo (temperatura, top-p, max tokens)

#### Conversation Management
- [ ] Desenvolver sistema de persistência para histórico de conversas
- [ ] Implementar busca full-text no histórico de conversas
- [ ] Criar funcionalidade de organização por tags e categorias
- [ ] Adicionar sistema de export/import de conversas em múltiplos formatos
- [ ] Implementar sistema de múltiplas conversas com interface de abas

#### Data Persistence
- [ ] Integrar banco de dados local (SQLite/Drift) para armazenamento persistente
- [ ] Implementar sistema de backup automático local
- [ ] Desenvolver funcionalidades de migração de dados entre versões
- [ ] Criar sistema de configurações de retenção de dados

### **Interface e Experiência do Usuário**

#### UI/UX Enhancements
- [ ] Implementar sistema de temas customizáveis além dos padrões claro/escuro
- [ ] Desenvolver configurações avançadas de interface (fontes, tamanhos, densidade)
- [ ] Adicionar indicadores visuais de progresso mais granulares
- [ ] Implementar feedback háptico para ações importantes (desktop)
- [ ] Otimizar responsividade para diferentes resoluções de tela

#### Advanced UI Components
- [ ] Desenvolver componente de editor de texto mais avançado com syntax highlighting
- [ ] Implementar sistema de auto-complete para prompts frequentes
- [ ] Criar interface de configuração visual para parâmetros de modelo
- [ ] Adicionar suporte a drag-and-drop para arquivos e imagens

#### Accessibility & Internationalization
- [ ] Implementar suporte completo a acessibilidade (screen readers, navegação por teclado)
- [ ] Adicionar suporte a múltiplos idiomas (i18n)
- [ ] Configurar temas de alto contraste para acessibilidade
- [ ] Implementar atalhos de teclado configuráveis

### **Integrações e Conectividade**

#### External Integrations
- [ ] Desenvolver sistema de plugins/extensões
- [ ] Implementar integração com editores de código populares
- [ ] Criar funcionalidades de export direto para Notion, Obsidian, etc.
- [ ] Adicionar suporte a webhooks para automação

#### Network & Communication
- [ ] Otimizar comunicação com API do Ollama com connection pooling
- [ ] Implementar suporte a múltiplas instâncias Ollama simultâneas
- [ ] Adicionar configuração de proxy e certificados SSL customizados
- [ ] Desenvolver modo offline com sincronização posterior

### **Performance e Otimização**

#### Memory & Performance
- [ ] Implementar garbage collection otimizado para conversas longas
- [ ] Adicionar lazy loading para componentes pesados da UI
- [ ] Otimizar rendering de markdown para documentos extensos
- [ ] Implementar virtualização para listas de conversas extensas

#### Caching & Storage
- [ ] Desenvolver sistema de cache inteligente para responses frequentes
- [ ] Implementar compressão de dados para armazenamento local
- [ ] Otimizar gerenciamento de memória para modelos grandes
- [ ] Adicionar limpeza automática de cache antigo

### **Extensibilidade e Arquitetura**

#### Architecture Improvements
- [ ] Refatorar para implementação completa de Clean Architecture
- [ ] Implementar pattern de Event Sourcing para auditoria de ações
- [ ] Desenvolver sistema de middleware para operações transversais
- [ ] Criar abstrações para futuras integrações com outros providers LLM

#### Developer Experience
- [ ] Documentar APIs internas para desenvolvimento de plugins
- [ ] Criar ferramentas de debug e profiling para desenvolvedores
- [ ] Implementar hot reload para desenvolvimento de temas
- [ ] Estabelecer padrões de contribuição e review de código

### **Expansão de Plataforma**

#### Multi-Platform Support
- [ ] Adaptar aplicação para Linux (AppImage, Snap, Flatpak)
- [ ] Desenvolver versão web/PWA mantendo funcionalidades core
- [ ] Otimizar para diferentes window managers no Linux
- [ ] Implementar auto-updater cross-platform

#### Mobile & Responsive
- [ ] Criar layouts otimizados para tablets
- [ ] Implementar gestos touch para navegação
- [ ] Adaptar componentes para uso em telas pequenas
- [ ] Desenvolver modo compacto para uso em dispositivos limitados

### **Funcionalidades Avançadas**

#### AI & ML Enhancements
- [ ] Implementar suporte a modelos multimodais (texto + imagem)
- [ ] Adicionar análise de sentimento e contexto das conversas
- [ ] Desenvolver sistema de sugestões inteligentes baseado no histórico
- [ ] Implementar funcionalidades de síntese e resumo automático

#### Collaboration & Sharing
- [ ] Criar sistema de compartilhamento de conversas
- [ ] Implementar funcionalidades de colaboração em tempo real
- [ ] Desenvolver sistema de comentários e anotações
- [ ] Adicionar modo de apresentação para demonstrações

### **Status Atual do Projeto**
- ✅ Arquitetura base implementada com Clean Architecture
- ✅ Interface principal funcional e responsiva
- ✅ Integração completa com API Ollama
- ✅ Sistema de temas claro/escuro
- ✅ Documentação completa do código fonte
- ✅ Web scraping para enriquecimento de contexto
- ✅ Suporte a streaming de respostas
- ✅ Sistema de pesquisa web integrado

## 6. Licença

Este projeto é distribuído sob a Licença MIT.
Consulte o arquivo `LICENSE` para obter mais detalhes.

