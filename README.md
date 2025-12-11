# Maid

<div align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
    </a>
    <a href="README.md">
        <img src="https://img.shields.io/badge/version-1.2.0-green.svg" alt="Version">
    </a>
	<a href="https://discord.gg/gQRfWpTsEE">
		<img src="https://img.shields.io/badge/discord-caps-brightgreen.svg" alt="Discord" />
	</a>
</div>

**Effortless resource management for Roblox development.**

A lightweight, type-safe library that streamlines cleanup processes by allowing you to register connections, instances, threads, and callbacks — then dispose of them all with a single method call.

---

## Features

- **Simple API** - Just three main methods to learn
- **Type-Safe** - Full Luau strict type support
- **Efficient** - Minimal overhead and memory footprint
- **Flexible** - Supports connections, instances, threads, functions, and nested Maids
- **Reliable** - Prevents memory leaks and dangling connections
- **Battle-Tested** - Used in production Roblox games

---

## Installation

### Manual Installation

1. Download the `Maid.luau` file
2. Place it in your project's library folder
3. Require it in your scripts:

```lua
local Maid = require(path.to.Maid)
```

---

## Quick Start

```lua
local Maid = require(path.to.Maid)

-- Create a new Maid instance
local maid = Maid.new()

-- Add cleanup tasks
local connection = workspace.ChildAdded:Connect(function(child)
    print("New child:", child.Name)
end)

local part = Instance.new("Part")
part.Parent = workspace

maid:AddTask(connection, part)

-- Clean up everything at once
maid:DoCleaning()
-- Connection is disconnected, part is destroyed
```

---

## Basic Usage

### Adding Tasks

```lua
local maid = Maid.new()

-- Add a connection
local connection = game:GetService("RunService").Heartbeat:Connect(function()
    print("Heartbeat!")
end)
maid:AddTask(connection)

-- Add an instance
local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui
maid:AddTask(gui)

-- Add a cleanup function
maid:AddTask(function()
    print("Cleanup complete!")
end)

-- Add multiple tasks at once
maid:AddTask(connection1, connection2, instance1)
```

### Automatic Cleanup with Instance Binding

```lua
local maid = Maid.new()

-- Add your tasks
maid:AddTask(workspace.ChildAdded:Connect(print))

-- Bind to a character - cleanup happens automatically when destroyed
local character = player.Character
maid:BindToInstance(character)

-- No need to manually call DoCleaning()!
```

### Nested Maids

```lua
local parentMaid = Maid.new()
local childMaid = Maid.new()

-- Child manages its own resources
childMaid:AddTask(someConnection)

-- Parent will clean up child
parentMaid:AddTask(childMaid)

-- Cleans both parent and child tasks
parentMaid:DoCleaning()
```

---

## Examples

### Class with Cleanup

```lua
local MyClass = {}
MyClass.__index = MyClass

function MyClass.new()
    local self = setmetatable({}, MyClass)
    self._maid = Maid.new()
    
    -- Setup connections that need cleanup
    self._maid:AddTask(
        game:GetService("RunService").Heartbeat:Connect(function()
            self:Update()
        end)
    )
    
    return self
end

function MyClass:Update()
    -- Your logic here
end

function MyClass:Destroy()
    self._maid:DoCleaning()
end

return MyClass
```

### UI Manager

```lua
local function createMenu(parent)
    local maid = Maid.new()
    
    -- Create UI
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.Parent = parent
    maid:AddTask(frame)
    
    -- Add button with connection
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 50)
    button.Text = "Click Me"
    button.Parent = frame
    
    maid:AddTask(button.Activated:Connect(function()
        print("Button clicked!")
    end))
    
    return maid
end

-- Usage
local menuMaid = createMenu(player.PlayerGui.ScreenGui)

-- Later, clean up entire menu
menuMaid:DoCleaning()
```

### Player Data Manager

```lua
local playerMaids = {}

game.Players.PlayerAdded:Connect(function(player)
    local maid = Maid.new()
    playerMaids[player] = maid
    
    -- Track player's character
    maid:AddTask(player.CharacterAdded:Connect(function(character)
        print(player.Name, "spawned")
    end))
    
    -- Cleanup function
    maid:AddTask(function()
        print("Saving data for", player.Name)
        -- Save player data here
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    local maid = playerMaids[player]
    if maid then
        maid:DoCleaning()
        playerMaids[player] = nil
    end
end)
```

### Temporary Effects

```lua
local function applySpeedBoost(character, duration)
    local maid = Maid.new()
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Modify speed
    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = originalSpeed * 2
    
    -- Add particle effect
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = character.PrimaryPart
    maid:AddTask(particles)
    
    -- Restore speed on cleanup
    maid:AddTask(function()
        humanoid.WalkSpeed = originalSpeed
        print("Speed boost ended")
    end)
    
    -- Auto cleanup after duration
    task.delay(duration, function()
        maid:DoCleaning()
    end)
    
    return maid
end

-- Usage
applySpeedBoost(player.Character, 10) -- 10 second speed boost
```

---

## API Reference

### `Maid.new() → Maid`

Creates a new Maid instance.

### `Maid:AddTask(...: MaidTask) → void`

Registers one or more cleanup tasks. Accepts:
- `RBXScriptConnection` - Event connections
- `Instance` - Roblox instances
- `thread` - Coroutines
- `() -> ()` - Cleanup functions
- `Maid` - Nested Maid objects
- Tables with `Disconnect` or `Destroy` methods

### `Maid:BindToInstance(instance: Instance) → void`

Automatically triggers cleanup when the specified Instance is destroyed.

### `Maid:DoCleaning() → void`

Executes cleanup for all registered tasks based on their type:
- **Connections** → Disconnected
- **Instances** → Destroyed
- **Threads** → Closed
- **Functions** → Called
- **Maids** → Cleaned

### `Maid:Destroy() → void`

Alias for `DoCleaning()`.

---

## Supported Task Types

| Type | Cleanup Action |
|------|----------------|
| `RBXScriptConnection` | `connection:Disconnect()` |
| `Instance` | `instance:Destroy()` |
| `thread` | `coroutine.close(thread)` |
| `() -> ()` | `function()` |
| `Maid` | `maid:DoCleaning()` |
| Table with `Disconnect` | `table:Disconnect()` |
| Table with `Destroy` | `table:Destroy()` |
| Table with `__call` | Called as function |

---

## Best Practices

✅ **DO:**
- Always call `DoCleaning()` when resources are no longer needed
- Use `BindToInstance()` for game objects with lifecycles
- Group related cleanup tasks in the same Maid
- Use nested Maids for complex hierarchical systems

❌ **DON'T:**
- Forget to clean up Maids when done
- Add tasks after calling `DoCleaning()` expecting them to be cleaned
- Create circular references between Maids

---

## Type Definitions

```lua
type MaidTask = () -> () | Instance | RBXScriptConnection | Maid | thread

type Maid = {
    AddTask: (self: Maid, ...MaidTask) -> (),
    BindToInstance: (self: Maid, instance: Instance) -> (),
    DoCleaning: (self: Maid) -> (),
    Destroy: (self: Maid) -> ()
}
```

---

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - Created by Vadym Maist
