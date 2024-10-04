#!/bin/zsh

### BEGIN Git_Editor.Selector CONFIGURATION

# Define the EDITORS array with supported editors
EDITORS=(
  "VS Code:/Applications/Visual Studio Code.app/Contents/MacOS/Electron:code -w"
  "Zed:zed:zed -w"
  "IntelliJ:idea:idea -w"
  "PyCharm:pycharm:pycharm -w"
  "Eclipse:eclipse:eclipse -w"
  "Sublime Text:subl:subl -w"
  "Atom:/Applications/Atom.app/Contents/MacOS/Atom:atom -w"
  "WebStorm:/Applications/WebStorm.app/Contents/MacOS/WebStorm:webstorm -w"
  "Rider:/Applications/Rider.app/Contents/MacOS/Rider:rider -w"
  "NetBeans:/Applications/NetBeans.app/Contents/MacOS/netbeans:netbeans"
  "Brackets:/Applications/Brackets.app/Contents/MacOS/Brackets:brackets -w"
  "BBEdit:/Applications/BBEdit.app/Contents/MacOS/BBEdit:bbedit -w"
  "Nova:/Applications/Nova.app/Contents/MacOS/Nova:nova -w"
  "Light Table:/Applications/Light\ Table.app/Contents/MacOS/Light\ Table:lighttable -w"
  "Vim:vim:vim"
)

git_commit() {
  echo "Checking for running editors"
  echo "🏃️..."
  echo ""

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

  # If multiple editors are running, prompt the user to choose one
  if (( num_running_editors > 1 )); then
    echo "Multiple editors are running. Please choose the editor for git commit:"

    for i in {1..$num_running_editors}; do
      editor_info="${running_editors[$i]}"
      editor_name="${editor_info%%:*}"
      echo "($i) $editor_name"
    done

    while true; do
      # Read user input
      read "choice? 👉 "

      # Validate user input and choose the editor
      if [[ "$choice" =~ ^[nN]$ ]]; then
        echo ""
        echo "Aborting git commit."
        return 1  # Exit the function without committing
      elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= num_running_editors )); then
        selected_editor_info="${running_editors[$choice]}"
        selected_editor_name="${selected_editor_info%%:*}"
        selected_editor_command="${selected_editor_info#*:}"

        echo ""
        echo "Using $selected_editor_name for git commit."

        GIT_EDITOR="$selected_editor_command" git commit "$@"
        return 0  # Exit the function after successful commit
      else
        echo ""
        echo "🫥 Invalid choice."
        echo "Please enter a valid editor number or 'n' to abort."
        # Re-display the list of editors
        for i in {1..$num_running_editors}; do
          editor_info="${running_editors[$i]}"
          editor_name="${editor_info%%:*}"
          echo "($i) $editor_name"
        done
      fi
    done

  # If one editor is running, use it
  elif (( num_running_editors == 1 )); then
    selected_editor_info="${running_editors[1]}"
    selected_editor_name="${selected_editor_info%%:*}"
    selected_editor_command="${selected_editor_info#*:}"

    echo ""
    echo "Using $selected_editor_name for git commit."

    GIT_EDITOR="$selected_editor_command" git commit "$@"

  # If no editors are running, default to the configured editor
  else
    echo "No recognized editor running."
    echo "Defaulting to '$EDITOR'."
    GIT_EDITOR="$EDITOR" git commit "$@"
  fi
}

# Alias for the custom commit function
alias gcommit='git_commit'

### END Git_Editor.Selector CONFIGURATION
