#!/bin/bash

# Feishu Calendar Events Lister
# Lists events from Feishu calendar

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
Usage: $0 [OPTIONS]

List events from Feishu calendar.

Options:
  -d, --date DATE          Date to list events for (format: YYYY-MM-DD, default: today)
  -r, --range DAYS         Number of days to include (default: 1)
  -c, --calendar ID        Calendar ID (default: primary calendar)
  -t, --token TOKEN        Feishu access token
  -v, --verbose            Show verbose output
  -h, --help               Show this help message
  --json                   Output in JSON format
  --search TEXT            Search events containing text

Time ranges:
  today                    Events for today (default)
  tomorrow                 Events for tomorrow
  week                     Events for the next 7 days
  month                    Events for the next 30 days

Examples:
  $0                        # List today's events
  $0 --date 2026-03-01      # List events for specific date
  $0 --range 7              # List events for next 7 days
  $0 --search "会议"        # Search for events containing "会议"
  $0 --json                 # Output in JSON format
EOF
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Function to get access token
get_access_token() {
    if [ -n "$FEISHU_ACCESS_TOKEN" ]; then
        echo "$FEISHU_ACCESS_TOKEN"
        return 0
    fi
    
    echo -e "${YELLOW}🔑 Feishu access token not set${NC}" >&2
    echo "Please set FEISHU_ACCESS_TOKEN environment variable or run:" >&2
    echo "  $CREATE_EVENT_SCRIPT --setup" >&2
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
    
    # Use primary calendar
    echo "primary"
}

# Function to parse date range
parse_date_range() {
    local date_str="$1"
    local range_days="$2"
    
    if [ -z "$date_str" ]; then
        date_str=$(date +"%Y-%m-%d")
    fi
    
    # Validate date format
    if [[ ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Handle special keywords
        case "$date_str" in
            today)
                date_str=$(date +"%Y-%m-%d")
                ;;
            tomorrow)
                date_str=$(date -d "+1 day" +"%Y-%m-%d")
                ;;
            week)
                date_str=$(date +"%Y-%m-%d")
                range_days=7
                ;;
            month)
                date_str=$(date +"%Y-%m-%d")
                range_days=30
                ;;
            *)
                echo -e "${RED}❌ Invalid date: $date_str${NC}" >&2
                echo "Expected: YYYY-MM-DD or today/tomorrow/week/month" >&2
                exit 1
                ;;
        esac
    fi
    
    # Calculate end date
    local start_time="${date_str}T00:00:00+08:00"
    local end_date=$(date -d "$date_str +$range_days days" +"%Y-%m-%d")
    local end_time="${end_date}T23:59:59+08:00"
    
    echo "$start_time $end_time"
}

# Function to format event for display
format_event() {
    local event_json="$1"
    local index="$2"
    local total="$3"
    
    # Extract fields using grep/sed (simple approach)
    local summary=$(echo "$event_json" | grep -o '"summary":"[^"]*"' | head -1 | cut -d'"' -f4)
    local description=$(echo "$event_json" | grep -o '"description":"[^"]*"' | head -1 | cut -d'"' -f4)
    local start_time=$(echo "$event_json" | grep -o '"timestamp":"[^"]*"' | head -1 | cut -d'"' -f4)
    local end_time=$(echo "$event_json" | grep -o '"timestamp":"[^"]*"' | tail -1 | cut -d'"' -f4)
    local location=$(echo "$event_json" | grep -o '"location":"[^"]*"' | head -1 | cut -d'"' -f4)
    local event_id=$(echo "$event_json" | grep -o '"event_id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    # Format times for display
    local display_start=$(echo "$start_time" | sed 's/T/ /; s/+08:00//')
    local display_end=$(echo "$end_time" | sed 's/T/ /; s/+08:00//')
    
    # Truncate description if too long
    if [ ${#description} -gt 100 ]; then
        description="${description:0:100}..."
    fi
    
    # Output formatted event
    echo -e "${BLUE}Event #$((index + 1))/${total}${NC}"
    echo "  📅 Title: $summary"
    echo "  ⏰ Time: $display_start - $display_end"
    
    if [ -n "$location" ] && [ "$location" != "null" ]; then
        echo "  📍 Location: $location"
    fi
    
    if [ -n "$description" ] && [ "$description" != "null" ]; then
        echo "  📝 Description: $description"
    fi
    
    echo "  🔗 ID: $event_id"
    echo ""
}

# Parse command line arguments
TARGET_DATE=""
RANGE_DAYS=1
CALENDAR_ID=""
VERBOSE=false
JSON_OUTPUT=false
SEARCH_TEXT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--date)
            TARGET_DATE="$2"
            shift 2
            ;;
        -r|--range)
            RANGE_DAYS="$2"
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
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --search)
            SEARCH_TEXT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}" >&2
            usage
            exit 1
            ;;
        *)
            # Handle positional arguments as date
            if [ -z "$TARGET_DATE" ]; then
                TARGET_DATE="$1"
            fi
            shift
            ;;
    esac
done

# Load configuration
load_config

# Get access token and calendar ID
ACCESS_TOKEN=$(get_access_token)
CALENDAR_ID=$(get_calendar_id)

# Parse date range
DATE_RANGE=$(parse_date_range "$TARGET_DATE" "$RANGE_DAYS")
START_TIME=$(echo "$DATE_RANGE" | cut -d' ' -f1)
END_TIME=$(echo "$DATE_RANGE" | cut -d' ' -f2)

if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}🔍 Listing calendar events${NC}"
    echo "Calendar: $CALENDAR_ID"
    echo "Start time: $START_TIME"
    echo "End time: $END_TIME"
    echo "Range: $RANGE_DAYS days"
    if [ -n "$SEARCH_TEXT" ]; then
        echo "Search: $SEARCH_TEXT"
    fi
    echo ""
fi

# Build API URL
API_URL="$API_BASE/calendars/$CALENDAR_ID/events"
API_URL="$API_URL?start_time=$START_TIME&end_time=$END_TIME"

# Add search if specified
if [ -n "$SEARCH_TEXT" ]; then
    # URL encode search text
    SEARCH_ENCODED=$(echo "$SEARCH_TEXT" | sed 's/ /%20/g')
    API_URL="$API_URL&query=$SEARCH_ENCODED"
fi

# Make API request
echo -e "${YELLOW}⏳ Fetching events...${NC}"

RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_URL")

# Check if response contains events
if echo "$RESPONSE" | grep -q '"items"'; then
    # Extract events array
    EVENTS_JSON=$(echo "$RESPONSE" | grep -o '"items":\[.*\]' | sed 's/"items"://')
    
    if [ "$EVENTS_JSON" = "[]" ]; then
        echo -e "${YELLOW}📭 No events found in the specified time range.${NC}"
        exit 0
    fi
    
    # Count events
    EVENT_COUNT=$(echo "$EVENTS_JSON" | grep -o '"event_id"' | wc -l)
    
    if [ "$JSON_OUTPUT" = true ]; then
        # Output raw JSON
        echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    else
        # Output formatted events
        echo -e "${GREEN}✅ Found $EVENT_COUNT event(s)${NC}"
        echo ""
        
        # Parse and display each event
        # Simple parsing - split by event objects
        IFS=$'\n'
        EVENT_INDEX=0
        while read -r line; do
            if [[ "$line" =~ \{.*event_id.*\} ]]; then
                format_event "$line" "$EVENT_INDEX" "$EVENT_COUNT"
                EVENT_INDEX=$((EVENT_INDEX + 1))
            fi
        done < <(echo "$EVENTS_JSON" | sed 's/},{/}\n{/g')
    fi
    
    # Summary
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${BLUE}📊 Summary${NC}"
        echo "Total events: $EVENT_COUNT"
        echo "Time range: $(echo "$START_TIME" | sed 's/T/ /; s/+08:00//') to $(echo "$END_TIME" | sed 's/T/ /; s/+08:00//')"
    fi
    
else
    # Check for error
    if echo "$RESPONSE" | grep -q '"code"'; then
        ERROR_CODE=$(echo "$RESPONSE" | grep -o '"code":[0-9]*' | cut -d: -f2)
        ERROR_MSG=$(echo "$RESPONSE" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
        echo -e "${RED}❌ API Error $ERROR_CODE: $ERROR_MSG${NC}" >&2
    else
        echo -e "${RED}❌ Failed to fetch events${NC}" >&2
        echo "Response: $RESPONSE" >&2
    fi
    exit 1
fi