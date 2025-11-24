extends VBoxContainer
class_name ProblemDisplay

@onready var editor:Editor = get_node("/root/editor")
var modId:StringName
var mod:Mods.Mod
var type:StringName
var findProblems:FindProblems
var showIndex:int = 0
var count:int:
	get(): return len(mod.problems[type])

func setup(_mod:StringName,_type:StringName, _findProblems:FindProblems) -> ProblemDisplay:
	modId = _mod
	mod = Mods.mods[modId]
	type = _type
	findProblems = _findProblems
	%nameLabel.text = getProblemName()
	return self

func setTexts() -> void:
	if count == 1: %countLabel.text = "1 instance"
	else: %countLabel.text = str(count) + " instances"
	%showIndex.text = str(showIndex+1) + "/" + str(count)
	visible = count > 0

func getProblemName() -> String:
	match [modId, type]:
		[&"NstdLockSize", &"NstdLockSize"]: return "Nonstandard Lock Size"
		[&"MoreLockConfigs", &"NstdLockConfig"]: return "Nonstandard Lock Configuration"
		[&"ZeroCopies",&"ZeroCopies"]: return "Zero Copy Door"
		[&"ZeroCostLock",&"ZeroCostLock"]: return "Zero Cost Lock"
		[&"InfCopies",&"InfCopies"]: return "Infinite Copy Door"
		[&"NoneColor",&"NoneColor"]: return "None Color"

		[&"C1", &"RemoteLock"]: return "Remote Lock"
		[&"C1", &"LockNegated"]: return "Negated Lock"
		[&"C2", &"DynamiteColor"]: return "Dynamite Color"
		[&"C2", &"QuicksilverColor"]: return "Quicksilver Color"
		[&"C3", &"PartialBlastLock"]: return "Partial Blast Lock"
		[&"C3", &"ExactLock"]: return "Exact Lock"
		[&"C4", &"DarkAuraColor"]: return "Dark Aura Color"
		[&"C4", &"AuraBreakerColor"]: return "Aura Breaker Color"
		[&"C5", &"CurseKeyType"]: return "Curse/Decurse Key"
		[&"C5", &"LockArmament"]: return "Lock Armament"

		[&"DisconnectedLock", &"DisconnectedLock"]: return "Disconnected Lock"
		[&"OutOfBounds", &"OutOfBounds"]: return "Object Out of Bounds"
	return "Somebody forgot to set the ProblemDisplay text for this error :)"

func showInstance(index:int) -> void:
	showIndex = index
	setTexts()
	var component:GameComponent = mod.problems[type][index]
	if component is GameObject:
		editor.focusDialog.defocusComponent()
		editor.focusDialog.focus(component,true)
	else: editor.focusDialog.focusComponent(component)
	editor.scrollIntoView(component)

func _showPressed():
	%shower.visible = true
	%show.visible = false
	if findProblems.shownDisplay: findProblems.shownDisplay.stopShowing()
	findProblems.shownDisplay = self
	showInstance(0)

func stopShowing() -> void:
	if findProblems.shownDisplay != self: return
	findProblems.shownDisplay = null
	%show.visible = true
	%shower.visible = false

func _showLeft(): showInstance(posmod(showIndex-1,count))
func _showRight(): showInstance(posmod(showIndex+1,count))

func newInstance() -> void: setTexts()

func removeInstance(index:int) -> void:
	if count == 0:
		visible = false
		findProblems.problemsLabel.text = "Problems found:" if mod.hasProblems() else "No problems here"
		return
	if showIndex > index: showIndex -= 1
	elif showIndex == count: showInstance(index-1)
	elif showIndex == index: showInstance(index)
	setTexts()
