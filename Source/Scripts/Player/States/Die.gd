extends "res://Scripts/Player/State.gd"

func _physics_process(delta):
	parent.movement.y += parent.grv/GlobalFunctions.div_by_delta(delta)
	parent.translate = true
	
	if parent.playerControl == 1:
		if parent.movement.y > 1000 and Global.lives > 0 and !Global.gameOver:
			parent.movement = Vector2.ZERO
			Global.lives -= 1
			# check if lives are remaining or death was a time over
			if Global.lives > 0 and Global.levelTime < Global.maxTime:
				Global.main.change_scene(null,"FadeOut")
				parent.pause_mode = PAUSE_MODE_STOP
			else:
				Global.gameOver = true
				# reset checkpoint time
				Global.checkPointTime = 0
	else:
		if parent.movement.y > 1000:
			parent.respawn()