extends Area2D

class_name Card
enum {SPADE, HEART, CLUB, DIAMOND}


var locked = false
var mouse_over = false
var frozen = false
var face_up = true;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Back.visible = !face_up

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

func set_face_up():
	face_up = true
	$Back.visible = !face_up

func set_face_down():
	face_up = false
	$Back.visible = !face_up

func flip():
	face_up = !face_up
	$Back.visible = !face_up
	
func get_face_up():
	return face_up
	
func get_overlapping():
	var areas =[]
	for area in get_overlapping_areas():
		areas.append(area)
	return areas


func can_go_over(card):
	return is_red() != card.is_red() and get_value() + 1 == card.get_value()


func _on_area_2d_mouse_entered() -> void:
	mouse_over = true


func _on_area_2d_mouse_exited() -> void:
	mouse_over = false
