class_name DebugOverlay
extends CanvasLayer

@export_group("References")
@export var panel: Control
@export var state_label: DebugStateLabel

@export_group("Behavior")
@export var toggle_action: StringName = &"toggle_debug_overlay"
@export_range(1.0, 60.0, 1.0) var refresh_rate_hz: float = 10.0
@export var visible_on_start: bool = true

var _refresh_timer: float = 0.0

func _ready() -> void:
	if panel == null:
		push_warning("DebugOverlay has no panel assigned.")
	else:
		panel.visible = visible_on_start

	_refresh()

func _process(delta: float) -> void:
	if panel == null or not panel.visible:
		return

	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return

	_refresh_timer = 1.0 / maxf(refresh_rate_hz, 1.0)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if toggle_action == &"":
		return

	if event.is_action_pressed(toggle_action, false):
		if panel != null:
			panel.visible = not panel.visible

			if panel.visible:
				_refresh_timer = 0.0
				_refresh()

		get_viewport().set_input_as_handled()

func _refresh() -> void:
	if state_label != null:
		state_label.refresh()
