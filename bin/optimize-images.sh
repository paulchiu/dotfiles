#!/bin/bash

# optimize-images-improved.sh - Advanced image optimization script
# Usage: ./optimize-images-improved.sh "glob_pattern" [quality] [--aggressive]
# Example: ./optimize-images-improved.sh "*.jpg" 80 --aggressive

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
DEFAULT_JPEG_QUALITY=85
DEFAULT_PNG_QUALITY=95
DEFAULT_WEBP_QUALITY=85
AGGRESSIVE_MODE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install missing tools on macOS
install_tools() {
    print_status "Checking for required tools..."
    
    local missing_tools=()
    
    # Check for ImageMagick
    if ! command_exists magick; then
        missing_tools+=("imagemagick")
    fi
    
    # Check for mozjpeg (better JPEG compression)
    if ! command_exists cjpeg; then
        missing_tools+=("mozjpeg")
    fi
    
    # Check for pngquant (better PNG compression)
    if ! command_exists pngquant; then
        missing_tools+=("pngquant")
    fi
    
    # Check for oxipng (Rust-based PNG optimizer)
    if ! command_exists oxipng; then
        missing_tools+=("oxipng")
    fi
    
    # Check for webp tools
    if ! command_exists cwebp; then
        missing_tools+=("webp")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_warning "Missing tools detected: ${missing_tools[*]}"
        print_status "Installing missing tools with Homebrew..."
        
        if ! command_exists brew; then
            print_error "Homebrew is required but not installed. Please install it first:"
            print_error "https://brew.sh"
            exit 1
        fi
        
        for tool in "${missing_tools[@]}"; do
            print_status "Installing $tool..."
            brew install "$tool"
        done
    fi
    
    print_success "All required tools are available!"
}

# Function to get file size in bytes
get_file_size() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$1"
    else
        stat -c%s "$1"
    fi
}

# Function to format file size
format_size() {
    local size=$1
    if [ $size -gt 1048576 ]; then
        echo "$(echo "scale=1; $size/1048576" | bc)MB"
    elif [ $size -gt 1024 ]; then
        echo "$(echo "scale=1; $size/1024" | bc)KB"
    else
        echo "${size}B"
    fi
}

# Function to optimize JPEG images
optimize_jpeg() {
    local input="$1"
    local output="$2"
    local quality="$3"
    
    if command_exists cjpeg && [ "$AGGRESSIVE_MODE" = true ]; then
        # Use mozjpeg for better compression
        djpeg "$input" | cjpeg -quality "$quality" -optimize -progressive > "$output"
    else
        # Use ImageMagick with optimized settings
        magick "$input" \
            -strip \
            -interlace JPEG \
            -gaussian-blur 0.05 \
            -quality "$quality" \
            -colorspace RGB \
            -sampling-factor 4:2:0 \
            "$output"
    fi
}

# Function to optimize PNG images
optimize_png() {
    local input="$1"
    local output="$2"
    local quality="$3"
    
    # First pass with ImageMagick
    magick "$input" \
        -strip \
        -define png:compression-filter=5 \
        -define png:compression-level=9 \
        -define png:compression-strategy=1 \
        "$output"
    
    if command_exists pngquant; then
        # Second pass with pngquant for better compression
        local temp_file="${output}.temp"
        if pngquant --quality=65-${quality} --output "$temp_file" "$output" 2>/dev/null; then
            mv "$temp_file" "$output"
        fi
    fi
    
    if command_exists oxipng && [ "$AGGRESSIVE_MODE" = true ]; then
        # Third pass with oxipng for maximum compression
        oxipng -o 6 --strip safe "$output"
    fi
}

# Function to optimize WebP images
optimize_webp() {
    local input="$1"
    local output="$2"
    local quality="$3"
    
    if command_exists cwebp; then
        cwebp -q "$quality" -m 6 -segments 4 -f 50 "$input" -o "$output"
    else
        magick "$input" -quality "$quality" "$output"
    fi
}

# Function to optimize a single image
optimize_image() {
    local img="$1"
    local quality="$2"
    
    if [ ! -f "$img" ]; then
        return
    fi
    
    # Get file info
    local ext="${img##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    local base_name=$(basename "$img")
    local dir_name=$(dirname "$img")
    
    # Skip if not an image
    case "$ext" in
        jpg|jpeg|png|webp) ;;
        *) 
            print_warning "Skipping non-image file: $img"
            return
            ;;
    esac
    
    print_status "Processing: $img"
    
    # Get original file size
    local original_size=$(get_file_size "$img")
    
    # Create temporary file
    local temp_file="${img}.tmp"
    
    # Optimize based on file type
    case "$ext" in
        jpg|jpeg)
            optimize_jpeg "$img" "$temp_file" "$quality"
            ;;
        png)
            optimize_png "$img" "$temp_file" "$quality"
            ;;
        webp)
            optimize_webp "$img" "$temp_file" "$quality"
            ;;
    esac
    
    # Check if optimization was successful and beneficial
    if [ -f "$temp_file" ]; then
        local new_size=$(get_file_size "$temp_file")
        local savings=$((original_size - new_size))
        local savings_percent=$((savings * 100 / original_size))
        
        if [ $new_size -lt $original_size ]; then
            # Replace original with optimized version
            mv "$temp_file" "$img"
            print_success "  $(format_size $original_size) → $(format_size $new_size) (${savings_percent}% smaller)"
        else
            # Keep original if optimization didn't help
            rm -f "$temp_file"
            print_warning "  No improvement, keeping original ($(format_size $original_size))"
        fi
    else
        print_error "  Failed to optimize $img"
    fi
}

# Main function
main() {
    # Parse arguments
    local glob_pattern=""
    local quality=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --aggressive)
                AGGRESSIVE_MODE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 \"glob_pattern\" [quality] [--aggressive]"
                echo ""
                echo "Options:"
                echo "  glob_pattern    File pattern to match (e.g., \"*.jpg\", \"**/*.png\")"
                echo "  quality         Quality setting (1-100, default varies by format)"
                echo "  --aggressive    Use more aggressive optimization (slower but better)"
                echo "  --help, -h      Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 \"*.jpg\" 85"
                echo "  $0 \"**/*.png\" 95 --aggressive"
                echo "  $0 \"images/*.{jpg,png,webp}\" 80"
                exit 0
                ;;
            *)
                if [ -z "$glob_pattern" ]; then
                    glob_pattern="$1"
                elif [ -z "$quality" ]; then
                    quality="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if at least glob pattern is provided
    if [ -z "$glob_pattern" ]; then
        print_error "Usage: $0 \"glob_pattern\" [quality] [--aggressive]"
        print_error "Example: $0 \"*.jpg\" 85"
        print_error "Use --help for more information"
        exit 1
    fi
    
    # Set default quality based on file type if not specified
    if [ -z "$quality" ]; then
        case "$glob_pattern" in
            *jpg*|*jpeg*) quality=$DEFAULT_JPEG_QUALITY ;;
            *png*) quality=$DEFAULT_PNG_QUALITY ;;
            *webp*) quality=$DEFAULT_WEBP_QUALITY ;;
            *) quality=$DEFAULT_JPEG_QUALITY ;;
        esac
    fi
    
    # Install required tools
    install_tools
    
    print_status "Starting optimization with pattern: $glob_pattern"
    print_status "Quality setting: $quality"
    [ "$AGGRESSIVE_MODE" = true ] && print_status "Aggressive mode: enabled"
    
    # Process images
    local processed_count=0
    local total_original_size=0
    local total_new_size=0
    
    # Use find for better glob support
    while IFS= read -r -d '' img; do
        local original_size=$(get_file_size "$img")
        optimize_image "$img" "$quality"
        local new_size=$(get_file_size "$img")
        
        total_original_size=$((total_original_size + original_size))
        total_new_size=$((total_new_size + new_size))
        processed_count=$((processed_count + 1))
    done < <(find . -name "$glob_pattern" -type f -print0)
    
    # Print summary
    if [ $processed_count -gt 0 ]; then
        local total_savings=$((total_original_size - total_new_size))
        local total_savings_percent=$((total_savings * 100 / total_original_size))
        
        print_success "Optimization complete!"
        print_success "Files processed: $processed_count"
        print_success "Total size: $(format_size $total_original_size) → $(format_size $total_new_size)"
        print_success "Total savings: $(format_size $total_savings) (${total_savings_percent}%)"
    else
        print_warning "No files found matching pattern: $glob_pattern"
    fi
}

# Check if bc is available for calculations
if ! command_exists bc; then
    print_error "bc (basic calculator) is required but not installed."
    print_error "On macOS: this should be pre-installed. Try: which bc"
    exit 1
fi

# Run main function
main "$@"
