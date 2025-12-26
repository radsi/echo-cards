extends Node

@onready var TransitionBG: ColorRect = $TransitionBG
@onready var eye: CanvasGroup = $Devil/CanvasGroup
@onready var hands: CanvasGroup = $CanvasGroup
@onready var chat: RichTextLabel = $Devil/Chat
@onready var HBoxChoice: HBoxContainer = $Control/HBoxContainer
@onready var PayButton: Button = $Control/HBoxContainer/PayButton

func _ready() -> void:
	TransitionBG.position = Vector2.ZERO
	globals.current_round = 0
	globals.change_text(PayButton.get_child(0), str(globals.cash) + "/" + str(globals.current_fee))
	
	if globals.cash < globals.current_fee:
		var lbl := PayButton.get_child(0) as Label
		if lbl != null:
			lbl.self_modulate = Color.RED
	
	chat.bbcode_enabled = true
	chat.visible_characters = 0

	eye.self_modulate = Color.TRANSPARENT

	var twn := create_tween()
	twn.tween_property(
		TransitionBG,
		"self_modulate",
		Color.TRANSPARENT,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	twn.finished.connect(_anim_eye)

func _anim_eye() -> void:
	var twn := create_tween()

	twn.tween_property(
		eye,
		"self_modulate",
		Color.WHITE,
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var twn2 := create_tween()

	twn2.tween_property(
		eye.get_child(1),
		"energy",
		1.69,
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	twn2.finished.connect(_anim_hands)

func _anim_hands() -> void:
	var twn := create_tween()

	twn.tween_property(
		hands,
		"position",
		Vector2(0, -150),
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	twn.tween_callback(func():
		hands.z_index = 10
	)

	twn.tween_property(
		hands,
		"position",
		Vector2(0, 0),
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	twn.finished.connect(func():
		speak("Give me...")
		_anim_choices()
	)

func _anim_choices() -> void:
	var twn := create_tween()
	
	twn.tween_property(HBoxChoice, "modulate", Color.WHITE, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func speak(text: String) -> void:
	chat.visible_characters = 0
	chat.text = text

	for i in text.length():
		await get_tree().create_timer(0.3).timeout
		chat.visible_characters += 1


func _on_pay_button_pressed() -> void:
	if (globals.cash < globals.current_fee): return
	globals.cash -= globals.current_fee
	globals.change_text(PayButton.get_child(0), str(globals.cash) + "/" + str(globals.current_fee))
	PayButton.disabled = true
	PayButton.modulate.a = 0.5
	
	$payment_sfx.play()
	
	var twn := create_tween()
	
	twn.tween_property(
		TransitionBG,
		"self_modulate",
		Color.BLACK,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	twn.finished.connect(func(): get_tree().change_scene_to_file("res://game.tscn"); globals.current_fee += 50)


func _on_soul_button_pressed() -> void:
	
	$laugh_sfx.play()
	
	var twn := create_tween()
	
	twn.tween_property(
		TransitionBG,
		"self_modulate",
		Color.BLACK,
		2.7
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	twn.finished.connect(func(): get_tree().change_scene_to_file("res://game_over.tscn"))
