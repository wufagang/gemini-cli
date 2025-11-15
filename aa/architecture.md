# Gemini CLI - Detailed Architecture

This document provides a more detailed look at the Gemini CLI's architecture,
breaking down the core packages into their primary responsibilities and showing
their interactions.

## Core Packages

- **`packages/cli`**: The user-facing layer. It's responsible for parsing
  arguments, rendering the UI (using Ink), and dispatching commands. It is the
  main entry point for the interactive application.
- **`packages/core`**: The brain of the application. It contains all the
  business logic, including communication with the Google AI APIs, tool
  management, configuration, and state management. It is designed to be
  environment-agnostic.
- **`packages/a2a-server`**: An agent-to-agent communication server. This allows
  other processes, like the VS Code extension, to communicate with a running CLI
  instance, enabling IDE integration.
- **`packages/vscode-ide-companion`**: The VS Code extension, which acts as
  another user-facing client, leveraging the `a2a-server` to interact with the
  core logic.

## Detailed Mermaid Diagram

```mermaid
graph TD
    subgraph User "User"
        direction LR
        UserInput["Terminal Input"]
        IDEAction["VS Code Action"]
    end

    subgraph CLI_Package [packages/cli]
        direction TB
        CLI_Entry["Entrypoint (gemini.tsx / nonInteractiveCli.ts)"]
        CLI_UI["UI Layer (Ink Components in ui/)"]
        CLI_Commands["Command Dispatcher (commands/)"]

        CLI_Entry --> CLI_Commands
        CLI_Entry --> CLI_UI
    end

    subgraph Core_Package [packages/core]
        direction TB
        Core_Agent["Main Agent (agents/)"]
        Core_Tools["Tool System (tools/)"]
        Core_Services["Google AI Service (services/)"]
        Core_Config["Config Loader (config/)"]
        Core_Context["Context Manager"]

        Core_Agent --> Core_Tools
        Core_Agent --> Core_Services
        Core_Agent --> Core_Context
    end

    subgraph IDE_Integration [IDE Integration]
        direction TB
        VSCode_Ext["packages/vscode-ide-companion"]
        A2A_Server["packages/a2a-server"]

        VSCode_Ext -- "IPC" --> A2A_Server
    end

    %% Data Flow
    UserInput --> CLI_Entry
    CLI_Commands -- "Executes Command" --> Core_Agent
    Core_Agent -- "Processes Logic" --> Core_Agent
    Core_Services -- "API Calls" --> GoogleAI_API[(Google AI API)]
    Core_Tools -- "Executes Tools" --> Shell[/Shell & Filesystem/]
    Core_Agent -- "Updates State" --> CLI_UI

    A2A_Server -- "Forwards Actions" --> Core_Agent
    IDEAction --> VSCode_Ext

    %% Dependencies
    CLI_Package -.-> Core_Package
    A2A_Server -.-> Core_Package
    VSCode_Ext -.-> A2A_Server
```

## Architectural Flow

1.  **Initialization**: The `cli` package starts, loading the configuration via
    the `core` package's `Config Loader`.
2.  **User Input**: The user enters a command in the terminal. The `UI Layer`
    captures this input.
3.  **Command Dispatch**: The `Command Dispatcher` in the `cli` package
    identifies the command and passes it to the `core` package.
4.  **Core Logic**: The `Main Agent` in `core` receives the request. It manages
    the conversation history (`Context Manager`) and decides whether to call the
    Google AI API or execute a local tool.
5.  **Tool Execution**: If a tool is needed, the `Tool System` is invoked, which
    might interact with the local shell or filesystem.
6.  **API Call**: If the model is needed, the `Google AI Service` makes a
    request to the external API.
7.  **Response**: The `Main Agent` processes the result from the tool or API.
8.  **UI Update**: The result is sent back to the `cli` package, and the
    `UI Layer` updates to display the output to the user.
9.  **IDE Integration**: Separately, the `VS Code Extension` can send commands
    through the `a2a-server`, which directly interfaces with the `Main Agent` in
    `core`, allowing IDE actions to trigger core functionalities.
