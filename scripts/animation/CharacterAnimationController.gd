class_name CharacterAnimationController
extends Node

@export var animation_player: AnimationPlayer
@export var idle_animation_name: StringName = &"Idle/mixamo_com"

var current_animation: StringName = &""

func _ready() -> void:
	if animation_player != null:
		print(animation_player.get_animation_list())
		
	_configure_animation_loops()
	play_idle()
	
func play_idle() -> void:
	play_animation(idle_animation_name)
	
func _configure_animation_loops() -> void:
	_set_animation_looping(idle_animation_name, true)
	
func _set_animation_looping(animation_name: StringName, should_loop: bool) -> void:
	if animation_player ==null:
		push_warning("CharacterAnimationController has no AnimationPlayer assigned.")
		return
		
	if not animation_player.has_animation(animation_name):
		push_warning("Cannot set looping. AnimationPlayer does not have animation: %s" % animation_name)
		return
		
	var animation := animation_player.get_animation(animation_name)
	
	if animation == null:
		push_warning("Cannot set looping. Animation is null: %s" % animation_name)
		return
	
	if should_loop:
		animation.loop_mode = Animation.LOOP_LINEAR
	else:
		animation.loop_mode = Animation.LOOP_NONE 
	
func play_animation(animation_name: StringName, custom_blend: float = 0.15) -> void:
	if animation_player == null:
		push_warning("CharacterAnimationController has no AnimationPlayer assigned.")
		return
		
	if not animation_player.has_animation(animation_name):
		push_warning("AnimationPlayer does not have animation: %s" % animation_name)
		return
		
	if current_animation == animation_name:
		return
		
	current_animation = animation_name
	animation_player.play(animation_name, custom_blend)
		
