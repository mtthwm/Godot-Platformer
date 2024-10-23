extends AnimatedSprite2D

func _process(_delta):
	if Input.is_action_pressed("move_left"):
		play("run");
		flip_h = true;
	elif Input.is_action_pressed("move_right"):
		play("run");
		flip_h = false;
	else:
		stop();
