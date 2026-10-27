extends Area2D

class_name Card
enum {SPADE, HEART, CLUB, DIAMOND}


var locked = false
var mouse_over = false
var frozen = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_card(suit, value):
	var index = suit*13+value-1;
	$Sprite.frame = index;

func set_card_index(index):
	$Sprite.frame = index;
func get_suit():
	return $Sprite.frame/13
func get_value():
	return $Sprite.frame % 13
func is_red():
	return get_suit() == HEART or get_suit() == DIAMOND

func get_card_index():
	return $Sprite.frame;


	
func get_overlapping_cards():
	var cards =[]
	for area in get_overlapping_areas():
		cards.append(area)
	return cards


func can_go_over(card):
	return is_red() != card.is_red() and get_value() + 1 == card.get_value()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	mouse_over = true


func _on_area_2d_mouse_exited() -> void:
	mouse_over = false
