extends Resource
class_name KeyColorGlitchTextures

@export var normal:GameTexture
@export var exact:GameTexture
@export var star:GameTexture
@export var unstar:GameTexture
@export var curse:GameTexture
@export var uncurse:GameTexture

func texture(type:KeyBulk.TYPE) -> GameTexture:
	match type:
		KeyBulk.TYPE.EXACT: return exact 
		KeyBulk.TYPE.STAR: return star 
		KeyBulk.TYPE.UNSTAR: return unstar 
		KeyBulk.TYPE.CURSE: return curse 
		KeyBulk.TYPE.UNCURSE: return uncurse 
		_: return normal
