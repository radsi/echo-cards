extends Sprite2D

var PlayerCards

var mouse_inside = false

func _ready():
	$Area2D.mouse_entered.connect(_on_mouse_entered)
	$Area2D.mouse_exited.connect(_on_mouse_exited)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and mouse_inside:
		PlayerCards.use_discard($".")

func _on_mouse_entered():
	mouse_inside = true
	_highlight_card()

func _on_mouse_exited():
	mouse_inside = false
	_reset_card()

func _process(delta):
	if mouse_inside:
		var mouse_pos = get_global_mouse_position()
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collide_with_areas = true
		query.collide_with_bodies = false
		
		var results = space_state.intersect_point(query)
		
		var top_card = null
		var highest_z = -999
		
		for result in results:
			var card = result.collider.get_parent()
			if card is Sprite2D:
				if card.z_index > highest_z:
					highest_z = card.z_index
					top_card = card
		
		if top_card == self:
			_highlight_card()
		else:
			_reset_card()

func _highlight_card():
	z_index = 100
	scale = Vector2(1.15, 1.15)

func _reset_card():
	z_index = 0
	scale = Vector2(1, 1)
