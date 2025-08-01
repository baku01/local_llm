# Local LLM Desktop Client

![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1-blue?style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)

## 1. Visão Geral do Projeto

O Local LLM é uma aplicação de desktop nativa, desenvolvida com o framework Flutter, projetada para fornecer uma interface de usuário elegante e performática para interação com Grandes Modelos de Linguagem (LLMs) executados localmente através do [Ollama](https://ollama.ai/).

Este projeto foi concebido para oferecer aos usuários uma maneira segura, privada e eficiente de interagir com diversos modelos de IA sem depender de serviços em nuvem. Ao se conectar a uma instância local do Ollama, a aplicação garante que todos os dados permaneçam na máquina do usuário, proporcionando total privacidade e operação offline. A arquitetura foi planejada para ser robusta e escalável, utilizando as melhores práticas do ecossistema Flutter para desenvolvimento desktop em macOS e Windows.

## 2. Principais Funcionalidades

-   **Interface de Usuário Adaptativa:** Construída com um design responsivo que se ajusta perfeitamente a diferentes resoluções e tamanhos de tela, garantindo uma experiência de usuário consistente e otimizada.
-   **Renderização Avançada de Markdown:** Suporte completo para a sintaxe Markdown nas respostas do modelo, incluindo renderização de tabelas, listas e blocos de código com destaque de sintaxe (`syntax highlighting`).
-   **Temas Claro e Escuro:** Suporte nativo para temas claro e escuro, com transição suave e adaptação automática às preferências do sistema operacional.
-   **Animações Fluidas:** A interface é enriquecida com animações sutis e significativas que melhoram a usabilidade e proporcionam uma experiência mais agradável.
-   **Gerenciamento de Janela Personalizado:** Controles de janela customizados (`minimize`, `maximize`, `close`) que se integram ao design da aplicação, oferecendo uma aparência coesa e nativa.
-   **Comunicação Direta com Ollama:** A interação com a API do Ollama é feita localmente, o que assegura baixa latência, alta velocidade de resposta e independência de conexão com a internet.

## 3. Guia de Instalação e Execução

Para compilar e executar o projeto em seu ambiente de desenvolvimento, siga os passos abaixo.

### 3.1. Pré-requisitos

Certifique-se de que os seguintes componentes estão instalados e configurados em sua máquina:

-   **Flutter SDK:** Versão `3.24.0` ou superior.
-   **Ollama:** A plataforma [Ollama](https://ollama.ai/) deve estar instalada e em execução.
-   **IDE:** Um editor de código como Visual Studio Code ou Android Studio.

### 3.2. Passos de Instalação

1.  **Clone o repositório do projeto:**
    ```sh
    git clone https://github.com/baku01/local_llm.git
    ```
2.  **Acesse o diretório do projeto:**
    ```sh
    cd local_llm
    ```
3.  **Instale as dependências Dart/Flutter:**
    ```sh
    flutter pub get
    ```
4.  **Execute a aplicação:**
    ```sh
    flutter run
    ```
    Para executar em uma plataforma específica (macOS ou Windows), utilize o argumento `-d`:
    ```sh
    flutter run -d macos
    # ou
    flutter run -d windows
    ```

## 4. Arquitetura e Tecnologias

O projeto é estruturado em torno de um conjunto de pacotes de alta qualidade do ecossistema Flutter, selecionados para garantir performance e manutenibilidade.

-   **Gerenciamento de Estado:** `provider` é utilizado para o gerenciamento de estado de forma simples e reativa.
-   **Comunicação de Rede:** `dio` é responsável por realizar as chamadas HTTP para a API do Ollama de forma eficiente e confiável.
-   **Interface e Experiência do Usuário:**
    -   `responsive_framework`: Facilita a criação de layouts responsivos.
    -   `adaptive_theme`: Gerencia os temas claro e escuro da aplicação.
    -   `google_fonts`: Fornece uma vasta gama de fontes para uma tipografia elegante.
    -   `flutter_animate`: Utilizado para a criação de animações complexas de forma declarativa.
-   **Processamento de Texto e Código:**
    -   `markdown_widget`: Renderiza o conteúdo Markdown recebido dos modelos.
    -   `code_text_field`: Oferece um campo de texto com destaque de sintaxe para visualização de código.
-   **Integração com Desktop:** `window_manager` permite a personalização e o controle do comportamento da janela da aplicação.

Uma lista exaustiva de todas as dependências pode ser encontrada no arquivo `pubspec.yaml`.

## 5. Pontos de Refatoração e Melhorias Futuras

Para aprimorar a qualidade do código, a escalabilidade e a funcionalidade do projeto, os seguintes pontos são sugeridos para futuras iterações:

-   **Arquitetura de Estado:**
    -   **Migração do Gerenciador de Estado:** Para aplicações mais complexas, considerar a migração do `provider` para uma solução mais robusta como `Riverpod` ou `BLoC`, que oferecem melhor separação de responsabilidades e facilitam os testes.
-   **Qualidade de Código e Padrões:**
    -   **Injeção de Dependência:** Implementar um padrão formal de Injeção de Dependência (DI) para desacoplar as camadas de serviço, repositório e UI.
    -   **Tratamento de Erros Centralizado:** Desenvolver um sistema de tratamento de erros mais sofisticado, que possa capturar, registrar e apresentar falhas de forma consistente em toda a aplicação.
    -   **Cobertura de Testes:** Aumentar a cobertura de testes, incluindo testes de unidade para a lógica de negócios, testes de widget para os componentes de UI e testes de integração para os fluxos principais.
-   **Novas Funcionalidades:**
    -   **Gerenciamento de Modelos:** Adicionar uma interface para gerenciar os modelos do Ollama (listar, baixar e excluir) diretamente da aplicação.
    -   **Persistência de Histórico:** Implementar uma solução de banco de dados local (como `sembast`, `Isar` ou `Drift`) para salvar o histórico de conversas.
    -   **Múltiplas Conversas:** Permitir que o usuário gerencie múltiplas conversas simultaneamente em abas ou em uma barra lateral.

## 6. Contribuições

Contribuições são fundamentais para o sucesso de projetos de código aberto. Toda e qualquer contribuição é **extremamente bem-vinda**.

Se você deseja contribuir, por favor, siga os passos abaixo:

1.  Realize um Fork do projeto.
2.  Crie uma nova Branch para a sua feature (`git checkout -b feature/AmazingFeature`).
3.  Faça o Commit de suas alterações (`git commit -m 'Add some AmazingFeature'`).
4.  Faça o Push para a Branch (`git push origin feature/AmazingFeature`).
5.  Abra um Pull Request.

Alternativamente, você pode abrir uma issue com a tag `enhancement` para sugerir novas funcionalidades ou melhorias.

## 7. Licença

Este projeto é distribuído sob a Licença MIT. Consulte o arquivo `LICENSE` para obter mais detalhes.
# local_llm
