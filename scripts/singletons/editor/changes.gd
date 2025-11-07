extends Node

@onready var editor:Editor = get_node("/root/editor")

var undoStack:Array[RefCounted] = [UndoSeparator.new()]
var stackPosition:int = 0

var saveBuffered:bool = false

# handles the undo system for the editor

func bufferSave() -> void:
	saveBuffered = true

func addChange(change:Change) -> Change:
	if change.cancelled: return null
	editor.game.anyChanges = true
	if stackPosition != len(undoStack) - 1: undoStack = undoStack.slice(0,stackPosition+1)
	undoStack.append(change)
	stackPosition += 1
	return change

func _process(_delta) -> void:
	if saveBuffered:
		saveBuffered = false
		if undoStack[stackPosition] is UndoSeparator: return # nothing new happened
		undoStack.append(UndoSeparator.new())
		stackPosition += 1

func undo() -> void:
	if stackPosition == 0: return
	editor.game.anyChanges = true
	if undoStack[stackPosition] is UndoSeparator: stackPosition -= 1
	else:
		assert(stackPosition == len(undoStack)-1) # new Changes havent been saved yet
		undoStack.append(UndoSeparator.new()) # [sep] [chg] <[chg]> -> [sep] [chg] <[chg]> [sep]
	saveBuffered = false
	while true:
		var change = undoStack[stackPosition]
		if change is UndoSeparator: return
		change.undo()
		stackPosition -= 1

func redo() -> void:
	if stackPosition == len(undoStack) - 1: return
	stackPosition += 1
	while true:
		var change = undoStack[stackPosition]
		if change is UndoSeparator: return
		change.do()
		stackPosition += 1

func copy(value:Variant) -> Variant:
	if value is C || value is Q: return value.copy()
	elif value is Array: return value.duplicate()
	else: return value

class Change extends RefCounted:
	var game:Game
	var cancelled:bool = false
	# is a singular recorded change
	func do() -> void: pass
	func undo() -> void: pass

class UndoSeparator extends RefCounted:
	# indicates the start/end of an undo in the stack
	func _to_string() -> String:
		return "<UndoSeparator>"

class TileChange extends Change:
	var position:Vector2i
	var beforeTile:bool # probably make a tile enum at some point but right now we either have tile or not
	var afterTile:bool # same as above

	func _init(_game:Game,_position:Vector2i,_afterTile:bool) -> void:
		game = _game
		position = _position
		afterTile = _afterTile
		beforeTile = game.tiles.get_cell_source_id(position) != -1
		if afterTile == beforeTile:
			cancelled = true
			return
		do()

	func do() -> void:
		if afterTile: game.tiles.set_cell(position,1,Vector2i(1,1))
		else: game.tiles.erase_cell(position)

	func undo() -> void:
		if beforeTile: game.tiles.set_cell(position,1,Vector2i(1,1))
		else: game.tiles.erase_cell(position)

	func _to_string() -> String:
		return "<TileChange:"+str(position.x)+","+str(position.y)+">"

class CreateComponentChange extends Change:
	var type:GDScript
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary
	var id:int
	var result:GameComponent

	func _init(_game:Game,_type:GDScript,parameters:Dictionary[StringName, Variant]) -> void:
		game = _game
		type = _type
		
		if type == Lock or type == KeyCounterElement: id = game.componentIdIter; game.componentIdIter += 1
		else: id = game.objectIdIter; game.objectIdIter += 1

		for property in type.CREATE_PARAMETERS:
			prop[property] = Changes.copy(parameters[property])
		
		if type in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects

		do()
		if type == PlayerSpawn and !game.levelStart:
			Changes.addChange(GlobalObjectChange.new(game,game,&"levelStart",result))
		elif type == KeyCounterElement:
			game.objects[prop[&"parentId"]]._elementsChanged()

	func do() -> void:
		var component:GameComponent
		var parent:Node = game.objectsParent
		if type in Game.NON_OBJECT_COMPONENTS: component = type.new()
		else: component = type.SCENE.instantiate()

		component.editor = game.editor
		component.game = game

		component.id = id
		for property in component.CREATE_PARAMETERS:
			component.set(property, Changes.copy(prop[property]))
			component.propertyChangedDo(property)
		dictionary[id] = component

		if type == Lock:
			parent = game.objects[prop[&"parentId"]]
			component.parent = parent
			prop[&"index"] = len(parent.locks)
			component.index = prop[&"index"]
			parent.locks.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = game.objects[prop[&"parentId"]]
			component.parent = parent
			prop[&"index"] = len(parent.elements)
			parent.elements.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexElements()
		else: parent.add_child(component)

		result = component
		if parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusHandlerAdded(type, prop[&"index"])

		await component.ready
		component.isReady = true
		if game.editor.findProblems: game.editor.findProblems.findProblems(component)

	func undo() -> void:
		game.editor.objectHovered = null
		game.editor.componentDragged = null

		if dictionary[id] == game.editor.focusDialog.focused: game.editor.focusDialog.defocus()
		elif dictionary[id] == game.editor.focusDialog.componentFocused: game.editor.focusDialog.defocusComponent()

		var parent:GameObject
		if type == Lock:
			parent = game.objects[prop[&"parentId"]]
			parent.locks.pop_at(prop[&"index"])
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = game.objects[prop[&"parentId"]]
			parent.elements.pop_at(prop[&"index"])
			parent.reindexElements()

		if game.editor.findProblems: game.editor.findProblems.componentRemoved(dictionary[id])

		dictionary[id].queue_free()
		dictionary.erase(id)

		if parent and parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusHandlerRemoved(type, prop[&"index"])
	
	func _to_string() -> String:
		return "<CreateComponentChange:"+str(id)+">"

class DeleteComponentChange extends Change:
	var type:GDScript
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary
	var arrays:Dictionary[StringName, Array] = {} # dictionary[property, array[type, array]]

	func _init(_game:Game,component:GameComponent) -> void:
		type = component.get_script()
		game = _game
		for property in component.PROPERTIES:
			prop[property] = Changes.copy(component.get(property))
		for array in component.ARRAYS.keys():
			var copiedArray = []
			for element in component.get(array):
				if element is GameComponent: copiedArray.append(element.id)
				else: copiedArray.append(Changes.copy(element))
			arrays[array] = [component.ARRAYS[array], copiedArray]

		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects
		
		if type == Door:
			for lock in component.locks.duplicate():
				Changes.addChange(DeleteComponentChange.new(game,lock))
		elif type == KeyCounter:
			for element in component.elements.duplicate():
				Changes.addChange(DeleteComponentChange.new(game,element))
		
		if type == PlayerSpawn and component == game.levelStart:
			Changes.addChange(GlobalObjectChange.new(game,game,&"levelStart",null))
		
		component.deletedInit()
		do()
		if type == KeyCounterElement:
			game.objects[prop[&"parentId"]]._elementsChanged()

	func do() -> void:
		game.editor.objectHovered = null
		game.editor.componentDragged = null

		if dictionary[prop[&"id"]] == game.editor.focusDialog.focused: game.editor.focusDialog.defocus()
		elif dictionary[prop[&"id"]] == game.editor.focusDialog.componentFocused: game.editor.focusDialog.defocusComponent()

		var parent:GameObject
		if type == Lock:
			parent = game.objects[prop[&"parentId"]]
			parent.locks.pop_at(prop[&"index"])
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = game.objects[prop[&"parentId"]]
			parent.elements.pop_at(prop[&"index"])
			parent.reindexElements()
		
		if game.editor.findProblems: game.editor.findProblems.componentRemoved(dictionary[prop[&"id"]])

		dictionary[prop[&"id"]].queue_free()
		dictionary.erase(prop[&"id"])

		if parent and parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusHandlerRemoved(type, prop[&"index"])
	
	func undo() -> void:
		var component:Variant
		var parent:Variant = game.objectsParent
		if type in Game.NON_OBJECT_COMPONENTS: component = type.new()
		else: component = type.SCENE.instantiate()
		
		component.editor = game.editor
		component.game = game

		for property in component.PROPERTIES:
			component.set(property, Changes.copy(prop[property]))
			component.propertyChangedDo(property)
		for array in component.ARRAYS.keys():
			var componentArray = component.get(array)
			componentArray.clear()
			if arrays[array][0] in Game.COMPONENTS:
				@warning_ignore("incompatible_ternary")
				var arrayDictionary:Dictionary = game.components if arrays[array][0] in Game.NON_OBJECT_COMPONENTS else game.objects
				for element in arrays[array][1]: componentArray.append(arrayDictionary[element])
			else:
				for element in arrays[array][1]: componentArray.append(Changes.copy(element))
			print(component.get(array))
		dictionary[prop[&"id"]] = component
		
		if type == Lock:
			parent = game.objects[prop[&"parentId"]]
			component.parent = parent
			component.index = prop[&"index"]
			parent.locks.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = game.objects[prop[&"parentId"]]
			component.parent = parent
			parent.elements.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexElements()
		else: parent.add_child(component)

		if parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusHandlerAdded(type, prop[&"index"])

		await component.ready
		component.isReady = true
		if game.editor.findProblems: game.editor.findProblems.findProblems(component)

	func _to_string() -> String:
		return "<DeleteComponentChange:"+str(prop[&"id"])+">"

class PropertyChange extends Change:
	var id:int
	var property:StringName
	var before:Variant
	var after:Variant
	var type:GDScript
	
	func _init(_game:Game,component:GameComponent,_property:StringName,_after:Variant) -> void:
		game = _game
		id = component.id
		property = _property
		before = Changes.copy(component.get(property))
		after = Changes.copy(_after)
		type = component.get_script()
		if before == after:
			cancelled = true
			return
		do()
		component.propertyChangedInit(property)

	func do() -> void: changeValue(Changes.copy(after))
	func undo() -> void: changeValue(Changes.copy(before))
	
	func changeValue(value:Variant) -> void:
		var component:GameComponent
		if type in Game.NON_OBJECT_COMPONENTS: component = game.components[id]
		else: component = game.objects[id]
		component.set(property, value)
		component.propertyChangedDo(property)
		component.queue_redraw()
		if game.editor.focusDialog.focused == component: game.editor.focusDialog.focus(component)
		elif game.editor.focusDialog.componentFocused == component: game.editor.focusDialog.focusComponent(component)
		if game.editor.findProblems: game.editor.findProblems.findProblems(component)
	
	func _to_string() -> String:
		return "<PropertyChange:"+str(id)+"."+str(property)+"->"+str(after)+">"

class GlobalObjectChange extends Change:
	# Changes a property that points to a gameobject in some singleton; -1 for null

	var singleton:Node
	var property:StringName
	var beforeId:int
	var afterId:int

	func _init(_game:Game, _singleton:Node, _property:StringName, after:GameObject) -> void:
		game =_game
		singleton = _singleton
		property = _property
		if singleton.get(property): beforeId = singleton.get(property).id
		else: beforeId = -1
		if after: afterId = after.id
		else: afterId = -1
		if beforeId == afterId:
			cancelled = true
			return
		do()
	
	func do() -> void: changePointer(afterId)
	func undo() -> void: changePointer(beforeId)

	func changePointer(id:int) -> void:
		if id == -1: singleton.set(property, null)
		else: singleton.set(property, game.objects[id])

		if singleton == game and property == &"levelStart":
			game.editor.topBar.updatePlayButton()

	func _to_string() -> String:
		return "<GlobalObjectChange:"+str(singleton)+"."+str(property)+"->"+str(afterId)+">"

class GlobalPropertyChange extends Change:
	# Changes a property in some singleton

	var singleton:Variant
	var property:StringName
	var before:Variant
	var after:Variant

	func _init(_singleton:Variant, _property:StringName, _after:Variant) -> void:
		singleton = _singleton
		property = _property
		before = singleton.get(property)
		after = _after
		if before == after:
			cancelled = true
			return
		do()

	func do() -> void: singleton.set(property, after)
	func undo() -> void: singleton.set(property, before)

	func _to_string() -> String:
		return "<GlobalPropertyChange:"+str(singleton)+"."+str(property)+"->"+str(after)+">"

class ArrayAppendChange extends Change:
	# appends to array
	var id:int
	var array:StringName
	var after:Variant
	var dictionary:Dictionary

	func _init(_game:Game,component:GameComponent,_array:StringName,_after:Variant) -> void:
		game = _game
		id = component.id
		after = _after
		array = _array
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects
		do()

	func do() -> void: dictionary[id].get(array).append(after); dictionary[id].queue_redraw()
	func undo() -> void: dictionary[id].get(array).pop_back(); dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ArrayAppendChange:"+str(id)+"."+str(array)+"+="+str(after)+">"

class ArrayElementChange extends Change:
	# Changes element of array
	var id:int
	var array:StringName
	var index:int
	var before:Variant
	var after:Variant
	var dictionary:Dictionary

	func _init(_game:Game,component:GameComponent,_array:StringName,_index:int,_after:Variant) -> void:
		game = _game
		id = component.id
		index = _index
		array = _array
		before = Changes.copy(component.get(array)[index])
		after = Changes.copy(_after)
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects
		do()

	func do() -> void: dictionary[id].get(array)[index] = Changes.copy(after); dictionary[id].queue_redraw()
	func undo() -> void: dictionary[id].get(array)[index] = Changes.copy(before); dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ArrayElementChange:"+str(id)+"."+str(array)+"."+str(index)+"->"+str(after)+">"
class ArrayPopAtChange extends Change:
	# pops at array index
	var id:int
	var array:StringName
	var index:int
	var before:Variant
	var dictionary:Dictionary

	func _init(_game:Game,component:GameComponent,_array:StringName,_index:int) -> void:
		game = _game
		id = component.id
		array = _array
		index = _index
		before = Changes.copy(component.get(array)[index])
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects
		do()

	func do() -> void: dictionary[id].get(array).pop_at(index); dictionary[id].queue_redraw()
	func undo() -> void: dictionary[id].get(array).insert(index,Changes.copy(before)); dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ArrayPopAtChange:"+str(id)+"."+str(array)+"-="+str(index)+">"

class ComponentArrayAppendChange extends Change:
	# appends to array of components
	var id:int
	var array:StringName
	var afterId:int
	var dictionary:Dictionary
	var elementDictionary:Dictionary
	var elementType:GDScript
	var index:int

	func _init(_game:Game,component:GameComponent,_array:StringName,after:GameComponent) -> void:
		game = _game
		id = component.id
		afterId = after.id
		array = _array
		elementType = after.get_script()
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects
		if elementType in Game.NON_OBJECT_COMPONENTS: elementDictionary = game.components
		else: elementDictionary = game.objects
		index = len(component.get(array))
		do()

	func do() -> void:
		dictionary[id].get(array).append(elementDictionary[afterId])
		if dictionary[id] == game.editor.focusDialog.focused or dictionary[id] == game.editor.focusDialog.componentFocused:
			game.editor.focusDialog.focusHandlerAdded(elementType, index)
		dictionary[id].queue_redraw()
	func undo() -> void:
		dictionary[id].get(array).pop_back()
		if dictionary[id] == game.editor.focusDialog.focused or dictionary[id] == game.editor.focusDialog.componentFocused:
			game.editor.focusDialog.focusHandlerRemoved(elementType, index)
		dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ComponentArrayAppendChange:"+str(id)+"."+str(array)+"+="+str(afterId)+">"
class ComponentArrayElementChange extends Change:
	# Changes element of array of components
	var id:int
	var array:StringName
	var index:int
	var beforeId:int
	var afterId:int
	var dictionary:Dictionary
	var elementDictionary:Dictionary

	func _init(_game:Game,component:GameComponent,_array:StringName,_index:int,after:GameComponent) -> void:
		game = _game
		id = component.id
		index = _index
		array = _array
		beforeId = component.get(array)[index].id
		afterId = after.id
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects
		if after.get_script() in Game.NON_OBJECT_COMPONENTS: elementDictionary = game.components
		else: elementDictionary = game.objects
		do()

	func do() -> void: dictionary[id].get(array)[index] = elementDictionary[afterId]; dictionary[id].queue_redraw()
	func undo() -> void: dictionary[id].get(array)[index] = elementDictionary[beforeId]; dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ComponentArrayElementChange:"+str(id)+"."+str(array)+"."+str(index)+"->"+str(afterId)+">"

class ComponentArrayPopAtChange extends Change:
	# pops at array of components index
	var id:int
	var array:StringName
	var index:int
	var beforeId:int
	var dictionary:Dictionary
	var elementDictionary:Dictionary
	var elementType:GDScript

	func _init(_game:Game,component:GameComponent,_array:StringName,_index:int) -> void:
		game = _game
		id = component.id
		array = _array
		index = _index
		beforeId = component.get(array)[index].id
		elementType = component.get(array)[index].get_script()
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = game.components
		else: dictionary = game.objects
		if elementType in Game.NON_OBJECT_COMPONENTS: elementDictionary = game.components
		else: elementDictionary = game.objects
		do()

	func do() -> void:
		dictionary[id].get(array).pop_at(index)
		if dictionary[id] == game.editor.focusDialog.focused or dictionary[id] == game.editor.focusDialog.componentFocused:
			game.editor.focusDialog.focusHandlerRemoved(elementType, index)
		dictionary[id].queue_redraw()
	
	func undo() -> void:
		dictionary[id].get(array).insert(index,elementDictionary[beforeId])
		if dictionary[id] == game.editor.focusDialog.focused or dictionary[id] == game.editor.focusDialog.componentFocused:
			game.editor.focusDialog.focusHandlerAdded(elementType, index)
		dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ComponentArrayPopAtChange:"+str(id)+"."+str(array)+"-="+str(index)+">"
