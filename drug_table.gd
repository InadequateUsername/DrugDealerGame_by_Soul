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

var normal_bg_color = Color("#444444")  # Lighter background for better contrast
var selected_bg_color = Color("#00AA00")  # Keep the green for selected items
var text_color = Color("#FFFFFF")  # White text for better readability
var selected_text_color = Color("#FFFFFF")  # Keep white for selected text
var border_color = Color("#666666")  # Lighter border for better visibility
var selected_border_color = Color("#00FF00")  # Keep green border for selected items
var row_height = 35  # Slightly taller rows for better visibility

# References
var scroll_container
var content_container

func _ready():
	# Set minimum size for the control
	custom_minimum_size = Vector2(200, 200)

	# Create basic structure
	setup_control()

	# Set default font
	font = ThemeDB.fallback_font

	# Set a larger font size for better readability
	var _default_font_size = 16

	# Initial draw
	refresh_items()

	# Set up resizing to ensure content is visible
	resized.connect(_on_resized)

func _on_resized():
	# Ensure scroll container fills the control when resized
	pass
	
func setup_control():
	# Create scroll container that fills the entire control
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
	
	# Make scroll container fill the entire area
	scroll_container.anchor_right = 1.0
	scroll_container.anchor_bottom = 1.0
	
	add_child(scroll_container)
	
	# Create content container
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = SIZE_EXPAND_FILL
	content_container.size_flags_vertical = SIZE_EXPAND_FILL
	scroll_container.add_child(content_container)

func set_columns(new_columns, new_widths = null):
	columns = new_columns
	if new_widths:
		column_widths = new_widths
	refresh_items()

func add_item(values):
	rows.append(values)
	refresh_items()

func clear():
	rows.clear()
	selected_index = -1
	refresh_items()

# Completely reworked refresh_items function to ensure proper highlighting and spacing
func refresh_items():
	# Clear existing rows
	for child in content_container.get_children():
		child.queue_free()
	
	# Create header with more visible styling
	var header = HBoxContainer.new()
	header.size_flags_horizontal = SIZE_EXPAND_FILL
	content_container.add_child(header)
	
	# Create header labels with enhanced visibility
	for i in range(columns.size()):
		var label = Label.new()
		label.text = columns[i]
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = column_widths[i]
		label.add_theme_font_override("font", font)
		label.add_theme_color_override("font_color", Color("#FFFF00"))  # Yellow headers
		label.add_theme_font_size_override("font_size", 18)  # Larger header text
		
		# Set proper alignment for headers
		if i == 1:  # Price column
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		header.add_child(label)
	
	# Add a separator for visual clarity
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 4)
	content_container.add_child(separator)
	
	# Create rows with proper highlighting and alignment
	for row_idx in range(rows.size()):
		# Get the current row data
		var row_data = rows[row_idx]
		
		# Check if row_data is an array, if not, convert it to an array
		if not row_data is Array:
			row_data = [row_data]  # Convert single value to array
		
		# Create row container
		var row_container = HBoxContainer.new()
		row_container.size_flags_horizontal = SIZE_EXPAND_FILL
		row_container.custom_minimum_size.y = row_height
		content_container.add_child(row_container)
		
		# Create background panel
		var bg = Panel.new()
		var style = StyleBoxFlat.new()
		
		# Set background color based on selection state
		if row_idx == selected_index:
			style.bg_color = selected_bg_color
			style.set_border_width_all(2)
			style.border_color = selected_border_color
		else:
			# Alternating row colors for better visibility
			if row_idx % 2 == 0:
				style.bg_color = normal_bg_color
			else:
				style.bg_color = Color(normal_bg_color.r * 0.9, normal_bg_color.g * 0.9, normal_bg_color.b * 0.9)
			
			style.set_border_width_all(1)
			style.border_color = border_color
		
		# Add rounded corners for better visual appeal
		style.set_corner_radius_all(3)
		
		bg.add_theme_stylebox_override("panel", style)
		
		# Set background to fill the entire row
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		row_container.add_child(bg)
		
		# Create clickable button that covers the entire row
		var button = Button.new()
		button.flat = true  # Make it transparent
		button.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# Connect signal
		var idx = row_idx
		button.pressed.connect(func(): _on_row_selected(idx))
		
		row_container.add_child(button)
		
		# Create container for text content (on top of the button)
		var text_container = HBoxContainer.new()
		text_container.size_flags_horizontal = SIZE_EXPAND_FILL
		text_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Pass mouse events to button underneath
		row_container.add_child(text_container)
		
		# Add text labels
		for i in range(min(row_data.size(), columns.size())):
			var label = Label.new()
			label.text = str(row_data[i])
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			label.size_flags_stretch_ratio = column_widths[i]
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 16)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Pass mouse events to button underneath
			
			# Apply different styling for price values
			if i == 1:  # Price column
				label.add_theme_color_override("font_color", Color("#4DFF4D"))  # Green for prices
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Center align prices
			else:
				label.add_theme_color_override("font_color", 
					selected_text_color if row_idx == selected_index else text_color)
			
			text_container.add_child(label)
		
		# Add spacing between rows
		if row_idx < rows.size() - 1:
			var row_separator = HSeparator.new()
			row_separator.add_theme_constant_override("separation", 2)
			content_container.add_child(row_separator)

# When a row is selected
func _on_row_selected(index):
	# Always update the selected index, even if it's the same row
	selected_index = index
	
	# Refresh the display to update highlighting
	refresh_items()
	
	# Emit signal with selected item data
	if index >= 0 and index < rows.size():
		var row = rows[index]
		var drug_name = row[0] if row.size() > 0 else ""
		var price = row[1] if row.size() > 1 else 0
		var quantity = row[2] if row.size() > 2 else 0
		
		print("Selected row: ", row)
		emit_signal("item_selected", drug_name, price, quantity)
