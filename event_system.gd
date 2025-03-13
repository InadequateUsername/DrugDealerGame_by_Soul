# Add this to your main game script or create a dedicated location manager

extends Node

# Current location
var current_location = "Bronx"

# Reference to the event system
@onready var event_system = $EventSystem

# UI elements
@onready var location_label = $LocationLabel
@onready var location_buttons = {

	"Bronx": $LocationButtons/BronxButton,
	"Manhattan": $LocationButtons/ManhattanButton,
	"Kensington": $LocationButtons/KensingtonButton,
	"Coney Island": $LocationButtons/ConeyIslandButton,
	"Central Park": $LocationButtons/CentralParkButton,
	"Brooklyn": $LocationButtons/BrooklynButton
}

func _ready():
	# Connect buttons
	for location in location_buttons:
		location_buttons[location].connect("pressed", self, "travel_to_location", [location])
	
	# Set initial location
	update_location_display()

# Function to handle traveling to a new location
func travel_to_location(location):
	if location == current_location:
		return
		
	# Update current location
	current_location = location
	
	# Update UI
	update_location_display()
	
	# Check for random event
	event_system.check_for_event(location)
	
	# Other location-specific changes (market prices, etc.)
	update_market_prices()

# Update the location display
func update_location_display():
	# Just show the location name, not "Subway from X"
	location_label.text = current_location

# Function to update market prices based on location
func update_market_prices():
	# Your implementation to adjust drug prices based on location
	pass

# Add functions for game stats modification (these will be called by the event system)
func add_cash(amount):
	# Update cash value
	var current_cash = int($StatsContainer/CashRow/CashValue.text)
	$StatsContainer/CashRow/CashValue.text = str(current_cash + amount)

func add_health(amount):
	# Update health value (clamped between 0 and 100)
	var current_health = int($HealthContainer/HealthBar.value)
	$HealthContainer/HealthBar.value = clamp(current_health + amount, 0, 100)

func add_heat(amount):
	# Update police heat value
	# Implement based on your game's heat system
	pass

func add_reputation(amount):
	# Update reputation value
	# Implement based on your game's reputation system
	pass

func add_inventory(amount):
	# Update inventory
	# Implement based on your game's inventory system
	pass

func add_time(hours):
	# Update game time
	# Implement based on your game's time system
	pass

func add_connection(amount):
	# Update connections/network
	# Implement based on your game's connection system
	pass
