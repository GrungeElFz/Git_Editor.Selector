#!/bin/zsh

### BEGIN Git_Editor.Selector CONFIGURATION

# Set your preferred default editor here
DEFAULT_EDITOR="code"  # Change 'code' to your preferred editor command

# <-- DEFAULT EDITORS LIST -->

# Define the EDITORS array with supported editors.
# Each entry consists of "Editor Name:Process Pattern:Editor Command".
EDITORS=(
  "Cursor:Cursor:cursor"
  "VS Code:Visual Studio Code:code"
  "Web Storm:WebStorm:webstorm"
  "Zed:Zed:zed"
)

# Define an associative array of default aliases
typeset -A default_aliases
default_aliases=(
  ["Cursor"]="cur"
  ["VS Code"]="vsc"
  ["Web Storm"]="web"
  ["Zed"]="zed"
)

# Configuration file paths.
CONFIG_DIR="$HOME/.config/git_editor_selector"
ALIASES_FILE="$CONFIG_DIR/aliases.conf"

# Ensure the configuration directory exists
mkdir -p "$CONFIG_DIR"

# <-- HELPER FUNCTIONS -->

# FUNCTION: Load editor aliases from the aliases configuration file.
load_aliases() {
  if [[ ! -f "$ALIASES_FILE" ]]; then
    echo "Aliases configuration file not found at $ALIASES_FILE."
    echo "Please run 'g init' to create it."
    return 1
  fi

  # Read aliases from the configuration file
  while IFS= read -r line; do
    # Remove leading and trailing whitespace
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    # Skip empty lines and comments
    if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
      continue
    fi

    # Skip the [aliases] section header
    if [[ "$line" == "[aliases]" ]]; then
      continue
    fi

    # Split line at the first '=' character
    key="${line%%=*}"
    value="${line#*=}"

    # Remove leading and trailing whitespace from key and value
    key="$(echo "$key" | sed 's/[[:space:]]*$//')"
    value="$(echo "$value" | sed 's/^[[:space:]]*//')"

    # Remove inline comments from value
    value="${value%%\#*}"
    value="$(echo "$value" | sed 's/[[:space:]]*$//')"

    # Create a shell function instead of an alias
    eval "
    $key() {
      open_with_editor '$value' \"\$@\"
    }
    "
  done < "$ALIASES_FILE"
}

# FUNCTION: Perform the initial setup when 'g init' is run.
setup_configuration() {
  echo "Initial setup:"
  echo ""
  echo "Available editors:"

  # Adjust column widths to minimize gaps
  printf "%-5s %-6s %s\n" "No." "Alias" "Editor Name"
  printf "%-5s %-6s %s\n" "---" "-----" "-----------"

  for (( i = 1; i <= ${#EDITORS[@]}; i++ )); do
    editor_info="${EDITORS[$i]}"
    editor_name="${editor_info%%:*}"
    # Check for default alias in the mapping
    if [[ -n "${default_aliases[$editor_name]}" ]]; then
      alias_name="${default_aliases[$editor_name]}"
    else
      # Generate alias if not specified
      alias_name="$(echo "$editor_name" | tr -d ' ' | tr '[:upper:]' '[:lower:]' | cut -c1-3)"
    fi

    printf "%-5s %-6s %s\n" "($i)" "$alias_name" "$editor_name"
  done

  # Ask the user whether to use default aliases
  echo ""
  echo "Use default aliases for the editors? (Y/n)"
  while true; do
    read "use_defaults? 👉 "
    if [[ "$use_defaults" =~ '^[Yy]$|^$' ]]; then
      use_defaults=true
      break
    elif [[ "$use_defaults" =~ ^[Nn]$ ]]; then
      use_defaults=false
      break
    else
      echo "Please enter 'Y' or 'n'."
    fi
  done

  # Create aliases.conf with default or custom aliases
  echo "[aliases]" > "$ALIASES_FILE"

  for editor_info in "${EDITORS[@]}"; do
    editor_name="${editor_info%%:*}"

    # Use the default alias from the mapping or generate one
    if [[ -n "${default_aliases[$editor_name]}" ]]; then
      alias_name="${default_aliases[$editor_name]}"
    else
      alias_name="$(echo "$editor_name" | tr -d ' ' | tr '[:upper:]' '[:lower:]' | cut -c1-3)"
    fi

    if $use_defaults; then
      # Use alias_name as is
      :
    else
      # Ask the user for a custom alias
      read "alias_input?Enter alias for $editor_name (default '$alias_name'): "
      if [[ -n "$alias_input" ]]; then
        alias_name="$alias_input"
      fi
    fi

    echo "$alias_name = $editor_name" >> "$ALIASES_FILE"
  done

  # Ask the user to choose the default editor for 'code' alias
  echo ""
  echo "Select the default editor to be used when you type ' code . ':"

  while true; do
    read "default_choice? 👉 "
    if [[ "$default_choice" =~ ^[0-9]+$ ]] && (( default_choice >= 1 && default_choice <= ${#EDITORS[@]} )); then
      default_editor_info="${EDITORS[$default_choice]}"
      default_editor_name="${default_editor_info%%:*}"
      break
    else
      echo "Please enter a valid number between 1 and ${#EDITORS[@]}."
    fi
  done

  # Add 'code' alias to aliases.conf
  echo "code = $default_editor_name  # Default 'code' alias" >> "$ALIASES_FILE"

  echo ""
  echo "✅ Aliases have been saved to:"
  echo "   $ALIASES_FILE"
  echo ""
  echo "Please restart the shell and terminal to apply."
  echo "(e.g., run ' source ~/.zshrc ' then restart the terminal)"
}

# FUNCTION: Open files/directories with the specified editor
open_with_editor() {
  local editor_name="$1"
  shift
  local editor_command=""
  for editor_info in "${EDITORS[@]}"; do
    local name="${editor_info%%:*}"
    local command="${editor_info##*:}"
    if [[ "$name" == "$editor_name" ]]; then
      editor_command="$command"
      break
    fi
  done

  if [[ -z "$editor_command" ]]; then
    echo "Editor '$editor_name' not found."
    return 1
  fi

  # If no arguments are provided, open the current directory
  if [[ $# -eq 0 ]]; then
    set -- "."
  fi

  # Split editor_command into an array using Zsh parameter expansion
  cmd_array=(${=editor_command})

  # Use 'command' to execute the editor command
  command "${cmd_array[@]}" "$@" || {
    echo "Failed to open the editor. Please check your editor settings."
    return 1
  }
}

# Load editor aliases
load_aliases

# <-- OTHER HELPER FUNCTIONS -->

# FUNCTION: Display a message indicating that the script is checking for running editors.
display_checking_message() {
  echo "Checking for running editors"
  echo "🏃️..."
  echo ""
}

# FUNCTION: Detect running editors based on the EDITORS array.
detect_running_editors() {
  running_editors=()

  for editor_info in "${EDITORS[@]}"; do
    editor_name="${editor_info%%:*}"
    rest="${editor_info#*:}"
    process_pattern="${rest%%:*}"
    editor_command="${rest#*:}"

    # Check if the application is running using osascript
    if osascript -e "tell application \"$process_pattern\" to return running" 2>/dev/null | grep -q "true"; then
      running_editors+=("$editor_name:$editor_command")
    fi
  done

  num_running_editors=${#running_editors[@]}
}

# FUNCTION: Prompt the user to select an editor when multiple editors are running.
prompt_editor_selection() {
  local action="$1"
  echo "Multiple editors are running. Please choose the editor for $action:"

  # Display the list of running editors.
  for (( i = 1; i <= num_running_editors; i++ )); do
    editor_info="${running_editors[$i]}"
    editor_name="${editor_info%%:*}"
    echo "($i) $editor_name"
  done

  while true; do
    read "choice? 👉 "
    if [[ "$choice" =~ ^[nN]$ ]]; then
      echo ""
      echo "Aborting $action."
      return 1 # User aborted the action.
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= num_running_editors )); then
      selected_editor_info="${running_editors[$choice]}"
      selected_editor_name="${selected_editor_info%%:*}"
      selected_editor_command="${selected_editor_info#*:}"
      return 0 # Successful selection.
    else
      echo ""
      echo "🫥 Invalid choice."
      echo "Please enter a valid editor number or 'n' to abort."
    fi
  done
}

# FUNCTION: Determine if the git command requires an editor.
requires_editor() {
  local cmd="$1"
  shift
  local args=("$@")
  local requires=false

  case "$cmd" in
    commit)
      requires=true
      local i=0
      while (( i < ${#args[@]} )); do
        arg="${args[i]}"
        case "$arg" in
          -m|--message)
            requires=false
            break
            ;;
          -m*|--message=*)
            requires=false
            break
            ;;
          *)
            ;;
        esac
        (( i++ ))
      done
      ;;
    merge|cherry-pick|revert)
      requires=true
      for arg in "${args[@]}"; do
        if [[ "$arg" == "--no-edit" ]]; then
            requires=false
            break
        fi
      done
      ;;
    pull)
      requires=false
      for arg in "${args[@]}"; do
        if [[ "$arg" == "--edit" ]]; then
            requires=true
            break
        fi
      done
      ;;
    rebase)
      requires=false
      if [[ "${args[1]}" == "-i" || "${args[1]}" == "--interactive" ]]; then
        requires=true
      fi
      ;;
    tag)
      requires=false
      for arg in "${args[@]}"; do
        if [[ "$arg" == "-a" || "$arg" == "--annotate" ]]; then
          requires=true
          break
        fi
      done
      ;;
    *)
      requires=false
      ;;
  esac

  $requires
}

# FUNCTION: Set GIT_EDITOR based on running editors and user selection.
select_git_editor() {
  local action="$1"

  # Run the editor selection logic to set GIT_EDITOR.
  display_checking_message
  detect_running_editors

  if (( num_running_editors > 1 )); then
    if ! prompt_editor_selection "$action"; then
      return 1  # User aborted the action.
    fi

    echo ""
    echo "Using $selected_editor_name as the git editor."
    SELECTED_EDITOR_COMMAND="$selected_editor_command"
    GIT_EDITOR="$selected_editor_command -w"
  elif (( num_running_editors == 1 )); then
    selected_editor_info="${running_editors[1]}"
    selected_editor_name="${selected_editor_info%%:*}"
    selected_editor_command="${selected_editor_info#*:}"

    echo ""
    echo "Using $selected_editor_name as the git editor."
    SELECTED_EDITOR_COMMAND="$selected_editor_command"
    GIT_EDITOR="$selected_editor_command -w"
  else
    echo "No recognized editor running."
    if [[ -n "$EDITOR" ]]; then
      echo "Defaulting to '$EDITOR'."
      SELECTED_EDITOR_COMMAND="$EDITOR"
      GIT_EDITOR="$EDITOR"
    else
      echo "Environment variable \$EDITOR is not set."
      echo "Defaulting to '$DEFAULT_EDITOR'."
      SELECTED_EDITOR_COMMAND="$DEFAULT_EDITOR"
      GIT_EDITOR="$DEFAULT_EDITOR"
    fi
  fi

  # Export GIT_EDITOR so that it's available to git.
  export GIT_EDITOR
}

# <-- MAIN FUNCTION -->

# FUNCTION: git commands wrapper and handle editor selection.
g() {
  case "$1" in
    setup)
      setup_configuration
      return
    ;;

    config)
      if [[ ! -f "$ALIASES_FILE" ]]; then
        echo "Aliases configuration file not found. Please run 'g init' first."
        return 1
      fi

      # Use editor selection logic
      if ! select_git_editor "editing aliases configuration"; then
        return 1
      fi

      if [[ -z "$SELECTED_EDITOR_COMMAND" ]]; then
        echo "No editor available to open the configuration file."
        return 1
      fi

      echo "Editing aliases configuration with $SELECTED_EDITOR_COMMAND..."

      # Split SELECTED_EDITOR_COMMAND into an array using Zsh parameter expansion
      editor_cmd=(${=SELECTED_EDITOR_COMMAND})

      # Add '-w' to the command to wait for the editor to close
      editor_cmd+=("-w")

      # Open the aliases file with the selected editor
      "${editor_cmd[@]}" "$ALIASES_FILE" || {
        echo "Failed to open the editor. Please check your editor settings."
        return 1
      }

      # Reload the aliases after editing
      load_aliases

      echo ""
      echo "✅ Aliases have been saved to:"
      echo "   $ALIASES_FILE"
      echo ""
      echo "Please restart the shell and terminal to apply."
      echo "(e.g., run ' source ~/.zshrc ' then restart the terminal)"
      return
    ;;

    *)
      local cmd="$1"
      shift
      local args=("$@")

      if requires_editor "$cmd" "${args[@]}"; then
        if ! select_git_editor "git $cmd"; then
          return 1  # User aborted the action.
        fi
      fi

      # Run the git command with any arguments.
      git "$cmd" "${args[@]}"
    ;;

  esac
}

### END Git_Editor.Selector CONFIGURATION
