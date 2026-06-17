---
name: sinum-custom-device-ui
description: Stable UI patterns for Sinum custom devices written in Lua and patched through the Sinum API. Use when working on Sinum custom device widgets, power switches, sliders, combo boxes, hidden sections, alarm history, Modbus RTU polling, API patching, UTF-8 Polish text, or when avoiding bouncing controls, jumping sliders, duplicate callbacks, invalid widget hashes, and full-widget renders after writes.
---

# Sinum Custom Device UI

## Core Rule

Treat Sinum controls as owner of their immediate UI state. Lua should write Modbus and update only targeted visibility or text fields. Avoid full widget redraws from value-change callbacks.

## Safe Callback Pattern

For sliders, power switches, combo boxes, and input fields:

```lua
function CustomDevice:write(addr, value, text)
    self:markPending(addr, value)
    K600_scheduleEffectiveRefresh(self)
    if self.rtu then
        self.rtu:writeHoldingRegisterAsync(addr, value)
    end
end
```

Do not call `self:render()` from `write`, `switchWrite`, or ordinary value-change callbacks. Do not call `self:slider(...)` from callbacks that were triggered by that same slider. Do not manually set a power switch value after click unless there is a very specific Sinum reason.

## Power Switches

Use the Sinum switch's own clicked state. Convert and write only:

```lua
function CustomDevice:switchWrite(addr, element, newValue, text)
    local value = SwitchValue(newValue)
    self:markPending(addr, value)
    K600_scheduleEffectiveRefresh(self)
    if self.rtu then
        self.rtu:writeHoldingRegisterAsync(addr, value)
    end
end
```

Avoid these in switch callbacks:

```lua
self:render()
element:setValue("value", value == 1, true)
self.reloadTimer:start(1)
```

Those patterns caused switch bounce: new value, old value, new value.

## Combo Boxes

Treat combo boxes like power switches: let Sinum hold the clicked value, write Modbus, and update only dependent visibility.

```lua
function CustomDevice:onHeatRegModeChanged(newValue, element)
    local value = W(optionValue(newValue, element, 0), 0, 0, 1)
    self:markPending(R_HEAT_REG_MODE, value)
    self:vis("heat_const_slider", value == 0)
    self:showHeatCurveControls(value == 1)
    K600_scheduleEffectiveRefresh(self)
    if self.rtu then
        self.rtu:writeHoldingRegisterAsync(R_HEAT_REG_MODE, value)
    end
end
```

Do not call `element:setValue("value", ...)` for combo boxes in ordinary callbacks. Parse defensively: Sinum may pass a value, a table-like value, or require reading the current element value.

## Temperature Sliders

Sliders are acceptable for user setpoints. Let Sinum keep the immediate slider position. On change, clamp the value and write Modbus. Do not redraw the slider until a normal full poll.

```lua
function CustomDevice:onDhwTargetChanged(newValue, element)
    self:write(R_DHW_TARGET, W(newValue, 50, 20, 65), "Zadana CWU")
end
```

Avoid calling `self:slider("dhw_target_slider", ...)` after the user moves that same slider. In full render, skip slider redraw while its register is `pending`.

## Text Inputs For Curves

Text inputs must validate visually and logically, because Sinum allows arbitrary typed text.

```lua
local function K600_setInput(element, value)
    if element then
        element:setValue("value", tostring(value), true)
    end
end

function CustomDevice:onHeatCurveM20Changed(newValue, element)
    local value = W(newValue, 45, 20, 70)
    K600_setInput(element, value)
    self:write(R_HEAT_CURVE_M20, value, "Krzywa ogrz. -20")
end
```

Heating curve fields use `20..70`. Cooling curve fields should use the safe cooling range used by the BMS map, not arbitrary text. Text-input validation is an allowed exception to the "do not set clicked control value" rule.

## Pending Values And Full Render

Full polling may call `render()`, but render must not overwrite controls that are waiting for BMS confirmation.

```lua
function CustomDevice:isPending(addr)
    return self.pending ~= nil and self.pending[addr] ~= nil
end

function CustomDevice:syncControl(name, addr, value)
    if not self:isPending(addr) then
        self:sv(name, value)
    end
end

function CustomDevice:syncSlider(name, addr, minValue, value, maxValue)
    if not self:isPending(addr) then
        self:slider(name, minValue, value, maxValue)
    end
end
```

Use `self:cv(addr)` for display logic so pending values can control visibility until the BMS confirms or pending expires.

## Visibility Without Full Render

When a combo or switch changes what should be visible, update visibility directly and avoid full render.

For work mode changes, restore nested state after showing a section:

```lua
local function K600_refreshModeVisibility(self, mode)
    local heatVisible = hasMode(mode, 1)
    local coolVisible = hasMode(mode, 4)

    self:showHeatControls(heatVisible)
    if heatVisible then
        local heatReg = W(self:cv(R_HEAT_REG_MODE), 0, 0, 1)
        self:vis("heat_const_slider", heatReg == 0)
        self:showHeatCurveControls(heatReg ~= 0)
    end

    self:showCoolControls(coolVisible)
    if coolVisible then
        local coolReg = W(self:cv(R_COOL_REG_MODE), 0, 0, 1)
        self:vis("cool_const_slider", coolReg == 0)
        self:showCoolCurveControls(coolReg ~= 0)
    end
end
```

Use `hidden_adjust` for hidden elements so the custom device collapses space where Sinum supports it.

## Effective Values Refresh

After writes, do not globally refresh the widget. Schedule a lightweight read after about 4-5 seconds and update only text fields.

```lua
local K600_EFFECTIVE_DELAY = 5

local function K600_scheduleEffectiveRefresh(self)
    self.k600_effective_refresh_due = true
    if self.reloadTimer then
        self.reloadTimer:start(K600_EFFECTIVE_DELAY)
    end
end
```

For K600, targeted read `readHoldingRegistersAsync(10, 6)` updates current and effective temperatures: CWU, buffer heating, buffer cooling. If circuits are shown, a targeted read around `38,10` can update circuit texts. The callback should call a text-only function such as `renderEffectiveTexts(addr)`, not full `render()`.

## Alarm History

For V1-style custom devices, keep alarm history no larger than the visible list unless the user explicitly needs deeper history. A practical default is 20 entries.

Use hidden text elements for persistence, for example:

```text
alarm_history_store
alarm_active_store
```

Rules:

- Do not update alarm history before the first successful alarm-register read.
- Track both START and KONIEC events when active alarms change.
- Avoid method/state name collisions: use names like `alarmHistoryIsExpanded()` for the method and `alarmHistoryOpen` for the boolean state. Never use both `alarmHistoryExpanded()` and `self.alarmHistoryExpanded`.
- Do not call `statistics:addPoint` unless all required Sinum parameters, including `unit`, are known and tested. A missing `unit` caused custom-device bans.

## Naming Guardrail

Do not give a method and a field the same name. Lua allows `self.someName = true` to shadow `function CustomDevice:someName()`, causing runtime errors like `attempt to call a boolean value`.

Preferred pattern:

```lua
function CustomDevice:alarmHistoryIsExpanded()
    return self.alarmHistoryOpen == true
end
```

## Normal Polling

Keep normal full polling at 60 seconds. Full poll may call `render()`. User-triggered writes should not trigger fast one-second full polling or a full-widget redraw.

## Pre-Patch Audit

Before patching live Sinum devices, check the Lua mechanically:

- Zero duplicate `function CustomDevice:*` definitions.
- Zero missing callbacks compared with `elements[].on_change`.
- Zero `self:render()` in user `on*Changed` callbacks.
- Zero direct `self:sv("...switch...")` or `self:sv("...combo...")` in render unless guarded by pending-aware helpers.
- Zero direct `self:slider(...)` in render unless guarded by pending-aware helpers.
- No `statistics:addPoint` unless its full signature is known and tested.
- History/store limits are bounded.

## API Notes

The Sinum API GET for Lua works at:

```text
GET /api/v1/devices/virtual/{id}/lua
```

Lua updates are accepted through:

```text
PATCH /api/v1/devices/virtual/{id}
{ "lua": "..." }
```

After updating, call:

```text
POST /api/v1/devices/virtual/{id}/config-finished
```

Always back up the full device JSON and Lua before patching live central units.

## UTF-8 API Patching

When patching from PowerShell, send JSON as UTF-8 bytes. Otherwise Polish characters and emoji may become `?` or mojibake.

```powershell
$body = @{ lua = $lua } | ConvertTo-Json -Depth 100
$bytes = [Text.Encoding]::UTF8.GetBytes($body)
Invoke-RestMethod -Method Patch `
  -Uri "$base/devices/virtual/$id" `
  -Headers $headers `
  -ContentType 'application/json; charset=utf-8' `
  -Body $bytes
```

## Live Backup Pattern

Before a patch, save:

- full device JSON,
- live Lua,
- element/callback CSV when debugging widget behavior.

After a successful patch, verify:

- `status`,
- `banned=false`,
- empty `ban_reason`,
- `error_counter=0`,
- Lua line count and UTF-8 text still look correct.