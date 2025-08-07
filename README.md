# Local LLM Desktop Client

[![Flutter](https://img.shields.io/badge/Flutter-3.27.0-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.0-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![CI/CD](https://img.shields.io/github/actions/workflow/status/l0gic_b0mb/local_llm/ci.yml?style=flat-square&label=CI%2FCD)](https://github.com/l0gic_b0mb/local_llm/actions)

## Visão Geral

O Local LLM é uma aplicação desktop desenvolvida em Flutter que fornece uma interface profissional para interação com Modelos de Linguagem de Grande Escala (LLMs) executados localmente através do Ollama. A aplicação foi projetada seguindo princípios de arquitetura limpa, garantindo manutenibilidade, escalabilidade e testabilidade.

## Características Principais

### Arquitetura e Design

- **Clean Architecture**: Implementação rigorosa com separação clara entre camadas de apresentação, domínio e dados
- **Injeção de Dependências**: Sistema robusto para gerenciamento de dependências e testabilidade
- **Padrões de Projeto**: Utilização de Repository Pattern, Use Cases e princípios SOLID
- **Cobertura de Testes**: Testes unitários e de integração com cobertura superior a 85%

### Funcionalidades Técnicas

- **Integração com Ollama**: Comunicação eficiente com API local para processamento de LLMs
- **Sistema de Busca Avançado**: Implementação multi-estratégia com fallback automático
  - Suporte para Google, Bing, DuckDuckGo e busca local
  - Circuit Breaker Pattern para tolerância a falhas
  - Rate Limiting com algoritmos token bucket e sliding window
  - Cache inteligente com TTL configurável
- **Streaming de Respostas**: Processamento em tempo real com renderização incremental
- **Análise de Relevância**: Algoritmos customizados para filtragem e ordenação de resultados

### Interface e Experiência

- **Design Responsivo**: Adaptação automática para diferentes resoluções e tamanhos de tela
- **Temas Dinâmicos**: Suporte completo para temas claro e escuro
- **Renderização Markdown**: Processamento avançado com syntax highlighting
- **Performance Otimizada**: Virtualização de listas e gerenciamento eficiente de estado

## Requisitos do Sistema

### Dependências Obrigatórias

- Flutter SDK 3.27.0 ou superior
- Dart SDK 3.5.0 ou superior
- Ollama instalado e configurado localmente
- Sistema operacional: Windows 10+, macOS 10.15+, ou Linux (Ubuntu 20.04+)

### Requisitos de Hardware

- Processador: x64 com suporte AVX2 (recomendado para Ollama)
- Memória RAM: Mínimo 8GB (16GB recomendado)
- Espaço em disco: 2GB para aplicação + espaço para modelos Ollama

## Instalação

### Configuração do Ambiente

1. Instale o Flutter SDK seguindo a [documentação oficial](https://flutter.dev/docs/get-started/install)
2. Instale o Ollama através do [site oficial](https://ollama.ai/)
3. Configure as variáveis de ambiente necessárias

### Compilação da Aplicação

```bash
# Clone o repositório
git clone https://github.com/l0gic_b0mb/local_llm.git
cd local_llm

# Instale as dependências
flutter pub get

# Execute a aplicação em modo desenvolvimento
flutter run -d windows  # ou macos, linux

# Compile para produção
flutter build windows --release
```

### Configuração do Ollama

```bash
# Inicie o serviço Ollama
ollama serve

# Baixe os modelos desejados
ollama pull llama2
ollama pull codellama
ollama pull mistral

# Verifique os modelos disponíveis
ollama list
```

## Arquitetura do Sistema

### Estrutura de Camadas

```
lib/
├── domain/           # Regras de negócio e interfaces
│   ├── entities/     # Modelos de domínio
│   ├── repositories/ # Contratos de repositório
│   └── usecases/     # Casos de uso da aplicação
├── infrastructure/   # Implementações concretas
│   ├── core/         # Serviços centrais
│   ├── datasources/  # Fontes de dados
│   └── repositories/ # Implementações de repositório
├── application/      # Lógica de aplicação
└── presentation/     # Interface do usuário
    ├── pages/        # Telas da aplicação
    ├── widgets/      # Componentes reutilizáveis
    └── providers/    # Gerenciamento de estado
```

### Fluxo de Dados

1. **Camada de Apresentação**: Recebe interações do usuário e delega para controladores
2. **Camada de Aplicação**: Orquestra casos de uso e gerencia o fluxo de dados
3. **Camada de Domínio**: Contém a lógica de negócio independente de implementação
4. **Camada de Infraestrutura**: Implementa comunicação com APIs e serviços externos

## Desenvolvimento

### Padrões de Código

O projeto segue as diretrizes oficiais do Dart e Flutter:
- Análise estática com `dart analyze`
- Formatação com `dart format`
- Convenções de nomenclatura consistentes
- Documentação inline para APIs públicas

### Execução de Testes

```bash
# Testes unitários
flutter test

# Testes com cobertura
flutter test --coverage

# Análise estática
dart analyze

# Verificação de formatação
dart format --set-exit-if-changed .
```

### CI/CD

O projeto utiliza GitHub Actions para integração contínua:
- Análise de código em cada pull request
- Execução automática de testes
- Build e release automatizados para tags
- Verificação de cobertura de código

## Contribuições

Contribuições são aceitas seguindo o fluxo padrão de pull requests:

1. Fork o repositório
2. Crie uma branch para sua funcionalidade (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças seguindo Conventional Commits
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

### Diretrizes para Contribuição

- Mantenha a cobertura de testes acima de 80%
- Siga os padrões de arquitetura estabelecidos
- Documente novas funcionalidades e APIs
- Atualize a documentação quando necessário

## Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## Suporte e Contato

- Issues: [GitHub Issues](https://github.com/l0gic_b0mb/local_llm/issues)
- Discussões: [GitHub Discussions](https://github.com/l0gic_b0mb/local_llm/discussions)
- Wiki: [Documentação Técnica](https://github.com/l0gic_b0mb/local_llm/wiki)

---

Copyright © 2024 Local LLM Contributors. Todos os direitos reservados.