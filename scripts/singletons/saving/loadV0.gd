extends Node
class_name LoadV0

static var COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement, KeyBulk, Door, Goal, KeyCounter, PlayerSpawn, RemoteLock]
static var NON_OBJECT_COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement]

static var PROPERTIES:Dictionary[GDScript,Array] = {
	Lock: [
		&"id", &"position", &"size",
		&"parentId", &"color", &"type", &"configuration", &"sizeType", &"count", &"isPartial", &"denominator", &"negated", &"armament",
		&"index", &"displayIndex"
	],
	KeyCounterElement: [
		&"id", &"position", &"size",
		&"parentId", &"color",
		&"index"
	],
	KeyBulk: [
		&"id", &"position", &"size",
		&"color", &"type", &"count", &"infinite"
	],
	Door: [
		&"id", &"position", &"size",
		&"colorSpend", &"copies", &"infCopies", &"type",
		&"frozen", &"crumbled", &"painted"
	],
	Goal: [
		&"id", &"position", &"size",
		&"type"
	],
	KeyCounter: [
		&"id", &"position", &"size",
	],
	PlayerSpawn: [
		&"id", &"position", &"size",
	],
	RemoteLock: [
		&"id", &"position", &"size",
		&"color", &"type", &"configuration", &"sizeType", &"count", &"isPartial", &"denominator", &"negated", &"armament",
		&"frozen", &"crumbled", &"painted"
	]
}
static var ARRAYS:Dictionary[GDScript,Dictionary] = {
	Lock: {},
	KeyCounterElement: {},
	KeyBulk: {},
	Door: {&"remoteLocks":RemoteLock},
	Goal: {},
	KeyCounter: {},
	PlayerSpawn: {},
	RemoteLock: {&"doors":Door},
}

# LEVEL METADATA:
# - level name
# - level description
# - level author
# - level size
# - active mods
# - modpack
# - modpack version
# LEVEL DATA:
# - tiles
# - components
# - objects

static func load(file:FileAccess, game:Game) -> void:
	game.level = file.get_var(true)
	game.level.game = game
	game.levelBounds.size = file.get_var()
	for mod in file.get_var(): Mods.mods[mod].active = true
	var modpackId:StringName = file.get_var()
	if modpackId: Mods.activeModpack = Mods.modpacks[modpackId]
	if Mods.activeModpack: Mods.activeVersion = Mods.activeModpack.versions[file.get_32()]
	var levelStart:int = file.get_64()
	# LEVEL DATA
	# tiles
	game.tiles.tile_map_data = file.get_var()
	# components
	game.componentIdIter = file.get_64()
	var componentBufferedArrays:Dictionary[int,Dictionary] = {} # dictionary[object id, dictionary[property name, array]]
	for _i in file.get_64():
		var type:GDScript = COMPONENTS[file.get_16()]
		var component = type.new()
		component.game = game
		component.editor = game.editor
		for property in PROPERTIES[type]:
			var value = file.get_var(true)
			if property == &"id":
				game.components[value] = component
			component.set(property, value)
			component.propertyChangedDo(property)
		for array in ARRAYS[type].keys():
			componentBufferedArrays[component.id][array] = file.get_var() # handle it at the end; not all components will be ready
	# objects
	game.objectIdIter = file.get_64()
	var objectBufferedArrays:Dictionary[int,Dictionary] = {} # dictionary[object id, dictionary[property name, array]]
	for _i in file.get_64():
		var type:GDScript = COMPONENTS[file.get_16()]
		var object = type.SCENE.instantiate()
		object.game = game
		object.editor = game.editor
		for property in PROPERTIES[type]:
			var value = file.get_var(true)
			if property == &"id":
				game.objects[value] = object
				game.objectsParent.add_child(object)
			object.set(property, value)
			object.propertyChangedDo(property)
		objectBufferedArrays[object.id] = {}
		for array in ARRAYS[type].keys():
			objectBufferedArrays[object.id][array] = file.get_var() # handle it at the end
		if type == Door:
			object.locks.assign(Saving.IDArraytoComponents(Lock, file.get_var()))
			for lock in object.locks:
				lock.parent = object
				object.add_child(lock)
			object.reindexLocks()
		if type == KeyCounter:
			object.elements.assign(Saving.IDArraytoComponents(KeyCounterElement, file.get_var()))
			for element in object.elements:
				element.parent = object
				object.add_child(element)
	
	for componentId in componentBufferedArrays.keys():
		var component:GameComponent = game.components[componentId]
		for array in ARRAYS[component.get_script()]:
			var value:Array = componentBufferedArrays[componentId][array]
			var arrayType:GDScript = ARRAYS[component.get_script()][array]
			if arrayType in COMPONENTS: value = Saving.IDArraytoComponents(arrayType,value)
			component.get(array).assign(value)

	for objectId in objectBufferedArrays.keys():
		var object:GameObject = game.objects[objectId]
		for array in ARRAYS[object.get_script()]:
			var value:Array = objectBufferedArrays[objectId][array]
			var arrayType:GDScript = ARRAYS[object.get_script()][array]
			if arrayType in COMPONENTS: value = Saving.IDArraytoComponents(arrayType,value)
			object.get(array).assign(value)

	if levelStart != -1:
		game.levelStart = game.objects[levelStart]
		game.editor.topBar._updateButtons()
	
	game.updateWindowName()
	game.editor.settingsMenu.opened()
	game.editor.updateDescription()
	game.get_tree().call_group("modUI", "changedMods")
