# Feishu Calendar API 示例

本文档提供 Feishu 日历 API 的使用示例，用于在 OpenClaw 中集成日历功能。

## 📋 API 概览

### 基础信息
- **API 地址**: `https://open.feishu.cn/open-apis/calendar/v4`
- **认证方式**: Bearer Token
- **权限要求**: `calendar:calendar.event:*`

### 主要端点

| 端点 | 方法 | 描述 |
|------|------|------|
| `/calendars` | GET | 获取日历列表 |
| `/calendars/{calendar_id}/events` | POST | 创建日历事件 |
| `/calendars/{calendar_id}/events/{event_id}` | GET | 获取事件详情 |
| `/calendars/{calendar_id}/events/{event_id}` | PATCH | 更新事件 |
| `/calendars/{calendar_id}/events/{event_id}` | DELETE | 删除事件 |
| `/calendars/{calendar_id}/events` | GET | 获取事件列表 |

## 🔑 认证

### 获取 Access Token

```bash
# 通过 Feishu 开放平台获取
curl -X POST \
  https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal \
  -H "Content-Type: application/json" \
  -d '{
    "app_id": "your_app_id",
    "app_secret": "your_app_secret"
  }'
```

### 使用 Access Token

```bash
# 在所有 API 请求中添加 Header
Authorization: Bearer {tenant_access_token}
```

## 📅 日历操作示例

### 1. 获取日历列表

```bash
curl -X GET \
  https://open.feishu.cn/open-apis/calendar/v4/calendars \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json"
```

### 2. 创建日历事件

```bash
curl -X POST \
  https://open.feishu.cn/open-apis/calendar/v4/calendars/{calendar_id}/events \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "团队会议",
    "description": "每周项目进度同步",
    "start_time": {
      "timestamp": "2026-03-01T14:00:00+08:00",
      "timezone": "Asia/Shanghai"
    },
    "end_time": {
      "timestamp": "2026-03-01T15:00:00+08:00",
      "timezone": "Asia/Shanghai"
    },
    "location": "会议室A"
  }'
```

### 3. 获取事件列表

```bash
curl -X GET \
  "https://open.feishu.cn/open-apis/calendar/v4/calendars/{calendar_id}/events?start_time=2026-03-01T00:00:00+08:00&end_time=2026-03-02T23:59:59+08:00" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json"
```

### 4. 更新事件

```bash
curl -X PATCH \
  https://open.feishu.cn/open-apis/calendar/v4/calendars/{calendar_id}/events/{event_id} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "团队会议（更新）",
    "description": "更新后的会议描述"
  }'
```

### 5. 删除事件

```bash
curl -X DELETE \
  https://open.feishu.cn/open-apis/calendar/v4/calendars/{calendar_id}/events/{event_id} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json"
```

## 🏋️‍♂️ 训练计划集成示例

### 创建训练事件

```bash
#!/bin/bash
# create_training_event.sh

ACCESS_TOKEN="your_access_token"
CALENDAR_ID="primary"

# 今天的心肺训练
curl -X POST \
  https://open.feishu.cn/open-apis/calendar/v4/calendars/$CALENDAR_ID/events \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "心肺恢复日训练",
    "description": "低冲击心肺训练 + 膝盖保护\n训练内容:\n1. 热身: 动态拉伸 + 关节激活\n2. 主训: 循环训练(5个动作×3轮)\n3. 有氧: 椭圆机/游泳/快走\n4. 放松: 拉伸 + 泡沫轴",
    "start_time": {
      "timestamp": "'$(date -d "16:00" +"%Y-%m-%dT%H:%M:%S+08:00")'",
      "timezone": "Asia/Shanghai"
    },
    "end_time": {
      "timestamp": "'$(date -d "17:20" +"%Y-%m-%dT%H:%M:%S+08:00")'",
      "timezone": "Asia/Shanghai"
    },
    "location": "家中/健身房"
  }'
```

### 批量创建训练计划

```bash
#!/bin/bash
# create_weekly_training.sh

ACCESS_TOKEN="your_access_token"
CALENDAR_ID="primary"

# 训练计划数组
TRAINING_PLAN=(
  "周一 07:00-08:40 力量训练日训练"
  "周三 07:00-08:40 力量训练日训练"
  "周五 07:00-08:40 力量训练日训练"
  "周日 16:00-17:20 心肺恢复日训练"
)

for plan in "${TRAINING_PLAN[@]}"; do
  day=$(echo $plan | cut -d' ' -f1)
  time=$(echo $plan | cut -d' ' -f2)
  title=$(echo $plan | cut -d' ' -f3-)
  
  # 计算日期
  case $day in
    周一) date_offset=1 ;;
    周二) date_offset=2 ;;
    周三) date_offset=3 ;;
    周四) date_offset=4 ;;
    周五) date_offset=5 ;;
    周六) date_offset=6 ;;
    周日) date_offset=0 ;;
  esac
  
  target_date=$(date -d "+$date_offset days" +"%Y-%m-%d")
  start_time="${target_date}T$(echo $time | cut -d'-' -f1):00+08:00"
  end_time="${target_date}T$(echo $time | cut -d'-' -f2):00+08:00"
  
  # 创建事件
  curl -X POST \
    https://open.feishu.cn/open-apis/calendar/v4/calendars/$CALENDAR_ID/events \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"summary\": \"$title\",
      \"description\": \"健身训练计划 - 请按时完成训练\",
      \"start_time\": {
        \"timestamp\": \"$start_time\",
        \"timezone\": \"Asia/Shanghai\"
      },
      \"end_time\": {
        \"timestamp\": \"$end_time\",
        \"timezone\": \"Asia/Shanghai\"
      },
      \"location\": \"健身房\"
    }"
done
```

## 🔄 与 OpenClaw 集成

### 1. 创建 OpenClaw 工具

```javascript
// feishu_calendar.js
module.exports = {
  name: 'feishu_calendar',
  description: 'Feishu calendar operations',
  actions: {
    createEvent: async ({ calendarId, eventData }) => {
      // 调用 Feishu API 创建事件
    },
    listEvents: async ({ calendarId, startTime, endTime }) => {
      // 调用 Feishu API 获取事件列表
    },
    updateEvent: async ({ calendarId, eventId, eventData }) => {
      // 调用 Feishu API 更新事件
    },
    deleteEvent: async ({ calendarId, eventId }) => {
      // 调用 Feishu API 删除事件
    }
  }
};
```

### 2. 在 Skill 中使用

```bash
# SKILL.md 示例
---
name: feishu-calendar
description: Feishu calendar operations
---

# Feishu Calendar Skill

使用示例:

```bash
# 创建训练事件
feishu_calendar createEvent \
  --calendar-id primary \
  --title "心肺训练" \
  --start "2026-03-01 16:00" \
  --end "2026-03-01 17:20" \
  --description "低冲击心肺训练"

# 查看今天的事件
feishu_calendar listEvents --date today
```

## 🛠️ 错误处理

### 常见错误码

| 错误码 | 描述 | 解决方案 |
|--------|------|----------|
| 99991663 | 无权限访问日历 | 检查应用权限配置 |
| 99991664 | 日历不存在 | 检查 calendar_id |
| 99991665 | 事件不存在 | 检查 event_id |
| 99991672 | 时间格式错误 | 检查时间格式 |

### 错误处理示例

```bash
#!/bin/bash
# 带错误处理的 API 调用

call_feishu_api() {
  local url="$1"
  local method="$2"
  local data="$3"
  
  response=$(curl -s -X "$method" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$data" \
    "$url")
  
  if echo "$response" | grep -q '"code":0'; then
    echo "✅ Success"
    echo "$response"
    return 0
  else
    error_code=$(echo "$response" | grep -o '"code":[0-9]*' | cut -d: -f2)
    error_msg=$(echo "$response" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
    echo "❌ Error $error_code: $error_msg"
    return 1
  fi
}
```

## 📚 参考资源

1. [Feishu 开放平台 - 日历 API](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/calendar-v4/calendar-event/create)
2. [OpenClaw 工具开发指南](https://docs.openclaw.ai/development/tools)
3. [iCalendar 标准](https://icalendar.org/)
4. [Feishu API 错误码](https://open.feishu.cn/document/ukTMukTMukTM/ugjM14COyUjL4ITN)

## 🚀 下一步

1. **完善工具**: 添加更多日历操作功能
2. **用户界面**: 创建 Web 界面管理日历
3. **集成测试**: 测试与现有系统的集成
4. **文档完善**: 添加更多使用示例

---

**注意**: 使用前请确保已获取正确的应用权限，并在 Feishu 开放平台完成应用配置。