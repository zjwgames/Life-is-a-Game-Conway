extends Node2D

const ZOOM_STEP = 0.1

var cells = {}
# Define an array of 2 dictionaries
var grids = [{}, {}]

func _unhandled_input(event):
	if event is InputEventMouseButton:
	   if event.button_index == BUTTON_LEFT and event.pressed:
		   place_cell(event.position)
	   if event.button_index == BUTTON_RIGHT and event.pressed:
		   remove_cell(event.position)
	   if event.button_index == BUTTON_WHEEL_DOWN:
		   change_zoom(ZOOM_STEP)
	   if event.button_index == BUTTON_WHEEL_UP:
		   change_zoom(-ZOOM_STEP)
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_MIDDLE:
		   move_camera(event.relative)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_accept"):
		start_stop()
	if event.is_action_pressed("ui_reset"):
		reset()

var zoom = 1.0

func change_zoom(dz: float):
   zoom = clamp(zoom + dz, 0.1, 8.0)
   $Camera2D.zoom = Vector2(zoom, zoom)

func move_camera(dv: Vector2):
   $Camera2D.offset -= dv

func place_cell(pos: Vector2):
	var key = get_grid_pos(pos)
	if not cells.has(key):
		var cell = $Cell.duplicate()
		cell.position = key * 32
		add_child(cell)
		cell.show()
		cells[key] = cell
		grids[1][key] = true

func get_grid_pos(pos: Vector2) -> Vector2:
	return pos.snapped(Vector2(32, 32)) / 32

func remove_cell(pos: Vector2):
	var key = get_grid_pos(pos)
	# Check if user clicked in occupied position
	if cells.has(key):
		cells[key].queue_free()
		cells.erase(key)
		grids[1].erase(key)

func start_stop():
	if $Timer.is_stopped() and cells.size() > 0:
		$Timer.start()
	else:
		$Timer.stop()

func reset():
	$Timer.stop()
	for key in cells.keys():
		cells[key].queue_free()
	grids[1].clear()
	cells.clear()


func _on_Timer_timeout():
	grids.invert()
	grids[1].clear()
	# Process the game rules
