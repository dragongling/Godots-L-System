# Credits to:
# https://godotengine.org/qa/24969/how-to-drag-camera-with-mouse?show=42369#c42369
# https://reddit.com/r/godot/comments/7za028/top_down_scrolling_in_and_out_with_mouse_wheel/dumt5kl
# https://godotengine.org/qa/234/how-to-get-the-screen-dimensions-in-gdscript?show=23791#a23791

extends Camera2D
class_name MainCamera

var _previousPosition: Vector2 = Vector2(0, 0);
var _moveCamera: bool = false;
var _curZoom = 1;
var _zoomSpeed = 0.1;
var _start_position = position

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		get_tree().set_input_as_handled();
		if event.is_pressed():
			_previousPosition = event.position;
			_moveCamera = true;
		else:
			_moveCamera = false;
	elif event is InputEventMouseMotion && _moveCamera:
		get_tree().set_input_as_handled();
		position += (_previousPosition - event.position) * zoom;
		_previousPosition = event.position;

func _input(event):
	if event.is_action_pressed("zoom_in"):
		_curZoom += _zoomSpeed
	elif event.is_action_pressed("zoom_out"):
		_curZoom -= _zoomSpeed
	elif event.is_action_pressed("reset_camera"):
		_curZoom = 1
		position = _start_position
	_zoom_camera()

func _zoom_camera():
	if _curZoom < _zoomSpeed:
		_curZoom = _zoomSpeed
	zoom = Vector2(1, 1) * (1 / pow(_curZoom, 2))
