# Git Editor Selector

![Git Editor Selector's Banner Image](https://raw.githubusercontent.com/GrungeElFz/Astro_Personal.Site/refs/heads/main/public/Banner-Git_Editor.Selector_Ice.png)

A dynamic `Bash` script that enhances your Git workflow by allowing you to seamlessly select and manage your preferred code editors. Whether you're working on commits, merges, rebases, or other Git operations that require an editor.

> _A documentation website is being developed at the moment : )_

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Initial Setup](#initial-setup)
  - [Editing Aliases](#editing-aliases)
- [Usage](#usage)
  - [Using the Git Wrapper (`g`)](#using-the-git-wrapper-g)
  - [Enhanced Commands](#enhanced-commands)
- [Supported Editors](#supported-editors)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Multiple Editor Support**: Choose from a variety of code editors like VS Code, Zed, Cursor, and more.
- **Dynamic Editor Selection**: Automatically detects running editors and allows you to select which one to use.
- **Custom Aliases**: Define short aliases for your favorite editors for quicker access.
- **Seamless Integration**: Wraps around Git commands to provide an enhanced and customizable Git experience.
- **Easy Configuration**: Simple setup process with interactive prompts to tailor the tool to your needs.

## Prerequisites

- **Operating System**:
  - MacOS (`osascript` for detecting running applications).
  - Linux (`pgrep` for process detection).
- **Shell**: Zsh
- **Git**: Installed and configured on your system.
- **Supported Editors**: Ensure your preferred editors are installed and accessible via command line (e.g., `code` for VS Code, `cursor` for Cursor).

> **Note:**
> Don't forget to install the command-line `PATH` for each IDE to make the IDE accessible from the command line.
> Here’s how you can do it for some common editors:
> [Cursor](https://forum.cursor.com/t/how-to-open-cursor-from-terminal/3757/10),
> [Visual Studio Code](https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line),
> [Zed](https://zed.dev/features#cli).
>
> For JetBrains's IDEs such as [Web Storm](https://www.jetbrains.com/help/webstorm/ƒworking-with-the-ide-features-from-command-line.html) and [PyCharm](https://www.jetbrains.com/help/pycharm/working-with-the-ide-features-from-command-line.html), use [JetBrains Toolbox](https://www.jetbrains.com/toolbox-app) to create command-line launcher.
>
> _i.e.,_
> Toolbox App _->_ Tool actions _->_ Settings _->_ Configuration _->_ Configure shell scripts generation... _->_ Generate shell scripts

## Installation

1. Clone the Repository

   ```zsh
   git clone https://github.com/GrungeElFz/Git_Editor.Selector.git
   ```

2. Navigate to the Directory

   ```zsh
   cd Git_Editor.Selector
   ```

3. Add the Script to Your Zsh Configuration

   You can add the script directly to your `.zshrc` or source it as a separate file.

   - **Option 1**: Directly in `.zshrc`

     Open your .zshrc file:

     ```zsh
     nano ~/.zshrc
     ```

     Paste the contents of the Git_Editor.Selector script into your `.zshrc` file.

     ***

   - **Option 2**: Source as a Separate File

     Save the `Git_Editor.Selector` script to a file (e.g., `~/.zsh/git_editor_selector.zsh`)

     ```zsh
     mkdir -p ~/.zsh
     nano ~/.zsh/git_editor_selector.zsh
     ```

     Paste the script into this file and save.

     Then, add the following line to your .zshrc to source the script:

     ```zsh
     source ~/.zsh/git_editor_selector.zsh
     ```

4. Reload Your `Zsh` Configuration
   ```zsh
   source ~/.zshrc
   ```

## Configuration

### Initial Setup

After installation, perform the initial setup to configure your preferred editors and aliases.

1. Run Initialization Command

   ```zsh
   g setup
   ```

2. Follow the Interactive Prompts

- **Select Editors**: You'll be presented with a list of available editors. Choose the ones you want to configure.

- **Aliases Configuration**: Decide whether to use default aliases or set custom ones for each editor.

- **Default Editor Selection**: Choose which editor should be the default when you execute `code` commands.

3. Restart Your Shell

   To apply the changes, restart the shell andterminal:

   ```zsh
   source ~/.zshrc
   ```

### Editing Aliases

You can edit your editor aliases at any time using the `g config` command.

```zsh
g config
```

This will open the `aliases.conf` file in your selected editor, allowing you to modify aliases as needed. After editing, reload your shell to apply the changes.

## Usage

Git Editor Selector provides a wrapper function `g` that replaces the standard git command, offering enhanced capabilities.

### Using the Git Wrapper (`g`)

#### Standard Commands

All standard Git commands are supported. Use `g` in place of `git`:

```zsh
g add .
g commit -m "Message"
g push origin main
```

#### Enhanced Commands

- Initialization

  ```zsh
  g setup
  ```

  Sets up the Git Editor Selector by configuring editors and aliases.

- Configuration

  ```zsh
  g config
  ```

  Opens the `aliases.conf` file for editing your editor aliases.

- Commit

  ```zsh
  g commit

  Checking for running editors
  🏃️...

  Multiple editors are running. Please choose the editor for git commit:
  (1) Visual Studio Code
  (2) Zed
  (3) Cursor
  👉 2

  Using Zed as the git editor.
  hint: Waiting for your editor to close the file...
  ```

  When multiple editors are active, `g commit` prompts you to select one. It then opens the commit message in the chosen editor and waits for you to close the file.

- Rebase

  ```zsh
  g rebase -i HEAD~5

  Checking for running editors
  🏃️...

  Multiple editors are running. Please choose the editor for git commit:
  (1) Visual Studio Code
  (2) Zed
  (3) Cursor
  👉 3

  Using Cursor as the git editor.
  hint: Waiting for your editor to close the file...
  ```

  Similar to commit, `g rebase -i HEAD~<number>` prompts you to select an editor if multiple are running and initiates an interactive rebase in the chosen editor.

> Note: If there's only one editor running, the script will automatically route to the running one.

## Supported Editors

By default, Git Editor Selector supports the following editors:

1. [Cursor](https://www.cursor.com)

   - Name: Cursor
   - Process Pattern: Cursor
   - Command: `cursor`
   - Alias: `cur`

2. [Visual Studio Code](https://code.visualstudio.com)

   - Name: VS Code
   - Process Pattern: Visual Studio Code
   - Command: `code`
   - Alias: `vsc`

3. [JetBrains: WebStorm](https://www.jetbrains.com/webstorm)

   - Name: Web Storm
   - Process Pattern: Web Storm
   - Command: `webstorm`
   - Alias: `web`

4. [JetBrains: PyCharm (Community Edition)](https://www.jetbrains.com/pycharm/editions)

   - Name: PyCharm (Community Edition)
   - Process Pattern: PyCharm CE
   - Command: `pycharm`
   - Alias: `charmc`

5. [JetBrains: PyCharm (Professional Edition)](https://www.jetbrains.com/pycharm/editions)

   - Name: PyCharm (Professional Edition)
   - Process Pattern: PyCharm
   - Command: `pycharm`
   - Alias: `charmp`

6. [Zed](https://zed.dev)
   - Name: Zed
   - Process Pattern: Zed
   - Command: `zed`
   - Alias: `zed`

### Adding More Editors

To add more editors:

1. Edit the Git_Editor.Selector Script

   Locate the `EDITORS` array in the script and add your editor in the following format:

   ```zsh
   "Editor Name:Process Pattern:Editor Command"
   ```

   Example:

   ```zsh
   EDITORS=(
     "Cursor:Cursor:cursor"
     "Visual Studio Code:Visual Studio Code:code"
     "Web Storm:WebStorm:webstorm"
     "Zed:Zed:zed"
   )
   ```

2. Update Default Aliases

   If you want to set a default alias for the new editor, add it to the `default_aliases` associative array:

   ```zsh
   default_aliases=(
     ["Cursor"]="cur"
     ["Visual Studio Code"]="vsc"
     ["Web Storm"]="web"
     ["Zed"]="zed"
   )
   ```

3. Run Configuration Again

   After making changes, run `g init` to reconfigure aliases.

## Customization

- Default Editor

  Set your preferred default editor by modifying the `DEFAULT_EDITOR` variable in the script:

  ```zsh
  DEFAULT_EDITOR="code"  # Change 'code' to your preferred editor command
  ```

- Aliases Configuration

  Customize your editor aliases by editing the `~/.config/git_editor_selector/aliases.conf` file.

  ```zsh
  [aliases]
    cur = Cursor
    vsc = Visual Studio Code
    web = Web Storm
    zed = Zed
    code = VS Code  # Default 'code' alias
  ```

## Troubleshooting

- Aliases Configuration File Not Found

  If you encounter an error about the aliases configuration file not being found, run:

  ```zsh
  g setup
  ```

- Editor Not Opening

  Ensure that the editor's command is correctly specified and that the editor is installed. You can test the command directly in the terminal:

  ```zsh
  code .
  ```

- Environment Variable `$EDITOR` Not Set

  If no editors are running and the `$EDITOR` environment variable is not set, Git Editor Selector defaults to `DEFAULT_EDITOR`.

  To set `$EDITOR`, add the following to your `.zshrc`:

  ```zsh
  export EDITOR="code"  # Replace 'code' with your preferred editor
  ```

  Then, restart the shell and terminal.

  ```zsh
  source ~/.zshrc
  ```

- Need more help?

  Run `g`, `g help`, `g -h`, or `g --help`:

  ```zsh
  g help
  ```

## Contributing

Contributions are extreamly welcome! If you have suggestions, improvements, or bug fixes, feel free to open an issue or submit a pull request.

1. Fork the Repository

2. Create a Feature Branch

   ```zsh
   git checkout -b feature/YourFeature
   ```

3. Commit Your Changes

   ```zsh
   git commit -m "Add your message here"
   ```

4. Push to the Branch

   ```zsh
   git push origin feature/YourFeature
   ```

5. Open a Pull Request

## Contributors

<a href="https://github.com/GrungeElFz/Git_Editor.Selector/graphs/contributors">
<img src="https://contrib.rocks/image?repo=GrungeElFz/Git_Editor.Selector" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

## License

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
