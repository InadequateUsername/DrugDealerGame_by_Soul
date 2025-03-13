extends Control

signal contact_selected(contact_name)

# Expose variables for easier access
@onready var message_label = $Popup/TextureRect/Control/VBoxContainer/MessageLabel

func _ready():
	# Connect the close button
	$Popup/TextureRect/Control/Button.pressed.connect(func(): hide())
	
	# Connect all the contact buttons
	$Popup/TextureRect/Control/VBoxContainer/LoanSharkButton.pressed.connect(
		func(): emit_signal("contact_selected", "Loan Shark"))
	
	$Popup/TextureRect/Control/VBoxContainer/GunDealerButton.pressed.connect(
		func(): emit_signal("contact_selected", "Gun Dealer"))
	
	$Popup/TextureRect/Control/VBoxContainer/PoliceInfoButton.pressed.connect(
		func(): emit_signal("contact_selected", "Police Info"))
	
	$Popup/TextureRect/Control/VBoxContainer/MarketTipsButton.pressed.connect(
		func(): emit_signal("contact_selected", "Market Tips"))

# Function to update the message text
func update_message(text):
	message_label.text = text
