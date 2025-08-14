#!/bin/bash

# Requirements Document Generator
# Uses aichat to generate requirements documents from filled forms

set -e # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORM_FILE="specs/requirements_form.md"              # In specs directory
PROMPT_FILE="$SCRIPT_DIR/requirements_prompt.md" # In script directory
OUTPUT_DIR="specs"                               # In project directory (CWD)
TEMP_DIR="temp"                                  # In project directory (CWD)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if aichat is installed
check_aichat() {
  if ! command -v aichat &>/dev/null; then
    log_error "aichat is not installed or not in PATH"
    echo
    echo "Please install aichat from: https://github.com/sigoden/aichat"
    echo
    echo "Installation options:"
    echo "  - Download binary from releases"
    echo "  - cargo install aichat"
    echo "  - Package managers (homebrew, etc.)"
    exit 1
  fi

  log_info "aichat found: $(aichat --version)"
}

# Check if required files exist
check_files() {
  # Check for form file in specs directory
  if [[ ! -f "$FORM_FILE" ]]; then
    log_error "Requirements form not found: $FORM_FILE"
    echo "This script should be run from a project directory containing the specs directory with the requirements form."
    echo "Expected file: $(pwd)/$FORM_FILE"
    echo
    echo "If this is a new project, create the form first or use the main spec-dev tool."
    exit 1
  fi

  # Check for prompt template in script directory
  if [[ ! -f "$PROMPT_FILE" ]]; then
    log_error "Prompt template not found: $PROMPT_FILE"
    echo "The prompt template should be in the same directory as this script."
    echo "Expected file: $PROMPT_FILE"
    echo
    echo "Please ensure the spec-dev tool is properly installed with all template files."
    exit 1
  fi

  log_info "Required files found"
}

# Check if form has been filled out (basic check)
check_form_completion() {
  # Look for the first required field - Project Name
  local project_name_line
  project_name_line=$(grep -A1 "^\*\*Project Name:\*\*" "$FORM_FILE" | tail -n1)

  # Check if line is empty or contains only HTML comment placeholder
  if [[ -z "$project_name_line" ]] || echo "$project_name_line" | grep -q "^[[:space:]]*<!--.*-->[[:space:]]*$"; then
    log_error "Requirements form appears incomplete"
    echo
    echo "The Project Name field is empty or still contains placeholder text."
    echo "Please fill out the requirements form ($FORM_FILE) before generating requirements."
    echo
    echo "Tip: Edit the form and replace the comment placeholders with your actual requirements."
    exit 1
  fi

  log_info "Form appears to be filled out (basic check passed)"
}

# Create output directories
setup_directories() {
  mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"
  log_info "Output directories ready"
}

# Generate the complete prompt by combining the template with the form data
create_full_prompt() {
  local full_prompt_file
  full_prompt_file="$(pwd)/$TEMP_DIR/full_prompt.md"

  # Read the prompt template and replace the placeholder with form data
  log_info "Preparing prompt with form data..." >&2

  # Use sed to replace the placeholder with the actual form content
  sed '/\[The completed requirements form will be inserted here by the script\]/r '"$FORM_FILE" "$PROMPT_FILE" |
    sed '/\[The completed requirements form will be inserted here by the script\]/d' >"$full_prompt_file"

  echo "$full_prompt_file"
}

# Generate requirements using aichat
generate_requirements() {
  local full_prompt_file="$1"
  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  local output_file="$OUTPUT_DIR/requirements_$timestamp.md"

  log_info "Generating requirements document..."
  log_info "This may take a moment depending on the LLM and prompt size..."

  # Call aichat with the full prompt
  if aichat -f "$full_prompt_file" >"$output_file" 2>"$TEMP_DIR/aichat_error.log"; then
    local word_count
    local line_count
    word_count=$(wc -w <"$output_file")
    line_count=$(wc -l <"$output_file")

    # Try to strip markdown code block markers if present
    strip_code_block "$output_file"

    log_success "Requirements document generated successfully!"
    echo
    echo "Output file: $output_file"
    echo "Document stats: $line_count lines, $word_count words"
    echo

    # Show a preview of the generated content
    log_info "Preview (first 10 lines):"
    echo "----------------------------------------"
    head -10 "$output_file"
    echo "----------------------------------------"

    # Check if the output seems reasonable
    if [[ $word_count -lt 100 ]]; then
      log_warning "Generated document seems quite short ($word_count words)"
      log_warning "You may want to review the output and check if the LLM response was complete"
    fi

  else
    log_error "Failed to generate requirements document"
    echo
    echo "Error details:"
    cat "$TEMP_DIR/aichat_error.log"
    echo
    echo "Possible issues:"
    echo "  - LLM service unavailable"
    echo "  - API key not configured"
    echo "  - Prompt too large"
    echo "  - Rate limiting"
    exit 1
  fi
}

# Strip markdown code block markers if present
strip_code_block() {
  local file="$1"
  local first_line
  local last_line
  local backticks='```'

  first_line=$(head -n1 "$file")
  last_line=$(tail -n1 "$file")

  # Check if the file starts with ```markdown and ends with ```
  if [[ "$first_line" == "${backticks}markdown" ]] && [[ "$last_line" == "$backticks" ]]; then
    # Remove first and last lines
    tail -n +2 "$file" | head -n -1 >"${file}.tmp"
    mv "${file}.tmp" "$file"
    log_info "Removed markdown code block markers from output file"
    return 0
  fi

  # Check if the file starts with ``` and ends with ```
  if [[ "$first_line" == "$backticks" ]] && [[ "$last_line" == "$backticks" ]]; then
    # Remove first and last lines
    tail -n +2 "$file" | head -n -1 >"${file}.tmp"
    mv "${file}.tmp" "$file"
    log_info "Removed markdown code block markers from output file"
    return 0
  fi

  return 1
}

# Cleanup temporary files
cleanup() {
  if [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
    log_info "Temporary files cleaned up"
  fi
}

# Main execution
main() {
  echo "=== Requirements Document Generator ==="
  echo

  # Perform all checks
  check_aichat
  check_files
  check_form_completion
  setup_directories

  # Generate the requirements
  local full_prompt_file
  full_prompt_file=$(create_full_prompt)
  generate_requirements "$full_prompt_file"

  # Clean up
  cleanup

  log_success "Requirements generation complete!"
  echo
  echo "Next steps:"
  echo "  1. Review the generated requirements document"
  echo "  2. Edit and refine as needed"
  echo "  3. Share with stakeholders for approval"
}

# Run main function with error handling
trap cleanup EXIT
main "$@"
