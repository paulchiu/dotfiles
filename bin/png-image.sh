#!/bin/zsh

# png-image.sh - Convert images to PNG format with specified resolution
# Usage: png-image.sh [options] <input_file>

# Default resolution
RESOLUTION="720p"

# Function to display help
show_help() {
    cat << EOF
Usage: png-image.sh [options] <input_file>

Convert any image file to PNG format with specified resolution.

OPTIONS:
    -r, --resolution RESOLUTION   Set output resolution (720p or 1080p)
                                  Default: 720p
    -h, --help                    Show this help message

EXAMPLES:
    png-image.sh image.jpg                    # Convert to 720p PNG
    png-image.sh -r 1080p image.jpg          # Convert to 1080p PNG
    png-image.sh --resolution 720p image.jpg # Convert to 720p PNG

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

# Function to convert image
convert_image() {
    local input_file="$1"
    local resolution="$2"
    
    # Check if input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file '$input_file' does not exist." >&2
        exit 1
    fi
    
    # Get dimensions
    local dimensions=($(get_dimensions "$resolution"))
    local width="${dimensions[1]}"
    local height="${dimensions[2]}"
    
    # Generate output filename
    local base_name="${input_file%.*}"
    local output_file="${base_name}_${resolution}.png"
    
    # Check if output file already exists
    if [[ -f "$output_file" ]]; then
        echo "Warning: Output file '$output_file' already exists."
        echo -n "Overwrite? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            exit 0
        fi
    fi
    
    echo "Converting '$input_file' to PNG ($resolution)..."
    
    # Use sips to convert and resize
    if sips -s format png -Z "$height" "$input_file" --out "$output_file" > /dev/null 2>&1; then
        echo "Successfully converted to: $output_file"
    else
        echo "Error: Failed to convert image. Make sure the input file is a valid image format." >&2
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
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
            # This is the input file
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# If no parameters given, show help
if [[ $# -eq 0 && -z "$INPUT_FILE" ]]; then
    show_help
    exit 0
fi

# Check if input file was provided
if [[ -z "$INPUT_FILE" ]]; then
    echo "Error: No input file specified." >&2
    echo "Use -h or --help for usage information." >&2
    exit 1
fi

# Convert the image
convert_image "$INPUT_FILE" "$RESOLUTION"