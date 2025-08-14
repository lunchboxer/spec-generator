#!/bin/bash

# Implementation Plan Generator
# Uses aichat to generate implementation plans from design documents

set -e # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/implementation_prompt.md" # In script directory
OUTPUT_DIR="specs"                                 # In project directory (CWD)
TEMP_DIR="temp"                                    # In project directory (CWD)

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
  # Check for implementation prompt template in script directory
  if [[ ! -f "$PROMPT_FILE" ]]; then
    log_error "Implementation prompt template not found: $PROMPT_FILE"
    echo "The implementation prompt template should be in the same directory as this script."
    echo "Expected file: $PROMPT_FILE"
    echo
    echo "Please ensure the spec-dev tool is properly installed with all template files."
    exit 1
  fi

  log_info "Required template files found: $PROMPT_FILE"
}

# Find the most recent design document
find_design_document() {
  if [[ ! -d "$OUTPUT_DIR" ]]; then
    log_error "Output directory not found: $OUTPUT_DIR"
    echo "No design documents found. Please generate design first."
    echo
    echo "Run the design generation before creating implementation plans."
    exit 1
  fi

  # Find the most recent design file
  local design_file
  design_file=$(find "$OUTPUT_DIR" -name "design_*.md" -type f -exec ls -t {} + | head -n1)

  if [[ -z "$design_file" ]]; then
    log_error "No design document found in $OUTPUT_DIR"
    echo
    echo "Please generate a design document first:"
    echo "  - Fill out requirements_form.md"
    echo "  - Run the requirements generation script"
    echo "  - Run the design generation script"
    exit 1
  fi

  if [[ ! -s "$design_file" ]]; then
    log_error "Design document is empty: $design_file"
    echo "Please ensure the design document was generated successfully."
    exit 1
  fi

  log_info "Using design document: $design_file" >&2
  echo "$design_file"
}

# Create output directories
setup_directories() {
  mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"
  log_info "Output directories ready"
}

# Generate the complete prompt by combining the template with the design document
create_full_prompt() {
  local design_file="$1"
  local full_prompt_file
  full_prompt_file="$(pwd)/$TEMP_DIR/implementation_prompt_full.md"

  # Read the prompt template and replace the placeholder with design document
  log_info "Preparing implementation prompt with design document..." >&2
  log_info "Design file: $design_file" >&2

  # Use sed to replace the placeholder with the actual design content
  sed '/\[The design document will be inserted here by the script\]/r '"$design_file" "$PROMPT_FILE" |
    sed '/\[The design document will be inserted here by the script\]/d' >"$full_prompt_file"

  echo "$full_prompt_file"
}

# Generate implementation plan using aichat
generate_implementation_plan() {
  local full_prompt_file="$1"
  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  local output_file="$OUTPUT_DIR/implementation_$timestamp.md"

  log_info "Generating implementation plan..."
  log_info "This may take a moment depending on the LLM and document complexity..."

  # Call aichat with the full prompt
  if aichat -f "$full_prompt_file" >"$output_file" 2>"$TEMP_DIR/aichat_error.log"; then
    local word_count
    local line_count
    word_count=$(wc -w <"$output_file")
    line_count=$(wc -l <"$output_file")

    # Try to strip markdown code block markers if present
    strip_code_block "$output_file"

    log_success "Implementation plan generated successfully!"
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
    echo "  1. Review the generated implementation plan"
    echo "  2. Refine tasks and timelines as needed"
    echo "  3. Share with development team for feedback"
    echo "  4. Use as foundation for actual implementation"

  else
    log_error "Failed to generate implementation plan"
    echo
    echo "Error details:"
    cat "$TEMP_DIR/aichat_error.log"
    echo
    echo "Possible issues:"
    echo "  - LLM service unavailable"
    echo "  - API key not configured"
    echo "  - Design document too large"
    echo "  - Rate limiting"
    echo "  - Invalid design document format"
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
  echo "=== Implementation Plan Generator ==="
  echo

  # Perform all checks
  check_aichat
  check_files
  setup_directories

  # Find and validate design document
  local design_file
  design_file=$(find_design_document)

  # Generate the implementation plan
  local full_prompt_file
  full_prompt_file=$(create_full_prompt "$design_file")
  generate_implementation_plan "$full_prompt_file"

  # Clean up
  cleanup

  log_success "Implementation plan generation complete!"
  echo
  echo "The implementation plan provides:"
  echo "  - Detailed tasks and phases for development"
  echo "  - Technology setup instructions"
  echo "  - Implementation guidance for developers"
  echo "  - Testing and deployment plans"
}

# Run main function with error handling
trap cleanup EXIT
main "$@"