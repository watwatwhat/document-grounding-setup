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

# Pipeline management file
PIPELINES_FILE="pipelines.json"

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

# Function to load pipelines
load_pipelines() {
    if [ -f "$PIPELINES_FILE" ]; then
        print_status "Loading pipelines from $PIPELINES_FILE"
        # pipelines.json is loaded as needed in specific functions
    else
        print_warning "Pipelines file not found. Will create new one."
        # Create empty pipelines file
        echo "{}" > "$PIPELINES_FILE"
        print_status "Created empty pipelines file: $PIPELINES_FILE"
    fi
}

# Function to save pipeline to pipelines.json
save_pipeline() {
    local pipeline_id="$1"
    local pipeline_data="$2"
    
    if [ -z "$pipeline_id" ] || [ -z "$pipeline_data" ]; then
        print_error "Invalid pipeline data for saving"
        return 1
    fi
    
    # Load existing pipelines
    if [ -f "$PIPELINES_FILE" ]; then
        # Use jq if available, otherwise use simple text replacement
        if command -v jq &> /dev/null; then
            # Use jq for proper JSON manipulation
            jq --arg id "$pipeline_id" --argjson data "$pipeline_data" \
               '. + {($id): $data}' "$PIPELINES_FILE" > temp_pipelines.json && \
            mv temp_pipelines.json "$PIPELINES_FILE"
        else
            # Simple text replacement (less robust but works without jq)
                    # Check if file is empty or just contains {}
        if [ ! -s "$PIPELINES_FILE" ] || [ "$(cat "$PIPELINES_FILE")" = "{}" ]; then
            # File is empty or just contains {}, create new structure
            cat > "$PIPELINES_FILE" << EOF
{
  "$pipeline_id": {
    "type": "WorkZone",
    "configuration": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "metadata": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "CREATED"
  }
}
EOF
        else
            # Remove existing entry if present and add new one
            grep -v "\"$pipeline_id\"" "$PIPELINES_FILE" > temp_pipelines.json 2>/dev/null
            if [ -s temp_pipelines.json ]; then
                # Remove trailing comma if exists and add new entry
                sed 's/,$//' temp_pipelines.json > temp_pipelines2.json
                cat >> temp_pipelines2.json << EOF
,
  "$pipeline_id": {
    "type": "WorkZone",
    "configuration": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "metadata": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "CREATED"
  }
}
EOF
                mv temp_pipelines2.json "$PIPELINES_FILE"
            else
                # File became empty, create new structure
                cat > "$PIPELINES_FILE" << EOF
{
  "$pipeline_id": {
    "type": "WorkZone",
    "configuration": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "metadata": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "CREATED"
  }
}
EOF
            fi
            rm -f temp_pipelines.json
        fi
        fi
        print_status "Pipeline saved to $PIPELINES_FILE"
    else
        # Create new file
        cat > "$PIPELINES_FILE" << EOF
{
  "$pipeline_id": {
    "type": "WorkZone",
    "configuration": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "metadata": {
      "destination": "DocumentGrounding_WZAdv"
    },
    "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "CREATED"
  }
}
EOF
        print_status "Created new pipelines file with pipeline: $PIPELINES_FILE"
    fi
}

# Function to remove pipeline from pipelines.json
remove_pipeline() {
    local pipeline_id="$1"
    
    if [ -z "$pipeline_id" ]; then
        print_error "Invalid pipeline ID for removal"
        return 1
    fi
    
    if [ -f "$PIPELINES_FILE" ]; then
        if command -v jq &> /dev/null; then
            # Use jq for proper JSON manipulation
            jq "del(.$pipeline_id)" "$PIPELINES_FILE" > temp_pipelines.json && \
            mv temp_pipelines.json "$PIPELINES_FILE"
        else
            # Simple text replacement
            grep -v "\"$pipeline_id\"" "$PIPELINES_FILE" > temp_pipelines.json
            mv temp_pipelines.json "$PIPELINES_FILE"
        fi
        print_status "Pipeline removed from $PIPELINES_FILE"
    fi
}

# Function to get pipeline from pipelines.json
get_pipeline() {
    local pipeline_id="$1"
    
    if [ -z "$pipeline_id" ]; then
        print_error "Invalid pipeline ID"
        return 1
    fi
    
    if [ -f "$PIPELINES_FILE" ]; then
        if command -v jq &> /dev/null; then
            jq -r ".$pipeline_id" "$PIPELINES_FILE" 2>/dev/null
        else
            # Simple text extraction
            sed -n '/"'$pipeline_id'":/,/^  }/p' "$PIPELINES_FILE" | grep -v "^  }$" | sed '1s/.*: //'
        fi
    fi
}

# Function to list all pipelines from pipelines.json
list_pipelines() {
    if [ -f "$PIPELINES_FILE" ]; then
        if command -v jq &> /dev/null; then
            jq -r 'keys[]' "$PIPELINES_FILE" 2>/dev/null
        else
            # Simple text extraction
            grep -o '"[^"]*":' "$PIPELINES_FILE" | sed 's/":$//' | sed 's/^"//'
        fi
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
    
    # Debug: Show the actual response structure
    if [[ "$RESPONSE" != "[]" ]] && [[ "$RESPONSE" != "null" ]]; then
        echo ""
        print_status "Debug: Response structure analysis:"
        echo "Raw response: $RESPONSE"
        
        # Try to format with python3 if available
        if command -v python3 &> /dev/null; then
            echo ""
            print_status "Formatted response:"
            echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "Failed to format JSON"
        fi
    fi
    
    # Parse and display pipeline information for selection
    if [[ "$RESPONSE" != "[]" ]] && [[ "$RESPONSE" != "null" ]]; then
        echo ""
        print_status "Available Pipelines:"
        
        # Extract pipeline information using grep and sed
        PIPELINE_COUNT=$(echo "$RESPONSE" | grep -o '"count":[0-9]*' | cut -d':' -f2)
        if [ -z "$PIPELINE_COUNT" ]; then
            # If no count field, count the number of pipeline objects manually
            PIPELINE_COUNT=$(echo "$RESPONSE" | grep -o '"id":' | wc -l)
        fi
        
        if [ -n "$PIPELINE_COUNT" ] && [ "$PIPELINE_COUNT" -gt 0 ]; then
            echo "Total Pipelines: $PIPELINE_COUNT"
            echo ""
            
            # Display pipeline information
            echo ""
            print_status "Available Pipelines:"
            echo "Total Pipelines: $PIPELINE_COUNT"
            echo ""
            
            # Show formatted response
            if command -v python3 &> /dev/null; then
                print_status "Formatted pipeline data:"
                echo "$RESPONSE" | python3 -m json.tool
            else
                print_status "Pipeline data:"
                echo "$RESPONSE"
            fi
            
            # Ask if user wants to refresh pipelines.json with current data
            echo ""
            read -p "Do you want to refresh $PIPELINES_FILE with current pipeline data? (y/n): " refresh_pipelines
            if [[ "$refresh_pipelines" =~ ^[Yy]$ ]]; then
                # Simply save the response directly to pipelines.json
                print_status "Refreshing $PIPELINES_FILE with current pipeline data..."
                
                # Convert array response to object format for easier access
                if command -v jq &> /dev/null; then
                    # Use jq to convert array to object with pipeline IDs as keys
                    jq -r 'reduce .[] as $pipeline ({}; . + {($pipeline.id): $pipeline})' <<< "$RESPONSE" > "$PIPELINES_FILE"
                    print_status "$PIPELINES_FILE refreshed successfully using jq!"
                else
                    # Simple approach: create a new file with the response data
                    # Add timestamp to each pipeline
                    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
                    echo "$RESPONSE" | sed 's/}/, "fetchedAt": "'$TIMESTAMP'", "status": "FETCHED"}/g' > "$PIPELINES_FILE"
                    print_status "$PIPELINES_FILE refreshed successfully!"
                fi
                
                print_status "Updated content:"
                cat "$PIPELINES_FILE"
            fi
        fi
    fi
}

# Function to configure WorkZone integration
configure_workzone_integration() {
    print_header "Step 22: Configuring WorkZone Integration"
    
    print_status "This step configures the integration between SAP Build Work Zone and Document Grounding."
    print_status "You will need to complete several steps in SAP BTP Cockpit and WorkZone Admin Console."
    echo ""
    
    print_status "Step 1: Create OAuth Client in WorkZone Admin Console"
    echo "1. Go to Admin Console > External Integrations > OAuth Clients"
    echo "2. Click 'Add OAuth Client'"
    echo "3. Name: 'Document Grounding OAuth Client' (or any meaningful name)"
    echo "4. Integration URL: 'https://www.yoururl.com' (any valid URL format)"
    echo "5. Click 'Create' and note down the Key and Secret values"
    echo ""
    
    print_status "Step 2: Enable Document Grounding Feature"
    echo "1. Go to Admin Console > Feature Enablement > Features"
    echo "2. In Feature Management section, enable 'Enable document grounding integration'"
    echo "3. Select the OAuth client created in Step 1"
    echo "4. Save changes"
    echo ""
    
    print_status "Step 3: Create Destination in BTP Cockpit"
    echo "1. Go to Connectivity > Destinations"
    echo "2. Create new destination with the following details:"
    echo "   - URL: Your DWS URL (from Admin Console Overview screen)/api/v1/dg-pipeline/metadata"
    echo "   - Proxy Type: Internet"
    echo "   - Authentication: OAuth2ClientCredentials"
    echo "   - Client ID: OAuth client Key from Step 1"
    echo "   - Client Secret: OAuth client Secret from Step 1"
    echo "   - Token Service URL Type: Dedicated"
    echo "   - Token Service URL: Your DWS URL/api/v1/auth/token"
    echo "3. Add Additional Properties:"
    echo "   - HTML5.DynamicDestination: true"
    echo "   - SetXForwardedHeaders: false"
    echo "   - HTML5.SetXForwardedHeaders: false"
    echo ""
    
    print_status "Now let's collect the required information:"
    
    # Get destination name only
    get_input "Destination Name (e.g., DocumentGrounding_WZAdv)" "" "DESTINATION_NAME"
    
    # Save configuration
    echo "DESTINATION_NAME=\"$DESTINATION_NAME\"" >> "$CONFIG_FILE"
    
    print_status "WorkZone integration configuration saved successfully!"
    print_status "You can now proceed to create the pipeline in the next step."
}

# Function to check grounding status
check_grounding_status() {
    print_header "Check Grounding Status"
    
    # Load configuration and get fresh token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Check if we have the required configuration
    if [ -z "$DOC_GROUNDING_SERVICE_BINDING_URL" ] || [ -z "$CERT_FILE" ] || [ -z "$KEY_FILE" ]; then
        print_error "Missing required configuration. Please complete the setup steps first."
        return 1
    fi
    
    # Get fresh access token
    print_status "Getting fresh access token for status check..."
    if ! get_access_token; then
        print_error "Failed to get access token. Cannot proceed with status check."
        return 1
    fi
    
    # Reload config to get the new token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Show status check menu
    while true; do
        echo ""
        print_header "Grounding Status Check Options"
        echo "1. Check Pipeline Status"
        echo "2. Check Execution Status"
        echo "3. Check Document Status"
        echo "4. Check All Statuses"
        echo "5. Back to Main Menu"
        echo ""
        
        read -p "Select an option (1-5): " status_choice
        
        case $status_choice in
            1)
                check_pipeline_status
                ;;
            2)
                check_execution_status
                ;;
            3)
                check_document_status
                ;;
            4)
                check_all_statuses
                ;;
            5)
                return 0
                ;;
            *)
                print_error "Invalid option. Please select 1-5."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Function to check pipeline status
check_pipeline_status() {
    print_header "Pipeline Status Check"
    
    if [ -z "$PIPELINE_ID" ]; then
        print_warning "No pipeline ID found in configuration."
        
        # Try to get pipeline ID from pipelines.json
        if [ -f "$PIPELINES_FILE" ]; then
            print_status "Checking $PIPELINES_FILE for available pipelines..."
            
            # List available pipelines
            AVAILABLE_PIPELINES=($(list_pipelines))
            if [ ${#AVAILABLE_PIPELINES[@]} -gt 0 ]; then
                echo ""
                print_status "Available pipelines in $PIPELINES_FILE:"
                for i in "${!AVAILABLE_PIPELINES[@]}"; do
                    echo "$((i+1)). ${AVAILABLE_PIPELINES[$i]}"
                done
                echo ""
                
                read -p "Select pipeline number (1-${#AVAILABLE_PIPELINES[@]}) or enter custom Pipeline ID: " pipeline_choice
                
                if [[ "$pipeline_choice" =~ ^[0-9]+$ ]] && [ "$pipeline_choice" -ge 1 ] && [ "$pipeline_choice" -le ${#AVAILABLE_PIPELINES[@]} ]; then
                    PIPELINE_ID="${AVAILABLE_PIPELINES[$((pipeline_choice-1))]}"
                    print_status "Selected Pipeline ID: $PIPELINE_ID"
                else
                    PIPELINE_ID="$pipeline_choice"
                fi
            else
                print_warning "No pipelines found in $PIPELINES_FILE"
                get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
            fi
        else
            print_warning "$PIPELINES_FILE not found"
            get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
        fi
        
        if [ -z "$PIPELINE_ID" ]; then
            print_error "Pipeline ID is required."
            return 1
        fi
    fi
    
    print_status "Checking status for pipeline: $PIPELINE_ID"
    
    RESPONSE=$(curl -s \
        --request GET \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID/status" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    if [ $? -eq 0 ]; then
        print_status "Pipeline Status Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        
        # Extract and display status
        STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$STATUS" ]; then
            echo ""
            print_status "Current Pipeline Status: $STATUS"
        fi
    else
        print_error "Failed to get pipeline status"
        echo "Response: $RESPONSE"
    fi
}

# Function to check execution status
check_execution_status() {
    print_header "Execution Status Check"
    
    if [ -z "$PIPELINE_ID" ]; then
        print_warning "No pipeline ID found in configuration."
        
        # Try to get pipeline ID from pipelines.json
        if [ -f "$PIPELINES_FILE" ]; then
            print_status "Checking $PIPELINES_FILE for available pipelines..."
            
            # List available pipelines
            AVAILABLE_PIPELINES=($(list_pipelines))
            if [ ${#AVAILABLE_PIPELINES[@]} -gt 0 ]; then
                echo ""
                print_status "Available pipelines in $PIPELINES_FILE:"
                for i in "${!AVAILABLE_PIPELINES[@]}"; do
                    echo "$((i+1)). ${AVAILABLE_PIPELINES[$i]}"
                done
                echo ""
                
                read -p "Select pipeline number (1-${#AVAILABLE_PIPELINES[@]}) or enter custom Pipeline ID: " pipeline_choice
                
                if [[ "$pipeline_choice" =~ ^[0-9]+$ ]] && [ "$pipeline_choice" -ge 1 ] && [ "$pipeline_choice" -le ${#AVAILABLE_PIPELINES[@]} ]; then
                    PIPELINE_ID="${AVAILABLE_PIPELINES[$((pipeline_choice-1))]}"
                    print_status "Selected Pipeline ID: $PIPELINE_ID"
                else
                    PIPELINE_ID="$pipeline_choice"
                fi
            else
                print_warning "No pipelines found in $PIPELINES_FILE"
                get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
            fi
        else
            print_warning "$PIPELINES_FILE not found"
            get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
        fi
        
        if [ -z "$PIPELINE_ID" ]; then
            print_error "Pipeline ID is required."
            return 1
        fi
    fi
    
    print_status "Checking executions for pipeline: $PIPELINE_ID"
    
    RESPONSE=$(curl -s \
        --request GET \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID/executions" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    if [ $? -eq 0 ]; then
        print_status "Execution Status Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        
        # Extract execution count
        EXECUTION_COUNT=$(echo "$RESPONSE" | grep -o '"count":[0-9]*' | cut -d':' -f2)
        
        # Validate that we got a valid number
        if [ -n "$EXECUTION_COUNT" ] && [[ "$EXECUTION_COUNT" =~ ^[0-9]+$ ]]; then
            echo ""
            print_status "Total Executions: $EXECUTION_COUNT"
            
            # Ask if user wants to check specific execution
            if [ "$EXECUTION_COUNT" -gt 0 ]; then
                echo ""
                read -p "Do you want to check a specific execution? (y/n): " check_specific
                if [[ "$check_specific" =~ ^[Yy]$ ]]; then
                    get_input "Enter Execution ID" "" "EXECUTION_ID"
                    if [ -n "$EXECUTION_ID" ]; then
                        check_specific_execution "$EXECUTION_ID"
                    fi
                fi
            fi
        fi
    else
        print_error "Failed to get execution status"
        echo "Response: $RESPONSE"
    fi
}

# Function to check specific execution
check_specific_execution() {
    local execution_id="$1"
    
    print_status "Checking specific execution: $execution_id"
    
    RESPONSE=$(curl -s \
        --request GET \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID/executions/$execution_id" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    if [ $? -eq 0 ]; then
        print_status "Specific Execution Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
        print_error "Failed to get specific execution status"
        echo "Response: $RESPONSE"
    fi
}

# Function to check document status
check_document_status() {
    print_header "Document Status Check"
    
    if [ -z "$PIPELINE_ID" ]; then
        print_warning "No pipeline ID selected."
        
        # Try to get pipeline ID from pipelines.json
        if [ -f "$PIPELINES_FILE" ]; then
            print_status "Checking $PIPELINES_FILE for available pipelines..."
            
            # List available pipelines
            AVAILABLE_PIPELINES=($(list_pipelines))
            if [ ${#AVAILABLE_PIPELINES[@]} -gt 0 ]; then
                echo ""
                print_status "Available pipelines in $PIPELINES_FILE:"
                for i in "${!AVAILABLE_PIPELINES[@]}"; do
                    echo "$((i+1)). ${AVAILABLE_PIPELINES[$i]}"
                done
                echo ""
                
                read -p "Select pipeline number (1-${#AVAILABLE_PIPELINES[@]}) or enter custom Pipeline ID: " pipeline_choice
                
                if [[ "$pipeline_choice" =~ ^[0-9]+$ ]] && [ "$pipeline_choice" -ge 1 ] && [ "$pipeline_choice" -le ${#AVAILABLE_PIPELINES[@]} ]; then
                    PIPELINE_ID="${AVAILABLE_PIPELINES[$((pipeline_choice-1))]}"
                    print_status "Selected Pipeline ID: $PIPELINE_ID"
                else
                    PIPELINE_ID="$pipeline_choice"
                fi
            else
                print_warning "No pipelines found in $PIPELINES_FILE"
                get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
            fi
        else
            print_warning "$PIPELINES_FILE not found"
            get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
        fi
        
        if [ -z "$PIPELINE_ID" ]; then
            print_error "Pipeline ID is required."
            return 1
        fi
    fi
    
    echo ""
    echo "Document Status Check Options:"
    echo "1. Check all documents in pipeline"
    echo "2. Check documents in specific execution"
    echo "3. Check specific document"
    echo ""
    
    read -p "Select option (1-3): " doc_choice
    
    case $doc_choice in
        1)
            check_pipeline_documents
            ;;
        2)
            check_execution_documents
            ;;
        3)
            check_specific_document
            ;;
        *)
            print_error "Invalid option selected"
            return 1
            ;;
    esac
}

# Function to check all documents in pipeline
check_pipeline_documents() {
    print_status "Checking all documents in pipeline: $PIPELINE_ID"
    
    RESPONSE=$(curl -s \
        --request GET \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID/documents" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    if [ $? -eq 0 ]; then
        print_status "Pipeline Documents Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        
        # Extract document count
        DOC_COUNT=$(echo "$RESPONSE" | grep -o '"count":[0-9]*' | cut -d':' -f2)
        if [ -n "$DOC_COUNT" ] && [[ "$DOC_COUNT" =~ ^[0-9]+$ ]]; then
            echo ""
            print_status "Total Documents: $DOC_COUNT"
        fi
    else
        print_error "Failed to get pipeline documents"
        echo "Response: $RESPONSE"
    fi
}

# Function to check documents in specific execution
check_execution_documents() {
    if [ -z "$PIPELINE_ID" ]; then
        print_error "Pipeline ID is required."
        return 1
    fi
    
    get_input "Enter Execution ID" "" "EXECUTION_ID"
    if [ -z "$EXECUTION_ID" ]; then
        print_error "Execution ID is required."
        return 1
    fi
    
    print_status "Checking documents in execution: $EXECUTION_ID"
    
    RESPONSE=$(curl -s \
        --request GET \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID/executions/$EXECUTION_ID/documents" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    if [ $? -eq 0 ]; then
        print_status "Execution Documents Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        
        # Extract document count
        DOC_COUNT=$(echo "$RESPONSE" | grep -o '"count":[0-9]*' | cut -d':' -f2)
        if [ -n "$DOC_COUNT" ] && [[ "$DOC_COUNT" =~ ^[0-9]+$ ]]; then
            echo ""
            print_status "Total Documents in Execution: $DOC_COUNT"
        fi
    else
        print_error "Failed to get execution documents"
        echo "Response: $RESPONSE"
    fi
}

# Function to check specific document
check_specific_document() {
    if [ -z "$PIPELINE_ID" ]; then
        print_error "Pipeline ID is required."
        return 1
    fi
    
    get_input "Enter Document ID" "" "DOCUMENT_ID"
    if [ -z "$DOCUMENT_ID" ]; then
        print_error "Document ID is required."
        return 1
    fi
    
    print_status "Checking specific document: $DOCUMENT_ID"
    
    RESPONSE=$(curl -s \
        --request GET \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID/documents/$DOCUMENT_ID" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    if [ $? -eq 0 ]; then
        print_status "Specific Document Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
        print_error "Failed to get specific document"
        echo "Response: $RESPONSE"
    fi
}

# Function to check all statuses
check_all_statuses() {
    print_header "Checking All Statuses"
    
    if [ -z "$PIPELINE_ID" ]; then
        print_warning "No pipeline ID selected."
        
        # Try to get pipeline ID from pipelines.json
        if [ -f "$PIPELINES_FILE" ]; then
            print_status "Checking $PIPELINES_FILE for available pipelines..."
            
            # List available pipelines
            AVAILABLE_PIPELINES=($(list_pipelines))
            if [ ${#AVAILABLE_PIPELINES[@]} -gt 0 ]; then
                echo ""
                print_status "Available pipelines in $PIPELINES_FILE:"
                for i in "${!AVAILABLE_PIPELINES[@]}"; do
                    echo "$((i+1)). ${AVAILABLE_PIPELINES[$i]}"
                done
                echo ""
                
                read -p "Select pipeline number (1-${#AVAILABLE_PIPELINES[@]}) or enter custom Pipeline ID: " pipeline_choice
                
                if [[ "$pipeline_choice" =~ ^[0-9]+$ ]] && [ "$pipeline_choice" -ge 1 ] && [ "$pipeline_choice" -le ${#AVAILABLE_PIPELINES[@]} ]; then
                    PIPELINE_ID="${AVAILABLE_PIPELINES[$((pipeline_choice-1))]}"
                    print_status "Selected Pipeline ID: $PIPELINE_ID"
                else
                    PIPELINE_ID="$pipeline_choice"
                fi
            else
                print_warning "No pipelines found in $PIPELINES_FILE"
                get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
            fi
        else
            print_warning "$PIPELINES_FILE not found"
            get_input "Enter Pipeline ID to check" "" "PIPELINE_ID"
        fi
        
        if [ -z "$PIPELINE_ID" ]; then
            print_error "Pipeline ID is required."
            return 1
        fi
    fi
    
    echo ""
    print_status "Checking all statuses for pipeline: $PIPELINE_ID"
    echo ""
    
    # Check pipeline status
    print_header "1. Pipeline Status"
    check_pipeline_status
    
    echo ""
    print_header "2. Execution Status"
    check_execution_status
    
    echo ""
    print_header "3. Document Status"
    check_pipeline_documents
    
    echo ""
    print_status "All status checks completed!"
}

# Function to trigger pipeline
trigger_pipeline() {
    print_header "Trigger Pipeline"
    
    # Load configuration and get fresh token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Check if we have the required configuration
    if [ -z "$DOC_GROUNDING_SERVICE_BINDING_URL" ] || [ -z "$CERT_FILE" ] || [ -z "$KEY_FILE" ]; then
        print_error "Missing required configuration. Please complete the setup steps first."
        return 1
    fi
    
    # Get fresh access token
    print_status "Getting fresh access token for pipeline trigger..."
    if ! get_access_token; then
        print_error "Failed to get access token. Cannot proceed with pipeline trigger."
        return 1
    fi
    
    # Reload config to get the new token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Check if pipeline ID is selected
    if [ -z "$PIPELINE_ID" ]; then
        print_warning "No pipeline ID selected."
        
        # Try to get pipeline ID from pipelines.json
        if [ -f "$PIPELINES_FILE" ]; then
            print_status "Checking $PIPELINES_FILE for available pipelines..."
            
            # List available pipelines
            AVAILABLE_PIPELINES=($(list_pipelines))
            if [ ${#AVAILABLE_PIPELINES[@]} -gt 0 ]; then
                echo ""
                print_status "Available pipelines in $PIPELINES_FILE:"
                for i in "${!AVAILABLE_PIPELINES[@]}"; do
                    echo "$((i+1)). ${AVAILABLE_PIPELINES[$i]}"
                done
                echo ""
                
                read -p "Select pipeline number (1-${#AVAILABLE_PIPELINES[@]}) or enter custom Pipeline ID: " pipeline_choice
                
                if [[ "$pipeline_choice" =~ ^[0-9]+$ ]] && [ "$pipeline_choice" -ge 1 ] && [ "$pipeline_choice" -le ${#AVAILABLE_PIPELINES[@]} ]; then
                    PIPELINE_ID="${AVAILABLE_PIPELINES[$((pipeline_choice-1))]}"
                    print_status "Selected Pipeline ID for trigger: $PIPELINE_ID"
                else
                    PIPELINE_ID="$pipeline_choice"
                fi
            else
                print_warning "No pipelines found in $PIPELINES_FILE"
                get_input "Enter Pipeline ID to trigger" "" "PIPELINE_ID"
            fi
        else
            print_warning "$PIPELINES_FILE not found"
            get_input "Enter Pipeline ID to trigger" "" "PIPELINE_ID"
        fi
        
        if [ -z "$PIPELINE_ID" ]; then
            print_error "Pipeline ID is required."
            return 1
        fi
    fi
    
    # Show pipeline information before trigger
    print_status "Pipeline to be triggered: $PIPELINE_ID"
    
    # Ask for confirmation
    echo ""
    print_warning "WARNING: This will start the content update process for the pipeline!"
    echo "Pipeline ID: $PIPELINE_ID"
    echo "Service URL: $DOC_GROUNDING_SERVICE_BINDING_URL"
    echo ""
    print_status "Note: This endpoint supports 5 calls in 1 minute per tenant."
    echo ""
    
    read -p "Are you sure you want to trigger this pipeline? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        print_status "Pipeline trigger cancelled."
        return 0
    fi
    
    print_status "Triggering pipeline: $PIPELINE_ID"
    
    # Create trigger request body
    TRIGGER_REQUEST="{
        \"pipelineId\": \"$PIPELINE_ID\"
    }"
    
    echo "==== Trigger Request Details ===="
    echo "  Endpoint: $DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/trigger"
    echo "  Accept: application/json"
    echo "  Content-Type: application/json"
    echo "  Authorization: Bearer $ACCESS_TOKEN"
    echo "  Certificate file: $CERT_FILE"
    echo "  Key file: $KEY_FILE"
    echo "  Request body:"
    echo "  $TRIGGER_REQUEST"
    echo "================================"
    
    # Send trigger request
    RESPONSE=$(curl -s \
        --request POST \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/trigger" \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --data "$TRIGGER_REQUEST" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        --request POST \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/trigger" \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --data "$TRIGGER_REQUEST" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    print_status "Trigger Response:"
    echo "$RESPONSE"
    
    if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 202 ]; then
        print_status "Pipeline triggered successfully!"
        print_status "HTTP Status: $HTTP_STATUS"
        
        # Update pipeline status in pipelines.json if available
        if [ -f "$PIPELINES_FILE" ]; then
            # Add trigger timestamp to pipeline data
            if command -v jq &> /dev/null; then
                # Use jq to add trigger timestamp
                jq --arg id "$PIPELINE_ID" --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
                   '.[$id].lastTriggered = $timestamp' "$PIPELINES_FILE" > temp_pipelines.json && \
                mv temp_pipelines.json "$PIPELINES_FILE"
                print_status "Pipeline trigger timestamp updated in $PIPELINES_FILE"
            else
                # Simple text replacement
                print_status "Pipeline trigger completed. Consider updating $PIPELINES_FILE manually."
            fi
        fi
        
    elif [ "$HTTP_STATUS" -eq 429 ]; then
        print_error "Too many requests. Rate limit exceeded (5 calls per minute per tenant)."
        print_status "Please wait before trying again."
    elif [ "$HTTP_STATUS" -eq 404 ]; then
        print_error "Pipeline not found (404). Please check the pipeline ID."
    else
        print_error "Failed to trigger pipeline. HTTP Status: $HTTP_STATUS"
        if [ -n "$RESPONSE" ]; then
            echo "Response: $RESPONSE"
        fi
        return 1
    fi
}

# Function to delete pipeline
delete_pipeline() {
    print_header "Delete Pipeline"
    
    # Load configuration and get fresh token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Check if we have the required configuration
    if [ -z "$DOC_GROUNDING_SERVICE_BINDING_URL" ] || [ -z "$CERT_FILE" ] || [ -z "$KEY_FILE" ]; then
        print_error "Missing required configuration. Please complete the setup steps first."
        return 1
    fi
    
    # Get fresh access token
    print_status "Getting fresh access token for pipeline deletion..."
    if ! get_access_token; then
        print_error "Failed to get access token. Cannot proceed with pipeline deletion."
        return 1
    fi
    
    # Reload config to get the new token
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Check if pipeline ID is selected
    if [ -z "$PIPELINE_ID" ]; then
        print_warning "No pipeline ID selected."
        
        # Try to get pipeline ID from pipelines.json
        if [ -f "$PIPELINES_FILE" ]; then
            print_status "Checking $PIPELINES_FILE for available pipelines..."
            
            # List available pipelines
            AVAILABLE_PIPELINES=($(list_pipelines))
            if [ ${#AVAILABLE_PIPELINES[@]} -gt 0 ]; then
                echo ""
                print_status "Available pipelines in $PIPELINES_FILE:"
                for i in "${!AVAILABLE_PIPELINES[@]}"; do
                    echo "$((i+1)). ${AVAILABLE_PIPELINES[$i]}"
                done
                echo ""
                
                read -p "Select pipeline number (1-${#AVAILABLE_PIPELINES[@]}) or enter custom Pipeline ID: " pipeline_choice
                
                if [[ "$pipeline_choice" =~ ^[0-9]+$ ]] && [ "$pipeline_choice" -ge 1 ] && [ "$pipeline_choice" -le ${#AVAILABLE_PIPELINES[@]} ]; then
                    PIPELINE_ID="${AVAILABLE_PIPELINES[$((pipeline_choice-1))]}"
                    print_status "Selected Pipeline ID for deletion: $PIPELINE_ID"
                else
                    PIPELINE_ID="$pipeline_choice"
                fi
            else
                print_warning "No pipelines found in $PIPELINES_FILE"
                get_input "Enter Pipeline ID to delete" "" "PIPELINE_ID"
            fi
        else
            print_warning "$PIPELINES_FILE not found"
            get_input "Enter Pipeline ID to delete" "" "PIPELINE_ID"
        fi
        
        if [ -z "$PIPELINE_ID" ]; then
            print_error "Pipeline ID is required."
            return 1
        fi
    fi

    
    # Show pipeline information before deletion
    print_status "Pipeline to be deleted: $PIPELINE_ID"
    
    # Ask for confirmation
    echo ""
    print_warning "WARNING: This action cannot be undone!"
    echo "Pipeline ID: $PIPELINE_ID"
    echo "Service URL: $DOC_GROUNDING_SERVICE_BINDING_URL"
    echo ""
    
    read -p "Are you sure you want to delete this pipeline? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        print_status "Pipeline deletion cancelled."
        return 0
    fi
    
    # Double confirmation
    echo ""
    print_warning "Final confirmation required!"
    echo "Type 'DELETE' to confirm pipeline deletion:"
    read -p "Confirmation: " final_confirmation
    
    if [[ "$final_confirmation" != "DELETE" ]]; then
        print_status "Pipeline deletion cancelled."
        return 0
    fi
    
    print_status "Deleting pipeline: $PIPELINE_ID"
    
    # Delete the pipeline
    RESPONSE=$(curl -s \
        --request DELETE \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        --request DELETE \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline/$PIPELINE_ID" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")
    
    if [ "$HTTP_STATUS" -eq 204 ] || [ "$HTTP_STATUS" -eq 200 ]; then
        print_status "Pipeline deleted successfully!"
        
        # Remove pipeline from pipelines.json
        if remove_pipeline "$PIPELINE_ID"; then
            print_status "Pipeline removed from $PIPELINES_FILE"
        fi
        
        # Pipeline information is now managed in pipelines.json
        print_status "Pipeline information is managed in $PIPELINES_FILE"
        
        # Save the updated configuration
        save_config
        print_status "Configuration updated and saved successfully"
        
    elif [ "$HTTP_STATUS" -eq 404 ]; then
        print_warning "Pipeline not found (404). It may have been already deleted."
        
        # Remove pipeline from pipelines.json anyway
        if remove_pipeline "$PIPELINE_ID"; then
            print_status "Pipeline removed from $PIPELINES_FILE"
        fi
        
        # Pipeline information is now managed in pipelines.json
        print_status "Pipeline information is managed in $PIPELINES_FILE"
        
    else
        print_error "Failed to delete pipeline. HTTP Status: $HTTP_STATUS"
        if [ -n "$RESPONSE" ]; then
            echo "Response: $RESPONSE"
        fi
        return 1
    fi
}

# Function to create WorkZone pipeline
create_pipeline() {
    print_header "Step 23: Creating WorkZone Pipeline"
    
    print_status "Getting fresh access token for pipeline creation..."
    
    # Get a fresh access token
    if ! get_access_token; then
        print_error "Failed to get access token. Cannot proceed with pipeline creation."
        return 1
    fi
    
    # Load the access token from config (which was just updated)
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Access token not found after generation. Cannot proceed."
        return 1
    fi
    
    print_status "Creating WorkZone pipeline for document grounding..."
    print_status "Based on SAP AI Core WorkZone pipeline creation"
    
    # Load WorkZone configuration if available
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Use saved destination name if available, otherwise ask for it
    if [ -n "$DESTINATION_NAME" ]; then
        print_status "Using saved destination name: $DESTINATION_NAME"
        GENERIC_SECRET_NAME="$DESTINATION_NAME"
    else
        get_input "Generic Secret Name (destination)" "" "GENERIC_SECRET_NAME"
    fi
    
    # Create pipeline configuration
    PIPELINE_CONFIG="{
        \"type\": \"WorkZone\",
        \"metadata\": {
            \"destination\": \"$GENERIC_SECRET_NAME\"
        }
    }"
    

    echo "==== Request Details ===="
    echo "  Pipeline Setting:"
    echo "  $PIPELINE_CONFIG"
    echo "======================="

    # パイプライン作成リクエストを送信
    RESPONSE=$(curl -s \
        --request POST \
        --url "$DOC_GROUNDING_SERVICE_BINDING_URL/pipeline/api/v1/pipeline" \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --data "$PIPELINE_CONFIG" \
        --cert "$CERT_FILE" \
        --key "$KEY_FILE")

    print_status "Response received!:"
    echo "$RESPONSE"
    
    # Extract pipeline ID if successful (try both "id" and "pipelineId" fields)
    print_status "Debug: Extracting pipeline ID from response"
    print_status "Debug: Response content: '$RESPONSE'"
    
    # Try to extract from "id" field
    PIPELINE_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    print_status "Debug: Extracted from 'id' field: '$PIPELINE_ID'"
    
    if [ -z "$PIPELINE_ID" ]; then
        # Try to extract from "pipelineId" field
        print_status "Debug: Trying 'pipelineId' field..."
        PIPELINE_ID=$(echo "$RESPONSE" | grep -o '"pipelineId":"[^"]*"' | cut -d'"' -f4)
        print_status "Debug: Extracted from 'pipelineId' field: '$PIPELINE_ID'"
        
        # If still empty, try alternative approach
        if [ -z "$PIPELINE_ID" ]; then
            print_status "Debug: Trying alternative extraction method..."
            PIPELINE_ID=$(echo "$RESPONSE" | sed 's/.*"pipelineId": *"\([^"]*\)".*/\1/')
            print_status "Debug: Alternative extraction result: '$PIPELINE_ID'"
            
            # If still empty, try jq if available
            if [ -z "$PIPELINE_ID" ] && command -v jq &> /dev/null; then
                print_status "Debug: Trying jq extraction..."
                PIPELINE_ID=$(echo "$RESPONSE" | jq -r '.pipelineId' 2>/dev/null)
                print_status "Debug: jq extraction result: '$PIPELINE_ID'"
            fi
            
            # Last resort: try with awk
            if [ -z "$PIPELINE_ID" ]; then
                print_status "Debug: Trying awk extraction..."
                PIPELINE_ID=$(echo "$RESPONSE" | awk -F'"' '/pipelineId/ {print $4}')
                print_status "Debug: awk extraction result: '$PIPELINE_ID'"
            fi
        fi
    fi
    
    if [ -n "$PIPELINE_ID" ]; then
        print_status "Pipeline created successfully with ID: $PIPELINE_ID"
        
        # Save pipeline configuration to config
        echo "AI_RESOURCE_GROUP=\"$AI_RESOURCE_GROUP\"" >> "$CONFIG_FILE"
        echo "GENERIC_SECRET_NAME=\"$GENERIC_SECRET_NAME\"" >> "$CONFIG_FILE"
        echo "PIPELINE_ID=\"$PIPELINE_ID\"" >> "$CONFIG_FILE"
        
        # Save pipeline to pipelines.json
        PIPELINE_DATA="{
            \"type\": \"WorkZone\",
            \"configuration\": {
                \"destination\": \"$GENERIC_SECRET_NAME\"
            },
            \"metadata\": {
                \"destination\": \"$GENERIC_SECRET_NAME\"
            },
            \"createdAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
            \"status\": \"CREATED\"
        }"
        
        print_status "Attempting to save pipeline to $PIPELINES_FILE"
        print_status "Pipeline ID: $PIPELINE_ID"
        print_status "Pipeline Data: $PIPELINE_DATA"
        
        if save_pipeline "$PIPELINE_ID" "$PIPELINE_DATA"; then
            print_status "Pipeline saved to $PIPELINES_FILE"
            
            # Verify the save operation
            if [ -f "$PIPELINES_FILE" ]; then
                print_status "Verifying saved data:"
                cat "$PIPELINES_FILE"
            fi
        else
            print_warning "Failed to save pipeline to $PIPELINES_FILE"
        fi
        
        # Pipeline information is now managed in pipelines.json
        print_status "Pipeline information saved to $PIPELINES_FILE"
    else
        print_warning "Pipeline ID not found in response"
        echo "Response: $RESPONSE"
        echo "Tried to extract from both 'id' and 'pipelineId' fields"
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
    
    # Load pipeline and WorkZone integration information if available
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        
        # WorkZone Integration Information
        if [ -n "$DESTINATION_NAME" ]; then
            echo "WorkZone Integration:"
            echo "  Destination Name: $DESTINATION_NAME"
            echo ""
        fi
        
        # Pipeline Information
        if [ -f "$PIPELINES_FILE" ]; then
            echo "Pipeline Information:"
            echo "  Pipelines file: $PIPELINES_FILE"
            AVAILABLE_PIPELINES=($(list_pipelines))
            if [ ${#AVAILABLE_PIPELINES[@]} -gt 0 ]; then
                echo "  Available pipelines: ${#AVAILABLE_PIPELINES[@]}"
                for pipeline_id in "${AVAILABLE_PIPELINES[@]}"; do
                    echo "    - $pipeline_id"
                done
            else
                echo "  No pipelines available"
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
    echo "6. Configure WorkZone Integration"
    echo "7. Create WorkZone Pipeline"
    echo "8. Check Grounding Status"
    echo "9. Delete Pipeline"
    echo "10. Trigger Pipeline"
    echo "11. Show Configuration Summary"
    echo "12. Load/Save Configuration"
    echo "13. Exit"
    echo ""
}

# Main function
main() {
    # Load existing configuration if available
    load_config
    
    # Load pipelines file
    load_pipelines
    
    while true; do
        show_menu
        read -p "Select an option (1-10): " choice
        
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
                configure_workzone_integration
                ;;
            7)
                create_pipeline
                ;;
            8)
                check_grounding_status
                ;;
            9)
                delete_pipeline
                ;;
            10)
                trigger_pipeline
                ;;
            11)
                show_summary
                ;;
            12)
                load_config
                save_config
                ;;
            13)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-13."
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
