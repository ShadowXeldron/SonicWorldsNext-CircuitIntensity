# Ray Glide script
extends PlayerState

# first is normal, second is super speed
var glideGrav = 0.125
var friction = 0.125
var speedClamp = 24*60

var turnTimer = 0
var speedPreservation = 0

var isFall = false
var landed = false
var sliding = false

# add a ground buffer so that the player won't have just 1 frame on the ground send them into a slide (for example monitors)
var groundBuffer = 0

func state_activated():
	groundBuffer = 0
	# if no movement on the x axis then go into a fall immediately
	if parent.movement.x == 0:
		isFall = true
		landed = false
		sliding = false
		parent.animator.play("roll")
		parent.animator.advance(1)
		
	else:
		if parent.movement.x > 0:
			turnTimer = 0
		else:
			turnTimer = 180
		speedPreservation = abs(parent.movement.x)
		parent.animator.play("glide")
		# work around for animation (needed for attacking flag)
		parent.lastActiveAnimation = "glide"
		isFall = false
		landed = false
		sliding = false
		parent.reflective = true

func state_exit():
	parent.reflective = false

# process mostly used for inputs (see player)
func _process(_delta):
	# Jump and Spindash cancel
	if (parent.inputs[parent.INPUTS.ACTION] == 1 or parent.inputs[parent.INPUTS.ACTION2] == 1 or parent.inputs[parent.INPUTS.ACTION3] == 1) and parent.ground:
		parent.movement.x = 0
		if (parent.inputs[parent.INPUTS.YINPUT] > 0):
			parent.animator.play("spinDash")
			parent.sfx[2].play()
			parent.sfx[2].pitch_scale = 1
			parent.spindashPower = 0
			parent.animator.play("spinDash")
			parent.set_state(parent.STATES.SPINDASH)
			parent.cameraDragLerp = 1
		else:
			# reset animations
			parent.action_jump()
			parent.set_state(parent.STATES.JUMP)
		
	# check if not falling, if not then do glide routine
	if !isFall and !sliding:
		# Go into roll state action not held
		if !parent.inputs[parent.INPUTS.ACTION] and !parent.inputs[parent.INPUTS.ACTION2] and !parent.inputs[parent.INPUTS.ACTION3]:
			parent.animator.play("roll")
			parent.set_state(parent.STATES.ROLL)
			parent.abilityUsed = true

func _physics_process(delta):
	# check if not falling, if not then do glide routine
	if !isFall and !sliding:
		# Turning
		# left
		if parent.direction > 0:
			if turnTimer >= 180:
				speedPreservation = abs(parent.movement.x)
			if turnTimer > 0:
				turnTimer -= 2.8125*delta*60
				parent.movement.x = speedPreservation*cos(deg_to_rad(turnTimer))
		# right
		elif parent.direction < 0:
			if turnTimer <= 0:
				speedPreservation = abs(parent.movement.x)
			if turnTimer < 180:
				turnTimer += 2.8125*delta*60
				parent.movement.x = speedPreservation*cos(deg_to_rad(turnTimer))
		
		turnTimer = clamp(turnTimer,0,180)
		
		# Animation
		var animSize = parent.animator.current_animation_length
		var offset = turnTimer/180
		
		parent.animator.advance(-parent.animator.current_animation_position+(animSize*offset))
		
		# set facing direction
		parent.sprite.flip_h = false
		
		# air movement
		if parent.pushingWall == 0:
			parent.movement.x = clamp(parent.movement.x + (GlobalFunctions.div_by_delta(delta)*parent.direction), -speedClamp, speedClamp)
		
		# Do Ray's vertical stuff
		parent.movement.y += parent.inputs[parent.INPUTS.YINPUT] * 6
		
		# Go into sliding if on ground
		if parent.ground and !sliding and groundBuffer >= 1:
			parent.set_state(parent.STATES.NORMAL)
		
		# apply ground buffer
		elif parent.ground:
			groundBuffer = 1
		else:
			groundBuffer = 0
		
		# prevent getting stuck on corners
		parent.horizontalSensor.position.y = (parent.get_node("HitBox").shape.size.y/2)-1
		parent.horizontalSensor.force_raycast_update()
		if parent.horizontalSensor.is_colliding() and !parent.ground:
			parent.movement.x = 0
	
	# if sliding then do sliding routine
	elif sliding:
		
		if parent.movement.x != 0:
			parent.direction = sign(parent.movement.x)
		parent.movement.x = move_toward(parent.movement.x,0,friction/GlobalFunctions.div_by_delta(delta))
		
		# set direction
		parent.sprite.flip_h = (parent.direction < 0)
		if parent.movement.x == 0 and parent.lastActiveAnimation != "glideGetUp" and parent.ground:
			parent.cameraDragLerp = 1
			parent.set_hitbox(parent.currentHitbox.NORMAL)
			#parent.animator.play("glideGetUp")
			# wait for animation to finish and check that the state is still the same
			if parent.currentState == parent.STATES.GLIDE and sliding:
				parent.set_state(parent.STATES.NORMAL)
		
		# check if angle is default, if not then set movement to 0
		if !is_equal_approx(parent.snap_angle(parent.gravityAngle),parent.snap_angle(parent.global_rotation)):
			parent.movement.x = 0
		
		# check for ground, if not on ground go into falling
		if !parent.ground and groundBuffer >= 1:
			sliding = false
			parent.animator.play("glideFall")
			parent.sprite.flip_h = (parent.direction < 0)
			# reset hitbox
			parent.set_hitbox(parent.currentHitbox.NORMAL)
			isFall = true
		else:
			# ground buffer's needed to prevent the player immediately disconecting
			groundBuffer = 1
			parent.movement.y = 0

# create skid dust
func _on_SkidDustTimer_timeout():
	if parent.currentState == parent.STATES.GLIDE:
		if !sliding or (parent.movement.x == 0 and parent.ground):
			$"../../SkidDustTimer".stop()
		elif parent.ground:
			var dust = parent.Particle.instantiate()
			dust.play("SkidDust")
			dust.global_position = parent.global_position+(Vector2.DOWN * 8).rotated(deg_to_rad(parent.spriteRotation - 90))
			dust.z_index = 10
			parent.get_parent().add_child(dust)
			parent.sfx[28].play()
