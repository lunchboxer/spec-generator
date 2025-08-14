#!/bin/bash

# Design Document Generator
# Uses aichat to generate design documents from requirements documents

set -e # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/design_prompt.md" # In script directory
OUTPUT_DIR="specs"                         # In project directory (CWD)
TEMP_DIR="temp"                            # In project directory (CWD)

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
  # Check for design prompt template in script directory
  if [[ ! -f "$PROMPT_FILE" ]]; then
    log_error "Design prompt template not found: $PROMPT_FILE"
    echo "The design prompt template should be in the same directory as this script."
    echo "Expected file: $PROMPT_FILE"
    echo
    echo "Please ensure the spec-dev tool is properly installed with all template files."
    exit 1
  fi

  log_info "Required template files found: $PROMPT_FILE"
}

# Find the most recent requirements document
find_requirements_document() {
  if [[ ! -d "$OUTPUT_DIR" ]]; then
    log_error "Output directory not found: $OUTPUT_DIR"
    echo "No requirements documents found. Please generate requirements first."
    echo
    echo "Run the requirements generation before creating design documents."
    exit 1
  fi

  # Find the most recent requirements file
  local requirements_file
  requirements_file=$(find "$OUTPUT_DIR" -name "requirements_*.md" -type f -exec ls -t {} + | head -n1)

  if [[ -z "$requirements_file" ]]; then
    log_error "No requirements document found in $OUTPUT_DIR"
    echo
    echo "Please generate a requirements document first:"
    echo "  - Fill out requirements_form.md"
    echo "  - Run the requirements generation script"
    exit 1
  fi

  if [[ ! -s "$requirements_file" ]]; then
    log_error "Requirements document is empty: $requirements_file"
    echo "Please ensure the requirements document was generated successfully."
    exit 1
  fi

  log_info "Using requirements document: $requirements_file" >&2
  echo "$requirements_file"
}

# Create output directories
setup_directories() {
  mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"
  log_info "Output directories ready"
}

# Generate the complete prompt by combining the template with the requirements document
create_full_prompt() {
  local requirements_file="$1"
  local full_prompt_file
  full_prompt_file="$(pwd)/$TEMP_DIR/design_prompt_full.md"

  # Read the prompt template and replace the placeholder with requirements document
  log_info "Preparing design prompt with requirements document..." >&2
  log_info "Requirements file: $requirements_file" >&2

  # Use sed to replace the placeholder with the actual requirements content
  sed '/\[The requirements document will be inserted here by the script\]/r '"$requirements_file" "$PROMPT_FILE" |
    sed '/\[The requirements document will be inserted here by the script\]/d' >"$full_prompt_file"

  echo "$full_prompt_file"
}

# Generate design document using aichat
generate_design_document() {
  local full_prompt_file="$1"
  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  local output_file="$OUTPUT_DIR/design_$timestamp.md"

  log_info "Generating design document..."
  log_info "This may take a moment depending on the LLM and document complexity..."

  # Call aichat with the full prompt
  if aichat -f "$full_prompt_file" >"$output_file" 2>"$TEMP_DIR/aichat_error.log"; then
    local word_count
    local line_count
    word_count=$(wc -w <"$output_file")
    line_count=$(wc -l <"$output_file")

    # Try to strip markdown code block markers if present
    strip_code_block "$output_file"

    log_success "Design document generated successfully!"
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
    if [[ $word_count -lt 200 ]]; then
      log_warning "Generated document seems quite short ($word_count words)"
      log_warning "You may want to review the output and check if the LLM response was complete"
    fi

    # Provide next steps
    echo
    log_info "Next steps:"
    echo "  1. Review the generated design document"
    echo "  2. Refine architectural decisions as needed"
    echo "  3. Share with development team for feedback"
    echo "  4. Use as foundation for implementation planning"

  else
    log_error "Failed to generate design document"
    echo
    echo "Error details:"
    cat "$TEMP_DIR/aichat_error.log"
    echo
    echo "Possible issues:"
    echo "  - LLM service unavailable"
    echo "  - API key not configured"
    echo "  - Requirements document too large"
    echo "  - Rate limiting"
    echo "  - Invalid requirements document format"
    exit 1
  fi
}

# Cleanup temporary files
cleanup() {
  if [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
    log_info "Temporary files cleaned up"
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

# Main execution
main() {
  echo "=== Design Document Generator ==="
  echo

  # Perform all checks
  check_aichat
  check_files
  setup_directories

  # Find and validate requirements document
  local requirements_file
  requirements_file=$(find_requirements_document)

  # Generate the design document
  local full_prompt_file
  full_prompt_file=$(create_full_prompt "$requirements_file")
  generate_design_document "$full_prompt_file"

  # Clean up
  cleanup

  log_success "Design document generation complete!"
  echo
  echo "The design document provides:"
  echo "  - System architecture and component design"
  echo "  - Technology stack recommendations"
  echo "  - Implementation guidance for developers"
  echo "  - Security and performance considerations"
}

# Run main function with error handling
trap cleanup EXIT
main "$@"
