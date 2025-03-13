extends Control

# Player stats
var cash = 2000
var bank = 0
var debt = 5500
var guns = 0
var health = 100

# Inventory
var inventory = []
var trenchcoat_capacity = 100
var current_capacity = 0

# Market prices
var drugs = {
	"Cocaine": {"price": 16388, "qty": 0},
	"Hashish": {"price": 604, "qty": 0},
	"Heroin": {"price": 10016, "qty": 0},
	"Ecstasy": {"price": 28, "qty": 0},
	"Smack": {"price": 2929, "qty": 0},
	"Opium": {"price": 542, "qty": 0},
	"Crack": {"price": 1941, "qty": 0},
	"Peyote": {"price": 476, "qty": 0},
	"Shrooms": {"price": 824, "qty": 0},
	"Speed": {"price": 135, "qty": 0},
	"Weed": {"price": 657, "qty": 0}
}

# Current location
var current_location = "Kensington"

# Variables for quantity dialog
var quantity_dialog
var quantity_slider
var confirm_button
var cancel_button
var current_drug
var current_price
var is_buying = false

# Message system
var message_label
var message_timer = 0
var message_duration = 3.0  # How long messages stay on screen

# UI References
@onready var cash_label = $MainContainer/TopSection/StatsContainer/CashRow/CashValue
@onready var bank_label = $MainContainer/TopSection/StatsContainer/BankRow/BankValue
@onready var debt_label = $MainContainer/TopSection/StatsContainer/DebtRow/DebtValue
@onready var guns_label = $MainContainer/TopSection/StatsContainer/GunsRow/GunsValue
@onready var health_progress = $MainContainer/TopSection/StatsContainer/HealthContainer/HealthRow/HealthBar
@onready var market_list = $MainContainer/BottomSection/MarketContainer/MarketList
@onready var inventory_list = $MainContainer/BottomSection/InventoryContainer/InventoryList
@onready var location_label = $MainContainer/TopSection/StatsContainer/LocationContainer/LocationLabel
@onready var capacity_label = $MainContainer/BottomSection/InventoryContainer/CapacityLabel

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Check if the node exists before connecting
	if has_node("MainContainer/BottomSection/ActionButtons/FinancesButton"):
		$MainContainer/BottomSection/ActionButtons/FinancesButton.pressed.connect(show_finances)
		$MainContainer/BottomSection/GameButtons/Spacer/NewGameButton.pressed.connect(new_game)
		$MainContainer/BottomSection/GameButtons/Spacer/ExitButton.pressed.connect(quit_game)
	else:
		print("FinancesButton not found! Full path:", get_path_to(get_node("MainContainer/BottomSection/ActionButtons")))

	# Initialize UI
	update_stats_display()
	update_market_display()
	update_inventory_display()
		# Initialize the lists with proper sizing
	initialize_lists()
	
	# Add a check to print the actual dimensions and key data
	print("Market list size after init: ", market_list.size)
	print("Market list row count: ", market_list.rows.size())
	# Connect button signals
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Bronx.pressed.connect(func(): change_location("Bronx"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Manhattan.pressed.connect(func(): change_location("Manhattan"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Kensington.pressed.connect(func(): change_location("Kensington"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/ConeyIsland.pressed.connect(func(): change_location("Coney Island"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/CentralPark.pressed.connect(func(): change_location("Central Park"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Brooklyn.pressed.connect(func(): change_location("Brooklyn"))
	
	$MainContainer/BottomSection/ActionButtons/BuyButton.pressed.connect(buy_drugs)
	$MainContainer/BottomSection/ActionButtons/SellButton.pressed.connect(sell_drugs)
	
	# Connect list signals
	market_list.item_selected.connect(_on_market_item_selected)
	inventory_list.item_selected.connect(_on_inventory_item_selected)
	
	# Initially disable buy/sell buttons until selection is made
	$MainContainer/BottomSection/ActionButtons/BuyButton.disabled = true
	$MainContainer/BottomSection/ActionButtons/SellButton.disabled = true
	
	# Setup additional UI elements
	setup_quantity_dialog()
	setup_message_system()

func _process(delta):
	# Handle message timeout
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_label.visible = false

func update_stats_display():
	cash_label.text = str(cash)
	bank_label.text = str(bank)
	debt_label.text = str(debt)
	guns_label.text = str(guns)
	health_progress.value = health

func update_market_display():
	market_list.clear()
	
	# Update prices based on location
	randomize_prices()
	
	# Set up columns for the market display
	market_list.set_columns(["Drug", "Price"], [0.6, 0.4])
	
	# Add items to the market list with debug info
	print("Adding " + str(drugs.size()) + " drugs to market in " + current_location)
	for drug_name in drugs:
		print("Adding to market: " + drug_name + " - $" + str(drugs[drug_name]["price"]))
		market_list.add_item([drug_name, "$" + str(drugs[drug_name]["price"])])
	
	# Reset buy button state
	$MainContainer/BottomSection/ActionButtons/BuyButton.disabled = true
	$MainContainer/BottomSection/ActionButtons/BuyButton.disabled = true

func update_inventory_display():
	inventory_list.clear()
	
	# Set up columns for the inventory display - removed price column
	inventory_list.set_columns(["Drug", "Qty"], [0.7, 0.3])
	
	for drug_name in drugs:
		if drugs[drug_name]["qty"] > 0:
			# Only show drug name and quantity in inventory
			inventory_list.add_item([
				drug_name, 
				str(drugs[drug_name]["qty"])
			])
	
	# Update capacity display
	capacity_label.text = "Trenchcoat Space: " + str(current_capacity) + "/" + str(trenchcoat_capacity)
	
	# Reset sell button state
	$MainContainer/BottomSection/ActionButtons/SellButton.disabled = true

func randomize_prices():
	# Simple price randomization - you'd want more complex logic in your game
	for drug_name in drugs:
		var base_price = drugs[drug_name]["price"]
		drugs[drug_name]["price"] = int(base_price * randf_range(0.8, 1.2))

func change_location(location):
	current_location = location
	location_label.text = "Currently In:  " + location
	
	# Update prices when changing location
	update_market_display()
	
	# Reset both button states
	$MainContainer/BottomSection/ActionButtons/BuyButton.disabled = true
	$MainContainer/BottomSection/ActionButtons/SellButton.disabled = true
	
	# Show location change message
	show_message("You've arrived in " + location)

func buy_drugs():
	# Get selected drug from market list
	var selected_idx = market_list.selected_index
	if selected_idx == -1:
		show_message("No drug selected to buy")
		return
		
	# Extract drug name and price from the selected item
	var selected_item = market_list.rows[selected_idx]
	if not selected_item is Array or selected_item.size() < 2:
		show_message("Invalid selection format")
		return
		
	var drug_name = selected_item[0]
	var price_str = selected_item[1]
	var price = int(price_str.substr(1))  # Remove the $ character
	
	# Calculate maximum amount the player can buy
	var max_affordable = floor(cash / price)
	var max_by_space = floor((trenchcoat_capacity - current_capacity))
	var max_qty = min(max_affordable, max_by_space)
	
	if max_qty <= 0:
		# Can't afford any or no space
		if max_affordable <= 0:
			show_message("You can't afford any " + drug_name)
		else:
			show_message("You don't have enough space in your trenchcoat")
		return
	
	# Show quantity dialog
	show_quantity_dialog(drug_name, price, max_qty, true)

# Update the sell_drugs function to work with the new inventory format
func sell_drugs():
	# Get selected drug from inventory list
	var selected_idx = inventory_list.selected_index
	if selected_idx == -1:
		show_message("No drug selected to sell")
		return
		
	# Extract drug name and quantity from the selected item (now just 2 columns)
	var selected_item = inventory_list.rows[selected_idx]
	if not selected_item is Array or selected_item.size() < 2:
		show_message("Invalid selection format")
		return
		
	var drug_name = selected_item[0]
	var quantity = int(selected_item[1])
	
	# Get the current market price directly from the drugs dictionary
	var price = drugs[drug_name]["price"]
	
	if quantity <= 0:
		show_message("You don't have any " + drug_name + " to sell")
		return
	
	# Show quantity dialog for selling
	show_quantity_dialog(drug_name, price, quantity, false)

# This function should be called in _ready() to ensure lists are properly initialized
func initialize_lists():
	# Ensure the lists have sufficient size
	$MainContainer/BottomSection/MarketContainer/MarketList.custom_minimum_size = Vector2(0, 200)
	$MainContainer/BottomSection/InventoryContainer/InventoryList.custom_minimum_size = Vector2(0, 200)
	
	# Wait a frame for layout
	await get_tree().process_frame
	
	# Force the lists to take up available space in their containers
	var market_container = $MainContainer/BottomSection/MarketContainer
	var inventory_container = $MainContainer/BottomSection/InventoryContainer
	
	market_list.size = Vector2(market_container.size.x, 200)
	inventory_list.size = Vector2(inventory_container.size.x, 200)
	
	# Initial market display
	update_market_display()
	update_inventory_display()
	
	# For debugging
	print("Market list initialized with size: ", market_list.size)
	print("Inventory list initialized with size: ", inventory_list.size)

func setup_quantity_dialog():
	# Create dialog
	quantity_dialog = PopupPanel.new()
	quantity_dialog.title = "Select Quantity"
	add_child(quantity_dialog)
	
	# Create container
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 150)
	quantity_dialog.add_child(vbox)
	
	# Add label
	var label = Label.new()
	label.text = "Select Quantity:"
	vbox.add_child(label)
	
	# Add slider
	quantity_slider = HSlider.new()
	quantity_slider.min_value = 1
	quantity_slider.max_value = 100
	quantity_slider.step = 1
	quantity_slider.value = 1
	vbox.add_child(quantity_slider)
	
	# Add quantity display
	var qty_display = Label.new()
	qty_display.text = "Quantity: 1"
	vbox.add_child(qty_display)
	
	# Add total display
	var total_display = Label.new()
	total_display.text = "Total: $0"
	vbox.add_child(total_display)
	
	# Update displays when slider changes
	quantity_slider.value_changed.connect(func(value): 
		qty_display.text = "Quantity: " + str(int(value))
		total_display.text = "Total: $" + str(int(value) * current_price)
	)
	
	# Add buttons
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	hbox.add_child(cancel_button)
	
	confirm_button = Button.new()
	confirm_button.text = "Confirm"
	hbox.add_child(confirm_button)
	
	# Connect buttons
	cancel_button.pressed.connect(func(): quantity_dialog.hide())
	confirm_button.pressed.connect(func(): confirm_quantity())

func show_quantity_dialog(drug_name, price, max_qty, buying=true):
	current_drug = drug_name
	current_price = price
	is_buying = buying
	
	# Set slider range
	quantity_slider.max_value = max_qty
	quantity_slider.value = 1
	
	# Update title
	if buying:
		quantity_dialog.title = "Buy " + drug_name
	else:
		quantity_dialog.title = "Sell " + drug_name
	
	# Show dialog
	quantity_dialog.popup_centered()

func confirm_quantity():
	var quantity = int(quantity_slider.value)
	
	if is_buying:
		# Buy the drugs
		var total_cost = current_price * quantity
		cash -= total_cost
		drugs[current_drug]["qty"] += quantity
		current_capacity += quantity
		show_message("Bought " + str(quantity) + " " + current_drug + " for $" + str(total_cost))
	else:
		# Sell the drugs
		var total_revenue = current_price * quantity  # Using current_price which is now the market price
		cash += total_revenue
		drugs[current_drug]["qty"] -= quantity
		current_capacity -= quantity
		show_message("Sold " + str(quantity) + " " + current_drug + " for $" + str(total_revenue))
	
	# Update UI
	update_stats_display()
	update_inventory_display()
	
	# Hide dialog
	quantity_dialog.hide()
	
func setup_message_system():
	# Create message label
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.custom_minimum_size = Vector2(400, 50)
	message_label.visible = false
	add_child(message_label)
	
	# Position at bottom center of screen
	message_label.anchor_bottom = 1.0
	message_label.anchor_right = 1.0
	message_label.anchor_left = 0.0
	message_label.offset_bottom = -20
	
	# Style label
	message_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Create background panel
	var panel = Panel.new()
	message_label.add_child(panel)
	panel.show_behind_parent = true
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Style panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.set_border_width_all(1)
	style.border_color = Color(1, 1, 1, 0.2)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)

func show_message(text, duration = 3.0):
	message_label.text = text
	message_label.visible = true
	message_timer = duration

func _on_market_item_selected(drug_name, price, _quantity):
	# Enable the buy button when a market item is selected
	$MainContainer/BottomSection/ActionButtons/BuyButton.disabled = false
	print("Selected from market: " + drug_name + " at $" + str(price))

# Update the _on_inventory_item_selected function to match the new format
func _on_inventory_item_selected(drug_name, quantity, _unused):
	# Note: the signal parameters have changed since we now have only 2 columns
	# The _unused parameter is there to maintain compatibility with the signal signature
	
	# Enable the sell button when an inventory item is selected
	$MainContainer/BottomSection/ActionButtons/SellButton.disabled = false
	print("Selected from inventory: " + drug_name + " qty: " + str(quantity))
	
func show_finances():
	# Placeholder for finances dialog
	show_message("Finances dialog would show here")

func new_game():
	# Reset game state
	cash = 2000
	bank = 0
	debt = 5500
	guns = 0
	health = 100
	
	for drug_name in drugs:
		drugs[drug_name]["qty"] = 0
	
	current_capacity = 0
	current_location = "Kensington"
	
	update_stats_display()
	update_market_display()
	update_inventory_display()
	
	show_message("New game started!")

func quit_game():
	get_tree().quit()
