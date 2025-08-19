#!/bin/bash

# Spec-Driven Development Tool
# Main script for managing LLM-assisted development workflow

set -e # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FORM="$SCRIPT_DIR/requirements_form.md"              # Template in script directory
TEMPLATE_PROMPT="$SCRIPT_DIR/requirements_prompt.md"          # Stays with script
DESIGN_PROMPT="$SCRIPT_DIR/design_prompt.md"                  # Design template
REQUIREMENTS_SCRIPT="$SCRIPT_DIR/generate_requirements.sh"    # Script location
DESIGN_SCRIPT="$SCRIPT_DIR/generate_design.sh"                # Design script
IMPLEMENTATION_SCRIPT="$SCRIPT_DIR/generate_implementation.sh" # Implementation script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_prompt() {
  echo -e "${CYAN}[PROMPT]${NC} $1"
}

# Show usage information
show_usage() {
  echo "Spec-Driven Development Tool"
  echo "A terminal-based solution for LLM-assisted spec-driven development"
  echo
  echo "Usage: $0 <command>"
  echo
  echo "Commands:"
  echo "  new             Start a new project (interactive setup)"
  echo "  requirements    Generate requirements document for current project"
  echo "  design          Generate design document from requirements"
  echo "  implementation  Generate implementation plan from design"
  echo "  help            Show this help message"
  echo
  echo "Workflow:"
  echo "  1. Run '$0 new' to create a new project directory and requirements form"
  echo "  2. Fill out the requirements form with your project details"
  echo "  3. Run '$0 requirements' to generate the requirements document"
  echo "  4. Run '$0 design' to generate the design document"
  echo "  5. Run '$0 implementation' to generate the implementation plan"
  echo
  echo "Examples:"
  echo "  $0 new                           # Start new project setup"
  echo "  cd my-project && $0 requirements # Generate requirements from project directory"
  echo "  cd my-project && $0 design       # Generate design from requirements"
  echo "  cd my-project && $0 implementation # Generate implementation plan from design"
  echo "  $0 help                          # Show this help"
}

# Check if template files exist
check_templates() {
  local missing_files=()

  if [[ ! -f "$TEMPLATE_FORM" ]]; then
    missing_files+=("requirements_form.md")
  fi

  if [[ ! -f "$TEMPLATE_PROMPT" ]]; then
    missing_files+=("requirements_prompt.md")
  fi

  if [[ ! -f "$DESIGN_PROMPT" ]]; then
    missing_files+=("design_prompt.md")
  fi

  if [[ ! -f "$REQUIREMENTS_SCRIPT" ]]; then
    missing_files+=("generate_requirements.sh")
  fi

  if [[ ! -f "$DESIGN_SCRIPT" ]]; then
    missing_files+=("generate_design.sh")
  fi

  if [[ ! -f "$IMPLEMENTATION_SCRIPT" ]]; then
    missing_files+=("generate_implementation.sh")
  fi

  if [[ ${#missing_files[@]} -gt 0 ]]; then
    log_error "Missing template files in script directory:"
    for file in "${missing_files[@]}"; do
      echo "  - $SCRIPT_DIR/$file"
    done
    echo
    echo "Please ensure all template files are in the same directory as this script:"
    echo "  $SCRIPT_DIR"
    exit 1
  fi
}

# Get user input with prompt
get_input() {
  local prompt="$1"
  local var_name="$2"
  local default="$3"

  if [[ -n "$default" ]]; then
    log_prompt "$prompt [$default]: "
  else
    log_prompt "$prompt: "
  fi

  read -r input

  if [[ -z "$input" && -n "$default" ]]; then
    input="$default"
  fi

  eval "$var_name='$input'"
}

# Validate project directory name
validate_project_name() {
  local name="$1"

  if [[ -z "$name" ]]; then
    log_error "Project name cannot be empty"
    return 1
  fi

  # Check for valid directory name characters
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_error "Project name must contain only letters, numbers, hyphens, and underscores"
    return 1
  fi

  return 0
}

# Create new project
create_new_project() {
  echo "=== New Project Setup ==="
  echo

  # Get project name
  local project_name
  while true; do
    get_input "Enter project name" project_name
    if validate_project_name "$project_name"; then
      break
    fi
  done

  # Get project directory
  local project_dir
  get_input "Enter project directory path" project_dir "./$project_name"

  # Expand tilde and resolve path
  project_dir="${project_dir/#\~/$HOME}"
  project_dir="$(realpath -m "$project_dir")"

  # Check if directory already exists
  if [[ -d "$project_dir" ]]; then
    log_warning "Directory already exists: $project_dir"
    log_prompt "Continue anyway? (y/N): "
    read -r continue_response
    if [[ ! "$continue_response" =~ ^[Yy]$ ]]; then
      log_info "Project creation cancelled"
      exit 0
    fi
  fi

  # Create project directory and specs subdirectory
  log_info "Creating project directory: $project_dir"
  mkdir -p "$project_dir/specs"

  # Copy template files to project directory
  log_info "Setting up project files..."
  cp "$TEMPLATE_FORM" "$project_dir/specs/"
  # Note: prompt template stays in script directory, requirements script will find it

  log_success "Project directory created successfully!"
  echo
  echo "Project: $project_name"
  echo "Location: $project_dir"
  echo "Requirements form: $project_dir/specs/requirements_form.md"
  echo

  # Ask if user wants to open the form in editor
  log_prompt "Open requirements form in default editor? (Y/n): "
  read -r edit_response
  if [[ ! "$edit_response" =~ ^[Nn]$ ]]; then
    log_info "Opening requirements form..."

    # Try to open with default editor
    if command -v xdg-open &>/dev/null; then
      xdg-open "$project_dir/specs/requirements_form.md" &
    elif command -v open &>/dev/null; then
      open "$project_dir/specs/requirements_form.md" &
    elif [[ -n "$EDITOR" ]]; then
      $EDITOR "$project_dir/specs/requirements_form.md"
    else
      log_warning "No default editor found. Please edit manually:"
      echo "  $project_dir/specs/requirements_form.md"
    fi
  fi

  echo
  log_info "Next steps:"
  echo "  1. Fill out the requirements form: $project_dir/specs/requirements_form.md"
  echo "  2. Generate requirements: cd '$project_dir' && '$REQUIREMENTS_SCRIPT'"
  echo

  # Ask if user wants to continue to requirements generation
  log_prompt "Continue to requirements generation now? (y/N): "
  read -r continue_to_requirements
  if [[ "$continue_to_requirements" =~ ^[Yy]$ ]]; then
    echo
    log_info "Switching to project directory and generating requirements..."
    cd "$project_dir"
    "$REQUIREMENTS_SCRIPT"
  else
    log_info "Project setup complete."
    echo "When ready, run: cd '$project_dir' && '$REQUIREMENTS_SCRIPT'"
  fi
}

# Generate requirements document
generate_requirements() {
  echo "=== Requirements Document Generation ==="
  echo

  # Check if we're in a project directory
  if [[ ! -f "specs/requirements_form.md" ]]; then
    log_error "Not in a project directory"
    echo
    echo "This command should be run from a project directory containing:"
    echo "  - requirements_form.md"
    echo
    echo "Create a project first with: $0 new"
    echo "Or run from within an existing project directory."
    exit 1
  fi

  # Run the requirements generation script from its location
  log_info "Running requirements generation..."
  "$REQUIREMENTS_SCRIPT"
}

# Find the most recent requirements document
find_latest_requirements() {
  if [[ ! -d "specs" ]]; then
    return 1
  fi

  local requirements_file
  requirements_file=$(find "specs" -name "requirements_*.md" -type f -exec ls -t {} + 2>/dev/null | head -n1)

  if [[ -z "$requirements_file" || ! -s "$requirements_file" ]]; then
    return 1
  fi

  echo "$requirements_file"
  return 0
}

# Generate design document (internal function for workflow)
generate_design_internal() {
  log_info "Running design generation..."
  "$DESIGN_SCRIPT"
}

# Generate design document (command function)
generate_design() {
  echo "=== Design Document Generation ==="
  echo

  # Check if we're in a project directory
  if [[ ! -f "specs/requirements_form.md" ]]; then
    log_error "Not in a project directory"
    echo
    echo "This command should be run from a project directory containing:"
    echo "  - specs/requirements_form.md"
    echo "  - specs/ directory with requirements document"
    echo
    echo "Create a project first with: $0 new"
    echo "Generate requirements first with: $0 requirements"
    exit 1
  fi

  # Check if requirements document exists
  local latest_requirements
  if ! latest_requirements=$(find_latest_requirements); then
    log_error "No requirements document found"
    echo
    echo "Please generate requirements first with: $0 requirements"
    exit 1
  fi

  log_info "Found requirements document: $latest_requirements"
  generate_design_internal
}

# Find the most recent design document
find_latest_design() {
  if [[ ! -d "specs" ]]; then
    return 1
  fi

  local design_file
  design_file=$(find "specs" -name "design_*.md" -type f -exec ls -t {} + 2>/dev/null | head -n1)

  if [[ -z "$design_file" || ! -s "$design_file" ]]; then
    return 1
  fi

  echo "$design_file"
  return 0
}

# Generate implementation plan (internal function for workflow)
generate_implementation_internal() {
  log_info "Running implementation plan generation..."
  "$IMPLEMENTATION_SCRIPT"
}

# Generate implementation plan (command function)
generate_implementation() {
  echo "=== Implementation Plan Generation ==="
  echo

  # Check if we're in a project directory
  if [[ ! -f "specs/requirements_form.md" ]]; then
    log_error "Not in a project directory"
    echo
    echo "This command should be run from a project directory containing:"
    echo "  - specs/requirements_form.md"
    echo "  - specs/ directory with design document"
    echo
    echo "Create a project first with: $0 new"
    echo "Generate design first with: $0 design"
    exit 1
  fi

  # Check if design document exists
  local latest_design
  if ! latest_design=$(find_latest_design); then
    log_error "No design document found"
    echo
    echo "Please generate design first with: $0 design"
    exit 1
  fi

  log_info "Found design document: $latest_design"
  generate_implementation_internal
}

# Open file in default editor
open_in_editor() {
  local file_path="$1"
  local file_description="$2"

  log_info "Opening $file_description..."

  # Try to open with default editor
  if command -v xdg-open &>/dev/null; then
    xdg-open "$file_path" &
    wait
  elif command -v open &>/dev/null; then
    open "$file_path" &
    wait
  elif [[ -n "$EDITOR" ]]; then
    $EDITOR "$file_path"
  else
    log_warning "No default editor found. Please edit manually:"
    echo "  $file_path"
  fi
}

# Main function
main() {
  local command="${1:-}"

  case "$command" in
  "new")
    check_templates
    create_new_project
    ;;
  "requirements")
    generate_requirements
    ;;
  "design")
    generate_design
    ;;
  "implementation")
    generate_implementation
    ;;
  "help" | "-h" | "--help")
    show_usage
    ;;
  "")
    log_error "No command specified"
    echo
    show_usage
    exit 1
    ;;
  *)
    log_error "Unknown command: $command"
    echo
    show_usage
    exit 1
    ;;
  esac
}

# Run main function
main "$@"
