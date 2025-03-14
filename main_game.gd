extends Control

const CellphoneUI = preload("res://cellphone_ui.tscn")
var cellphone_instance

# Variables for loan shark
var loan_shark_dialog
var loan_amount_input
var loan_amount = 0
var payback_button
var borrow_button

# Bank variables
var bank_dialog
var deposit_button
var withdraw_button
var bank_amount_input
var bank_amount = 0

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
# Base drug prices for price calculations
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

# Save/load variables
var save_file_path = "user://dope_wars_save.json"
var auto_save = true
var save_dialog
var load_dialog

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
	
	# Set up UI elements and systems
	setup_message_system()
	setup_quantity_dialog()
	setup_file_dialogs()
	setup_bank_dialog()
	setup_loan_shark_dialog()
	setup_cellphone()
	
	# Connect bank button
	if has_node("MainContainer/BottomSection/ActionButtons/GridContainer/BankButton"):
		$MainContainer/BottomSection/ActionButtons/GridContainer/BankButton.pressed.connect(show_bank_dialog)
	
	# Connect game buttons
	if has_node("MainContainer/BottomSection/GameButtons/Spacer/NewGameButton"):
		$MainContainer/BottomSection/GameButtons/Spacer/NewGameButton.pressed.connect(start_new_game)
	
	if has_node("MainContainer/BottomSection/GameButtons/Spacer/SaveGameButton"):
		$MainContainer/BottomSection/GameButtons/Spacer/SaveGameButton.pressed.connect(save_game)
	
	if has_node("MainContainer/BottomSection/GameButtons/Spacer/LoadGameButton"):
		$MainContainer/BottomSection/GameButtons/Spacer/LoadGameButton.pressed.connect(load_game)

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
	
	# Connect CellphoneButton
	if has_node("MainContainer/BottomSection/ActionButtons/GridContainer/CellphoneButton"):
		$MainContainer/BottomSection/ActionButtons/GridContainer/CellphoneButton.pressed.connect(func(): show_cellphone())
	
	# Connect list signals
	market_list.item_selected_full.connect(_on_market_item_selected)
	inventory_list.item_selected_full.connect(_on_inventory_item_selected)
	
	# Initially disable buy/sell buttons until selection is made
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.disabled = true
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.disabled = true
	
	# Try to load the game on startup
	var loaded = load_game()
	
	if not loaded:
		# If no save file, start a new game
		new_game()

func _process(delta):
	# Handle message timeout
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_label.visible = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if auto_save:
			save_game()
		get_tree().quit()

# Handle load dialog file selection
func _on_load_dialog_file_selected(path):
	load_game_from_path(path)
























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

# Market/Location functions
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

# Price randomization function
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

# Buying/Selling functions
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

func sell_drugs():
	# Get selected drug from inventory list
	var selected_idx = inventory_list.selected_index
	if selected_idx == -1:
		show_message("No drug selected to sell")
		return
		
	# Extract drug name and quantity from the selected item
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

# Event handling functions
func _on_market_item_selected(drug_name, price, _quantity):
	# Enable the buy button when a market item is selected
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.disabled = false
	print("Selected from market: " + drug_name + " at $" + str(price))

func _on_inventory_item_selected(drug_name, quantity, _unused):
	# Enable the sell button when an inventory item is selected
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.disabled = false
	print("Selected from inventory: " + drug_name + " qty: " + str(quantity))


# Load game from a specific path
func load_game_from_path(path):
	has_unsaved_changes = false
	if not FileAccess.file_exists(path):
		show_message("No save file found")
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		show_message("Failed to open save file: " + str(FileAccess.get_open_error()))
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		show_message("Failed to parse save data: " + json.get_error_message())
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
	return true

# Bank Functions
func setup_bank_dialog():
	bank_dialog = PopupPanel.new()
	bank_dialog.title = "Bank Operations"
	add_child(bank_dialog)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 200)
	bank_dialog.add_child(vbox)
	
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
	
	bank_amount_input.text_changed.connect(func(new_text):
		if new_text.is_valid_int():
			bank_amount = int(new_text)
		else:
			bank_amount_input.text = str(bank_amount)
	)
	
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
	
	deposit_button.pressed.connect(func(): deposit_money())
	withdraw_button.pressed.connect(func(): withdraw_money())
	
	close_button.pressed.connect(func(): 
		bank_dialog.hide()
		if is_instance_valid(cellphone_instance):
			cellphone_instance.get_node("Popup").popup_centered()
	)

func show_bank_dialog():
	if not is_instance_valid(bank_dialog):
		setup_bank_dialog()
		return
	
	var vbox = bank_dialog.get_child(0)
	if not is_instance_valid(vbox):
		return
		
	var cash_display = vbox.get_node_or_null("Cash Display")
	var bank_display = vbox.get_node_or_null("Bank Display")
	
	if cash_display:
		cash_display.text = "Cash: $" + str(int(cash))
		
	if bank_display:
		bank_display.text = "Bank: $" + str(int(bank))
		
	bank_dialog.popup_centered()

func deposit_money():
	var amount = bank_amount
	
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
		
	if amount > cash:
		show_message("You don't have enough cash")
		return
		
	cash -= amount
	bank += amount
	
	update_stats_display()
	show_message("Deposited $" + str(amount) + " to bank")
	
	bank_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	bank_dialog.get_child(0).get_node("Bank Display").text = "Bank: $" + str(int(bank))
	
	has_unsaved_changes = true

func withdraw_money():
	var amount = bank_amount
	
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
		
	if amount > bank:
		show_message("You don't have enough money in the bank")
		return
		
	bank -= amount
	cash += amount
	
	update_stats_display()
	show_message("Withdrew $" + str(amount) + " from bank")
	
	bank_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	bank_dialog.get_child(0).get_node("Bank Display").text = "Bank: $" + str(int(bank))
	
	has_unsaved_changes = true

# Loan Shark Functions
func setup_loan_shark_dialog():
	loan_shark_dialog = PopupPanel.new()
	loan_shark_dialog.title = "Loan Shark"
	add_child(loan_shark_dialog)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 200)
	loan_shark_dialog.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "Loan Shark Operations"
	vbox.add_child(title_label)
	
	var debt_display = Label.new()
	debt_display.name = "Debt Display"
	debt_display.text = "Current Debt: $" + str(int(debt))
	vbox.add_child(debt_display)
	
	var interest_display = Label.new()
	interest_display.name = "Interest Display"
	interest_display.text = "Interest Rate: 10%"
	vbox.add_child(interest_display)
	
	var cash_display = Label.new()
	cash_display.name = "Cash Display"
	cash_display.text = "Cash: $" + str(int(cash))
	vbox.add_child(cash_display)
	
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
	
	loan_amount_input.text_changed.connect(func(new_text):
		if new_text.is_valid_int():
			loan_amount = int(new_text)
		else:
			loan_amount_input.text = str(loan_amount)
	)
	
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
	
	payback_button.pressed.connect(func(): pay_debt())
	borrow_button.pressed.connect(func(): borrow_money())
	
	close_button.pressed.connect(func(): 
		loan_shark_dialog.hide()
		if is_instance_valid(cellphone_instance):
			cellphone_instance.get_node("Popup").popup_centered()
	)

func show_loan_shark():
	if not is_instance_valid(loan_shark_dialog):
		setup_loan_shark_dialog()
	
	var vbox = loan_shark_dialog.get_child(0)
	if vbox:
		var debt_display = vbox.get_node_or_null("Debt Display")
		var cash_display = vbox.get_node_or_null("Cash Display")
		
		if debt_display:
			debt_display.text = "Current Debt: $" + str(int(debt))
			
		if cash_display:
			cash_display.text = "Cash: $" + str(int(cash))
	
	cellphone_instance.get_node("Popup").hide()
	loan_shark_dialog.popup_centered()

func pay_debt():
	var amount = loan_amount
	
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
		
	if amount > cash:
		show_message("You don't have enough cash")
		return
		
	if amount > debt:
		show_message("You're trying to pay more than you owe")
		return
		
	cash -= amount
	debt -= amount
	
	update_stats_display()
	show_message("Paid $" + str(amount) + " to Loan Shark")
	
	loan_shark_dialog.get_child(0).get_node("Debt Display").text = "Current Debt: $" + str(int(debt))
	loan_shark_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	
	has_unsaved_changes = true

func borrow_money():
	var amount = loan_amount
	
	if amount <= 0:
		show_message("Amount must be greater than 0")
		return
	
	var max_borrow = 10000
	if amount > max_borrow:
		show_message("Loan Shark won't lend more than $" + str(max_borrow) + " at once")
		return
	
	cash += amount
	debt += amount
	
	update_stats_display()
	show_message("Borrowed $" + str(amount) + " from Loan Shark")
	
	loan_shark_dialog.get_child(0).get_node("Debt Display").text = "Current Debt: $" + str(int(debt))
	loan_shark_dialog.get_child(0).get_node("Cash Display").text = "Cash: $" + str(int(cash))
	
	has_unsaved_changes = true

# Cellphone Functions
func setup_cellphone():
	cellphone_instance = CellphoneUI.instantiate()
	add_child(cellphone_instance)
	cellphone_instance.hide()
	cellphone_instance.contact_selected.connect(_on_cellphone_contact_selected)

func show_cellphone():
	if cellphone_instance:
		cellphone_instance.get_node("Popup").popup_centered()

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
			cellphone_instance.get_node("Popup").hide()
			show_bank_dialog()

func show_gun_dealer():
	var gun_price = 1000
	var message = "Guns available: Standard pistol\n"
	message += "Price: $" + str(gun_price) + "\n"
	
	if cash >= gun_price:
		message += "You have enough cash to buy a gun."
	else:
		message += "You need $" + str(gun_price - cash) + " more to buy a gun."
		
	cellphone_instance.update_message(message)
	show_message("Gun Dealer: 'I've got what you need.'")

func show_police_info():
	var message = "Police activity in different locations:\n"
	message += "- High: York, Pittsburgh\n"
	message += "- Medium: Erie, Kensington\n"
	message += "- Low: Love Park, Reading\n"
	message += "\nCurrent location: " + current_location
	
	cellphone_instance.update_message(message)
	show_message("Police are active in " + current_location)

func show_market_tips():
	var drugs_list = drugs.keys()
	var random_drug = drugs_list[randi() % drugs_list.size()]
	var best_location = ""
	var highest_modifier = 0
	
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
	
	var random_drug2 = drugs_list[randi() % drugs_list.size()]
	while random_drug2 == random_drug:
		random_drug2 = drugs_list[randi() % drugs_list.size()]
	
	message += "\nAlso check out " + random_drug2 + " in " + current_location
	
	cellphone_instance.update_message(message)
	show_message("Tip: Check your phone for market information")

# UI Functions
func setup_message_system():
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.custom_minimum_size = Vector2(400, 50)
	message_label.visible = false
	add_child(message_label)
	
	message_label.anchor_bottom = 1.0
	message_label.anchor_right = 1.0
	message_label.anchor_left = 0.0
	message_label.offset_bottom = -20
	
	message_label.add_theme_color_override("font_color", Color.WHITE)
	
	var panel = Panel.new()
	message_label.add_child(panel)
	panel.show_behind_parent = true
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
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

func update_stats_display():
	cash_label.text = str(int(cash))
	debt_label.text = str(int(debt))
	guns_label.text = str(int(guns))
	health_progress.value = int(health)

func update_market_display():
	market_list.clear()
	
	if current_location.is_empty():
		return
	
	randomize_prices()
	
	market_list.set_columns(["Drug", "Price"], [0.6, 0.4])
	
	for drug_name in drugs:
		market_list.add_item([drug_name, "$" + str(drugs[drug_name]["price"])])
	
	$MainContainer/BottomSection/ActionButtons/GridContainer/BuyButton.disabled = true

func update_inventory_display():
	inventory_list.clear()
	
	inventory_list.set_columns(["Drug", "Qty"], [0.7, 0.3])
	
	for drug_name in drugs:
		if drugs[drug_name]["qty"] > 0:
			var qty_int = int(drugs[drug_name]["qty"])
			inventory_list.add_item([drug_name, str(qty_int)])
	
	capacity_label.text = "Trenchcoat Space: " + str(int(current_capacity)) + "/" + str(int(trenchcoat_capacity))
	
	$MainContainer/BottomSection/ActionButtons/GridContainer/SellButton.disabled = true

# Initial game setup and lists
func initialize_lists():
	$MainContainer/BottomSection/MarketContainer/MarketList.custom_minimum_size = Vector2(0, 200)
	$MainContainer/BottomSection/InventoryContainer/InventoryList.custom_minimum_size = Vector2(0, 200)
	
	await get_tree().process_frame
	
	var market_container = $MainContainer/BottomSection/MarketContainer
	var inventory_container = $MainContainer/BottomSection/InventoryContainer
	
	market_list.size = Vector2(market_container.size.x, 200)
	inventory_list.size = Vector2(inventory_container.size.x, 200)
	
	update_market_display()
	update_inventory_display()

func initialize_drug_prices():
	for drug_name in drugs:
		if base_drug_prices.has(drug_name):
			drugs[drug_name]["price"] = base_drug_prices[drug_name]
			drugs[drug_name]["qty"] = 0
	
	randomize_prices()

# Game state functions
func new_game():
	cash = 2000
	bank = 0
	debt = 5000
	guns = 0
	health = 100
	has_unsaved_changes = false

	for drug_name in drugs:
		drugs[drug_name]["qty"] = 0
	
	initialize_drug_prices()
	
	current_capacity = 0
	
	current_location = "Kensington"
	location_label.text = "Currently In:  " + current_location
	
	show_message("Welcome to " + current_location)

	update_stats_display()
	update_market_display()
	update_inventory_display()
	
	show_message("New game started!")

func start_new_game():
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Are you sure you want to start a new game? All unsaved progress will be lost."
	confirmation.title = "Start New Game"
	add_child(confirmation)
	
	confirmation.confirmed.connect(func():
		new_game()
	)
	
	confirmation.popup_centered()

# Save/Load functions
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
	
	for drug_name in drugs:
		save_data["drugs"][drug_name] = {
			"price": drugs[drug_name]["price"],
			"qty": drugs[drug_name]["qty"]
		}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		show_message("Game saved successfully")
	else:
		show_message("Failed to save game: " + str(FileAccess.get_open_error()))

func load_game():
	if not get_tree().paused:
		load_dialog.popup_centered(Vector2(800, 600))
		return false

	if not FileAccess.file_exists(save_file_path):
		return false
	
	return load_game_from_path(save_file_path)

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

	for drug_name in drugs:
		save_data["drugs"][drug_name] = {
			"price": drugs[drug_name]["price"],
			"qty": drugs[drug_name]["qty"]
		}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		show_message("Game saved successfully to: " + path)
	else:
		show_message("Failed to save game: " + str(FileAccess.get_open_error()))

func setup_file_dialogs():
	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.filters = ["*.json ; JSON Files"]
	save_dialog.title = "Save Game"
	save_dialog.current_path = "user://dope_wars_save.json"
	add_child(save_dialog)
	
	save_dialog.file_selected.connect(_on_save_dialog_file_selected)
	
	load_dialog = FileDialog.new()
	load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_dialog.access = FileDialog.ACCESS_FILESYSTEM
	load_dialog.filters = ["*.json ; JSON Files"]
	load_dialog.title = "Load Game"
	load_dialog.current_path = "user://dope_wars_save.json"
	add_child(load_dialog)
	
	load_dialog.file_selected.connect(_on_load_dialog_file_selected)
