extends Node2D
# Witness the terrible scriptwork of the fool, ShadowXeldron! 

@export var music = preload("res://Audio/Soundtrack/MainMenu.ogg") 

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.music.stream = music
	Global.music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass 

func _on_start_game_gui_input(event):
	Global.main.change_scene_to_file("res://Scene/Presentation/CharacterSelect.tscn","FadeOut","FadeOut",1)
	# Should go to a save select screen instead

func _on_return_to_title_gui_input(event):
	Global.main.change_scene_to_file("res://Scene/Presentation/Title.tscn","FadeOut","FadeOut",1)
