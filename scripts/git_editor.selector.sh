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

git_with_editor() {
  local action="$1"
  shift
  local git_args=("$@")

  display_checking_message
  detect_running_editors

  if (( num_running_editors > 1 )); then
    if ! prompt_editor_selection "$action"; then
      return 1
    fi

    echo ""
    echo "Using $selected_editor_name for $action."

    GIT_EDITOR="$selected_editor_command" git "${git_args[@]}"
    return 0

  elif (( num_running_editors == 1 )); then
    selected_editor_info="${running_editors[1]}"
    selected_editor_name="${selected_editor_info%%:*}"
    selected_editor_command="${selected_editor_info#*:}"

    echo ""
    echo "Using $selected_editor_name for $action."

    GIT_EDITOR="$selected_editor_command" git "${git_args[@]}"

  else
    echo "No recognized editor running."
    echo "Defaulting to '$EDITOR'."
    GIT_EDITOR="$EDITOR" git "${git_args[@]}"
  fi
}

git_commit() {
  git_with_editor "git commit" commit "$@"
}

git_rebase_i() {
  git_with_editor "git rebase -i" rebase -i "$@"
}

# Define the 'g' function
g() {
  if [[ "$1" == "commit" ]]; then
    shift  # Remove 'commit' from the arguments
    git_commit "$@"  # Call the custom git_commit function
  elif [[ "$1" == "rebase" && "$2" == "-i" ]]; then
    shift 2  # Remove 'rebase' and '-i' from the arguments
    git_rebase_i "$@"  # Call the custom git_rebase_i function
  else
    git "$@"  # Call the regular git command with all arguments
  fi
}

### END Git_Editor.Selector CONFIGURATION
