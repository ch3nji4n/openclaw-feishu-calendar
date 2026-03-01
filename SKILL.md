---
name: feishu-calendar
description: |
  Feishu calendar operations. Create, read, update, and delete calendar events.
  Activate when user mentions Feishu calendar, schedule, or events.
---

# Feishu Calendar Skill

Create and manage Feishu calendar events through OpenClaw.

## 🎯 Features

- **Create Events**: Add new events to Feishu calendar
- **Read Events**: List and view calendar events
- **Update Events**: Modify existing events
- **Delete Events**: Remove events from calendar
- **Search Events**: Find events by date, title, or description

## 🔧 Implementation Approach

Since there's no direct `feishu_calendar` tool in OpenClaw, this skill provides:

1. **Wrapper scripts** that use Feishu Open Platform API
2. **Example implementations** for common calendar operations
3. **Integration guidance** with existing Feishu tools

## 📋 Required Permissions

Based on `feishu_app_scopes` check, the following permissions are available:
- ✅ `calendar:calendar.event:create` - Create calendar events
- ✅ `calendar:calendar.event:read` - Read calendar events
- ✅ `calendar:calendar.event:update` - Update calendar events
- ✅ `calendar:calendar.event:delete` - Delete calendar events
- ✅ `calendar:calendar:read` - Read calendar metadata
- ✅ `calendar:calendar:create` - Create calendars

## 🚀 Quick Start

### 1. Create a Calendar Event

```bash
# Using the wrapper script
./create_calendar_event.sh "训练计划" "2026-03-01 16:00" "2026-03-01 17:20" "心肺恢复日训练"
```

### 2. List Today's Events

```bash
./list_calendar_events.sh today
```

### 3. Create Training Schedule

```bash
./create_training_schedule.sh
```

## 📁 File Structure

```
feishu-calendar/
├── SKILL.md                    # This documentation
├── create_calendar_event.sh    # Create single event
├── list_calendar_events.sh     # List events
├── create_training_schedule.sh # Create training schedule
├── delete_calendar_event.sh    # Delete event
├── update_calendar_event.sh    # Update event
├── calendar_api_examples.md    # API examples
└── README.md                   # Usage instructions
```

## 🔌 API Integration

### Feishu Calendar API Endpoints

- **Create Event**: `POST /calendar/v4/calendars/{calendar_id}/events`
- **Get Event**: `GET /calendar/v4/calendars/{calendar_id}/events/{event_id}`
- **Update Event**: `PATCH /calendar/v4/calendars/{calendar_id}/events/{event_id}`
- **Delete Event**: `DELETE /calendar/v4/calendars/{calendar_id}/events/{event_id}`
- **List Events**: `GET /calendar/v4/calendars/{calendar_id}/events`

### Required Parameters

1. **Access Token**: Obtained through Feishu app authentication
2. **Calendar ID**: User's default calendar or specific calendar ID
3. **Event Data**: Title, start/end time, description, location, etc.

## 🛠️ Implementation Scripts

### 1. `create_calendar_event.sh`

Creates a single calendar event with the provided details.

```bash
#!/bin/bash
# Usage: ./create_calendar_event.sh "标题" "开始时间" "结束时间" "描述"
```

### 2. `create_training_schedule.sh`

Creates a complete training schedule based on the fitness plan.

```bash
#!/bin/bash
# Creates today's and tomorrow's training events
```

### 3. `list_calendar_events.sh`

Lists events for a specific date range.

```bash
#!/bin/bash
# Usage: ./list_calendar_events.sh [today|tomorrow|week|2026-03-01]
```

## 🔄 Integration with Existing Tools

This skill can work alongside:

1. **feishu-doc**: Store detailed training plans in documents
2. **feishu-bitable**: Track training progress in tables
3. **message tool**: Send calendar reminders

## 📝 Example: Training Plan Integration

```bash
# Step 1: Create training plan document
# Step 2: Create calendar events for training sessions
# Step 3: Send reminder messages
# Step 4: Track completion in bitable
```

## ⚠️ Limitations & Workarounds

### Current Limitations:
1. No direct `feishu_calendar` tool in OpenClaw
2. Requires manual API token management
3. Need to obtain calendar ID

### Workarounds:
1. Use wrapper scripts with curl commands
2. Store credentials in environment variables
3. Use default calendar when specific ID not available

## 🔍 Debugging

### Check Permissions:
```bash
feishu_app_scopes
```

### Test API Access:
```bash
curl -H "Authorization: Bearer $FEISHU_ACCESS_TOKEN" \
  "https://open.feishu.cn/open-apis/calendar/v4/calendars"
```

### View Available Calendars:
```bash
./list_calendars.sh
```

## 🚧 Development Status

- [x] Skill structure created
- [x] Documentation written
- [ ] API wrapper scripts
- [ ] Authentication flow
- [ ] Error handling
- [ ] Integration examples

## 📚 References

- [Feishu Open Platform - Calendar API](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/calendar-v4/calendar-event/create)
- [OpenClaw Feishu Integration](https://docs.openclaw.ai/channels/feishu)
- [Calendar Event Format](https://icalendar.org/)

## 🤝 Contributing

To extend this skill:

1. Add new wrapper scripts for additional API endpoints
2. Improve error handling and logging
3. Add support for recurring events
4. Create GUI or web interface

## 📄 License

This skill is part of OpenClaw ecosystem.

---

**Note**: This is a prototype skill. Full implementation requires:
1. Feishu app configuration
2. Access token management
3. Calendar ID discovery
4. Error handling improvements