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
    editor_name="${editor_info%%:*}"           # Extract the editor name before the first colon
    rest="${editor_info#*:}"                   # Remove editor name and first colon
    process_pattern="${rest%%:*}"              # Extract the process pattern before the next colon
    editor_command="${rest#*:}"                # Extract the editor command after the second colon

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

  for (( i=0; i<num_running_editors; i++ )); do
    index=$((i + 1))
    editor_info="${running_editors[$i]}"
    editor_name="${editor_info%%:*}"
    echo "($index) $editor_name"
  done

  while true; do
    # Read user input
    read "choice? 👉 "

    # Validate user input and choose the editor
    if [[ "$choice" =~ ^[nN]$ ]]; then
      echo ""
      echo "Aborting $action."
      return 1  # Indicate that the user aborted the action
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= num_running_editors )); then
      selected_index=$((choice - 1))
      selected_editor_info="${running_editors[$selected_index]}"
      selected_editor_name="${selected_editor_info%%:*}"
      selected_editor_command="${selected_editor_info#*:}"
      return 0  # Successful selection
    else
      echo ""
      echo "🫥 Invalid choice."
      echo "Please enter a valid editor number or 'n' to abort."
    fi
  done
}

git_with_editor() {
  local action="$1"      # Description of the git action (e.g., "git commit")
  local git_command="$2" # The actual git command to run (e.g., "git commit")
  shift 2
  local args=("$@")      # Any additional arguments

  display_checking_message
  detect_running_editors

  # If multiple editors are running, prompt the user to choose one
  if (( num_running_editors > 1 )); then
    if ! prompt_editor_selection "$action"; then
      return 1  # User aborted the action
    fi

    echo ""
    echo "Using $selected_editor_name for $action."

    GIT_EDITOR="$selected_editor_command" $git_command "${args[@]}"
    return 0  # Exit the function after successful command

  # If one editor is running, use it
  elif (( num_running_editors == 1 )); then
    selected_editor_info="${running_editors[0]}"
    selected_editor_name="${selected_editor_info%%:*}"
    selected_editor_command="${selected_editor_info#*:}"

    echo ""
    echo "Using $selected_editor_name for $action."

    GIT_EDITOR="$selected_editor_command" $git_command "${args[@]}"

  # If no editors are running, default to the configured editor
  else
    echo "No recognized editor running."
    echo "Defaulting to '$EDITOR'."
    GIT_EDITOR="$EDITOR" $git_command "${args[@]}"
  fi
}

git_commit() {
  git_with_editor "git commit" "git commit" "$@"
}

git_rebase_i() {
  git_with_editor "git rebase -i" "git rebase -i" "$@"
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
