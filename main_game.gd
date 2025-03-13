extends Control

# Player stats
var cash = 2000
var bank = 0
var debt = 5500
var guns = 0
var health = 100
var reputation = 50 # Added for event system
var heat = 0 # Added for event system - police attention

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
@onready var event_system = $EventSystem # Reference to the EventSystem node

func _ready():
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Check if the node exists before connecting
	if has_node("MainContainer/TopSection/ActionButtons/FinancesButton"):
		$MainContainer/TopSection/ActionButtons/FinancesButton.pressed.connect(show_finances)
		$MainContainer/BottomSection/GameButtons/Spacer/NewGameButton.pressed.connect(new_game)
		$MainContainer/BottomSection/GameButtons/Spacer/ExitButton.pressed.connect(quit_game)
	else:
		print("FinancesButton not found! Full path:", get_path_to(get_node("MainContainer/TopSection/ActionButtons")))

	# Initialize UI
	update_stats_display()
	update_market_display()
	update_inventory_display()
	
	# Connect button signals
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Bronx.pressed.connect(func(): change_location("Bronx"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Manhattan.pressed.connect(func(): change_location("Manhattan"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Kensington.pressed.connect(func(): change_location("Kensington"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/ConeyIsland.pressed.connect(func(): change_location("Coney Island"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/CentralPark.pressed.connect(func(): change_location("Central Park"))
	$MainContainer/TopSection/StatsContainer/LocationContainer/LocationButtons/Brooklyn.pressed.connect(func(): change_location("Brooklyn"))
	
	$MainContainer/TopSection/ActionButtons/BuyButton.pressed.connect(buy_drugs)
	$MainContainer/TopSection/ActionButtons/SellButton.pressed.connect(sell_drugs)

func update_stats_display():
	cash_label.text = str(cash)
	bank_label.text = str(bank)
	debt_label.text = str(debt)
	guns_label.text = str(guns)
	health_progress.value = health

func update_market_display():
	if market_list:
		market_list.clear()
	else:
		print("Warning: MarketList not found!")
	# Update prices based on location (this would be more complex in your game)
	randomize_prices()
	
	# Add items to the market list
	for drug_name in drugs:
		market_list.add_item(drug_name + " - $" + str(drugs[drug_name]["price"]))

func update_inventory_display():
	if inventory_list:
		inventory_list.clear()
	else:
		print("Warning: InventoryList not found!")
	
	# Rest of your function...
	inventory_list.clear()
	
	for drug_name in drugs:
		if drugs[drug_name]["qty"] > 0:
			inventory_list.add_item(drug_name + " - " + str(drugs[drug_name]["qty"]) + " - $" + str(drugs[drug_name]["price"]))
	
	# Update capacity display
	capacity_label.text = "Trenchcoat Space: " + str(current_capacity) + "/" + str(trenchcoat_capacity)

func randomize_prices():
	# Simple price randomization - you'd want more complex logic in your game
	for drug_name in drugs:
		var base_price = drugs[drug_name]["price"]
		drugs[drug_name]["price"] = int(base_price * randf_range(0.8, 1.2))

func change_location(location):
	var previous_location = current_location
	current_location = location
	location_label.text = location # Changed to just show the location name
	update_market_display()
	
	# Check for random events when changing location
	if previous_location != location: # Only check for events if actually changing locations
		$EventSystem.check_for_event(location)

# Functions needed by the event system

func buy_drugs():
	# Implement buying logic
	pass

func sell_drugs():
	# Implement selling logic
	pass

func show_finances():
	# Show finances dialog
	pass

func new_game():
	# Reset game state
	cash = 2000
	bank = 0
	debt = 5500
	guns = 0
	health = 100
	reputation = 50
	heat = 0
	
	for drug_name in drugs:
		drugs[drug_name]["qty"] = 0
	
	current_capacity = 0
	current_location = "Kensington"
	
	update_stats_display()
	update_market_display()
	update_inventory_display()

func quit_game():
	get_tree().quit()

# === Event System Integration Functions ===

# These functions will be called by the event system when events occur
func add_cash(amount):
	cash += amount
	update_stats_display()
	
func add_health(amount):
	health = clamp(health + amount, 0, 100)
	update_stats_display()

func add_reputation(amount):
	reputation = clamp(reputation + amount, 0, 100)
	# If you have a reputation display, update it here
	
func add_heat(amount):
	heat = clamp(heat + amount, 0, 100)
	# If you have a heat display, update it here
	
func add_inventory(amount):
	# This is simplified - you might want to add a specific drug
	current_capacity = clamp(current_capacity + amount, 0, trenchcoat_capacity)
	update_inventory_display()
	
func add_time(_hours):
	# If you have a time system, implement it here
	pass
	
func add_connection(_amount):
	# If you have a connections/network system, implement it here
	pass
func show_notification(text):
	# Create a notification label
	var notification_label = Label.new()
	notification_label.text = text
	notification_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.2)) # Yellow text
	notification_label.position = Vector2(50, 50)
	add_child.call_deferred(notification_label)
	
	# Create a timer to remove the notification
	var timer = Timer.new()
	timer.wait_time = 2.5
	timer.one_shot = true
	timer.timeout.connect(func(): notification_label.queue_free())
	notification_label.add_child(timer)
	timer.autostart = true
