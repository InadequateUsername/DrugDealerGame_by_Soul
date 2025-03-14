extends Control

signal contact_selected(contact_name)

# Expose variables for easier access
@onready var message_label = $Popup/TextureRect/Control/VBoxContainer/MessageLabel

func _ready():
	$Popup.hide()  # Hide the popup specifically
	# Connect the close button
	$Popup/TextureRect/Control/Button.pressed.connect(func(): _on_close_button_pressed())
	
	# Connect all the contact buttons
	$Popup/TextureRect/Control/VBoxContainer/LoanSharkButton.pressed.connect(
		func(): emit_signal("contact_selected", "Loan Shark"))
	
	$Popup/TextureRect/Control/VBoxContainer/GunDealerButton.pressed.connect(
		func(): emit_signal("contact_selected", "Gun Dealer"))
	
	$Popup/TextureRect/Control/VBoxContainer/PoliceInfoButton.pressed.connect(
		func(): emit_signal("contact_selected", "Police Info"))
	
	$Popup/TextureRect/Control/VBoxContainer/MarketTipsButton.pressed.connect(
		func(): emit_signal("contact_selected", "Market Tips"))
		
	$Popup/TextureRect/Control/VBoxContainer/BankButton.pressed.connect(
		func(): emit_signal("contact_selected", "Soulioli Banking"))

# Function to update the message text
func update_message(text):
	message_label.text = text

func _on_close_button_pressed():
	print("Close button pressed")  # Debug print
	$Popup.hide()  # Hide the popup specifically
