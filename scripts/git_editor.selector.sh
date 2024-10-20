#!/bin/zsh

### BEGIN Git_Editor.Selector CONFIGURATION

# Define the EDITORS array with supported editors
EDITORS=(
  "VS Code:/Applications/Visual Studio Code.app/Contents/MacOS/Electron:code -w"
  "Zed:zed:zed -w"
  "Cursor:/Applications/Cursor.app/Contents/MacOS/Cursor:cursor -w"
)

# Helper Functions
display_checking_message() {
  echo "Checking for running editors"
  echo "🏃️..."
  echo ""
}

detect_running_editors() {
  running_editors=()

  # Loop through each editor and check if it's running
  for editor_info in "${EDITORS[@]}"; do
    editor_name="${editor_info%%:*}"
    rest="${editor_info#*:}"
    process_pattern="${rest%%:*}"
    editor_command="${rest#*:}"

    # Check if the editor process is running
    if pgrep -f "$process_pattern" > /dev/null; then
      running_editors+=("$editor_name:$editor_command")
    fi
  done

  num_running_editors=${#running_editors[@]}
}

prompt_editor_selection() {
  local action="$1"
  echo "Multiple editors are running. Please choose the editor for $action:"

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
      return 1
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= num_running_editors )); then
      selected_editor_info="${running_editors[$choice]}"
      selected_editor_name="${selected_editor_info%%:*}"
      selected_editor_command="${selected_editor_info#*:}"
      return 0
    else
      echo ""
      echo "🫥 Invalid choice."
      echo "Please enter a valid editor number or 'n' to abort."
    fi
  done
}

# Define the 'g' function
g() {
  local cmd="$1"
  shift
  local requires_editor=false

  if [[ "$cmd" == "commit" ]]; then
    requires_editor=true
    local args=("$@")
    local i=0
    while (( i < ${#args[@]} )); do
      arg="${args[i]}"
      case "$arg" in
        -m|--message)
          requires_editor=false
          break
          ;;
        -m*|--message=*)
          requires_editor=false
          break
          ;;
        *)
          ;;
      esac
      (( i++ ))
    done
  elif [[ "$cmd" == "merge" ]]; then
    requires_editor=true
    for arg in "$@"; do
      if [[ "$arg" == "--no-edit" ]]; then
        requires_editor=false
        break
      fi
    done
  elif [[ "$cmd" == "pull" ]]; then
    requires_editor=true
    for arg in "$@"; do
      if [[ "$arg" == "--no-edit" ]]; then
        requires_editor=false
        break
      fi
    done
  elif [[ "$cmd" == "rebase" ]]; then
    requires_editor=false
    if [[ "$1" == "-i" || "$1" == "--interactive" ]]; then
      requires_editor=true
    fi
  elif [[ "$cmd" == "tag" ]]; then
    requires_editor=false
    for arg in "$@"; do
      if [[ "$arg" == "-a" || "$arg" == "--annotate" ]]; then
        requires_editor=true
        break
      fi
    done
  elif [[ "$cmd" == "cherry-pick" ]]; then
    requires_editor=true
    for arg in "$@"; do
      if [[ "$arg" == "--no-edit" ]]; then
        requires_editor=false
        break
      fi
    done
  elif [[ "$cmd" == "revert" ]]; then
    requires_editor=true
    for arg in "$@"; do
      if [[ "$arg" == "--no-edit" ]]; then
        requires_editor=false
        break
      fi
    done
  fi

  if $requires_editor; then
    # Run the editor selection logic to set GIT_EDITOR
    display_checking_message
    detect_running_editors

    if (( num_running_editors > 1 )); then
      if ! prompt_editor_selection "git $cmd"; then
        return 1  # User aborted the action
      fi

      echo ""
      echo "Using $selected_editor_name as the git editor."
      GIT_EDITOR="$selected_editor_command"
    elif (( num_running_editors == 1 )); then
      selected_editor_info="${running_editors[1]}"
      selected_editor_name="${selected_editor_info%%:*}"
      selected_editor_command="${selected_editor_info#*:}"

      echo ""
      echo "Using $selected_editor_name as the git editor."
      GIT_EDITOR="$selected_editor_command"
    else
      echo "No recognized editor running."
      echo "Defaulting to '$EDITOR'."
      GIT_EDITOR="$EDITOR"
    fi

    # Export GIT_EDITOR so that it's available to git
    export GIT_EDITOR
  fi

  # Run the git command with any arguments
  git "$cmd" "$@"
}

### END Git_Editor.Selector CONFIGURATION
