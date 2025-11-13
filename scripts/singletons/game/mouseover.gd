extends PanelContainer
class_name Mouseover

const KEY_TYPES = ["", "Exact ", "Star ", "Unstar ", "Signflip ", "Rotor (i) ", "Rotor (-i) ", "Curse ", "Uncurse "]
const LOCK_TYPES = ["", "Blank ", "Blast ", "All ", "Exact "]

func describe(object:GameObject, pos:Vector2, screenBottomRight:Vector2) -> void:
	if !object:
		visible = false
		return
	visible = true
	var string:String = ""
	match object.get_script():
		KeyBulk:
			string += KEY_TYPES[object.type] + Game.COLOR_NAMES[object.color] + " Key"
			if object.type in [KeyBulk.TYPE.NORMAL, KeyBulk.TYPE.EXACT]:
				string += "\nAmount: " + str(object.count)
			if object.color == Game.COLOR.GLITCH: string += "\nMimic: " + Game.COLOR_NAMES[object.glitchMimic]
		Door:
			if object.type == Door.TYPE.SIMPLE:
				string += LOCK_TYPES[object.locks[0].type] + Game.COLOR_NAMES[object.colorSpend] + " Door"
				if object.locks[0].armament: string += " (Armament)"
				string += "\nCost: " + lockCost(object.locks[0])
				if object.locks[0].color != object.colorSpend: string += " " + Game.COLOR_NAMES[object.locks[0].color]
			else:
				if object.type == Door.TYPE.COMBO:
					string += Game.COLOR_NAMES[object.colorSpend]
					string += " Lockless Door" if len(object.locks) == 0 else " Combo Door"
				else: string += "Empty Gate" if len(object.locks) == 0 else "Gate"
				for lock in object.locks:
					string += "\nLock: " + LOCK_TYPES[lock.type] + Game.COLOR_NAMES[lock.color] + ", Cost: " + lockCost(lock)
					if lock.armament:
						string += " (Armament"
						if lock.color == Game.COLOR.GLITCH and lock.glitchMimic != object.glitchMimic: string += ", Mimic: " + Game.COLOR_NAMES[lock.glitchMimic]
						string += ")"
			if object.hasBaseColor(Game.COLOR.GLITCH): string += "\nMimic: " + Game.COLOR_NAMES[object.glitchMimic]
			string += effects(object)
			
		RemoteLock:
			string += LOCK_TYPES[object.type] + Game.COLOR_NAMES[object.color] + " Remote Lock\n"
			string += ("S" if object.satisfied else "Uns") + "atisfied, Cost: " + str(object.cost)
			if object.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]: string += " (" + lockCost(object) + ")"
			if object.armament: string += " (Armament)"
			if object.color == Game.COLOR.GLITCH: string += "\nMimic: " + Game.COLOR_NAMES[object.glitchMimic]
			string += effects(object)
		_:
			visible = false
			return
	%text.text = string
	size = Vector2.ZERO
	position = pos
	if position.x + size.x > screenBottomRight.x: position.x -= size.x
	if position.y + size.y > screenBottomRight.y: position.y -= size.y

func lockCost(lock:GameComponent) -> String:
	var string:String = ""
	if lock.negated: string += "Not "
	match lock.type:
		Lock.TYPE.NORMAL: string += str(lock.count) if lock.count.neq(0) else "None"
		Lock.TYPE.BLANK: string += "None"
		Lock.TYPE.BLAST, Lock.TYPE.ALL:
			string += "["
			var numerator:C = lock.count
			if !lock.denominator.isComplex(): numerator = numerator.over(lock.denominator.axisOrOne())
			if lock.count.isComplex() or numerator.neq(1): string += str(numerator)
			string += "All" if lock.type == Lock.TYPE.BLAST else "ALL"
			if lock.type == Lock.TYPE.BLAST and !lock.denominator.isComplex(): string += (" -" if lock.denominator.sign()<0 else " +") + ("i" if lock.denominator.isNonzeroImag() else "")
			if lock.isPartial:
				if lock.denominator.isComplex() or lock.denominator.eq(0): string += " / " + str(lock.denominator)
				else: string += "/" + str(lock.denominator.over(lock.denominator.axis()))
			string += "]"
		Lock.TYPE.EXACT: string += "Exactly " + str(lock.count)
	return string

func effects(object:GameObject) -> String:
	var string:String = ""
	if object.cursed:
		if object.curseColor == Game.COLOR.BROWN: string += "\nCursed!"
		else:
			string += "\nCursed " + Game.COLOR_NAMES[object.curseColor] + "!"
			if object.curseColor == Game.COLOR.GLITCH: string += " (Mimic: " + Game.COLOR_NAMES[object.curseGlitchMimic] + ")"
	if object.gameFrozen: string += "\nFrozen! (1xRed)"
	if object.gameCrumbled: string += "\nEroded! (5xGreen)"
	if object.gamePainted: string += "\nPainted! (3xBlue)"
	if string: string = "\n- Effects -" + string
	return string
