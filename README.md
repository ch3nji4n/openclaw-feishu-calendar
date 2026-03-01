# Feishu Calendar Skill for OpenClaw

一个用于在飞书日历中创建和管理事件的 OpenClaw skill。

## 🎯 功能特性

- ✅ **创建日历事件** - 在飞书日历中添加新事件
- ✅ **查看事件列表** - 按日期范围查看日历事件
- ✅ **训练计划集成** - 专门为健身训练设计的创建脚本
- ✅ **批量操作** - 支持批量创建训练计划
- ✅ **错误处理** - 完善的错误处理和用户反馈

## 📋 前提条件

### 1. 飞书应用权限
确保你的飞书应用拥有以下权限：
- `calendar:calendar.event:create` - 创建日历事件
- `calendar:calendar.event:read` - 读取日历事件
- `calendar:calendar.event:update` - 更新日历事件
- `calendar:calendar.event:delete` - 删除日历事件

### 2. 访问令牌
需要获取 Feishu 访问令牌 (Access Token)。

### 3. 依赖工具
- `curl` - HTTP 客户端
- `date` - 日期时间处理
- `jq` - JSON 处理 (可选，用于更好的输出)

## 🚀 快速开始

### 1. 配置访问令牌

```bash
# 运行配置向导
./create_calendar_event.sh --setup

# 或手动设置环境变量
export FEISHU_ACCESS_TOKEN="your_access_token_here"
```

### 2. 创建测试事件

```bash
# 创建一个简单的测试事件
./create_calendar_event.sh "测试会议" --start "14:00" --end "15:00"
```

### 3. 查看日历事件

```bash
# 查看今天的事件
./list_calendar_events.sh today

# 查看本周事件
./list_calendar_events.sh week
```

### 4. 创建训练计划

```bash
# 创建训练计划（今天和明天）
./create_training_schedule.sh

# 预览而不实际创建
./create_training_schedule.sh --dry-run
```

## 📁 文件说明

| 文件 | 描述 |
|------|------|
| `SKILL.md` | Skill 主文档 |
| `create_calendar_event.sh` | 创建单个日历事件 |
| `create_training_schedule.sh` | 创建训练计划事件 |
| `list_calendar_events.sh` | 列出日历事件 |
| `calendar_api_examples.md` | API 使用示例 |
| `README.md` | 本说明文件 |

## 🏋️‍♂️ 训练计划集成

### 默认训练计划

技能包含一个预设的训练计划：
- **今天 (周日)**: 心肺恢复日训练 (16:00-17:20)
- **明天 (周一)**: 力量训练日训练 (07:00-08:40)

### 自定义训练计划

编辑 `create_training_schedule.sh` 文件，修改 `TRAINING_SCHEDULE` 数组：

```bash
# 格式：日期 开始时间 结束时间 标题 描述 地点
TRAINING_SCHEDULE=(
    "2026-03-01" "16:00" "17:20" "心肺训练" "训练描述..." "健身房"
    "2026-03-02" "07:00" "08:40" "力量训练" "训练描述..." "家中"
)
```

## 🔧 高级用法

### 1. 使用特定日历

```bash
# 指定日历 ID
./create_calendar_event.sh "会议" \
  --calendar "cal_1234567890" \
  --start "14:00" \
  --end "15:00"
```

### 2. 详细输出

```bash
# 显示详细执行信息
./create_calendar_event.sh "会议" --verbose
```

### 3. JSON 输出

```bash
# 以 JSON 格式输出事件列表
./list_calendar_events.sh --json
```

### 4. 搜索事件

```bash
# 搜索包含特定文字的事件
./list_calendar_events.sh --search "训练"
```

## ⚠️ 常见问题

### 1. 权限错误
**问题**: `Error 99991663: No permission to access calendar`
**解决**: 检查飞书应用权限配置，确保有日历相关权限。

### 2. 令牌过期
**问题**: `Error 99991668: Invalid access token`
**解决**: 重新获取访问令牌并更新配置。

### 3. 时间格式错误
**问题**: `Invalid datetime format`
**解决**: 使用正确的格式：`YYYY-MM-DD HH:MM` 或 `HH:MM`

### 4. 日历不存在
**问题**: `Calendar not found`
**解决**: 使用 `primary` 作为日历 ID，或检查日历 ID 是否正确。

## 🔄 与 OpenClaw 集成

### 作为 Skill 使用

1. 将本目录复制到 OpenClaw skills 目录：
   ```bash
   cp -r feishu-calendar /root/.openclaw/workspace/skills/
   ```

2. 在 OpenClaw 中引用：
   ```yaml
   skills:
     - feishu-calendar
   ```

### 在 Agent 中使用

```bash
# 通过 Agent 调用
agent.execute({
  skill: 'feishu-calendar',
  action: 'createTrainingSchedule',
  params: {
    startDate: '2026-03-01'
  }
})
```

## 📊 测试验证

### 1. 配置测试
```bash
./create_calendar_event.sh --setup
```

### 2. 功能测试
```bash
# 创建测试事件
./create_calendar_event.sh "功能测试" --dry-run

# 查看事件列表
./list_calendar_events.sh today --verbose
```

### 3. 集成测试
```bash
# 创建完整的训练计划
./create_training_schedule.sh --dry-run
```

## 🛠️ 开发扩展

### 添加新功能

1. **创建新脚本**：
   ```bash
   # 例如：update_calendar_event.sh
   # 实现事件更新功能
   ```

2. **更新文档**：
   - 在 `SKILL.md` 中添加新功能说明
   - 在 `README.md` 中添加使用示例

3. **测试验证**：
   - 编写测试用例
   - 验证功能正常工作

### 贡献指南

1. Fork 本仓库
2. 创建功能分支
3. 提交更改
4. 创建 Pull Request

## 📚 相关资源

- [Feishu 开放平台文档](https://open.feishu.cn/document/)
- [OpenClaw 技能开发指南](https://docs.openclaw.ai/development/skills)
- [日历 API 参考](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/calendar-v4/calendar-event/create)

## 📄 许可证

本项目基于 MIT 许可证开源。

## 🤝 支持与反馈

如有问题或建议，请：
1. 查看 [常见问题](#常见问题) 部分
2. 提交 Issue
3. 或通过飞书联系开发者

---

**开始使用**：运行 `./create_calendar_event.sh --setup` 进行初始配置！