extends Control

@export_range(1, 100, 1) var initial_money: float = 1

var entered_market_with: float
var entered_market_at: float = -1 # Negative means you're not in the market

var money: float:
	get:
		return money
	set(value):
		money = value
		$HBoxContainer/VBoxContainer/Money/Label.text = "$ %06.2f" % snappedf(money, 0.01)

func _ready() -> void:
	money = initial_money
	$HBoxContainer/VBoxContainer/Title/Label.text = ""
	$HBoxContainer/VBoxContainer/Text/Label.text = ""

func _process(_delta: float) -> void:
	var value_at_cursor = $HBoxContainer/Chart.value_at_cursor
	$HBoxContainer/VBoxContainer/Market/Label.text = "%06.2f" % snappedf(value_at_cursor, 0.01)
	if $HBoxContainer/Chart.is_cursor_activated:
		if entered_market_at < 0:
			entered_market_with = money
			entered_market_at = value_at_cursor
	else:
		entered_market_at = -1
	
	if entered_market_at > 0:
		var ratio = value_at_cursor / entered_market_at
		money = entered_market_with * ratio
		


func _on_chart_next_event(title: String, text: String) -> void:
	print("Hello World")
	$HBoxContainer/VBoxContainer/Title/Label.text = title
	$HBoxContainer/VBoxContainer/Text/Label.text = text
