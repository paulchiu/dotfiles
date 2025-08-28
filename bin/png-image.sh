#!/bin/zsh

# png-image.sh - Convert images to PNG format with specified resolution
# Usage: png-image.sh [options] <input_files...>

# Default resolution
RESOLUTION="720p"
FORCE_OVERWRITE=false

# Function to display help
show_help() {
    cat << EOF
Usage: png-image.sh [options] <input_files...>

Convert any image files to PNG format with specified resolution.

OPTIONS:
    -r, --resolution RESOLUTION   Set output resolution (720p or 1080p)
                                  Default: 720p
    -y, --yes                     Automatically overwrite existing files
    -h, --help                    Show this help message

EXAMPLES:
    png-image.sh image.jpg                    # Convert single image to 720p PNG
    png-image.sh -r 1080p image.jpg          # Convert to 1080p PNG
    png-image.sh -y *.jpg                    # Convert all JPEG files to 720p PNG, overwrite existing
    png-image.sh -r 1080p -y *.png *.jpg    # Convert all PNG and JPEG files to 1080p PNG, overwrite existing

SUPPORTED FORMATS:
    Input: JPEG, TIFF, BMP, GIF, and other formats supported by sips
    Output: PNG

RESOLUTIONS:
    720p  - 1280x720 pixels
    1080p - 1920x1080 pixels
EOF
}

# Function to get dimensions for resolution
get_dimensions() {
    case "$1" in
        "720p")
            echo "1280 720"
            ;;
        "1080p")
            echo "1920 1080"
            ;;
        *)
            echo "Error: Unsupported resolution '$1'. Use 720p or 1080p." >&2
            exit 1
            ;;
    esac
}

# Function to get constraint dimension (smaller of width/height)
get_constraint() {
    case "$1" in
        "720p")
            echo "720"
            ;;
        "1080p")
            echo "1080"
            ;;
        *)
            echo "Error: Unsupported resolution '$1'. Use 720p or 1080p." >&2
            exit 1
            ;;
    esac
}

# Function to convert image
convert_image() {
    local input_file="$1"
    local resolution="$2"
    
    # Check if input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file '$input_file' does not exist." >&2
        exit 1
    fi
    
    # Get constraint dimension
    local constraint=$(get_constraint "$resolution")
    
    # Generate output filename
    local base_name="${input_file%.*}"
    local output_file="${base_name}_${resolution}.png"
    
    # Check if output file already exists
    if [[ -f "$output_file" && "$FORCE_OVERWRITE" != true ]]; then
        echo "Warning: Output file '$output_file' already exists."
        echo -n "Overwrite? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Skipping '$input_file'."
            return 0
        fi
    fi
    
    echo "Converting '$input_file' to PNG ($resolution)..."
    
    # Use sips to convert and resize
    if sips -Z "$constraint" -s format png "$input_file" --out "$output_file"; then
        echo "Successfully converted to: $output_file"
    else
        echo "Error: Failed to convert '$input_file'. Make sure the input file is a valid image format." >&2
        return 1
    fi
}

# Initialize array to store input files
INPUT_FILES=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -y|--yes)
            FORCE_OVERWRITE=true
            shift
            ;;
        -r|--resolution)
            if [[ -n "$2" ]]; then
                RESOLUTION="$2"
                shift 2
            else
                echo "Error: --resolution requires a value (720p or 1080p)" >&2
                exit 1
            fi
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            echo "Use -h or --help for usage information." >&2
            exit 1
            ;;
        *)
            # This is an input file
            INPUT_FILES+=("$1")
            shift
            ;;
    esac
done

# If no parameters given, show help
if [[ ${#INPUT_FILES[@]} -eq 0 ]]; then
    show_help
    exit 0
fi

# Convert all input files
for input_file in "${INPUT_FILES[@]}"; do
    convert_image "$input_file" "$RESOLUTION"
done