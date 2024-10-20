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

# Define the 'g' function
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
