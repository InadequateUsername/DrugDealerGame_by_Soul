extends Control
class_name DrugTable

signal item_selected(drug_name, price, quantity)

# Table properties
var columns = ["Drug", "Price"]
var column_widths = [0.6, 0.4]  # Proportions
var rows = []
var selected_index = -1

# Styling
var font
var normal_bg_color = Color(1, 1, 1)
var selected_bg_color = Color(0.2, 0.4, 0.8)
var text_color = Color(0, 0, 0)
var selected_text_color = Color(1, 1, 1)
var border_color = Color(0, 0, 0)
var row_height = 24

# References
var scroll_container
var content_container

func _ready():
	# Create basic structure
	setup_control()
	
	# Set default font
	font = ThemeDB.fallback_font
	
	# Initial draw
	queue_redraw()

func setup_control():
	# Create scroll container
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll_container)
	
	# Create content container
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(content_container)

func set_columns(new_columns, new_widths = null):
	columns = new_columns
	if new_widths:
		column_widths = new_widths
	queue_redraw()

func add_item(values):
	rows.append(values)
	refresh_items()

func clear():
	rows.clear()
	selected_index = -1
	refresh_items()

func refresh_items():
	# Clear existing rows
	for child in content_container.get_children():
		child.queue_free()
	
	# Create header
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_child(header)
	
	# Create header labels - using only columns.size() since this is just for headers
	for i in range(columns.size()):
		var label = Label.new()
		label.text = columns[i]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = column_widths[i]
		label.add_theme_font_override("font", font)
		label.add_theme_color_override("font_color", text_color)
		header.add_child(label)
	
	# Create rows
	for row_idx in range(rows.size()):
		# Get the current row data
		var row_data = rows[row_idx]
		
		# Check if row_data is an array, if not, convert it to an array
		if not row_data is Array:
			row_data = [row_data]  # Convert single value to array
		
		var row_container = HBoxContainer.new()
		row_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_container.custom_minimum_size.y = row_height
		
		# Create background panel
		var bg = Panel.new()
		var style = StyleBoxFlat.new()
		style.bg_color = normal_bg_color if row_idx != selected_index else selected_bg_color
		style.set_border_width_all(1)
		style.border_color = border_color
		bg.add_theme_stylebox_override("panel", style)
		
		# Add background as full-size child
		row_container.add_child(bg)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		# Add click detection
		var row_button = Button.new()
		row_button.flat = true
		row_button.mouse_filter = Control.MOUSE_FILTER_PASS
		row_button.set_anchors_preset(Control.PRESET_FULL_RECT)
		row_container.add_child(row_button)
		
		# Connect button signal
		var idx = row_idx  # Make a copy for the closure
		row_button.pressed.connect(func(): _on_row_selected(idx))
		
		# Add text values - now safely checking if row_data is an array
		for i in range(min(row_data.size(), columns.size())):
			var label = Label.new()
			label.text = str(row_data[i])
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_stretch_ratio = column_widths[i]
			label.add_theme_font_override("font", font)
			label.add_theme_color_override("font_color", 
				text_color if row_idx != selected_index else selected_text_color)
			
			# Add as child of row container
			row_container.add_child(label)
		
		content_container.add_child(row_container)

func _on_row_selected(index):
	selected_index = index
	refresh_items()
	
	# Emit signal with selected item data
	if index >= 0 and index < rows.size():
		var row = rows[index]
		var drug_name = row[0] if row.size() > 0 else ""
		var price = row[1] if row.size() > 1 else 0
		var quantity = row[2] if row.size() > 2 else 0
		
		emit_signal("item_selected", drug_name, price, quantity)
