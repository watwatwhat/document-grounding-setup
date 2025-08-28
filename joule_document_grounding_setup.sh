#!/bin/bash

# SAP Joule Document Grounding Setup Script for macOS
# This script automates the configuration of user authentication for SAP Joule document grounding

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="joule_config.properties"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        print_status "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        print_warning "Configuration file not found. Will create new one."
    fi
}

# Function to save configuration
save_config() {
    print_status "Saving configuration to $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOF
# SAP Joule Document Grounding Configuration
# Generated on $(date)

# Document Grounding Instance
DOC_GROUNDING_INSTANCE_NAME="$DOC_GROUNDING_INSTANCE_NAME"
DOC_GROUNDING_SERVICE_BINDING_NAME="$DOC_GROUNDING_SERVICE_BINDING_NAME"
DOC_GROUNDING_SERVICE_BINDING_URL="$DOC_GROUNDING_SERVICE_BINDING_URL"

# Cloud Identity Services Instance
CLOUD_IDENTITY_INSTANCE_NAME="$CLOUD_IDENTITY_INSTANCE_NAME"
CLOUD_IDENTITY_SERVICE_BINDING_NAME="$CLOUD_IDENTITY_SERVICE_BINDING_NAME"

# Authentication Details
CLIENT_ID="$CLIENT_ID"
AUTHORIZATION_ENDPOINT="$AUTHORIZATION_ENDPOINT"
TOKEN_ENDPOINT="$TOKEN_ENDPOINT"

# Certificate Files
CERT_FILE="$CERT_FILE"
KEY_FILE="$KEY_FILE"
EOF
    chmod 600 "$CONFIG_FILE"
    print_status "Configuration saved to $CONFIG_FILE"
}

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        if [ -z "$input" ]; then
            input="$default"
        fi
    else
        read -p "$prompt: " input
    fi
    
    eval "$var_name=\"$input\""
}

# Function to create document grounding instance
create_document_grounding_instance() {
    print_header "Step 1-6: Creating Document Grounding Instance"
    
    get_input "Enter Document Grounding Instance Name" "$DOC_GROUNDING_INSTANCE_NAME" "DOC_GROUNDING_INSTANCE_NAME"
    get_input "Enter Document Grounding Service Binding Name" "$DOC_GROUNDING_SERVICE_BINDING_NAME" "DOC_GROUNDING_SERVICE_BINDING_NAME"
    
    print_status "Please complete the following steps in SAP BTP Cockpit:"
    echo "1. Go to Services > Service Marketplace"
    echo "2. Search for 'document grounding' and choose the tile"
    echo "3. Choose Create"
    echo "4. Choose 'Other' as Runtime Environment"
    echo "5. Enter Instance Name: $DOC_GROUNDING_INSTANCE_NAME"
    echo "6. Choose Create"
    echo "7. Choose 'View Instance'"
    echo "8. Select the instance and create a service binding"
    echo "9. Enter Service Binding Name: $DOC_GROUNDING_SERVICE_BINDING_NAME"
    echo "10. Choose Create"
    echo "11. Copy the service binding URL"
    
    get_input "Enter the Document Grounding Service Binding URL" "$DOC_GROUNDING_SERVICE_BINDING_URL" "DOC_GROUNDING_SERVICE_BINDING_URL"
    
    print_status "Document Grounding instance configuration completed"
}

# Function to create cloud identity services instance
create_cloud_identity_instance() {
    print_header "Step 7-15: Creating Cloud Identity Services Instance"
    
    get_input "Enter Cloud Identity Services Instance Name" "$CLOUD_IDENTITY_INSTANCE_NAME" "CLOUD_IDENTITY_INSTANCE_NAME"
    get_input "Enter Cloud Identity Service Binding Name" "$CLOUD_IDENTITY_SERVICE_BINDING_NAME" "CLOUD_IDENTITY_SERVICE_BINDING_NAME"
    
    print_status "Please complete the following steps in SAP BTP Cockpit:"
    echo "1. Go to Services > Service Marketplace"
    echo "2. Search for 'Cloud Identity Services' and choose the tile"
    echo "3. Choose Create"
    echo "4. Choose 'application' as Plan and 'Other' as Runtime Environment"
    echo "5. Enter Instance Name: $CLOUD_IDENTITY_INSTANCE_NAME"
    echo "6. Choose Next"
    echo "7. In Parameters, enter the following JSON:"
    echo "   {"
    echo "     \"consumed-services\": ["
    echo "       {"
    echo "         \"service-instance-name\": \"$DOC_GROUNDING_INSTANCE_NAME\""
    echo "       }"
    echo "     ]"
    echo "   }"
    echo "8. Choose Create"
    echo "9. Choose 'View Instance'"
    echo "10. Select the instance and create a service binding"
    echo "11. Enter Service Binding Name: $CLOUD_IDENTITY_SERVICE_BINDING_NAME"
    echo "12. Enter the following parameters:"
    echo "    {"
    echo "      \"credential-type\": \"X509_GENERATED\","
    echo "      \"validity\": 365,"
    echo "      \"validity-type\": \"DAYS\""
    echo "    }"
    echo "13. Choose Create"
    echo "14. Copy the values for 'clientid' and 'authorization_endpoint'"
    
    get_input "Enter the clientid value" "$CLIENT_ID" "CLIENT_ID"
    get_input "Enter the authorization_endpoint value" "$AUTHORIZATION_ENDPOINT" "AUTHORIZATION_ENDPOINT"
    
    # Convert authorization_endpoint to token endpoint
    TOKEN_ENDPOINT="${AUTHORIZATION_ENDPOINT%/oauth2/authorize}/oauth2/token"
    print_status "Token endpoint calculated: $TOKEN_ENDPOINT"
    
    print_status "Cloud Identity Services instance configuration completed"
}

# Function to create certificate files
create_certificate_files() {
    print_header "Step 16-19: Creating Certificate Files"
    
            print_status "Choose how to input certificate and key values:"
        echo "1. Enter values directly (for small certificates)"
        echo "2. Read from files (recommended for large certificates)"
        echo "3. Use clipboard (macOS only)"
        echo ""
        print_status "For option 2, you can:"
        echo "  - Select from available files in credentials/ and credentials_adjusted/ directories"
        echo "  - Enter custom paths (relative or absolute)"
        echo "  - Drag and drop files from Finder"
        echo "  - Generated files will be saved in credentials_adjusted/ directory"
    
    read -p "Select option (1-3): " input_method
    
    case $input_method in
        1)
            # Direct input method
            print_warning "Direct input may not work for large certificates"
            get_input "Enter the certificate value from service binding" "" "CERT_VALUE"
            get_input "Enter the key value from service binding" "" "KEY_VALUE"
            ;;
        2)
            # File input method
            print_status "Available files in credentials directory:"
            
            # Check if credentials directory exists
            if [ -d "credentials" ]; then
                echo "Files in credentials directory:"
                ls -la credentials/
                echo ""
                
                # Get list of certificate files
                CERT_FILES=($(find credentials/ -name "*.cer" -o -name "*.crt" -o -name "*.pem" 2>/dev/null))
                KEY_FILES=($(find credentials/ -name "*.key" -o -name "*.pem" 2>/dev/null))
                
                # Also check credentials_adjusted directory
                if [ -d "credentials_adjusted" ]; then
                    echo "Files in credentials_adjusted directory:"
                    ls -la credentials_adjusted/
                    echo ""
                    
                    # Get list of files from credentials_adjusted
                    ADJUSTED_CERT_FILES=($(find credentials_adjusted/ -name "*.cer" -o -name "*.crt" -o -name "*.pem" 2>/dev/null))
                    ADJUSTED_KEY_FILES=($(find credentials_adjusted/ -name "*.key" -o -name "*.pem" 2>/dev/null))
                    
                    # Combine both directories
                    CERT_FILES+=("${ADJUSTED_CERT_FILES[@]}")
                    KEY_FILES+=("${ADJUSTED_KEY_FILES[@]}")
                fi
                
                if [ ${#CERT_FILES[@]} -gt 0 ]; then
                    echo "Available certificate files:"
                    for i in "${!CERT_FILES[@]}"; do
                        echo "  $((i+1)). ${CERT_FILES[$i]}"
                    done
                    
                    read -p "Select certificate file number (1-${#CERT_FILES[@]}) or enter custom path: " cert_choice
                    
                    if [[ "$cert_choice" =~ ^[0-9]+$ ]] && [ "$cert_choice" -ge 1 ] && [ "$cert_choice" -le ${#CERT_FILES[@]} ]; then
                        CERT_INPUT_FILE="${CERT_FILES[$((cert_choice-1))]}"
                        print_status "Selected certificate file: $CERT_INPUT_FILE"
                    else
                        get_input "Enter path to certificate file (or drag and drop file here)" "" "CERT_INPUT_FILE"
                    fi
                else
                    get_input "Enter path to certificate file (or drag and drop file here)" "" "CERT_INPUT_FILE"
                fi
                
                if [ ${#KEY_FILES[@]} -gt 0 ]; then
                    echo "Available key files:"
                    for i in "${!KEY_FILES[@]}"; do
                        echo "  $((i+1)). ${KEY_FILES[$i]}"
                    done
                    
                    read -p "Select key file number (1-${#KEY_FILES[@]}) or enter custom path: " key_choice
                    
                    if [[ "$key_choice" =~ ^[0-9]+$ ]] && [ "$key_choice" -ge 1 ] && [ "$key_choice" -le ${#KEY_FILES[@]} ]; then
                        KEY_INPUT_FILE="${KEY_FILES[$((key_choice-1))]}"
                        print_status "Selected key file: $KEY_INPUT_FILE"
                    else
                        get_input "Enter path to key file (or drag and drop file here)" "" "KEY_INPUT_FILE"
                    fi
                else
                    get_input "Enter path to key file (or drag and drop file here)" "" "KEY_INPUT_FILE"
                fi
            else
                print_warning "Credentials directory not found. Please enter file paths manually."
                get_input "Enter path to certificate file (or drag and drop file here)" "" "CERT_INPUT_FILE"
                get_input "Enter path to key file (or drag and drop file here)" "" "KEY_INPUT_FILE"
            fi
            
            # Remove quotes if present (from drag and drop) and normalize path
            CERT_INPUT_FILE=$(echo "$CERT_INPUT_FILE" | tr -d '"' | tr -d "'")
            KEY_INPUT_FILE=$(echo "$KEY_INPUT_FILE" | tr -d '"' | tr -d "'")
            
            # Normalize path by removing any extra slashes and resolving . and ..
            CERT_INPUT_FILE=$(realpath "$CERT_INPUT_FILE" 2>/dev/null || echo "$CERT_INPUT_FILE")
            KEY_INPUT_FILE=$(realpath "$KEY_INPUT_FILE" 2>/dev/null || echo "$KEY_INPUT_FILE")
            
            # Show helpful information about path resolution
            print_status "Certificate file path: $CERT_INPUT_FILE"
            print_status "Key file path: $KEY_INPUT_FILE"
            print_status "Current working directory: $(pwd)"
            
            # Try to resolve relative paths (only if not already absolute)
            if [[ "$CERT_INPUT_FILE" != /* ]]; then
                print_status "Certificate path is relative, resolving from current directory"
                CERT_INPUT_FILE="$(pwd)/$CERT_INPUT_FILE"
                print_status "Resolved certificate path: $CERT_INPUT_FILE"
            else
                print_status "Certificate path is already absolute"
            fi
            
            if [[ "$KEY_INPUT_FILE" != /* ]]; then
                print_status "Key path is relative, resolving from current directory"
                KEY_INPUT_FILE="$(pwd)/$KEY_INPUT_FILE"
                print_status "Resolved key path: $KEY_INPUT_FILE"
            else
                print_status "Key path is already absolute"
            fi
            
            # Check if files exist and provide detailed error information
            if [ ! -f "$CERT_INPUT_FILE" ]; then
                print_error "Certificate input file not found: $CERT_INPUT_FILE"
                print_status "Current working directory: $(pwd)"
                print_status "Available files in current directory:"
                ls -la
                if [ -d "$(dirname "$CERT_INPUT_FILE")" ]; then
                    print_status "Files in target directory:"
                    ls -la "$(dirname "$CERT_INPUT_FILE")"
                fi
                return 1
            fi
            
            if [ ! -f "$KEY_INPUT_FILE" ]; then
                print_error "Key input file not found: $KEY_INPUT_FILE"
                print_status "Current working directory: $(pwd)"
                print_status "Available files in current directory:"
                ls -la
                if [ -d "$(dirname "$KEY_INPUT_FILE")" ]; then
                    print_status "Files in target directory:"
                    ls -la "$(dirname "$KEY_INPUT_FILE")"
                fi
                return 1
            fi
            
            # Read values from files
            CERT_VALUE=$(cat "$CERT_INPUT_FILE")
            KEY_VALUE=$(cat "$KEY_INPUT_FILE")
            
            print_status "Certificate and key values loaded from files"
            ;;
        3)
            # Clipboard method (macOS only)
            if command -v pbcopy &> /dev/null && command -v pbpaste &> /dev/null; then
                print_status "macOS clipboard detected"
                echo "Please copy the certificate value to clipboard, then press Enter"
                read -p "Press Enter after copying certificate to clipboard..."
                CERT_VALUE=$(pbpaste)
                
                echo "Please copy the key value to clipboard, then press Enter"
                read -p "Press Enter after copying key to clipboard..."
                KEY_VALUE=$(pbpaste)
                
                print_status "Certificate and key values loaded from clipboard"
            else
                print_error "Clipboard commands not available. Please use file input method."
                return 1
            fi
            ;;
        *)
            print_error "Invalid option selected"
            return 1
            ;;
    esac
    
    # Validate that we have values
    if [ -z "$CERT_VALUE" ] || [ -z "$KEY_VALUE" ]; then
        print_error "Certificate or key value is empty"
        return 1
    fi
    
    # Default file names in credentials_adjusted directory
    CERT_FILE="${CERT_FILE:-credentials_adjusted/doc-grounding.crt}"
    KEY_FILE="${KEY_FILE:-credentials_adjusted/doc-grounding.key}"
    
    # Ensure credentials_adjusted directory exists
    mkdir -p credentials_adjusted
    
    get_input "Enter certificate filename (will be saved in credentials_adjusted/)" "$CERT_FILE" "CERT_FILE"
    get_input "Enter key filename (will be saved in credentials_adjusted/)" "$KEY_FILE" "KEY_FILE"
    
    # Ensure files are saved in credentials_adjusted directory
    if [[ "$CERT_FILE" != credentials_adjusted/* ]]; then
        CERT_FILE="credentials_adjusted/$CERT_FILE"
        print_status "Certificate file will be saved as: $CERT_FILE"
    fi
    
    if [[ "$KEY_FILE" != credentials_adjusted/* ]]; then
        KEY_FILE="credentials_adjusted/$KEY_FILE"
        print_status "Key file will be saved as: $KEY_FILE"
    fi
    
    # Create certificate file
    print_status "Creating certificate file: $CERT_FILE"
    echo -e "$CERT_VALUE" > "$CERT_FILE"
    
    # Create key file
    print_status "Creating key file: $KEY_FILE"
    echo -e "$KEY_VALUE" > "$KEY_FILE"
    
    # Convert \n to actual line breaks using sed (macOS compatible)
    print_status "Converting \\n to line breaks in certificate file"
    sed 's/\\n/\n/g' "$CERT_FILE" > temp.crt && mv temp.crt "$CERT_FILE"
    
    print_status "Converting \\n to line breaks in key file"
    sed 's/\\n/\n/g' "$KEY_FILE" > temp.key && mv temp.key "$KEY_FILE"
    
    # Set proper permissions
    chmod 600 "$CERT_FILE" "$KEY_FILE"
    
    print_status "Certificate files created successfully"
    print_warning "Certificate files are set to read-only for security"
    
    # Show file sizes for verification
    CERT_SIZE=$(wc -c < "$CERT_FILE")
    KEY_SIZE=$(wc -c < "$KEY_FILE")
    print_status "Certificate file size: $CERT_SIZE bytes"
    print_status "Key file size: $KEY_SIZE bytes"
}

# Function to get access token
get_access_token() {
    print_header "Step 20: Getting Access Token"
    
    print_status "Requesting access token..."
    
    # Check if certificate files exist
    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        print_error "Certificate files not found. Please run the certificate creation step first."
        return 1
    fi
    
    # Make the token request
    TOKEN_RESPONSE=$(curl -s \
        --request POST \
        --url "$TOKEN_ENDPOINT" \
        --header 'accept: application/json' \
        --header 'content-type: application/x-www-form-urlencoded' \
        --data "client_id=$CLIENT_ID" \
        --data 'grant_type=client_credentials' \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    # Extract access token
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$ACCESS_TOKEN" ]; then
        print_status "Access token obtained successfully"
        echo "Token: ${ACCESS_TOKEN:0:20}..."
        
        # Save token to config
        echo "ACCESS_TOKEN=\"$ACCESS_TOKEN\"" >> "$CONFIG_FILE"
        
        return 0
    else
        print_error "Failed to obtain access token"
        echo "Response: $TOKEN_RESPONSE"
        return 1
    fi
}

# Function to test document grounding endpoints
test_endpoints() {
    print_header "Step 21: Testing Document Grounding Endpoints"
    
    # Load the access token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Access token not found. Please run the token generation step first."
        return 1
    fi
    
    print_status "Testing document grounding pipeline endpoint..."
    
    RESPONSE=$(curl -s \
        --request GET \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline" \
        --header 'accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    print_status "Response received:"
    echo "$RESPONSE"
    
    if [[ "$RESPONSE" == "[]" ]]; then
        print_status "Success! Empty pipeline list received (expected for new setup)"
    else
        print_warning "Unexpected response received"
    fi
}

# Function to create WorkZone pipeline
create_pipeline() {
    print_header "Step 22: Creating WorkZone Pipeline"
    
    # Load the access token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Access token not found. Please run the token generation step first."
        return 1
    fi
    
    print_status "Creating WorkZone pipeline for document grounding..."
    print_status "Based on SAP AI Core WorkZone pipeline creation"
    
    # Get required parameters
    get_input "AI Resource Group" "" "AI_RESOURCE_GROUP"
    get_input "Generic Secret Name (destination)" "" "GENERIC_SECRET_NAME"
    
    # Create pipeline configuration
    PIPELINE_CONFIG="{
        \"type\": \"WorkZone\",
        \"metadata\": {
            \"destination\": \"$GENERIC_SECRET_NAME\"
        }
    }"
    
    print_status "Pipeline configuration: $PIPELINE_CONFIG"
    
    # Create pipeline using the document grounding endpoint
    RESPONSE=$(curl -s \
        --request POST \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline" \
        --header 'accept: application/json' \
        --header 'content-type: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --data "$PIPELINE_CONFIG" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    print_status "Response received:"
    echo "$RESPONSE"
    
    # Extract pipeline ID if successful
    PIPELINE_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$PIPELINE_ID" ]; then
        print_status "Pipeline created successfully with ID: $PIPELINE_ID"
        # Save pipeline configuration to config
        echo "AI_RESOURCE_GROUP=\"$AI_RESOURCE_GROUP\"" >> "$CONFIG_FILE"
        echo "GENERIC_SECRET_NAME=\"$GENERIC_SECRET_NAME" >> "$CONFIG_FILE"
        echo "PIPELINE_ID=\"$PIPELINE_ID\"" >> "$CONFIG_FILE"
    else
        print_warning "Pipeline ID not found in response"
    fi
}

# Function to display configuration summary
show_summary() {
    print_header "Configuration Summary"
    
    echo "Document Grounding Instance: $DOC_GROUNDING_INSTANCE_NAME"
    echo "Document Grounding Service Binding: $DOC_GROUNDING_SERVICE_BINDING_NAME"
    echo "Document Grounding URL: $DOC_GROUNDING_SERVICE_BINDING_URL"
    echo ""
    echo "Cloud Identity Instance: $CLOUD_IDENTITY_INSTANCE_NAME"
    echo "Cloud Identity Service Binding: $CLOUD_IDENTITY_SERVICE_BINDING_NAME"
    echo "Client ID: $CLIENT_ID"
    echo "Token Endpoint: $TOKEN_ENDPOINT"
    echo ""
    echo "Certificate Files:"
    echo "  Certificate: $CERT_FILE"
    echo "  Key: $KEY_FILE"
    echo ""
    
    # Load pipeline information if available
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        if [ -n "$PIPELINE_ID" ]; then
            echo "Pipeline Information:"
            echo "  Pipeline ID: $PIPELINE_ID"
            if [ -n "$AI_RESOURCE_GROUP" ]; then
                echo "  AI Resource Group: $AI_RESOURCE_GROUP"
            fi
            if [ -n "$GENERIC_SECRET_NAME" ]; then
                echo "  Generic Secret Name: $GENERIC_SECRET_NAME"
            fi
        fi
    fi
    
    echo ""
    echo "Configuration saved to: $CONFIG_FILE"
}

# Function to show main menu
show_menu() {
    clear
    print_header "SAP Joule Document Grounding Setup"
    echo ""
    echo "1. Create Document Grounding Instance"
    echo "2. Create Cloud Identity Services Instance"
    echo "3. Create Certificate Files"
    echo "4. Get Access Token"
    echo "5. Test Document Grounding Endpoints"
    echo "6. Create WorkZone Pipeline"
    echo "7. Show Configuration Summary"
    echo "8. Load/Save Configuration"
    echo "9. Exit"
    echo ""
}

# Main function
main() {
    # Load existing configuration if available
    load_config
    
    while true; do
        show_menu
        read -p "Select an option (1-8): " choice
        
        case $choice in
            1)
                create_document_grounding_instance
                save_config
                ;;
            2)
                create_cloud_identity_instance
                save_config
                ;;
            3)
                create_certificate_files
                save_config
                ;;
            4)
                get_access_token
                ;;
            5)
                test_endpoints
                ;;
            6)
                create_pipeline
                ;;
            7)
                show_summary
                ;;
            8)
                load_config
                save_config
                ;;
            9)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-9."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS. Please use the appropriate version for your operating system."
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed. Please install curl first."
    exit 1
fi

# Check if sed is available
if ! command -v sed &> /dev/null; then
    print_error "sed is required but not installed. Please install sed first."
    exit 1
fi

# Run main function
main
