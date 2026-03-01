#!/bin/bash

# Feishu Calendar Event Creator
# Creates a calendar event in Feishu using Open Platform API

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_FILE="$HOME/.feishu_calendar_config"
API_BASE="https://open.feishu.cn/open-apis/calendar/v4"

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] "EVENT_TITLE"

Create a calendar event in Feishu.

Required:
  "EVENT_TITLE"  Title of the event

Options:
  -s, --start DATETIME    Start time (format: YYYY-MM-DD HH:MM, default: now + 1 hour)
  -e, --end DATETIME      End time (format: YYYY-MM-DD HH:MM, default: start + 1 hour)
  -d, --description TEXT  Event description
  -l, --location TEXT     Event location
  -c, --calendar ID       Calendar ID (default: primary calendar)
  -t, --token TOKEN       Feishu access token
  -v, --verbose           Show verbose output
  -h, --help              Show this help message

Examples:
  $0 "团队会议" -s "2026-03-01 14:00" -e "2026-03-01 15:00"
  $0 "训练计划" -s "16:00" -e "17:20" -d "心肺恢复日训练" -l "健身房"
  $0 "每日站会" --start "09:30" --end "09:45" --description "每日同步会议"

Time formats:
  Full: "2026-03-01 14:00:00"
  Date only: "2026-03-01" (uses default time 09:00)
  Time only: "14:00" (uses today's date)
EOF
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        if [ "$VERBOSE" = "true" ]; then
            echo -e "${BLUE}📁 Loaded config from $CONFIG_FILE${NC}"
        fi
    else
        if [ "$VERBOSE" = "true" ]; then
            echo -e "${YELLOW}⚠️  Config file not found: $CONFIG_FILE${NC}"
        fi
    fi
}

# Function to save configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Feishu Calendar Configuration
# Generated on $(date)

# Access token (obtain from Feishu Open Platform)
FEISHU_ACCESS_TOKEN="${FEISHU_ACCESS_TOKEN}"

# Default calendar ID
DEFAULT_CALENDAR_ID="${DEFAULT_CALENDAR_ID}"

# Default timezone (Asia/Shanghai)
DEFAULT_TIMEZONE="Asia/Shanghai"
EOF
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${GREEN}✅ Config saved to $CONFIG_FILE${NC}"
    fi
}

# Function to get access token
get_access_token() {
    if [ -n "$FEISHU_ACCESS_TOKEN" ]; then
        echo "$FEISHU_ACCESS_TOKEN"
        return 0
    fi
    
    echo -e "${YELLOW}🔑 Feishu access token not set${NC}" >&2
    echo "Please obtain an access token from Feishu Open Platform and:" >&2
    echo "1. Set FEISHU_ACCESS_TOKEN environment variable" >&2
    echo "2. Or run: $0 --setup" >&2
    echo "3. Or add to $CONFIG_FILE" >&2
    exit 1
}

# Function to get calendar ID
get_calendar_id() {
    if [ -n "$CALENDAR_ID" ]; then
        echo "$CALENDAR_ID"
        return 0
    fi
    
    if [ -n "$DEFAULT_CALENDAR_ID" ]; then
        echo "$DEFAULT_CALENDAR_ID"
        return 0
    fi
    
    # Try to get primary calendar
    ACCESS_TOKEN=$(get_access_token)
    RESPONSE=$(curl -s -X GET \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        "$API_BASE/calendars/primary")
    
    if echo "$RESPONSE" | grep -q '"calendar_id"'; then
        CALENDAR_ID=$(echo "$RESPONSE" | grep -o '"calendar_id":"[^"]*"' | head -1 | cut -d'"' -f4)
        DEFAULT_CALENDAR_ID="$CALENDAR_ID"
        save_config
        echo "$CALENDAR_ID"
        return 0
    else
        echo -e "${RED}❌ Failed to get calendar ID${NC}" >&2
        echo "Response: $RESPONSE" >&2
        exit 1
    fi
}

# Function to parse datetime
parse_datetime() {
    local input="$1"
    local default_date="$2"
    local default_time="$3"
    
    # Check if input contains date and time
    if [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2} ]]; then
        # Full datetime: "2026-03-01 14:00"
        echo "$input:00"
    elif [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Date only: "2026-03-01"
        echo "${input} ${default_time}"
    elif [[ "$input" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        # Time only: "14:00"
        echo "${default_date} ${input}:00"
    else
        echo -e "${RED}❌ Invalid datetime format: $input${NC}" >&2
        echo "Expected: YYYY-MM-DD HH:MM or YYYY-MM-DD or HH:MM" >&2
        exit 1
    fi
}

# Function to convert to ISO format
to_iso_format() {
    local datetime="$1"
    # Convert "2026-03-01 14:00:00" to "2026-03-01T14:00:00+08:00"
    local date_part=$(echo "$datetime" | cut -d' ' -f1)
    local time_part=$(echo "$datetime" | cut -d' ' -f2)
    echo "${date_part}T${time_part}+08:00"
}

# Function to setup configuration
setup_config() {
    echo -e "${BLUE}🔧 Feishu Calendar Setup${NC}"
    echo ""
    
    echo "Please provide the following information:"
    echo ""
    
    # Get access token
    read -p "Feishu Access Token: " FEISHU_ACCESS_TOKEN
    while [ -z "$FEISHU_ACCESS_TOKEN" ]; do
        echo -e "${YELLOW}⚠️  Access token is required${NC}"
        read -p "Feishu Access Token: " FEISHU_ACCESS_TOKEN
    done
    
    # Get calendar ID (optional)
    read -p "Calendar ID (press Enter to auto-detect): " DEFAULT_CALENDAR_ID
    
    # Save configuration
    save_config
    
    echo ""
    echo -e "${GREEN}✅ Setup completed!${NC}"
    echo "Configuration saved to: $CONFIG_FILE"
    echo ""
    echo "You can now create calendar events:"
    echo "  $0 \"会议标题\" -s \"14:00\" -e \"15:00\""
    exit 0
}

# Parse command line arguments
EVENT_TITLE=""
START_TIME=""
END_TIME=""
DESCRIPTION=""
LOCATION=""
CALENDAR_ID=""
VERBOSE=false
SETUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--start)
            START_TIME="$2"
            shift 2
            ;;
        -e|--end)
            END_TIME="$2"
            shift 2
            ;;
        -d|--description)
            DESCRIPTION="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -c|--calendar)
            CALENDAR_ID="$2"
            shift 2
            ;;
        -t|--token)
            FEISHU_ACCESS_TOKEN="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --setup)
            SETUP=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}" >&2
            usage
            exit 1
            ;;
        *)
            EVENT_TITLE="$1"
            shift
            ;;
    esac
done

# Handle setup mode
if [ "$SETUP" = true ]; then
    setup_config
fi

# Load configuration
load_config

# Check if event title is provided
if [ -z "$EVENT_TITLE" ]; then
    echo -e "${RED}Error: Event title is required${NC}" >&2
    usage
    exit 1
fi

# Set default times if not provided
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%H:%M")
NEXT_HOUR=$(date -d "+1 hour" +"%H:%M")

if [ -z "$START_TIME" ]; then
    START_TIME="$NEXT_HOUR"
fi

if [ -z "$END_TIME" ]; then
    # Parse start time to calculate end time
    if [[ "$START_TIME" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        # Time only, add 1 hour
        END_TIME=$(date -d "$CURRENT_DATE $START_TIME:00 +1 hour" +"%H:%M")
    else
        # Full datetime, add 1 hour
        END_TIME=$(date -d "$START_TIME +1 hour" +"%H:%M")
    fi
fi

# Parse datetime strings
FULL_START=$(parse_datetime "$START_TIME" "$CURRENT_DATE" "09:00")
FULL_END=$(parse_datetime "$END_TIME" "$CURRENT_DATE" "10:00")

# Convert to ISO format
ISO_START=$(to_iso_format "$FULL_START")
ISO_END=$(to_iso_format "$FULL_END")

# Get access token and calendar ID
ACCESS_TOKEN=$(get_access_token)
CALENDAR_ID=$(get_calendar_id)

# Prepare event data
EVENT_DATA=$(cat << EOF
{
  "summary": "$EVENT_TITLE",
  "description": "$DESCRIPTION",
  "start_time": {
    "timestamp": "$ISO_START",
    "timezone": "Asia/Shanghai"
  },
  "end_time": {
    "timestamp": "$ISO_END",
    "timezone": "Asia/Shanghai"
  },
  "location": "$LOCATION"
}
EOF
)

if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}🔧 Creating calendar event${NC}"
    echo "Title: $EVENT_TITLE"
    echo "Start: $FULL_START ($ISO_START)"
    echo "End: $FULL_END ($ISO_END)"
    echo "Description: $DESCRIPTION"
    echo "Location: $LOCATION"
    echo "Calendar ID: $CALENDAR_ID"
    echo ""
    echo "Request data:"
    echo "$EVENT_DATA" | jq . 2>/dev/null || echo "$EVENT_DATA"
    echo ""
fi

# Create the event
echo -e "${YELLOW}⏳ Creating calendar event...${NC}"

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$EVENT_DATA" \
  "$API_BASE/calendars/$CALENDAR_ID/events")

# Check response
if echo "$RESPONSE" | grep -q '"event_id"'; then
    EVENT_ID=$(echo "$RESPONSE" | grep -o '"event_id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${GREEN}✅ Event created successfully!${NC}"
    echo "Event ID: $EVENT_ID"
    
    # Try to get event URL
    EVENT_URL_RESPONSE=$(curl -s -X GET \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      "$API_BASE/calendars/$CALENDAR_ID/events/$EVENT_ID")
    
    if echo "$EVENT_URL_RESPONSE" | grep -q '"html_link"'; then
        EVENT_URL=$(echo "$EVENT_URL_RESPONSE" | grep -o '"html_link":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "Event URL: $EVENT_URL"
    fi
    
    exit 0
else
    echo -e "${RED}❌ Failed to create event${NC}" >&2
    echo "Response: $RESPONSE" >&2
    exit 1
fi