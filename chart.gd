extends Control

@export_range(0, 1, 0.01) var noise_amplitude: float = 0.05
@export_range(0, 1, 0.01) var yoy_growth: float = 0.00
@export_range(10, 100) var days_in_window: int = 30
@export_range(1, 10) var horizontal_speed: float = 5 # How many days to scroll per second
var dod_growth: float = pow(1 + yoy_growth, 1. / 365) - 1

var last_index_in_window: int = -1 # Store latest in window to not loop over all points at every frame
var line_rect: Rect2
var rng = RandomNumberGenerator.new()
var data: Array[float]
var horizontal_unit: float # Distance between two days
var current_start_index: int = 0
const MONTHS := [
	{ "name": "January", "abbr": "Jan", "days": 31 },
	{ "name": "February", "abbr": "Feb", "days": 28 }, # 29 in leap years
	{ "name": "March", "abbr": "Mar", "days": 31 },
	{ "name": "April", "abbr": "Apr", "days": 30 },
	{ "name": "May", "abbr": "May", "days": 31 },
	{ "name": "June", "abbr": "Jun", "days": 30 },
	{ "name": "July", "abbr": "Jul", "days": 31 },
	{ "name": "August", "abbr": "Aug", "days": 31 },
	{ "name": "September", "abbr": "Sep", "days": 30 },
	{ "name": "October", "abbr": "Oct", "days": 31 },
	{ "name": "November", "abbr": "Nov", "days": 30 },
	{ "name": "December", "abbr": "Dec", "days": 31 }
]

func is_leap_year(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)

func generate_data(n: int) -> Array[float]:
	var d: Array[float] = [100.]
	for i in range(n - 1):
		d.append(d[i] * (1 + dod_growth))
	var noise_sum: float = 0.
	for i in range(n):
		noise_sum += rng.randf_range(-1, 1) * noise_amplitude
		d[i] += noise_sum
	return d

func get_data_min_max(from_index, to_index) -> Array[float]:
	var min_data = data[from_index]
	var max_data = data[from_index]
	for i in range(from_index, to_index):
		if data[i] < min_data:
			min_data = data[i]
		if data[i] > max_data:
			max_data = data[i]
	return [min_data, max_data]
	
func get_y_func(a: Vector2, b: Vector2):
	if a.x > b.x: # Swap so a.x <= b.x
		var temp = a
		a = b
		b = temp
	# Move X to 0
	var x_from = a.x
	a.x -= x_from
	b.x -= x_from
	var c: float = (b.y - a.y) / (b.x - a.x)
	var d: float = b.y - c * b.x
	return func(x): return snappedf(c * (x - x_from) + d, 0.01)
	

func draw_all_data() -> void:
	$Line/Line2D.clear_points()
	var min_max = get_data_min_max(0, len(data))
	var y_func = get_y_func(Vector2(min_max[0], line_rect.size.y), Vector2(min_max[1], 0))
	for i in range(len(data)):
		var x = horizontal_unit * i
		var y = y_func.call(data[i])
		$Line/Line2D.add_point(Vector2(x, y))
		
func draw_all_x_ticks() -> void:
	for i in range(len(data)):
		if i % 7 != 0:
			continue # Only display ticks every 7 days
		var x = horizontal_unit * i
		var label = XTickLabel.new()
		var d = get_date_for_index(i)
		label.index = i
		label.text = "%d %s" % [d.day, d.month_abbr]
		$Line/XTicks.add_child(label)
		label.position = Vector2(x - label.size.x / 2, -label.size.y)
		
#func update_window():
	## Update Graph
	##var min_max = get_data_min_max(current_start_index, current_start_index + days_in_window)
	#var min_max = get_data_min_max(0, len(data))
	#var y_from: float = min_max[0]
	#var y_range: float = min_max[1] - min_max[0]
	#for i in range(len(data)):
		#var x = horizontal_unit * (i - current_start_index)
		#var y = line_rect.size.y * (-1. / y_range * data[i] + 1 + y_from / y_range)
		#desired_positions[i] = Vector2(x, y)
	## Update X Ticks
	#for child in $XTicks.get_children():
		#if child is XTickLabel:
			#var x = horizontal_unit * (child.index - current_start_index)
			#child.desired_position = Vector2(x - child.size.x, child.position.y)

func _ready() -> void:
	rng.seed = hash("Godot")
	print("Day over day growth: %2.3f" % dod_growth)
	data = generate_data(365)
	#$Timer.wait_time = 1. / horizontal_speed
	_on_line_item_rect_changed()
	draw_all_x_ticks()
	
## Move Graph
#for i in range(len(data)):
	#var current_position: Vector2 = $Line/Line2D.get_point_position(i)
	#var desired_position: Vector2 = desired_positions[i]
	#if current_position.distance_squared_to(desired_position) < 1e-3:
		#continue # Already at the desired position
	#var direction: Vector2 = desired_position - current_position
	#var scaled_direction: Vector2 = direction / abs(direction.x) * horizontal_unit
	#$Line/Line2D.set_point_position(i, current_position + scaled_direction * delta * horizontal_speed)
## Move X Ticks
#for child in $XTicks.get_children():
	#if child is XTickLabel:
		#var current_position: Vector2 = child.position
		#if current_position.distance_squared_to(child.desired_position) < 1e-3:
			#continue # Already at the desired position
		#var direction: Vector2 = child.desired_position - current_position
		#var scaled_direction: Vector2 = direction / abs(direction.x) * horizontal_unit
		#child.position = current_position + scaled_direction * delta * horizontal_speed
	
func _process(delta: float) -> void:
	if $Line/Line2D.get_point_count() == 0:
		return # Graph not ready yet
	# Move Graph - X
	$Line/Line2D.position.x -= horizontal_unit * horizontal_speed * delta
	# Move X Ticks - X
	$Line/XTicks.position.x -= horizontal_unit * horizontal_speed * delta
	# Move Cursor
	var index: int = last_index_in_window # Will never be -1 unless line_rect.size.x is 0
	while index < $Line/Line2D.get_point_count():
		index += 1
		var position: Vector2 = $Line/Line2D.get_point_position(index)
		if position.x > line_rect.size.x - $Line/Line2D.position.x:
			break
		last_index_in_window = index
	var position_a: Vector2 = $Line/Line2D.get_point_position(last_index_in_window)
	var position_b: Vector2 = $Line/Line2D.get_point_position(last_index_in_window + 1)
	var y_func = get_y_func(position_a, position_b)
	var x = line_rect.size.x - $Line/Line2D.position.x # End of the window
	var y = y_func.call(x)
	$Cursor.position = $Line/Line2D.position + Vector2(x, y)
	#var index_a: int = current_start_index + days_in_window # Last index in window
	#var index_b: int = index_a + 1
	#var position_a: Vector2 = $Line/Line2D.get_point_position(index_a)
	#var position_b: Vector2 = $Line/Line2D.get_point_position(index_b)
	#var a: float = (position_b.y - position_a.y) / (position_b.x - position_a.x)
	#var b: float = position_a.y - a * position_a.x
	#var x = line_rect.size.x
	#var y = a * x + b
	#$Cursor.position = line_rect.position + Vector2(x, y)

func _on_line_item_rect_changed() -> void:
	line_rect = $Line.get_rect()
	horizontal_unit = line_rect.size.x / days_in_window
	if len(data) == 0:
		return # Data not available yet
	draw_all_data()
	#$Timer.start()

#func _on_timer_timeout() -> void:
	#current_start_index += 1
	#update_window()

func get_date_for_index(index: int, start_year: int = 2024) -> Dictionary:
	var day_count := index
	var year := start_year
	
	# Step 1: Find correct year
	while true:
		var days_in_year = 366 if  is_leap_year(year) else 365
		if day_count < days_in_year:
			break
		day_count -= days_in_year
		year += 1
	
	# Step 2: Find correct month
	var month := 0
	while true:
		var days_in_month = MONTHS[month]["days"]
		if month == 1 and is_leap_year(year):
			days_in_month = 29
		if day_count < days_in_month:
			break
		day_count -= days_in_month
		month += 1
	
	# Step 3: Return date parts
	return {
		"year": year,
		"month": month + 1, # 1-based
		"month_name": MONTHS[month]["name"],
		"month_abbr": MONTHS[month]["abbr"],
		"day": day_count + 1 # 1-based
	}
