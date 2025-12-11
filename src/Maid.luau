--!strict
-- Vadym Maist

type MaidTask = () -> () | Instance | RBXScriptConnection | Maid | thread

--[=[
	@class Maid
	A resource manager that handles cleanup of various task types.
	Simplifies state management and provides structured cleanup patterns.
]=]
local Maid = {}
Maid.__index = Maid

--[=[
	Constructs a fresh Maid instance
	@return Maid
]=]
function Maid.new(): Maid
	return setmetatable({
		_taskList = {} :: { MaidTask },
	}, Maid)
end

--[=[
	Registers one or more tasks to be cleaned up later via [Maid:Cleanup()].
	Accepts multiple arguments of any cleanup task type.
	@return None
]=]
function Maid.AddTask(self: Maid, ...: MaidTask)
	for _, task in { ... } do
		if type(task) == "table" and not task.Destroy then
			warn("[Maid.AddTask] - Gave table task without .Destroy\n\n" .. debug.traceback())
			return
		end

		table.insert(self._taskList, task)
	end
end

--[=[
	Binds this Maid's lifecycle to an Instance's lifetime.
	When the Instance is destroyed, cleanup will automatically trigger.

	:::note
	The connection monitoring destruction is itself added as a cleanup task
	and will be properly disconnected during the cleanup process.
	:::
]=]
function Maid.BindToInstance(self: Maid, instance: Instance)
	assert(instance, "[Maid.BindToInstance] - Gave nil instance\n\n" .. debug.traceback())

	self:AddTask(instance.Destroying:Connect(function()
		self:DoCleaning()
	end))
end

--[=[
	Will empty the current task table, and iterate over the previously
	given tasks and clean them up, depending on the type of [MaidTask].

	- Tasks of type `RBXScriptConnection`, or tables with a `Disconnect` method
	will have `::Disconnect()` called upon them.

	- Tasks of type `thread` will be terminated through `coroutine.close(Task)`.

	- Tasks of type `Instance`, or tables with a `Destroy` method will have
	`::Destroy()` called upon them.

	- **Any other tasks** will be called as a function.

	:::tip
	Because the default fallback behaviour is to call a given task like
	a function, tables with a `__call` metamethod can be given as a task.
	:::

	:::info
	Only tasks given up to this method's initial invocation will be cleaned,
	even if this method is still running while another task is being given.
	:::

	@yields
]=]
function Maid.DoCleaning(self: Maid)
	local tasks = self._taskList
	for _, t in tasks do
		local taskType = typeof(t)
		local isTable = taskType == "table"

		if taskType == "RBXScriptConnection" then
			(t :: RBXScriptConnection):Disconnect()
		elseif taskType == "thread" then
			coroutine.close(t :: thread)
		elseif taskType == "Instance" or (isTable and (t :: any).Destroy) then
			(t :: Instance):Destroy()
		else
			(t :: () -> ())()
		end
	end

	table.clear(tasks)
end

Maid.Destroy = Maid.DoCleaning

export type Maid = typeof(Maid.new(...))
return table.freeze(Maid)
