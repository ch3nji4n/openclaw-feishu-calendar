#!/bin/bash

# Feishu Training Schedule Creator
# Creates training events in Feishu calendar based on fitness plan

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATE_EVENT_SCRIPT="$SCRIPT_DIR/create_calendar_event.sh"
CONFIG_FILE="$HOME/.feishu_calendar_config"

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Create training schedule events in Feishu calendar.

Options:
  -t, --today DATE         Today's date (format: YYYY-MM-DD, default: today)
  -c, --calendar ID        Calendar ID (default: primary calendar)
  -v, --verbose            Show verbose output
  -h, --help               Show this help message
  --dry-run                Show what would be created without actually creating

Examples:
  $0                        # Create training schedule for today and tomorrow
  $0 --today 2026-03-01     # Create schedule starting from specific date
  $0 --dry-run              # Show schedule without creating events
EOF
}

# Function to check dependencies
check_dependencies() {
    if [ ! -f "$CREATE_EVENT_SCRIPT" ]; then
        echo -e "${RED}❌ Missing dependency: create_calendar_event.sh${NC}" >&2
        echo "Please ensure all script files are in the same directory." >&2
        exit 1
    fi
    
    if ! command -v date &> /dev/null; then
        echo -e "${RED}❌ Missing dependency: date command${NC}" >&2
        exit 1
    fi
}

# Function to parse date
parse_date() {
    local date_str="$1"
    if [ -z "$date_str" ]; then
        date +"%Y-%m-%d"
    else
        # Validate date format
        if [[ "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "$date_str"
        else
            echo -e "${RED}❌ Invalid date format: $date_str${NC}" >&2
            echo "Expected: YYYY-MM-DD" >&2
            exit 1
        fi
    fi
}

# Function to get tomorrow's date
get_tomorrow() {
    local date_str="$1"
    date -d "$date_str +1 day" +"%Y-%m-%d"
}

# Function to create training event
create_training_event() {
    local date="$1"
    local time_start="$2"
    local time_end="$3"
    local title="$4"
    local description="$5"
    local location="$6"
    local dry_run="$7"
    
    local datetime_start="$date $time_start"
    local datetime_end="$date $time_end"
    
    if [ "$dry_run" = true ]; then
        echo -e "${BLUE}📅 Would create:${NC}"
        echo "  Title: $title"
        echo "  Date: $date"
        echo "  Time: $time_start - $time_end"
        echo "  Description: $description"
        echo "  Location: $location"
        echo ""
        return 0
    fi
    
    echo -e "${YELLOW}⏳ Creating: $title ($date $time_start-$time_end)...${NC}"
    
    # Build command
    CMD="$CREATE_EVENT_SCRIPT \"$title\" \
        --start \"$datetime_start\" \
        --end \"$datetime_end\" \
        --description \"$description\" \
        --location \"$location\""
    
    if [ -n "$CALENDAR_ID" ]; then
        CMD="$CMD --calendar \"$CALENDAR_ID\""
    fi
    
    if [ "$VERBOSE" = true ]; then
        CMD="$CMD --verbose"
    fi
    
    # Execute command
    if eval "$CMD"; then
        echo -e "${GREEN}✅ Created: $title${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to create: $title${NC}" >&2
        return 1
    fi
}

# Parse command line arguments
TODAY_DATE=""
CALENDAR_ID=""
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--today)
            TODAY_DATE="$2"
            shift 2
            ;;
        -c|--calendar)
            CALENDAR_ID="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
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
            echo -e "${RED}Error: Unexpected argument $1${NC}" >&2
            usage
            exit 1
            ;;
    esac
done

# Check dependencies
check_dependencies

# Parse dates
TODAY=$(parse_date "$TODAY_DATE")
TOMORROW=$(get_tomorrow "$TODAY")

echo -e "${BLUE}🏋️‍♂️ Feishu Training Schedule Creator${NC}"
echo "Today: $TODAY"
echo "Tomorrow: $TOMORROW"
echo "Dry run: $DRY_RUN"
echo ""

# Training schedule definition
# Format: date, start_time, end_time, title, description, location

TRAINING_SCHEDULE=(
    # Today - Cardio Recovery Day
    "$TODAY" "16:00" "17:20" "心肺恢复日训练" \
    "低冲击心肺训练 + 膝盖保护\n训练内容:\n1. 热身: 动态拉伸 + 关节激活\n2. 主训: 循环训练(5个动作×3轮)\n3. 有氧: 椭圆机/游泳/快走\n4. 放松: 拉伸 + 泡沫轴" \
    "家中/健身房"
    
    # Tomorrow - Strength Training Day
    "$TOMORROW" "07:00" "08:40" "力量训练日训练" \
    "全身力量训练 + 膝盖保护\n训练内容:\n1. 热身: 综合热身15分钟\n2. 力量: A组(下肢) + B组(上肢+核心)\n3. 心肺: 间歇训练10分钟\n4. 放松: 深度拉伸15分钟" \
    "家中/健身房"
)

# Create training events
echo -e "${YELLOW}📋 Creating training schedule...${NC}"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for ((i=0; i<${#TRAINING_SCHEDULE[@]}; i+=6)); do
    date="${TRAINING_SCHEDULE[i]}"
    start_time="${TRAINING_SCHEDULE[i+1]}"
    end_time="${TRAINING_SCHEDULE[i+2]}"
    title="${TRAINING_SCHEDULE[i+3]}"
    description="${TRAINING_SCHEDULE[i+4]}"
    location="${TRAINING_SCHEDULE[i+5]}"
    
    if create_training_event "$date" "$start_time" "$end_time" "$title" "$description" "$location" "$DRY_RUN"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}📊 Summary${NC}"
echo "Successful: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}⚠️  Dry run completed. No events were actually created.${NC}"
    echo "To create actual events, run without --dry-run flag."
elif [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ Training schedule created successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Check your Feishu calendar for the new events"
    echo "2. Set reminders if needed"
    echo "3. Update training progress as you complete sessions"
else
    echo -e "${YELLOW}⚠️  Some events failed to create.${NC}"
    echo "Check the error messages above for details."
fi

# Additional information
echo ""
echo -e "${BLUE}💡 Tips${NC}"
echo "• Events are created in your primary Feishu calendar"
echo "• You can modify the schedule by editing this script"
echo "• For recurring training, consider setting up repeating events"
echo "• Combine with feishu-doc for detailed training plans"

exit $FAIL_COUNT