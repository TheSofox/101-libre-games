@tool
extends Area2D

class_name  CardBase
@onready var image : Sprite2D = $Image
#enum {EMPTY, OUTLINE, YES, NO}

@export_enum("Empty", "Outline", "Yes", "No") var base_type: int:
	set(value):
		if value!= null:
			base_type = value
			#print(value)
			set_image(value)
			#print("Heya")
			#$Image.frame = 3

#

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_image(base_type)

func set_image(img):
	if image:
		image.frame = img
