extends Node

# Theme colors
const DARK_BG_COLOR = Color("#1E1E1E")
const DARKER_BG_COLOR = Color("#252526")
const DARKEST_BG_COLOR = Color("#0D0D0D")
const BUTTON_BG_COLOR = Color("#333333")
const BUTTON_ACTIVE_BG_COLOR = Color("#444444")
const BORDER_COLOR = Color("#555555")
const SELECTION_COLOR = Color("#00CC66")
const TEXT_COLOR = Color("#CCCCCC")
const CASH_COLOR = Color("#4DF75B")  # Bright green
const DEBT_COLOR = Color("#FF5555")  # Bright red
const GUNS_COLOR = Color("#F7F34D")  # Bright yellow
const HEALTH_COLOR = Color("#0066CC")  # Medium blue

func _ready():
	# Wait one frame to ensure all nodes are properly initialized
	await get_tree().process_frame
	
	# Add all buttons to the "buttons" group
	var all_buttons = []
	find_all_buttons(get_tree().root, all_buttons)
	for button in all_buttons:
		button.add_to_group("buttons")
	
	# Apply dark theme to the entire UI
	apply_dark_theme()

# Recursively find all buttons in the scene
func find_all_buttons(node, button_list):
	if node is Button:
		button_list.append(node)
	
	for child in node.get_children():
		find_all_buttons(child, button_list)

func apply_dark_theme():
	# Create the base theme
	var darktheme = Theme.new()
	
	# Set up default font
	var default_font = ThemeDB.fallback_font
	darktheme.set_default_font(default_font)
	darktheme.set_default_font_size(14)
	
	# Apply theme to the root control
	var root_control = get_parent()
	if root_control:
		root_control.theme = darktheme
	
	# Style each component
	style_panels()
	style_stats_panels()
	style_buttons()
	style_tables()
	style_progress_bars()
	
	# Update all UI elements with initial values
	update_ui()

func style_panels():
	# Main background panel
	var main_panel = get_node_or_null("/root/Control/MainContainer")
	if not main_panel:
		push_warning("Could not find MainContainer")
		return
		
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = DARK_BG_COLOR
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color.BLACK
	main_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Top section panel
	var top_section = get_node_or_null("/root/Control/MainContainer/TopSection")
	if top_section:
		var top_style = StyleBoxFlat.new()
		top_style.bg_color = DARK_BG_COLOR
		top_section.add_theme_stylebox_override("panel", top_style)
	
	# Bottom section panel
	var bottom_section = get_node_or_null("/root/Control/MainContainer/BottomSection")
	if bottom_section:
		var bottom_style = StyleBoxFlat.new()
		bottom_style.bg_color = DARK_BG_COLOR
		bottom_section.add_theme_stylebox_override("panel", bottom_style)
	
	# Location container
	var location_container = get_node_or_null("/root/Control/MainContainer/TopSection/LocationContainer")
	if location_container:
		var location_style = StyleBoxFlat.new()
		location_style.bg_color = DARKER_BG_COLOR
		location_style.set_border_width_all(1)
		location_style.border_color = BORDER_COLOR
		location_container.add_theme_stylebox_override("panel", location_style)
	
	# Apply text color to all labels
	var all_labels = []
	find_all_labels(get_tree().root, all_labels)
	for label in all_labels:
		label.add_theme_color_override("font_color", TEXT_COLOR)

# Recursively find all labels in the scene
func find_all_labels(node, label_list):
	if node is Label:
		label_list.append(node)
	
	for child in node.get_children():
		find_all_labels(child, label_list)

func style_stats_panels():
	# Apply styling to stats panels (Cash, Bank, Debt, Guns)
	style_stat_panel("/root/Control/MainContainer/TopSection/StatsContainer/CashRow", CASH_COLOR)
	style_stat_panel("/root/Control/MainContainer/TopSection/StatsContainer/BankRow", CASH_COLOR)
	style_stat_panel("/root/Control/MainContainer/TopSection/StatsContainer/DebtRow", DEBT_COLOR)
	style_stat_panel("/root/Control/MainContainer/TopSection/StatsContainer/GunsRow", GUNS_COLOR)

func style_stat_panel(node_path, text_color):
	var panel = get_node_or_null(node_path)
	if not panel:
		push_warning("Could not find node: " + node_path)
		return
	
	# Panel background
	var style = StyleBoxFlat.new()
	style.bg_color = DARKEST_BG_COLOR
	style.set_border_width_all(1)
	style.border_color = BORDER_COLOR
	panel.add_theme_stylebox_override("panel", style)
	
	# Find label and value children
	var label_node = null
	var value_node = null
	
	for child in panel.get_children():
		if "Label" in child.name:
			label_node = child
		elif "Value" in child.name:
			value_node = child
	
	# Apply styling to children
	if label_node:
		label_node.add_theme_color_override("font_color", text_color)
	
	if value_node:
		value_node.add_theme_color_override("font_color", text_color)

func style_buttons():
	# Get all buttons
	var buttons = get_tree().get_nodes_in_group("buttons")
	
	for button in buttons:
		var bg_color = BUTTON_BG_COLOR
		var hover_color = Color(BUTTON_BG_COLOR.r + 0.1, BUTTON_BG_COLOR.g + 0.1, BUTTON_BG_COLOR.b + 0.1)
		var pressed_color = BUTTON_ACTIVE_BG_COLOR
		var border_color = BORDER_COLOR
		var text_color = TEXT_COLOR
		
		# Special styling for Buy button (green)
		if button.name == "Buy":
			bg_color = Color("#2D882D")  # Darker green
			hover_color = Color("#3AA83A")  # Medium green
			pressed_color = Color("#4BC44B")  # Lighter green
			border_color = Color("#88FF88")  # Light green border
			text_color = Color.WHITE
		
		# Special styling for Sell button (red)
		elif button.name == "Sell":
			bg_color = Color("#AA2828")  # Darker red
			hover_color = Color("#CC3232")  # Medium red
			pressed_color = Color("#E03C3C")  # Lighter red
			border_color = Color("#FF8888")  # Light red border
			text_color = Color.WHITE
		
		# Default styling for other action buttons
		elif button.get_parent() and button.get_parent().name == "ActionButtons":
			bg_color = Color("#4D8A4D")  # Green for other action buttons
			hover_color = Color("#5AAD5A")
			pressed_color = Color("#75C675")
			border_color = Color("#88FF88")
			text_color = Color.WHITE
		
		# Normal state
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = bg_color
		normal_style.set_border_width_all(1)
		normal_style.border_color = border_color
		normal_style.set_corner_radius_all(3)  # Rounded corners for better appearance
		
		# Hover state
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = hover_color
		hover_style.set_border_width_all(1)
		hover_style.border_color = border_color
		hover_style.set_corner_radius_all(3)
		
		# Pressed state
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = pressed_color
		pressed_style.set_border_width_all(1)
		pressed_style.border_color = border_color
		pressed_style.set_corner_radius_all(3)
		
		# Focus state
		var focus_style = StyleBoxFlat.new()
		focus_style.bg_color = bg_color
		focus_style.set_border_width_all(2)
		focus_style.border_color = SELECTION_COLOR
		focus_style.set_corner_radius_all(3)
		
		# Apply styles
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_stylebox_override("focus", focus_style)
		
		# Text color
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		
		# Change cursor to pointing hand for all buttons
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func style_tables():
	# Style the market and inventory lists
	style_list("/root/Control/MainContainer/BottomSection/MarketContainer/MarketList")
	style_list("/root/Control/MainContainer/BottomSection/InventoryContainer/InventoryList")

func style_list(node_path):
	var list = get_node_or_null(node_path)
	
	# Check if the node exists before styling it
	if not list:
		push_warning("Could not find node: " + node_path)
		return
	
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = DARKER_BG_COLOR
	bg_style.set_border_width_all(1)
	bg_style.border_color = BORDER_COLOR
	
	# Selected item style
	var selected_style = StyleBoxFlat.new()
	selected_style.bg_color = SELECTION_COLOR
	selected_style.set_border_width_all(1)
	selected_style.border_color = BORDER_COLOR
	
	# Apply styles
	list.add_theme_stylebox_override("panel", bg_style)
	list.add_theme_stylebox_override("selected", selected_style)
	list.add_theme_color_override("font_color", TEXT_COLOR)
	list.add_theme_color_override("font_selected_color", Color.WHITE)
	
func style_progress_bars():
	# Style health bar
	var health_bar = get_node_or_null("/root/Control/MainContainer/TopSection/StatsContainer/HealthContainer/HealthRow/HealthBar")
	if not health_bar:
		push_warning("Could not find HealthBar")
		return
		
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = DARKER_BG_COLOR
	bg_style.set_border_width_all(1)
	bg_style.border_color = BORDER_COLOR
	
	# Fill style
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = HEALTH_COLOR
	fill_style.set_border_width_all(0)
	
	# Apply styles
	health_bar.add_theme_stylebox_override("background", bg_style)
	health_bar.add_theme_stylebox_override("fill", fill_style)

func update_ui():
	# Update all UI elements with current values
	# (This would connect to your game state)
	pass
