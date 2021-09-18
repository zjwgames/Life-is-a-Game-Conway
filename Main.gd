extends Node2D

const ZOOM_STEP = 0.1
const CELL = preload("res://Cell.tscn")
export var color_alive = Color.aqua
export var color_dead = Color.gray
export var sim_speed = 1

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
	if event.is_action_pressed("ui_page_up"):
		sim_speed -= 0.1
		$Timer.wait_time = sim_speed
	if event.is_action_pressed("ui_page_down"):
		sim_speed += 0.1
		$Timer.wait_time = sim_speed

var zoom = 1.0

func change_zoom(dz: float):
   zoom = clamp(zoom + dz, 0.1, 8.0)
   $Camera2D.zoom = Vector2(zoom, zoom)

func move_camera(dv: Vector2):
   $Camera2D.offset -= dv

func place_cell(pos: Vector2):
	# Convert mouse position to camera view coordinates
	pos = mouse_pos_to_cam_pos(pos)
	var grid_pos = get_grid_pos(pos)
	if not cells.has(grid_pos):
		add_new_cell(grid_pos)

func mouse_pos_to_cam_pos(pos):
	return pos + $Camera2D.offset / $Camera2D.zoom - get_viewport_rect().size / 2

func add_new_cell(grid_pos):
	var pos = grid_pos * 32.0
	var cell = CELL.instance()
	cell.position = pos
	add_child(cell)
	cell.show()
	cells[grid_pos] = cell
	grids[1][grid_pos] = true
	print("Cell placed!")

func get_grid_pos(pos: Vector2) -> Vector2:
	var pixels = 32.0 / $Camera2D.zoom.x
	return pos.snapped(Vector2(pixels, pixels)) / pixels

func remove_cell(pos: Vector2):
	var key = get_grid_pos(mouse_pos_to_cam_pos(pos))
	# Check if user clicked in occupied position
	if cells.has(key):
		cells[key].queue_free()
		cells.erase(key)
		grids[1].erase(key)
		print("Cell removed!")

func start_stop():
	if $Timer.is_stopped() and cells.size() > 0:
		$Timer.wait_time = sim_speed
		$Timer.start()
		print("Timer started!")
	else:
		$Timer.stop()
		print("Timer stopped!")

func reset():
	$Timer.stop()
	for key in cells.keys():
		cells[key].queue_free()
	grids[1].clear()
	cells.clear()
	print("Board reset!")


func _on_Timer_timeout():
	grids.invert()
	grids[1].clear()
	# Process the game rules
	regenerate()
	add_new_cells()
	update_cells()

func regenerate():
	for key in cells.keys():
		var n = get_num_live_cells(key)
		if grids[0][key]: # Alive
			grids[1][key] = (n == 2 or n == 3)
		else: # Dead
			grids[1][key] = (n == 3)

var to_check = []

func get_num_live_cells(pos: Vector2, first_pass = true):
	var num_live_cells = 0
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x != 0 or y != 0:
				var new_pos = pos + Vector2(x, y)
				if grids[0].has(new_pos):
					if grids[0][new_pos]: # If alive
						num_live_cells += 1
				else:
					if first_pass:
						to_check.append(new_pos)
	return num_live_cells

func update_cells():
	for key in cells.keys():
		cells[key].modulate = color_alive if grids[1][key] else color_dead

func add_new_cells():
	for pos in to_check:
		var n = get_num_live_cells(pos, false)
		if n == 3 and not grids[1].has(pos):
			add_new_cell(pos)
	to_check = []
