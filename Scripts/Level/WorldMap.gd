extends Node2D
@export var music = preload("res://Audio/Soundtrack/9. SWD_TitleScreen.ogg")

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.music.stream = music
	Global.music.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
