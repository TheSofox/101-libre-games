extends Node2D

@export var card_scene: PackedScene
@onready var board: Node2D = $Board
@onready var field_start: Vector2 = $FieldStart.position
# Called when the node enters the scene tree for the first time.
var field: Array = [[],[],[],[],[],[],[] ]
var foundation: Array = [[],[],[],[]]
var draw_pile: Array = []
var waste_pile: Array = []
var vert_gap = 40
func _ready() -> void:
	start_game()
	
	var cards = range(52)
	cards.shuffle()
	for x in range(7):
		for y in range(7):
			if x>=y:
				var card = place_card(cards.pop_back(), 0, 0)
				field[x].append(card)
	while len(cards)>0:
		draw_pile.append(cards.pop_back())
	refresh_board()

func refresh_board():
	var x=0; var y=0;
	vert_gap = 35 - max(0, (get_column_max()-8)*2)

	for col in field:
		for card in col:
			bring_card_to_front(card)
			card.position = Vector2(field_start.x + x*150, field_start.y+y*vert_gap)
			card.frozen = card!=col.back()
			y+=1
		x+=1
		y=0

func get_column_max():
	var max = 0
	for col in field:
		if len(col)>max:
			max = len(col)
	return max
	
func move_card_over(move_card, landing_card):
	for col:Array in field:
		for card in col:
			if card==move_card:
				col.erase(move_card)
	for col:Array in field:
		for card in col:
			if card==landing_card:
				col.append(move_card)
	refresh_board()


var held_cards: Array = []
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		var cards = get_cards_under_mouse()
		var chosen_card
		for card in cards:
			chosen_card = get_card_in_front(card,chosen_card)
		var stack = get_stack_below(chosen_card)
		if not stack.is_empty():
			held_cards = stack
			for card in held_cards:	
				bring_card_to_front(card)
	if event.is_action_released("click"):
		if not held_cards.is_empty():
			stack_released(held_cards)
		held_cards = []
		refresh_board()
		
	if event is InputEventMouseMotion:
		for card in held_cards:
			card.position +=event.relative
		
func get_col(card: Card):
	for col in field:
		for c in col:
			if c==card:
				return col

func get_stack_below(card: Card):
	if card == null:
		return []
	var col  = get_col(card)
	var stack=[]
	for c:Card in col:
		if c == card and stack.is_empty():
			stack.append(c)
			continue
		if not stack.is_empty():
			if c.can_go_over(stack.back()):
				stack.append(c)
			else:
				return []
	return stack

func get_card_in_front(card1, card2):
	if card1 == null:
		return card2
	if card2 == null:
		return card1
	var col = get_col(card1)
	if col != get_col(card2):
		return null
	var ret_card
	for card in col:
		if card==card1:
			ret_card = card1
		if card==card2:
			ret_card = card2
	return ret_card


func is_at_bottom(card):
	for col: Array in field:
		if col.back() == card:
			return true
	return false

func stack_released(stack: Array):
	var card: Card = stack.front()
	var landing_card
	var max_distance = INF
	for overlap_card in card.get_overlapping_cards():
		if is_at_bottom(overlap_card) and card.can_go_over(overlap_card):
			var dist = card.position.distance_to(overlap_card.position)
			if dist < max_distance:
				max_distance = dist
				landing_card = overlap_card
	if landing_card:
		var prev_card = landing_card
		for c in stack:
			move_card_over(c, prev_card)
			prev_card = c
		
	
	
func misc(card, overlaps):
	var places = []
	for overlap in overlaps:
		if overlap is Card and overlap.frozen ==false:
			places.append(overlap)
	if len(places) == 0:
		return
	var landing_card = null
	if len(places) == 1:
		landing_card = places[0]
	if len(places)>1:
		var closest = INF
		for p in places:
			var dist = card.position.distance_to(p.position)
			if dist<closest:
				closest = dist;
				landing_card = p
	card.set_base_position(landing_card.position + Vector2.DOWN*40)
			
	print(places)

func place_card(index, x, y):
	var card = make_card(index)
	card.position = Vector2(x, y);
	$Board.add_child(card)
	return card
	
	
func start_game():
	pass

func make_card(index):
	var card : Card = card_scene.instantiate()
	card.set_card_index(index)
	card.visible = true
	return card

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func bring_card_to_front(card):
	card.get_parent().move_child(card, card.get_parent().get_child_count())
	
func get_cards_under_mouse():
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	
	var results = space_state.intersect_point(params)
	var cards = []
	for result in results:
		if result["collider"] is Area2D:
			cards.append(result["collider"])
	return cards
