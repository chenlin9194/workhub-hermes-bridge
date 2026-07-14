# Feishu Acceptance Prompts

Run these in a new Feishu/Hermes session after `doctor.ps1` passes.

## 1. Raw Connection Check

```text
请只调用 WorkHub 的 health 工具，并原样返回工具响应 JSON；不要自行统计、不要解释。
```

Expected: `service` is `workhub-hermes-v1` and `tools` contains 32 entries including `health`.

## 2. Read-only Overview

```text
请调用 WorkHub 的 get_workhub_overview，告诉我当前项目数、阻塞事项数、风险事项数和未完成 action items 数；不要创建或修改任何内容。
```

## 3. Project Lookup

```text
请在 WorkHub 搜索“<PROJECT_KEYWORD>”，只返回匹配项目的名称、ID、状态和负责人；不要创建或修改任何内容。
```

## 4. Disposable Write Test

```text
请先搜索 WorkHub 是否已有“飞书Hermes MCP验证项目-YYYYMMDD”。如果没有，再创建该项目，并返回项目 ID。
```

```text
请在“飞书Hermes MCP验证项目-YYYYMMDD”中创建事项“V1.0 联通验证”，类型 action，优先级 P1，截止日期 YYYY-MM-DD；同时创建三个 action items，并返回所有 ID。
```

```text
请先读取“V1.0 联通验证”事项。确认唯一后，将状态更新为 following，并更新下一步行动。完成后确认是否生成了“事项变化”系统日志。
```

## 5. Decision and Facts Test

```text
请在“飞书Hermes MCP验证项目-YYYYMMDD”中创建一条可汇报的决策日志，type=decision，source=feishu，reportable=true。
```

```text
请调用 get_today_facts，并只汇总“飞书Hermes MCP验证项目-YYYYMMDD”的可汇报事实、未完成 action items 和风险/阻塞项。
```
