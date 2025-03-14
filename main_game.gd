extends Control

const CellphoneUI = preload("res://cellphone_ui.tscn")
var cellphone_instance

# Variables for loan shark
var loan_shark_dialog
var loan_amount_input
var loan_amount = 0
var payback_button
var borrow_button

# Handle load dialog file selection
func _on_load_dialog_file_selected(path):
	load_game_from_path(path)

# Load game from a specific path
func load_game_from_path(path):
	has_unsaved_changes = false
	if not FileAccess.file_exists(path):
		show_message("No save file found")
		print("No save file found at: " + path)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		show_message("Failed to open save file: " + str(FileAccess.get_open_error()))
		print("Failed to open save file: " + str(FileAccess.get_open_error()))
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		show_message("Failed to parse save data: " + json.get_error_message())
		print("Failed to parse save data: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return false
	
	var save_data = json.get_data()
	
	# Load player data with explicit integer conversion
	cash = int(save_data["player"]["cash"])
	bank = int(save_data["player"]["bank"])
	debt = int(save_data["player"]["debt"])
	guns = int(save_data["player"]["guns"])
	health = int(save_data["player"]["health"])
	current_capacity = int(save_data["player"]["current_capacity"])
	
	# Load location
	current_location = save_data["location"]
	location_label.text = "Currently In:  " + current_location
	
	# Load drug data with integer conversion
	for drug_name in save_data["drugs"]:
		if drugs.has(drug_name):
			drugs[drug_name]["price"] = int(save_data["drugs"][drug_name]["price"])
			drugs[drug_name]["qty"] = int(save_data["drugs"][drug_name]["qty"])
	
	# Update UI
	update_stats_display()
	update_market_display()
	update_inventory_display()
	
	show_message("Game loaded successfully from: " + path)
	print("Game loaded from: " + path)
	return true

func show_bank_dialog():
	# Check if the dialog exists
	if not is_instance_valid(bank_dialog):
		print("Bank dialog is not valid")
		setup_bank_dialog()  # Try to set it up again
		return
	
	# Get references to the labels
	var vbox = bank_dialog.get_child(0)
	if not is_instance_valid(vbox):
		print("VBox container not found in bank dialog")
		return
		
	var cash_display = vbox.get_node_or_null("Cash Display")
	var bank_display = vbox.get_node_or_null("Bank Display")
	
	# Update the displayed values, checking if labels exist
	if cash_display:
		cash_display.text = "Cash: $" + str(int(cash))
	else:
		print("Cash display label not found")
		
	if bank_display:
		bank_display.text = "Bank: $" + str(int(bank))
	else:
		print("Bank display label not found")
	bank_dialog.popup_centered()

func setup_bank_dialog():
	# Create dialog
	bank_dialog = PopupPanel.new()
	bank_dialog.title = "Bank Operations"
	add_child(bank_dialog)
	
	# Create container
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 200)
	bank_dialog.add_child(vbox)
	
	# Add label
	var label = Label.new()
	label.text = "Banking Operations"
	vbox.add_child(label)
	
	var cash_display = Label.new()
	cash_display.name = "Cash Display"
	cash_display.text = "Cash: $" + str(int(cash))
	vbox.add_child(cash_display)
	var bank_display = Label.new()
	bank_display.name = "Bank Display"
	bank_display.text = "Bank: $" + str(int(bank))
	vbox.add_child(bank_display)
	
	# Add amount input
	var input_container = HBoxContainer.new()
	vbox.add_child(input_container)
	
	var input_label = Label.new()
	input_label.text = "Amount: $"
	input_container.add_child(input_label)
	
	bank_amount_input = LineEdit.new()
	bank_amount_input.placeholder_text = "Enter amount"
	bank_amount_input.text = "100"  # Default amount
	bank_amount_input.size_flags_horizontal = SIZE_EXPAND_FILL
	input_container.add_child(bank_amount_input)
	
	# Connect the text changed signal
	bank_amount_input.text_changed.connect(func(new_text):
		if new_text.is_valid_int():
			bank_amount = int(new_text)
		else:
			bank_amount_input.text = str(bank_amount)
	)
	
	# Add buttons
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(button_container)
	
	deposit_button = Button.new()
	deposit_button.text = "Deposit"
	deposit_button.size_flags_horizontal = SIZE_EXPAND_FILL
	button_container.add_child(deposit_button)
	
	withdraw_button = Button.new()
	withdraw_button.text = "Withdraw"
	withdraw_button.size_flags_horizontal = SIZE_EXPAND_FILL
	button_container.add_child(withdraw_button)
	
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(close_button)
	
	# Connect buttons
	deposit_button.pressed.connect(func(): deposit_money())
	withdraw_button.pressed.connect(func(): withdraw_money())
	
	# Modify the close button connection to reopen the phone
	close_button.pressed.connect(func(): 
		bank_dialog.hide()
		# Reopen the phone
		if is_instance_valid(cellphone_instance):
			cellphone_instance.get_node("Popup").popup_centered()
	)

# Function to deposit money
func deposit_money():
	var amount = bank_amount
	
	# Check if the player has enough cash
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
		
	if amount > cash:
		show_message("You don't have enough cash")
		return
		
	# Transfer the money
	cash -= amount
	bank += amount
	
	# Update displays
	update_stats_display()
	show_message("Deposited $" + str(amount) + " to bank")
	
	# Update the dialog display
	bank_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	bank_dialog.get_child(0).get_node("Bank Display").text = "Bank: $" + str(int(bank))
	
	# Mark changes as unsaved
	has_unsaved_changes = true

# Function to withdraw money
func withdraw_money():
	var amount = bank_amount
	
	# Check if the bank has enough money
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
		
	if amount > bank:
		show_message("You don't have enough money in the bank")
		return
		
	# Transfer the money
	bank -= amount
	cash += amount
	
	# Update displays
	update_stats_display()
	show_message("Withdrew $" + str(amount) + " from bank")
	
	# Update the dialog display
	bank_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	bank_dialog.get_child(0).get_node("Bank Display").text = "Bank: $" + str(int(bank))
	
	# Mark changes as unsaved
	has_unsaved_changes = true

# Fixed function to add save/load buttons to the game
func quit_game():
	get_tree().quit()

# Player stats
var cash = 2000
var bank = 0
var debt = 5000
var guns = 0
var health = 100

# Inventory
var inventory = []
var trenchcoat_capacity = 100
var current_capacity = 0
var has_unsaved_changes = false

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
# Add these variables near your other market variables
var base_drug_prices = {
	"Cocaine": 16000,
	"Hashish": 600,
	"Heroin": 10000,
	"Ecstasy": 30,
	"Smack": 3000,
	"Opium": 550,
	"Crack": 2000,
	"Peyote": 480,
	"Shrooms": 800,
	"Speed": 140,
	"Weed": 650
}

# Location price modifiers (percentage adjustment)
var location_modifiers = {
	"Erie": {"Crack": 80, "Weed": 110, "Speed": 90},
	"York": {"Cocaine": 120, "Heroin": 110, "Ecstasy": 130},
	"Kensington": {"Hashish": 90, "Smack": 80, "Shrooms": 70},
	"Pittsburgh": {"Weed": 120, "Ecstasy": 80, "Peyote": 110},
	"Love Park": {"Shrooms": 120, "Peyote": 130, "Weed": 90},
	"Reading": {"Crack": 70, "Smack": 85, "Speed": 120}
}

# Market events (rare price spikes or crashes)
var market_events = [
	{"name": "Police Bust", "drug": "", "message": "Police busted a major supplier! DRUG_NAME prices are soaring!", "effect": 250},
	{"name": "New Shipment", "drug": "", "message": "A new shipment of DRUG_NAME has flooded the market. Prices are crashing!", "effect": 40},
	{"name": "Gang War", "drug": "", "message": "A gang war has disrupted the DRUG_NAME trade. Prices are up!", "effect": 180},
	{"name": "Lab Raid", "drug": "", "message": "DEA raided several DRUG_NAME labs. Prices are up!", "effect": 200},
	{"name": "Addicts Dying", "drug": "", "message": "Too many DRUG_NAME users are dying. Demand is down!", "effect": 60},
	{"name": "Celebrity Overdose", "drug": "", "message": "A celebrity OD'd on DRUG_NAME. The drug is trending!", "effect": 150}
]

# Current location
var current_location = ""

# Add these variables to your existing variables
var save_file_path = "user://dope_wars_save.json"
var auto_save = true  # Set to true to save automatically when quitting

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

# Add these variables to your existing variables
var save_dialog
var load_dialog

#Bank Variables
var bank_dialog
var deposit_button
var withdraw_button
var bank_amount_input
var bank_amount = 0

# UI References
@onready var cash_label = $MainContainer/TopSection/StatsContainer/CashRow/CashValue
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
	
	# First, set up UI elements and systems to ensure they're ready
	setup_message_system()
	setup_quantity_dialog()
	setup_file_dialogs()
	setup_bank_dialog()  # Add this line to set up the bank dialog
	setup_loan_shark_dialog()  # Add this line
	# In your _ready() function
	
	if has_node("MainContainer/BottomSection/ActionButtons/GridContainer/BankButton"):
		$MainContainer/BottomSection/ActionButtons/GridContainer/BankButton.pressed.connect(show_bank_dialog)
		print("Bank button connected")
	else:
		print("Bank button not found in scene tree")

	# Connect New Game button
	if has_node("MainContainer/BottomSection/GameButtons/Spacer/NewGameButton"):
		$MainContainer/BottomSection/GameButtons/Spacer/NewGameButton.pressed.connect(start_new_game)
		print("New Game button connected")
	else:
		print("New Game button not found in scene tree")
		
	# Connect save/load buttons
	if has_node("MainContainer/BottomSection/GameButtons/Spacer/SaveGameButton"):
		$MainContainer/BottomSection/GameButtons/Spacer/SaveGameButton.pressed.connect(save_game)
		print("Save button connected")
	else:
		print("Save button not found in scene tree")
	
	if has_node("MainContainer/BottomSection/GameButtons/Spacer/LoadGameButton"):
		$MainContainer/BottomSection/GameButtons/Spacer/LoadGameButton.pressed.connect(load_game)
		print("Load button connected")
	else:
		print("Load button not found in scene tree")

	# Initialize UI display 
	update_stats_display()
	
	# Initialize the lists with proper sizing
	initialize_lists()
	
	# Connect location button signals
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Erie.pressed.connect(func(): change_location("Erie"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/York.pressed.connect(func(): change_location("York"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Kensington.pressed.connect(func(): change_location("Kensington"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Pittsburgh.pressed.connect(func(): change_location("Pittsburgh"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/LovePark.pressed.connect(func(): change_location("Love Park"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Reading.pressed.connect(func(): change_location("Reading"))
	
	# Connect action buttons
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.pressed.connect(buy_drugs)
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.pressed.connect(sell_drugs)
	
	# Connect list signals
	market_list.item_selected_full.connect(_on_market_item_selected)
	inventory_list.item_selected_full.connect(_on_inventory_item_selected)
	
	# Initially disable buy/sell buttons until selection is made
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.disabled = true
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.disabled = true
	
	# Start with empty market until a location is selected
	market_list.clear()
	
	# Try to load the game on startup
	print("Attempting to auto-load game from: " + save_file_path)
	var loaded = load_game()
	
	if not loaded:
		# If no save file, start a new game
		print("No save file found or load failed, starting new game")
		new_game()
	else:
		print("Game auto-loaded successfully")
# Connect CellphoneButton in your _ready() function
	setup_cellphone()
	
	# Connect CellphoneButton
	if has_node("MainContainer/BottomSection/ActionButtons/GridContainer/CellphoneButton"):
		$MainContainer/BottomSection/ActionButtons/GridContainer/CellphoneButton.pressed.connect(func(): show_cellphone())
		print("Cellphone button connected")
	else:
		print("Cellphone button not found in scene tree")

func show_cellphone():
	# This ensures the cellphone only appears when you click the button
	if cellphone_instance:
		cellphone_instance.get_node("Popup").popup_centered()

func _process(delta):
	# Handle message timeout
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_label.visible = false

func update_stats_display():
	# Convert all values to integers before displaying
	cash_label.text = str(int(cash))
	debt_label.text = str(int(debt))
	guns_label.text = str(int(guns))
	health_progress.value = int(health)

func update_market_display():
	market_list.clear()
	
	# Safety check: only show drugs if a location is selected
	if current_location.is_empty():
		print("No location selected yet, not displaying market")
		return
	
	# Update prices based on location
	randomize_prices()
	
	# Set up columns for the market display
	market_list.set_columns(["Drug", "Price"], [0.6, 0.4])
	
	# Add items to the market list
	print("Adding " + str(drugs.size()) + " drugs to market in " + current_location)
	for drug_name in drugs:
		print("Adding to market: " + drug_name + " - $" + str(drugs[drug_name]["price"]))
		market_list.add_item([drug_name, "$" + str(drugs[drug_name]["price"])])
	
	# Reset buy button state
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.disabled = true

func update_inventory_display():
	inventory_list.clear()
	
	# Set up columns for the inventory display - removed price column
	inventory_list.set_columns(["Drug", "Qty"], [0.7, 0.3])
	
	for drug_name in drugs:
		if drugs[drug_name]["qty"] > 0:
			# Convert quantity to integer and display as string
			var qty_int = int(drugs[drug_name]["qty"])
			
			# Only show drug name and quantity in inventory
			inventory_list.add_item([
				drug_name, 
				str(qty_int)  # This ensures an integer display
			])
	
	# Update capacity display with integer values
	capacity_label.text = "Trenchcoat Space: " + str(int(current_capacity)) + "/" + str(int(trenchcoat_capacity))
	
	# Reset sell button state
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.disabled = true

# Improved price randomization function
func randomize_prices():
	# 10% chance of a market event
	var event_chance = randf()
	var event_triggered = false
	
	if event_chance < 0.1:
		# Trigger a random market event
		var event = market_events[randi() % market_events.size()]
		
		# Select a random drug for this event
		var all_drugs = drugs.keys()
		var random_drug = all_drugs[randi() % all_drugs.size()]
		event["drug"] = random_drug
		
		# Apply the effect
		var base_price = base_drug_prices[random_drug]
		var new_price = int(base_price * (event["effect"] / 100.0))
		drugs[random_drug]["price"] = new_price
		
		# Show event message
		var message = event["message"].replace("DRUG_NAME", random_drug)
		show_message(message)
		
		event_triggered = true
	
	# Normal price fluctuations for all drugs
	for drug_name in drugs:
		# Skip drug if it was affected by an event
		if event_triggered and drug_name == market_events[0]["drug"]:
			continue
			
		# Start with the base price
		var base_price = base_drug_prices[drug_name]
		
		# Apply location modifiers if any exist for this drug in this location
		var location_modifier = 100
		if location_modifiers.has(current_location) and location_modifiers[current_location].has(drug_name):
			location_modifier = location_modifiers[current_location][drug_name]
		
		# Calculate adjusted base price
		var adjusted_base = int(base_price * (location_modifier / 100.0))
		
		# Apply random fluctuation (80% to 120% of the adjusted base price)
		var fluctuation = randf_range(0.8, 1.2)
		drugs[drug_name]["price"] = int(adjusted_base * fluctuation)
	
	# Debug info
	print("Updated drug prices in " + current_location)
	for drug_name in drugs:
		print(drug_name + ": $" + str(drugs[drug_name]["price"]))

func change_location(location):
	# Update current location
	current_location = location
	location_label.text = "Currently In: " + location
	
	# Update prices when changing location
	update_market_display()
	
	# Reset both button states
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.disabled = true
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.disabled = true
	
	# Mark that we have unsaved changes
	has_unsaved_changes = true
	
	# Show a simple notification in the middle of the screen
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
	var max_affordable = int(cash / price)
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

# Add this function to initialize base prices when starting a new game
func initialize_drug_prices():
	for drug_name in drugs:
		if base_drug_prices.has(drug_name):
			drugs[drug_name]["price"] = base_drug_prices[drug_name]
			drugs[drug_name]["qty"] = 0
	
	# Apply initial randomization
	randomize_prices()

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
	quantity_slider.max_value = 10000
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

# Update buy_drugs to mark changes 
func confirm_quantity():
	var quantity = int(quantity_slider.value)
	
	if is_buying:
		# Buy the drugs
		var total_cost = int(current_price * quantity)
		cash -= total_cost
		drugs[current_drug]["qty"] += quantity
		current_capacity += quantity
		show_message("Bought " + str(quantity) + " " + current_drug + " for $" + str(total_cost))
	else:
		# Sell the drugs
		var total_revenue = int(current_price * quantity)
		cash += total_revenue
		drugs[current_drug]["qty"] -= quantity
		current_capacity -= quantity
		show_message("Sold " + str(quantity) + " " + current_drug + " for $" + str(total_revenue))
	
	# Make sure all values are integers
	drugs[current_drug]["qty"] = int(drugs[current_drug]["qty"])
	current_capacity = int(current_capacity)
	cash = int(cash)
	
	# Mark that we have unsaved changes
	has_unsaved_changes = true
	
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
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.disabled = false
	print("Selected from market: " + drug_name + " at $" + str(price))

# Update the _on_inventory_item_selected function to match the new format
func _on_inventory_item_selected(drug_name, quantity, _unused):
	# Note: the signal parameters have changed since we now have only 2 columns
	# The _unused parameter is there to maintain compatibility with the signal signature
	
	# Enable the sell button when an inventory item is selected
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.disabled = false
	print("Selected from inventory: " + drug_name + " qty: " + str(quantity))

func new_game():
	# Reset game state with explicit integer values
	cash = 2000
	bank = 0
	debt = 5000  # Starting with debt as in your original variables
	guns = 0
	health = 100
	has_unsaved_changes = false

	# Reset inventory
	for drug_name in drugs:
		drugs[drug_name]["qty"] = 0
	
	# Initialize drugs with base prices
	initialize_drug_prices()
	
	# Reset capacity
	current_capacity = 0
	
	# Set starting location
	current_location = "Kensington"
	location_label.text = "Currently In:  " + current_location
	
	# Show welcome message
	show_message("Welcome to " + current_location)

	# Update all UI displays
	update_stats_display()
	update_market_display()
	update_inventory_display()
	
	show_message("New game started!")

# Then add this new method for handling the new game button press:
func start_new_game():
	# Show confirmation dialog before starting a new game
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Are you sure you want to start a new game? All unsaved progress will be lost."
	confirmation.title = "Start New Game"
	add_child(confirmation)
	
	# Connect the confirmed signal
	confirmation.confirmed.connect(func():
		# Call your existing new_game() function
		new_game()
	)
	
	# Show the dialog
	confirmation.popup_centered()

# Called when the game is about to close
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if auto_save:
			save_game()
		get_tree().quit()

# Save game data to a file
func save_game():
	save_dialog.popup_centered(Vector2(800, 600))
	var save_data = {
		"player": {
			"cash": cash,
			"bank": bank,
			"debt": debt,
			"guns": guns,
			"health": health,
			"current_capacity": current_capacity
		},
		"location": current_location,
		"drugs": {}
	}
	
	# Save drug data
	for drug_name in drugs:
		save_data["drugs"][drug_name] = {
			"price": drugs[drug_name]["price"],
			"qty": drugs[drug_name]["qty"]
		}
	
	# Create a file and save the data
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		show_message("Game saved successfully")
		print("Game saved to: " + save_file_path)
	else:
		show_message("Failed to save game: " + str(FileAccess.get_open_error()))
		print("Failed to save game: " + str(FileAccess.get_open_error()))

# Load game data from file
func load_game():
	# Check if being called from UI button (manual load)
	if not get_tree().paused:
		# For manual loads, show the dialog and return
		load_dialog.popup_centered(Vector2(800, 600))
		return false

	# For auto-loading, check if the save file exists
	if not FileAccess.file_exists(save_file_path):
		print("No save file found at: " + save_file_path)
		return false
	
	# Try to load the game from the default path
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		print("Failed to open save file: " + str(FileAccess.get_open_error()))
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		print("Failed to parse save data: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return false
	
	var save_data = json.get_data()
	
	# Load player data with explicit integer conversion
	cash = int(save_data["player"]["cash"])
	bank = int(save_data["player"]["bank"])
	debt = int(save_data["player"]["debt"])
	guns = int(save_data["player"]["guns"])
	health = int(save_data["player"]["health"])
	current_capacity = int(save_data["player"]["current_capacity"])
	
	# Load location
	current_location = save_data["location"]
	location_label.text = "Currently In: " + current_location
	
	# Load drug data with integer conversion
	for drug_name in save_data["drugs"]:
		if drugs.has(drug_name):
			drugs[drug_name]["price"] = int(save_data["drugs"][drug_name]["price"])
			drugs[drug_name]["qty"] = int(save_data["drugs"][drug_name]["qty"])
	
	# Mark as saved (no unsaved changes)
	has_unsaved_changes = false
	
	# Update UI
	update_stats_display()
	update_market_display()
	update_inventory_display()
	
	# Only show message if message system is initialized
	if message_label and is_instance_valid(message_label):
		show_message("Game loaded successfully")
	
	print("Game loaded from: " + save_file_path)
	return true
	
# Add this function to set up the file dialogs
func setup_file_dialogs():
	# Create save dialog
	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.filters = ["*.json ; JSON Files"]
	save_dialog.title = "Save Game"
	save_dialog.current_path = "user://dope_wars_save.json"
	add_child(save_dialog)
	
	# Connect save dialog signals
	save_dialog.file_selected.connect(_on_save_dialog_file_selected)
	
	# Create load dialog
	load_dialog = FileDialog.new()
	load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_dialog.access = FileDialog.ACCESS_FILESYSTEM
	load_dialog.filters = ["*.json ; JSON Files"]
	load_dialog.title = "Load Game"
	load_dialog.current_path = "user://dope_wars_save.json"
	add_child(load_dialog)
	
	# Connect load dialog signals
	load_dialog.file_selected.connect(_on_load_dialog_file_selected)

# Handle save dialog file selection
func _on_save_dialog_file_selected(path):
	var save_data = {
		"player": {
			"cash": cash,
			"bank": bank,
			"debt": debt,
			"guns": guns,
			"health": health,
			"current_capacity": current_capacity
		},
		"location": current_location,
		"drugs": {}
	}

	has_unsaved_changes = false

	# Save drug data
	for drug_name in drugs:
		save_data["drugs"][drug_name] = {
			"price": drugs[drug_name]["price"],
			"qty": drugs[drug_name]["qty"]
		}
	
	# Create a file and save the data
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		show_message("Game saved successfully to: " + path)
		print("Game saved to: " + path)
	else:
		show_message("Failed to save game: " + str(FileAccess.get_open_error()))
		print("Failed to save game: " + str(FileAccess.get_open_error()))

func show_gun_dealer():
	var gun_price = 1000
	var message = "Guns available: Standard pistol\n"
	message += "Price: $" + str(gun_price) + "\n"
	
	if cash >= gun_price:
		message += "You have enough cash to buy a gun."
	else:
		message += "You need $" + str(gun_price - cash) + " more to buy a gun."
		
	cellphone_instance.update_message(message)  # Use this instead of update_phone_message
	show_message("Gun Dealer: 'I've got what you need.'")

func show_police_info():
	var message = "Police activity in different locations:\n"
	message += "- High: York, Pittsburgh\n"
	message += "- Medium: Erie, Kensington\n"
	message += "- Low: Love Park, Reading\n"
	message += "\nCurrent location: " + current_location
	
	cellphone_instance.update_message(message)  # Use this instead of update_phone_message
	show_message("Police are active in " + current_location)

func show_market_tips():
	var drugs_list = drugs.keys()
	var random_drug = drugs_list[randi() % drugs_list.size()]
	var best_location = ""
	var highest_modifier = 0
	
	# Find location with highest price modifier for the random drug
	for location in location_modifiers:
		if location_modifiers[location].has(random_drug):
			var modifier = location_modifiers[location][random_drug]
			if modifier > highest_modifier:
				highest_modifier = modifier
				best_location = location
	
	var message = "Market Tips:\n"
	if best_location != "":
		message += random_drug + " prices are high in " + best_location + "\n"
	else:
		message += random_drug + " prices are standard everywhere\n"
	
	# Add a second random tip
	var random_drug2 = drugs_list[randi() % drugs_list.size()]
	while random_drug2 == random_drug:
		random_drug2 = drugs_list[randi() % drugs_list.size()]
	
	message += "\nAlso check out " + random_drug2 + " in " + current_location
	
	cellphone_instance.update_message(message)  # Use this instead of update_phone_message
	show_message("Tip: Check your phone for market information")

func setup_cellphone():
	# Create an instance of the phone UI
	cellphone_instance = CellphoneUI.instantiate()
	add_child(cellphone_instance)

	# Make sure it's initially hidden
	cellphone_instance.hide()

	# Connect the contact_selected signal
	cellphone_instance.contact_selected.connect(_on_cellphone_contact_selected)

func _on_cellphone_contact_selected(contact_name):
	match contact_name:
		"Loan Shark":
			show_loan_shark()
		"Gun Dealer":
			show_gun_dealer()
		"Police Info":
			show_police_info()
		"Market Tips":
			show_market_tips()
		"Soulioli Banking":
			# Hide the phone first
			cellphone_instance.get_node("Popup").hide()
			# Then show the banking dialog
			show_bank_dialog()


#Loan Shark
func setup_loan_shark_dialog():
	# Create dialog
	loan_shark_dialog = PopupPanel.new()
	loan_shark_dialog.title = "Loan Shark"
	add_child(loan_shark_dialog)
	
	# Create container
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 200)
	loan_shark_dialog.add_child(vbox)
	
	# Add label
	var title_label = Label.new()
	title_label.text = "Loan Shark Operations"
	vbox.add_child(title_label)
	
	# Add debt display
	var debt_display = Label.new()
	debt_display.name = "Debt Display"
	debt_display.text = "Current Debt: $" + str(int(debt))
	vbox.add_child(debt_display)
	
	# Add interest rate display
	var interest_display = Label.new()
	interest_display.name = "Interest Display"
	interest_display.text = "Interest Rate: 10%"
	vbox.add_child(interest_display)
	
	# Add cash display
	var cash_display = Label.new()
	cash_display.name = "Cash Display"
	cash_display.text = "Cash: $" + str(int(cash))
	vbox.add_child(cash_display)
	
	# Add amount input
	var input_container = HBoxContainer.new()
	vbox.add_child(input_container)
	
	var input_label = Label.new()
	input_label.text = "Amount: $"
	input_container.add_child(input_label)
	
	loan_amount_input = LineEdit.new()
	loan_amount_input.placeholder_text = "Enter amount"
	loan_amount_input.text = "100"  # Default amount
	loan_amount_input.size_flags_horizontal = SIZE_EXPAND_FILL
	input_container.add_child(loan_amount_input)
	
	# Connect the text changed signal
	loan_amount_input.text_changed.connect(func(new_text):
		if new_text.is_valid_int():
			loan_amount = int(new_text)
		else:
			loan_amount_input.text = str(loan_amount)
	)
	
	# Add buttons
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(button_container)
	
	payback_button = Button.new()
	payback_button.text = "Pay Debt"
	payback_button.size_flags_horizontal = SIZE_EXPAND_FILL
	button_container.add_child(payback_button)
	
	borrow_button = Button.new()
	borrow_button.text = "Borrow"
	borrow_button.size_flags_horizontal = SIZE_EXPAND_FILL
	button_container.add_child(borrow_button)
	
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(close_button)
	
	# Connect buttons
	payback_button.pressed.connect(func(): pay_debt())
	borrow_button.pressed.connect(func(): borrow_money())
	
	# Modify the close button connection to reopen the phone
	close_button.pressed.connect(func(): 
		loan_shark_dialog.hide()
		# Reopen the phone
		if is_instance_valid(cellphone_instance):
			cellphone_instance.get_node("Popup").popup_centered()
	)

func pay_debt():
	var amount = loan_amount
	
	# Check if the player has enough cash
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
		
	if amount > cash:
		show_message("You don't have enough cash")
		return
		
	if amount > debt:
		show_message("You're trying to pay more than you owe")
		return
		
	# Transfer the money
	cash -= amount
	debt -= amount
	
	# Update displays
	update_stats_display()
	show_message("Paid $" + str(amount) + " to Loan Shark")
	
	# Update the dialog display
	loan_shark_dialog.get_child(0).get_node("Debt Display").text = "Current Debt: $" + str(int(debt))
	loan_shark_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	
	# Mark changes as unsaved
	has_unsaved_changes = true

func borrow_money():
	var amount = loan_amount
	
	# Validations
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
	
	# Optional: Add a maximum borrowing limit
	var max_borrow = 10000
	if amount > max_borrow:
		show_message("Loan Shark won't lend more than $" + str(max_borrow) + " at once")
		return
	
	# Add the borrowed amount to cash and debt
	cash += amount
	debt += amount
	
	# Update displays
	update_stats_display()
	show_message("Borrowed $" + str(amount) + " from Loan Shark")
	
	# Update the dialog display
	loan_shark_dialog.get_child(0).get_node("Debt Display").text = "Current Debt: $" + str(int(debt))
	loan_shark_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	
	# Mark changes as unsaved
	has_unsaved_changes = true

func show_loan_shark():
	# Check if the dialog exists
	if not is_instance_valid(loan_shark_dialog):
		print("Loan shark dialog is not valid")
		setup_loan_shark_dialog()  # Set it up if it doesn't exist
	
	# Update the displayed values
	var vbox = loan_shark_dialog.get_child(0)
	if vbox:
		var debt_display = vbox.get_node_or_null("Debt Display")
		var cash_display = vbox.get_node_or_null("Cash Display")
		
		if debt_display:
			debt_display.text = "Current Debt: $" + str(int(debt))
		else:
			print("Debt display label not found")
			
		if cash_display:
			cash_display.text = "Cash: $" + str(int(cash))
		else:
			print("Cash display label not found")
	
	# Hide the phone first
	cellphone_instance.get_node("Popup").hide()
	
	# Show the loan shark dialog
	loan_shark_dialog.popup_centered()
