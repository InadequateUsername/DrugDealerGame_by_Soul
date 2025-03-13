extends Node

# Dictionary of possible events for each location
var location_events = {
	"Bronx": [
		{
			"text": "You spot a nervous junkie looking to score. He seems desperate.",
			"options": [
				{"text": "Sell at premium", "outcome": "cash_gain", "value": 200},
				{"text": "Ignore him", "outcome": "reputation_loss", "value": 5}
			]
		},
		{
			"text": "A police patrol car slowly drives by. The officers give you a suspicious look.",
			"options": [
				{"text": "Act casual", "outcome": "nothing", "value": 0},
				{"text": "Run away", "outcome": "heat_gain", "value": 10}
			]
		},
		{
			"text": "You notice a rival dealer watching you from across the street.",
			"options": [
				{"text": "Confront them", "outcome": "reputation_gain", "value": 15},
				{"text": "Find another spot", "outcome": "time_loss", "value": 1}
			]
		}
	],
	"Manhattan": [
		{
			"text": "A wealthy businessman discreetly asks if you have any 'party favors'.",
			"options": [
				{"text": "Hook him up", "outcome": "cash_gain", "value": 350},
				{"text": "Too risky", "outcome": "nothing", "value": 0}
			]
		},
		{
			"text": "You spot an unmarked police car nearby.",
			"options": [
				{"text": "Blend with the crowd", "outcome": "nothing", "value": 0},
				{"text": "Leave the area", "outcome": "time_loss", "value": 1}
			]
		}
	],
	"Kensington": [
		{
			"text": "An addict approaches you with stolen electronics to trade.",
			"options": [
				{"text": "Make the trade", "outcome": "inventory_gain", "value": 5},
				{"text": "Cash only", "outcome": "reputation_loss", "value": 3}
			]
		},
		{
			"text": "A group of local gang members approaches you.",
			"options": [
				{"text": "Pay protection money", "outcome": "cash_loss", "value": 100},
				{"text": "Stand your ground", "outcome": "health_loss", "value": 15}
			]
		},
		{
			"text": "You find a small package hidden in an alley.",
			"options": [
				{"text": "Take it", "outcome": "inventory_gain", "value": 5},
				{"text": "Leave it alone", "outcome": "nothing", "value": 0}
			]
		}
	],
	"Coney Island": [
		{
			"text": "Some teenagers at the beach ask if you're selling.",
			"options": [
				{"text": "Sell to them", "outcome": "cash_gain_heat_gain", "value": [150, 15]},
				{"text": "Tell them to get lost", "outcome": "nothing", "value": 0}
			]
		},
		{
			"text": "You spot an opportunity to set up a new distribution network.",
			"options": [
				{"text": "Invest time", "outcome": "connection_gain", "value": 1},
				{"text": "Focus on quick sales", "outcome": "cash_gain", "value": 100}
			]
		}
	],
	"Central Park": [
		{
			"text": "A concert is happening today. The crowd could be good for business.",
			"options": [
				{"text": "Blend in and sell", "outcome": "cash_gain_heat_risk", "value": [300, 20]},
				{"text": "Too many cops around", "outcome": "nothing", "value": 0}
			]
		},
		{
			"text": "You see someone who looks like an undercover cop.",
			"options": [
				{"text": "Leave immediately", "outcome": "time_loss", "value": 2},
				{"text": "Keep a low profile", "outcome": "heat_risk", "value": 25}
			]
		}
	],
	"Brooklyn": [
		{
			"text": "A local bartender offers to help move product through his establishment.",
			"options": [
				{"text": "Set up the arrangement", "outcome": "connection_gain", "value": 2},
				{"text": "Too risky", "outcome": "nothing", "value": 0}
			]
		},
		{
			"text": "Some of your product got wet and damaged in the rain.",
			"options": [
				{"text": "Sell it anyway", "outcome": "cash_gain_reputation_loss", "value": [100, 10]},
				{"text": "Dispose of it", "outcome": "inventory_loss", "value": 3}
			]
		}
	]
}

# Probability (0-100) that an event will trigger when traveling
@export var event_chance = 40

# Reference to the event dialog UI (will be created in _ready)
var event_dialog
var event_text_label
var options_container
var current_event

func _ready():
	# Create the dialog UI programmatically
	create_event_dialog()

func create_event_dialog():
	# Create the popup panel
	event_dialog = PopupPanel.new()
	event_dialog.size = Vector2(400, 250)
	add_child(event_dialog)
	
	# Create the main container
	var main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.position = Vector2(4, 4)
	# Fix Vector2 subtraction
	var container_size_x = event_dialog.size.x - 8
	var container_size_y = event_dialog.size.y - 8
	main_container.size = Vector2(container_size_x, container_size_y)
	event_dialog.add_child(main_container)
	
	# Create the event text label
	event_text_label = Label.new()
	event_text_label.text = "Event text will appear here"
	event_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_text_label.custom_minimum_size = Vector2(0, 100)
	event_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_container.add_child(event_text_label)
	
	# Add a separator
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# Create the options container
	options_container = VBoxContainer.new()
	options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_container.custom_minimum_size = Vector2(0, 130)
	options_container.add_theme_constant_override("separation", 10)
	main_container.add_child(options_container)

# Function to check if an event should happen
func check_for_event(location):
	# Random chance to trigger an event
	if randf() * 100 < event_chance and location in location_events:
		# Pick a random event from the location's event list
		var events = location_events[location]
		var event = events[randi() % events.size()]
		
		# Store the current event for reference when an option is selected
		current_event = event
		
		# Show the event dialog
		show_event_dialog(event)
		return true
	return false

# Function to display the event dialog
func show_event_dialog(event):
	# Update event text
	event_text_label.text = event.text
	
	# Clear previous option buttons
	for child in options_container.get_children():
		child.queue_free()
	
	# Add option buttons
	for option in event.options:
		var button = Button.new()
		button.text = option.text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_option_selected.bind(option))
		options_container.add_child(button)
	
	# Show the dialog
	event_dialog.popup_centered()

# Function called when an option is selected
func _on_option_selected(option):
	# Close the dialog
	event_dialog.hide()
	
	# Apply the outcome based on the option selected
	match option.outcome:
		"cash_gain":
			get_parent().add_cash(option.value)
			get_parent().show_notification("You gained $" + str(option.value))
		"cash_loss":
			get_parent().add_cash(-option.value)
			get_parent().show_notification("You lost $" + str(option.value))
		"health_loss":
			get_parent().add_health(-option.value)
			get_parent().show_notification("You lost " + str(option.value) + " health")
		"reputation_gain":
			get_parent().add_reputation(option.value)
			get_parent().show_notification("Your street rep increased")
		"reputation_loss":
			get_parent().add_reputation(-option.value)
			get_parent().show_notification("Your street rep decreased")
		"heat_gain":
			get_parent().add_heat(option.value)
			get_parent().show_notification("Police heat increased")
		"inventory_gain":
			get_parent().add_inventory(option.value)
			get_parent().show_notification("You gained some product")
		"inventory_loss":
			get_parent().add_inventory(-option.value)
			get_parent().show_notification("You lost some product")
		"time_loss":
			get_parent().add_time(option.value)
			get_parent().show_notification("You wasted some time")
		"connection_gain":
			get_parent().add_connection(option.value)
			get_parent().show_notification("You made a new connection")
		"cash_gain_heat_gain":
			get_parent().add_cash(option.value[0])
			get_parent().add_heat(option.value[1])
			get_parent().show_notification("You gained $" + str(option.value[0]) + " but heat increased")
		"cash_gain_reputation_loss":
			get_parent().add_cash(option.value[0])
			get_parent().add_reputation(-option.value[1])
			get_parent().show_notification("You gained $" + str(option.value[0]) + " but lost reputation")
		"cash_gain_heat_risk":
			get_parent().add_cash(option.value[0])
			if randf() < 0.5:
				get_parent().add_heat(option.value[1])
				get_parent().show_notification("You gained $" + str(option.value[0]) + " but got noticed by the cops")
			else:
				get_parent().show_notification("You gained $" + str(option.value[0]))
		"heat_risk":
			if randf() < 0.5:
				get_parent().add_heat(option.value)
				get_parent().show_notification("A cop noticed your activities")
			else:
				get_parent().show_notification("You remained undetected")
		"nothing":
			get_parent().show_notification("Nothing happened")
