extends Node2D

@export var card_scene: PackedScene
@onready var board: Node2D = $Board
@onready var tableau_slots: Node2D = $TableauSlots
# Called when the node enters the scene tree for the first time.
var field: Array = [[],[],[],[],[],[],[] ]
var board_foundation: Array = [[],[],[],[]]
var draw_pile: Array = []
var waste_pile: Array = []
var vert_gap = 40

enum {FIELD, FOUNDATION, DRAW, WASTE}

func get_card_location(card: Card):
	for col in field:
		for c in col:
			if c == card:
				return FIELD
	for col in board_foundation:
		for c in col:
			if c==card:
				return FOUNDATION
	for c in draw_pile:
		if c== card:
			return DRAW
	for c in waste_pile:
		if c == card:
			return WASTE

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
		draw_pile.append(place_card(cards.pop_back(), 0, 0))
	refresh_board()

func refresh_board():
	var x=0; var y=0;
	vert_gap = 35 - max(0, (get_column_max()-8)*2)

	for col in field:
		var col_pos = tableau_slots.get_child(x).position
		for card in col:
			bring_card_to_front(card)
			
			card.position = Vector2(col_pos.x, col_pos.y+y*vert_gap)
			card.frozen = card!=col.back()
			y+=1
		x+=1
		y=0
	var foundation_index = 0
	for foundation in board_foundation:
		for card in foundation:
			card.position = $Base/Foundations.get_child(foundation_index).position
		foundation_index+=1
	for card in draw_pile:
		card.position = $Base/DrawPile.position
		bring_card_to_front(card)
		card.set_face_down()
		
	for card in waste_pile:
		card.position = $Base/WastePile.position
		bring_card_to_front(card)
		card.set_face_up()

func get_column_max():
	var col_max = 0
	for col in field:
		if len(col)>col_max:
			col_max = len(col)
	return col_max
	
func move_card_over(move_card, landing_card):
	remove_from_field(move_card)
	for col:Array in field:
		for card in col:
			if card==landing_card:
				col.append(move_card)
	refresh_board()

func move_card_foundation(card:Card, foundation:Node2D):
	var foundation_index = foundation.get_index()
	move_card_data_foundation(card, board_foundation[foundation_index])
	
func move_card_data_foundation(card:Card, foundation:Array):
	foundation.append(card)
	remove_from_field(card)
	refresh_board()
	
func move_card_tableau_base(card:Card, tableau_base:Node2D):
	remove_from_field(card)
	var index = tableau_base.get_index()
	field[index].append(card)
	refresh_board()
	
	
func remove_from_field(remove_card:Card):
	for col:Array in field:
		for card in col:
			if card==remove_card:
				col.erase(remove_card)
	if len(waste_pile)>0 and remove_card==waste_pile.back():
		waste_pile.erase(remove_card)

var held_cards: Array = []
var draw_click = false
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		if is_mouse_over_draw_pile():
			draw_click = true
	if event.is_action_released("click"):
		if is_mouse_over_draw_pile() and draw_click:
			draw_cards()
		draw_click = false
		
	if event.is_action_pressed("click"):
		var cards = get_cards_under_mouse()
		var chosen_card
		for card in cards:
			if get_card_location(card) == FIELD:
				chosen_card = get_card_in_front(card,chosen_card)
			if get_card_location(card) == WASTE and waste_pile.back()== card:
				chosen_card = card
		var stack = get_stack_below(chosen_card)
		
		if event.double_click and len(stack)==1 and add_card_to_foundation(stack.front()):
			pass
		elif not stack.is_empty():
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

func add_card_to_foundation(card:Card):
	for foundation in board_foundation:
		if can_card_land_on_foundation(card, foundation):
			move_card_data_foundation(card, foundation)
			return

func draw_cards():
	if len(draw_pile)>0:
		waste_pile.append(draw_pile.pop_back())
	else:
		draw_pile = waste_pile
		draw_pile.reverse()
		waste_pile = []

func get_col(card: Card):
	for col in field:
		for c in col:
			if c==card:
				return col

func get_stack_below(card: Card):
	if card == null or not is_card(card):
		return []
	if get_card_location(card)==WASTE:
		return [card]
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
	if card1 == null or is_foundation(card1):
		return card2
	if card2 == null or is_foundation(card2):
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
	var cards = []
	var foundations = []
	var tableau_bases = []
	for area in card.get_overlapping():
		if is_foundation(area) and card_match_foundation(card, area):
			foundations.append(area)
		if area is Card and is_at_bottom(area) and card.can_go_over(area):
			cards.append(area)
		if is_free_tableau_base(area) and card.get_value() ==12:
			tableau_bases.append(area)
			print("King can be placed")
	
	var landing_card = get_closest(card, cards)

	if landing_card:
		var prev_card = landing_card
		for c in stack:
			move_card_over(c, prev_card)
			prev_card = c
	elif len(stack) == 1 and len(foundations)>0:
			var closest_foundation = get_closest(card,foundations)
			move_card_foundation(stack.front(), closest_foundation)
	elif len(tableau_bases)>0:
			var closest_base = get_closest(card,tableau_bases)
			move_card_tableau_base(stack.front(), closest_base)
			var prev_card = stack.pop_front()
			for c in stack:
				move_card_over(c, prev_card)
				prev_card = c

func can_card_land_on_foundation(card: Card, foundation):
	if len(foundation) == 0 and card.get_value()==0:
		return true
	if len(foundation)==0:
		return false
	if foundation.back().get_value()+1 == card.get_value() and foundation.back().get_suit() == card.get_suit():
			return true
	return false

func card_match_foundation(card: Card, foundation):
	var foundation_index = foundation.get_index()
	var data_foundation: Array = board_foundation[foundation_index]
	return can_card_land_on_foundation(card, data_foundation)

		

func get_closest(target:Node2D, list:Array):
	var max_distance = INF
	var result
	for item in list:
		var dist = item.position.distance_to(target.position)
		if dist < max_distance:
			max_distance = dist
			result = item
	return result
		
	
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

	
func bring_card_to_front(card):
	card.get_parent().move_child(card, card.get_parent().get_child_count())
	
func is_foundation(item):
	return item.get_parent().name == "Foundations"
	
func is_free_tableau_base(item):
	if item.get_parent().name == "TableauSlots":
		var index = item.get_index()
		return len(field[index])==0
		

func is_card(item):
	return item is Card
	#return item.get_script() and item.get_script().get_global_name()=="Card"


func is_mouse_over_draw_pile():
	for area in get_areas_under_mouse():
		if area["collider"].name =="DrawPile":
			return true
	return false

func get_areas_under_mouse():
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	
	return space_state.intersect_point(params)
	
func get_cards_under_mouse():
	var cards = []
	for result in get_areas_under_mouse():
		
		if result["collider"] is Area2D and is_card(result["collider"]):
			cards.append(result["collider"])
	return cards
