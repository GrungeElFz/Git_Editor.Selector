#!/bin/zsh

### BEGIN Git_Editor.Selector CONFIGURATION

# <-- IDE LIST -->

# Define the EDITORS array with supported editors.
# Each entry consists of "Editor Name : Process Pattern : Editor Command".
EDITORS=(
  "VS Code:/Applications/Visual Studio Code.app/Contents/MacOS/Electron:code -w"
  "Zed:zed:zed -w"
  "Cursor:/Applications/Cursor.app/Contents/MacOS/Cursor:cursor -w"
)

# <-- HELPER FUNCTIONS -->

# FUNCTION: Display a message indicating that the script is checking for running editors.
display_checking_message() {
  echo "Checking for running editors"
  echo "🏃️..."
  echo ""
}

# FUNCTION: Detect running editors based on the EDITORS array.
# Populates the 'running_editors' array with the format "Editor Name:Editor Command".
detect_running_editors() {
  running_editors=()

  # Loop through each editor and check if it's running.
  for editor_info in "${EDITORS[@]}"; do
    editor_name="${editor_info%%:*}"        # Extract the editor name.
    rest="${editor_info#*:}"                # Remove editor name and first colon.
    process_pattern="${rest%%:*}"           # Extract the process pattern.
    editor_command="${rest#*:}"             # Extract the editor command.

    # Check if the editor process is running.
    if pgrep -f "$process_pattern" > /dev/null; then
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
    merge|pull|cherry-pick|revert)
      requires=true
      for arg in "${args[@]}"; do
        if [[ "$arg" == "--no-edit" ]]; then
          requires=false
          break
        fi
      done
      ;;
    rebase)
      requires=false
      if [[ "${args[0]}" == "-i" || "${args[0]}" == "--interactive" ]]; then
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

  # Export GIT_EDITOR so that it's available to git.
  export GIT_EDITOR
}

# <-- MAIN FUNCTION -->

# FUNCTION: git commands wrapper and handle editor selection.
g() {
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
}

### END Git_Editor.Selector CONFIGURATION
