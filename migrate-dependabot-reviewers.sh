#!/bin/bash
# Self-contained cross-platform script to migrate Dependabot reviewers to CODEOWNERS
#
# Compatible with: Windows (Git Bash/WSL), Linux, Solaris, macOS
# 
# Requirements:
# - bash (available on all target platforms)
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize global arrays for YAML parsing (bash 3.2 compatibility)
YAML_KEYS=()
YAML_VALUES=()

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

yaml_set() {
    local key="$1"
    local value="$2"
    
    # Check if key already exists
    local i=0
    while [[ $i -lt ${#YAML_KEYS[@]} ]]; do
        if [[ "${YAML_KEYS[$i]}" == "$key" ]]; then
            YAML_VALUES[$i]="$value"
            return
        fi
        ((i++))
    done
    
    # Add new key-value pair
    YAML_KEYS[${#YAML_KEYS[@]}]="$key"
    YAML_VALUES[${#YAML_VALUES[@]}]="$value"
}

# Function to get value by key
yaml_get() {
    local key="$1"
    local i=0
    
    while [[ $i -lt ${#YAML_KEYS[@]} ]]; do
        if [[ "${YAML_KEYS[$i]}" == "$key" ]]; then
            echo "${YAML_VALUES[$i]}"
            return
        fi
        ((i++))
    done
}

# Function to get all keys matching a pattern
yaml_keys_matching() {
    local pattern="$1"
    local i=0
    
    while [[ $i -lt ${#YAML_KEYS[@]} ]]; do
        if [[ "${YAML_KEYS[$i]}" =~ $pattern ]]; then
            echo "${YAML_KEYS[$i]}"
        fi
        ((i++))
    done
}

# Function to parse YAML content with proper indentation handling
parse_yaml() {
    local input="$1"
    local prefix="$2"
    
    # Clear previous data
    YAML_KEYS=()
    YAML_VALUES=()
    
    local line_number=0
    local current_update_index=-1
    local current_reviewer_index=0
    local current_directory_index=0
    local in_reviewers_section=false
    local in_directories_section=false
    local reviewers_indent=0
    local directories_indent=0
    
    # Process YAML line by line
    while IFS= read -r line; do
        ((line_number++))
        
        # Safety check to prevent infinite loops
        if [[ $line_number -gt 1000 ]]; then
            break
        fi
        
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Get indentation level
        local indent=""
        if [[ "$line" =~ ^([[:space:]]*) ]]; then
            indent="${BASH_REMATCH[1]}"
        fi
        local indent_level=${#indent}
        
        # Trim the line
        local trimmed_line="${line#"${line%%[![:space:]]*}"}"
        
        # Handle array items starting with "-"
        if [[ "$trimmed_line" =~ ^-[[:space:]]*(.*)$ ]]; then
            local value="${BASH_REMATCH[1]}"
            
            # Check if this is a top-level updates array item (indent_level 2 for 2-space YAML)
            if [[ $indent_level -eq 2 && "$value" =~ ^package-ecosystem: ]]; then
                # New update entry
                ((current_update_index++))
                current_reviewer_index=0
                current_directory_index=0
                in_reviewers_section=false
                in_directories_section=false
                
                # Extract package-ecosystem value
                if [[ "$value" =~ ^package-ecosystem:[[:space:]]*[\"\']*([^\"\']*)[\"\']*$ ]]; then
                    local ecosystem="${BASH_REMATCH[1]}"
                    yaml_set "updates.${current_update_index}.package-ecosystem" "$ecosystem"
                fi
            elif [[ "$in_reviewers_section" == true && $indent_level -eq $reviewers_indent ]]; then
                # Reviewer item
                value="${value#"${value%%[![:space:]]*}"}" # trim leading whitespace
                value="${value%"${value##*[![:space:]]}"}" # trim trailing whitespace
                
                # Remove quotes if present
                if [[ "$value" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                    value="${BASH_REMATCH[1]}"
                fi
                
                if [[ -n "$value" ]]; then
                    yaml_set "updates.${current_update_index}.reviewers.${current_reviewer_index}" "$value"
                    ((current_reviewer_index++))
                fi
            elif [[ "$in_directories_section" == true && $indent_level -eq $directories_indent ]]; then
                # Directory item
                value="${value#"${value%%[![:space:]]*}"}" # trim leading whitespace
                value="${value%"${value##*[![:space:]]}"}" # trim trailing whitespace
                
                # Remove quotes if present
                if [[ "$value" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                    value="${BASH_REMATCH[1]}"
                fi
                
                if [[ -n "$value" ]]; then
                    yaml_set "updates.${current_update_index}.directories.${current_directory_index}" "$value"
                    ((current_directory_index++))
                fi
            elif [[ "$value" =~ ^([^:]+):[[:space:]]*(.*)$ ]]; then
                # Object property in array item
                local key="${BASH_REMATCH[1]}"
                local val="${BASH_REMATCH[2]}"
                
                # Clean up key and value
                key="${key// /}"
                val="${val#"${val%%[![:space:]]*}"}" # trim leading whitespace
                val="${val%"${val##*[![:space:]]}"}" # trim trailing whitespace
                
                # Remove quotes if present
                if [[ "$val" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                    val="${BASH_REMATCH[1]}"
                fi
                
                if [[ -n "$val" && $current_update_index -ge 0 ]]; then
                    yaml_set "updates.${current_update_index}.${key}" "$val"
                fi
            fi
        elif [[ "$trimmed_line" =~ ^([^:]+):[[:space:]]*(.*)$ ]]; then
            # Regular key-value pair
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Clean up key and value
            key="${key// /}"
            value="${value#"${value%%[![:space:]]*}"}" # trim leading whitespace
            value="${value%"${value##*[![:space:]]}"}" # trim trailing whitespace
            
            # Remove quotes if present
            if [[ "$value" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi
            
            # Handle special cases
            if [[ "$key" == "reviewers" ]]; then
                in_reviewers_section=true
                in_directories_section=false
                reviewers_indent=$((indent_level + 2)) # Expecting reviewers to be indented 2 spaces more
                current_reviewer_index=0
                # If there's a value on the same line, it's likely an error or single-line format
                if [[ -n "$value" ]]; then
                    # Handle inline array format like "reviewers: [user1, user2]"
                    if [[ "$value" =~ ^\[.*\]$ ]]; then
                        value="${value:1:-1}" # Remove [ ]
                        local old_ifs="$IFS"
                        IFS=','
                        local reviewers_array=($value)
                        IFS="$old_ifs"
                        for reviewer in "${reviewers_array[@]}"; do
                            reviewer="${reviewer#"${reviewer%%[![:space:]]*}"}" # trim leading whitespace
                            reviewer="${reviewer%"${reviewer##*[![:space:]]}"}" # trim trailing whitespace
                            if [[ "$reviewer" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                                reviewer="${BASH_REMATCH[1]}"
                            fi
                            if [[ -n "$reviewer" ]]; then
                                yaml_set "updates.${current_update_index}.reviewers.${current_reviewer_index}" "$reviewer"
                                ((current_reviewer_index++))
                            fi
                        done
                        in_reviewers_section=false
                    fi
                fi
            elif [[ "$key" == "directories" ]]; then
                # Handle directories array
                in_directories_section=true
                in_reviewers_section=false
                directories_indent=$((indent_level + 2)) # Expecting directories to be indented 2 spaces more
                current_directory_index=0
                if [[ -n "$value" ]]; then
                    # Handle inline array format
                    if [[ "$value" =~ ^\[.*\]$ ]]; then
                        value="${value:1:-1}" # Remove [ ]
                        local old_ifs="$IFS"
                        IFS=','
                        local dirs_array=($value)
                        IFS="$old_ifs"
                        for dir in "${dirs_array[@]}"; do
                            dir="${dir#"${dir%%[![:space:]]*}"}" # trim leading whitespace
                            dir="${dir%"${dir##*[![:space:]]}"}" # trim trailing whitespace
                            if [[ "$dir" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                                dir="${BASH_REMATCH[1]}"
                            fi
                            if [[ -n "$dir" ]]; then
                                yaml_set "updates.${current_update_index}.directories.${current_directory_index}" "$dir"
                                ((current_directory_index++))
                            fi
                        done
                        in_directories_section=false
                    fi
                fi
            else
                # Regular key-value pair
                if [[ -n "$value" && $current_update_index -ge 0 ]]; then
                    yaml_set "updates.${current_update_index}.${key}" "$value"
                fi
                
                # Reset sections if we encounter a different key at the same or lower indent level
                if [[ "$in_reviewers_section" == true && $indent_level -le $((reviewers_indent - 2)) ]]; then
                    in_reviewers_section=false
                fi
                if [[ "$in_directories_section" == true && $indent_level -le $((directories_indent - 2)) ]]; then
                    in_directories_section=false
                fi
            fi
        elif [[ "$in_reviewers_section" == true && -n "$trimmed_line" ]]; then
            # Handle reviewers that might not start with "-" (malformed YAML)
            local reviewer="$trimmed_line"
            
            # Remove quotes if present
            if [[ "$reviewer" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                reviewer="${BASH_REMATCH[1]}"
            fi
            
            if [[ -n "$reviewer" ]]; then
                yaml_set "updates.${current_update_index}.reviewers.${current_reviewer_index}" "$reviewer"
                ((current_reviewer_index++))
            fi
        elif [[ "$in_directories_section" == true && -n "$trimmed_line" ]]; then
            # Handle directories that might not start with "-" (malformed YAML)
            local directory="$trimmed_line"
            
            # Remove quotes if present
            if [[ "$directory" =~ ^[\"\']*([^\"\']*)[\"\']*$ ]]; then
                directory="${BASH_REMATCH[1]}"
            fi
            
            if [[ -n "$directory" ]]; then
                yaml_set "updates.${current_update_index}.directories.${current_directory_index}" "$directory"
                ((current_directory_index++))
            fi
        fi
    done <<< "$input"
}

# Function to get YAML value by path (compatible with new array-based approach)
get_yaml_value() {
    local path="$1"
    yaml_get "$path"
}

# Function to get all keys matching a pattern (compatible with new array-based approach)
get_yaml_keys() {
    local pattern="$1"
    yaml_keys_matching "$pattern"
}

# Function to get all keys matching a pattern
get_yaml_keys() {
    local pattern="$1"
    for key in "${!YAML_DATA[@]}"; do
        if [[ "$key" =~ $pattern ]]; then
            echo "$key"
        fi
    done
}

parse_json() {
    local input="$1"
    local prefix="$2"
    
    echo "JSON parsing not implemented in this version - use YAML format"
}

# Function to get JSON value by path (placeholder)
get_json_value() {
    local path="$1"
    echo ""
}

get_json_keys() {
    local pattern="$1"
    echo ""
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Migrate Dependabot reviewers from .github/dependabot.yml to CODEOWNERS file"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Platform Support:"
    echo "  - Windows: Git Bash/WSL/Command Prompt"
    echo "  - Linux: All distributions"
    echo "  - Solaris: All versions"
    echo "  - macOS: All versions"
    echo ""
    echo "Requirements:"
    echo "  - bash shell (only requirement)"
    echo ""
    echo "Examples:"
    echo "  $0  "
    echo ""
}

# Function to get manifest files for each ecosystem
get_manifest_files_for_ecosystem() {
    local ecosystem="$1"
    local directory="$2"
    
    # Normalize directory path
    if [[ ! "$directory" =~ ^/ ]]; then
        directory="/$directory"
    fi
    
    if [[ "$directory" == "/" ]]; then
        directory=""
    else
        directory="${directory%/}"  # Remove trailing slash
    fi
    
    local patterns=()
    
    case "$ecosystem" in
        "bundler")
            local manifests=("Gemfile" "Gemfile.lock" "*.gemspec")
            ;;
        "bun")
            local manifests=("package.json" "bun.lockb")
            ;;
        "npm")
            local manifests=("package.json" "package-lock.json" "npm-shrinkwrap.json" "yarn.lock" "pnpm-lock.yaml")
            ;;
        "cargo")
            local manifests=("Cargo.toml" "Cargo.lock")
            ;;
        "composer")
            local manifests=("composer.json" "composer.lock")
            ;;
        "devcontainers")
            local manifests=(".devcontainer/devcontainer.json" ".devcontainer.json")
            ;;
        "docker")
            local manifests=("Dockerfile" "Dockerfile.*" "*.dockerfile")
            ;;
        "docker-compose")
            local manifests=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")
            ;;
        "dotnet-sdk")
            local manifests=("*.csproj" "*.fsproj" "*.vbproj" "*.sln" "packages.config" "global.json")
            ;;
        "nuget")
            local manifests=("*.csproj" "*.fsproj" "*.vbproj" "*.sln" "packages.config" "Directory.Build.props" "Directory.Packages.props")
            ;;
        "elm")
            local manifests=("elm.json")
            ;;
        "github-actions")
            local manifests=(".github/workflows/*.yml" ".github/workflows/*.yaml" "action.yml" "action.yaml")
            ;;
        "gitsubmodule")
            local manifests=(".gitmodules")
            ;;
        "gomod")
            local manifests=("go.mod" "go.sum")
            ;;
        "gradle")
            local manifests=("build.gradle" "build.gradle.kts" "gradle.properties" "settings.gradle" "settings.gradle.kts")
            ;;
        "maven")
            local manifests=("pom.xml" "*.pom")
            ;;
        "helm")
            local manifests=("Chart.yaml" "Chart.yml" "values.yaml" "values.yml")
            ;;
        "mix")
            local manifests=("mix.exs" "mix.lock")
            ;;
        "pip")
            local manifests=("requirements.txt" "requirements/*.txt" "setup.py" "setup.cfg" "pyproject.toml" "Pipfile" "Pipfile.lock")
            ;;
        "uv")
            local manifests=("pyproject.toml" "uv.lock")
            ;;
        "pub")
            local manifests=("pubspec.yaml" "pubspec.yml" "pubspec.lock")
            ;;
        "swift")
            local manifests=("Package.swift" "Package.resolved")
            ;;
        "terraform")
            local manifests=("*.tf" "*.tfvars" "*.hcl")
            ;;
        *)
            return 1
            ;;
    esac
    
    # Generate patterns for each manifest file
    for manifest in "${manifests[@]}"; do
        if [[ -z "$directory" ]]; then
            # Root directory case
            if [[ "$manifest" == *"*"* || "$manifest" == *"?"* ]]; then
                # Glob pattern
                patterns+=("/$manifest")
                if [[ ! "$manifest" =~ ^\*\*/ ]]; then
                    patterns+=("/**/$manifest")
                fi
            else
                # Specific file
                patterns+=("/$manifest")
            fi
        else
            # Specific directory case
            if [[ "$manifest" == *"*"* || "$manifest" == *"?"* ]]; then
                patterns+=("$directory/$manifest")
                if [[ ! "$manifest" =~ ^\*\*/ ]]; then
                    patterns+=("$directory/**/$manifest")
                fi
            else
                patterns+=("$directory/$manifest")
            fi
        fi
    done
    
    # Remove duplicates and return unique patterns
    printf '%s\n' "${patterns[@]}" | sort -u
}

# Function to parse dependabot.yml and extract reviewers using embedded parser
parse_dependabot_yml() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        print_error "dependabot.yml file not found!"
        return 1
    fi
    
    local content
    content=$(cat "$file_path")
    
    # Parse YAML
    parse_yaml "$content" ""
    
    # Extract updates with reviewers
    local updates_with_reviewers=()
    local update_index=0
    
    # Find all update entries
    while true; do
        local ecosystem_key="updates.${update_index}.package-ecosystem"
        local directory_key="updates.${update_index}.directory"
        local directories_key="updates.${update_index}.directories"
        local reviewers_key="updates.${update_index}.reviewers"
        
        local ecosystem
        ecosystem=$(get_yaml_value "$ecosystem_key")
        
        if [[ -z "$ecosystem" ]]; then
            break
        fi
        
        # Check if this update has reviewers
        local has_reviewers=false
        local reviewer_index=0
        local all_reviewers=()
        
        while true; do
            local reviewer
            reviewer=$(get_yaml_value "${reviewers_key}.${reviewer_index}")
            if [[ -n "$reviewer" ]]; then
                has_reviewers=true
                all_reviewers+=("$reviewer")
                ((reviewer_index++))
            else
                break
            fi
            if [[ $reviewer_index -gt 50 ]]; then  # Safety limit
                break
            fi
        done
        
        if [[ "$has_reviewers" == true ]]; then
            # Check for single directory
            local directory
            directory=$(get_yaml_value "$directory_key")
            
            # Check for multiple directories (directories field)
            local has_directories=false
            local dir_index=0
            local all_directories=()
            
            while true; do
                local dir
                dir=$(get_yaml_value "${directories_key}.${dir_index}")
                if [[ -n "$dir" ]]; then
                    has_directories=true
                    all_directories+=("$dir")
                    ((dir_index++))
                else
                    break
                fi
                if [[ $dir_index -gt 50 ]]; then  # Safety limit
                    break
                fi
            done
            
            # If no directory specified, default to root
            if [[ -z "$directory" && "$has_directories" == false ]]; then
                directory="/"
            fi
            
            # Format reviewers as space-separated string
            local reviewers_string="${all_reviewers[*]}"
            
            if [[ "$has_directories" == true ]]; then
                # Handle multiple directories
                for dir in "${all_directories[@]}"; do
                    updates_with_reviewers+=("$ecosystem|$dir|$reviewers_string")
                done
            else
                # Handle single directory
                updates_with_reviewers+=("$ecosystem|$directory|$reviewers_string")
            fi
        fi
        
        ((update_index++))
        if [[ $update_index -gt 100 ]]; then  # Safety limit
            break
        fi
    done
    
    # Output in format that can be easily processed
    if [[ ${#updates_with_reviewers[@]} -gt 0 ]]; then
        printf '%s\n' "${updates_with_reviewers[@]}"
    fi
}

# Function to find existing CODEOWNERS file
find_codeowners_file() {
    local possible_paths=("CODEOWNERS" ".github/CODEOWNERS" "docs/CODEOWNERS")
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    # Return default location if none found
    echo "CODEOWNERS"
}

# Function to sort CODEOWNERS lines
sort_codeowners_lines() {
    # Sort with the following priority:
    # 1. Root patterns (/*) first
    # 2. Less wildcards first
    # 3. Files with extensions first
    # 4. Shorter paths first
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        local pattern
        pattern=$(echo "$line" | awk '{print $1}')
        
        local wildcard_count
        wildcard_count=$(echo "$pattern" | tr -cd '*?' | wc -c)
        
        local path_depth
        path_depth=$(echo "$pattern" | tr -cd '/' | wc -c)
        
        local has_extension=1
        if [[ "$pattern" == *.* ]]; then
            has_extension=0
        fi
        
        local is_root_pattern=1
        if [[ "$pattern" =~ ^/[^/]*$ ]]; then
            is_root_pattern=0
        fi
        
        # Create sort key: is_root_pattern:wildcard_count:has_extension:path_depth:pattern
        echo "$is_root_pattern:$wildcard_count:$has_extension:$path_depth:$line"
    done | sort -t: -k1,1n -k2,2n -k3,3n -k4,4n -k5 | cut -d: -f5-
}

# Main function
main() {
    local dependabot_file=".github/dependabot.yml"
    local has_changes=false
    
    print_info "Starting Dependabot reviewers migration to CODEOWNERS (Self-contained)..."
    print_info "Platform: $(uname -s) $(uname -m)"
    print_success "using embedded parsers"
    
    # Check if dependabot.yml exists
    if [[ ! -f "$dependabot_file" ]]; then
        print_error "dependabot.yml file not found at $dependabot_file!"
        return 1
    fi
    
    # Find CODEOWNERS file
    local codeowners_file
    codeowners_file=$(find_codeowners_file)
    
    if [[ -f "$codeowners_file" ]]; then
        print_info "Found existing CODEOWNERS file at: $codeowners_file"
    else
        print_info "No existing CODEOWNERS file found, will create at: $codeowners_file"
    fi
    
    # Create directory if it doesn't exist
    local codeowners_dir
    codeowners_dir=$(dirname "$codeowners_file")
    if [[ -n "$codeowners_dir" && "$codeowners_dir" != "." && ! -d "$codeowners_dir" ]]; then
        mkdir -p "$codeowners_dir"
        print_info "Created directory: $codeowners_dir"
    fi
    
    # Parse dependabot.yml and process each update
    local temp_file
    temp_file=$(mktemp)
    
    # Extract updates with reviewers
    local parse_output
    parse_output=$(parse_dependabot_yml "$dependabot_file")
    echo "$parse_output" > "$temp_file"
    
    if [[ ! -s "$temp_file" ]]; then
        print_warning "No reviewers found in dependabot.yml!"
        rm -f "$temp_file"
        return 1
    fi
    
    # Process each update configuration
    local new_reviewers_lines=()
    
    # Process each line from the parsed output
    while IFS='|' read -r ecosystem directory reviewers; do
        if [[ -z "$reviewers" ]]; then
            continue
        fi
        
        print_info "Processing ecosystem: $ecosystem, directory: $directory"
        
        # Get manifest patterns for this ecosystem
        local manifest_patterns=()
        local temp_patterns
        temp_patterns=$(get_manifest_files_for_ecosystem "$ecosystem" "$directory")
        
        while IFS= read -r pattern; do
            if [[ -n "$pattern" ]]; then
                manifest_patterns+=("$pattern")
            fi
        done <<< "$temp_patterns"
        
        if [[ ${#manifest_patterns[@]} -eq 0 ]]; then
            print_warning "No manifest patterns found for ecosystem: $ecosystem"
            continue
        fi
        
        # Format reviewers (ensure they start with @)
        local formatted_reviewers=()
        for reviewer in $reviewers; do
            if [[ ! "$reviewer" =~ ^@ ]]; then
                reviewer="@$reviewer"
            fi
            formatted_reviewers+=("$reviewer")
        done
        
        # Create CODEOWNERS lines for each manifest pattern
        for pattern in "${manifest_patterns[@]}"; do
            local line="$pattern ${formatted_reviewers[*]}"
            new_reviewers_lines+=("$line")
        done
        
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    if [[ ${#new_reviewers_lines[@]} -eq 0 ]]; then
        print_warning "No reviewers configuration found!"
        return 1
    fi
    
    # Sort the new reviewer lines
    local sorted_lines=()
    local temp_sorted
    temp_sorted=$(printf '%s\n' "${new_reviewers_lines[@]}" | sort_codeowners_lines)
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            sorted_lines+=("$line")
        fi
    done <<< "$temp_sorted"
    
    # Read existing CODEOWNERS content
    local codeowners_content=""
    if [[ -f "$codeowners_file" ]]; then
        codeowners_content=$(cat "$codeowners_file")
    fi
    
    # Process the CODEOWNERS file
    local dependabot_section="# Dependabot reviewers (migrated from .github/dependabot.yml)"
    local temp_codeowners
    temp_codeowners=$(mktemp)
    
    if [[ -n "$codeowners_content" ]]; then
        echo "$codeowners_content" > "$temp_codeowners"
    fi
    
    # Check if dependabot section already exists
    local section_exists=false
    local section_line_num=0
    
    if grep -n "# Dependabot reviewers" "$temp_codeowners" >/dev/null 2>&1; then
        section_exists=true
        section_line_num=$(grep -n "# Dependabot reviewers" "$temp_codeowners" | head -1 | cut -d: -f1)
    fi
    
    if [[ "$section_exists" == "true" ]]; then
        print_info "Updating existing Dependabot reviewers section..."
        
        # Create a new file by reconstructing it properly
        local temp_without_section
        temp_without_section=$(mktemp)
        
        # Copy lines before the Dependabot section
        if [[ $section_line_num -gt 1 ]]; then
            head -n $((section_line_num - 1)) "$temp_codeowners" > "$temp_without_section"
        fi
        
        # Add the new Dependabot section
        echo "$dependabot_section" >> "$temp_without_section"
        printf '%s\n' "${sorted_lines[@]}" >> "$temp_without_section"
        
        # Find and copy any content after the current Dependabot section
        # Look for the next comment section or end of file
        local next_section_line
        next_section_line=$(awk -v start="$section_line_num" '
            NR > start && /^[[:space:]]*#/ && !/# Dependabot reviewers/ { print NR; exit }
        ' "$temp_codeowners")
        
        if [[ -n "$next_section_line" && "$next_section_line" =~ ^[0-9]+$ ]]; then
            # There's content after the Dependabot section
            echo "" >> "$temp_without_section"  # Add blank line
            tail -n +$next_section_line "$temp_codeowners" >> "$temp_without_section"
        fi
        
        # Replace the temp file
        mv "$temp_without_section" "$temp_codeowners"
        
        has_changes=true
    else
        print_info "Adding new Dependabot reviewers section..."
        
        # Add new section at the end
        if [[ -s "$temp_codeowners" ]]; then
            echo "" >> "$temp_codeowners"
        fi
        echo "$dependabot_section" >> "$temp_codeowners"
        printf '%s\n' "${sorted_lines[@]}" >> "$temp_codeowners"
        
        has_changes=true
    fi
    
    # Write changes if any
    if [[ "$has_changes" == "true" ]]; then
        cp "$temp_codeowners" "$codeowners_file"
        print_success "CODEOWNERS file updated at: $codeowners_file"
        
        # Set GitHub Actions output
        if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
            echo "has_changes=true" >> "$GITHUB_OUTPUT"
            echo "codeowners_path=$codeowners_file" >> "$GITHUB_OUTPUT"
        fi
    else
        print_info "No changes were made to CODEOWNERS file"
        
        # Set GitHub Actions output
        if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
            echo "has_changes=false" >> "$GITHUB_OUTPUT"
        fi
    fi
    
    rm -f "$temp_codeowners"
    
    print_success "Migration completed successfully!"
    
    return 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Run main function
    main
fi
