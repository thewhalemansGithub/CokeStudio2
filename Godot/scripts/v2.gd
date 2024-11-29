extends Node3D
#We import what is needed
#@export var furni_couch = preload("res://furni/cokeCouch.tscn")
@export var furni_mixer = preload("res://furni/mixer.tscn")
@export var furni_seperator = preload("res://furni/seperator.tscn")
@export var furni_cokecouch = preload("res://furni/cokeCouch.tscn")
@export var furni_cables = preload("res://furni/cables.tscn")


#All the shit for seperators
@export var icon_sep_00 = preload("res://assets/icons/seperator_beige.png")
@export var icon_sep_01 = preload("res://assets/icons/seperator_black.png")
@export var icon_sep_02 = preload("res://assets/icons/seperator_blue.png")
@export var icon_sep_03 = preload("res://assets/icons/seperator_green.png")
@export var icon_sep_04 = preload("res://assets/icons/seperator_orange.png")
@export var icon_sep_05 = preload("res://assets/icons/seperator_steel.png")
@export var icon_sep_06 = preload("res://assets/icons/seperator_yellow.png")
@export var icon_sep_07 = preload("res://assets/icons/seperator_white.png")
var icon_sep = [icon_sep_00, icon_sep_01, icon_sep_02, icon_sep_03, icon_sep_04, icon_sep_05, icon_sep_06, icon_sep_07]
var icon_sep_count = 0
var sep_colors = [
	Vector3( 217 , 217, 213 ),
	Vector3( 76, 76, 89 ),
	Vector3(58, 123, 215),
	Vector3(119, 160, 49),
	Vector3(209, 139, 37),
	Vector3(111, 160, 152),
	Vector3(218, 206, 56),
	Vector3(196, 146, 77)]

#declare!!!
var intersect_floor
var intersect_playable
var intersect_all
var intersect_edit
var intersect_gizmo
var mousePosition

var screenMousePosLast

@export var smoothness = float(0.125)

var editMode = false

var spawnedFurni

var activeFurni
var activeFurni_collider
var activeFurni_history
var activeFurni_rotation

var dragging
var moveRequest = Vector3(0,0,0)
var moveRequestResult = false
var rotationRequest = 0.0
var moveFilter
var moveOffset = Vector3(0,0,0)
var rotationOffset = Vector3(0,0,0)

@export var increments = float(0.5)

var time_elapsed = 0.0

func _ready() -> void:
	$UI/edit/buttons.visible = false
	$gizmo.visible = false
	$UI/edit/PanelContainer/SubViewportContainer/SubViewport/iconCamera/MeshInstance3D.visible = false
	pass
		
func _unhandled_input(event):
	
	#any mouse input
	if event is InputEventMouse:
		
		#setup mouse ray
		if event.position:
			intersect_floor = Global.get_mouse_intersect( event.position, 1 | 32) # ground
			intersect_playable = Global.get_mouse_intersect( event.position, 1 ) # playable ground
			intersect_edit = Global.get_mouse_intersect( event.position, 16 ) # edit
			intersect_all = Global.get_mouse_intersect( event.position, 1 | 2 | 4 | 16 | 32) # ground + furni + gizmo
			intersect_gizmo = Global.get_mouse_intersect( event.position, 32) # ground + furni + gizmo
			
			if intersect_floor: mousePosition = intersect_floor.position

	#mouse input click
	if event is InputEventMouseButton:
		
		#Make gizmo appear if we double click the active furni
		if event.is_double_click() and activeFurni:
			$gizmo.visible = true
			$gizmo.global_position = activeFurni.global_position
			$gizmo.global_position.y = activeFurni.global_position.y + 0.1			
		
		#hand left clicking
		var leftButtonPressed = event.button_index == MOUSE_BUTTON_LEFT && event.pressed
		var leftButtonReleased = event.button_index == MOUSE_BUTTON_LEFT && !event.pressed
		
		#If we click on a peice of furniture, set it as active furni
		if leftButtonPressed and intersect_all:
			
			#check if we can move it
			var moveable = intersect_all.collider.get_owner().get_meta("Moveable")

			#if we aren't in edit mode then we turn it on.
			if !editMode and moveable:

				setActiveFurni(true, intersect_all)

		#Lets move furniture
		if activeFurni and intersect_edit and leftButtonPressed:
			
			#Can we move it?
			var move = intersect_edit.collider.get_meta("move")

			#enable dragging mode
			if move:
				dragging = true
			
			#Gizmo shit
			#Set gizmo axis filter [X | Z | XZ | R(Rotation)]
			if move and move == "x":
				#X movement filter/offset
				moveFilter = "x"
				moveOffset =  Vector3($gizmo.global_position.x - intersect_floor.position.x, 0, 0)
			elif move and move == "z":
				#Z movement filter/offset
				moveFilter = "z"
				moveOffset =  Vector3(0,0,$gizmo.global_position.z - intersect_floor.position.z)
			elif move and move == "xz":
				#XZ movement filter/offset
				var tempX = $gizmo.global_position.x - intersect_floor.position.x
				var tempZ = $gizmo.global_position.z - intersect_floor.position.z
				moveOffset = Vector3(tempX, 0 ,tempZ)
				moveFilter = "xz"
			elif move and move == "r":
				#R movement filter/offset
				moveFilter = "r"
				screenMousePosLast = get_viewport().get_mouse_position()	

		#Check if the active furni is in the correct spot if we are dragging
		if intersect_edit and activeFurni and checkValidity(activeFurni) and leftButtonReleased:
			#Accept the move and set new history
			activeFurni_history = moveRequest
			activeFurni_rotation = rotationRequest

			#print("Move request accepted")
		elif activeFurni and checkValidity(activeFurni) == false and leftButtonReleased:
			
			#handle if the thing we tried to place was recently spawned, aka has no history
			if spawnedFurni:
				deleteActiveFurni(activeFurni)
			else:
				#Reject the move, and reset it to previous position
				moveRequest = activeFurni_history
				rotationRequest = activeFurni_rotation

			print("Move request rejected")

		#deactivate furniture if pressed left click, are in edit mode, are not clicking on active furniture, and are no clicking on the gizmo. fuckme.
		if leftButtonPressed and editMode and intersect_all.collider.get_owner() != activeFurni and dragging == false and intersect_all.collider.get_owner() != $gizmo:

			#Use the gizmos visibily to try stop disabling edit mode
			if $gizmo.visible == false:
				setActiveFurni(false, null)
			else:
				$gizmo.visible = false
			
		#disable dragging no matter what
		if leftButtonReleased:
			dragging = false
			
	#Rotate shortcut
	#delete function
	if activeFurni and event is InputEventKey and event.keycode == KEY_R and event.pressed:
		
		var newRotation = rad_to_deg( activeFurni.rotation.y )
		newRotation += 90
		newRotation = snapped(newRotation, 90)
		
		if newRotation >= 270:
			newRotation = -90
		
		rotationRequest = deg_to_rad(newRotation)
	
	#check if the rotation should be accepted
	#write this code later
	if activeFurni and event is InputEventKey and event.keycode == KEY_R and !event.pressed and checkValidity(activeFurni):
		pass
	else:
		pass
		
	#delete function
	if activeFurni and event is InputEventKey and event.keycode == KEY_DELETE and event.pressed:
		deleteActiveFurni(activeFurni)

func _process(delta: float) -> void:
	
	#DEBUG PURPOSES
	time_elapsed += delta
	
	if time_elapsed >= 1.0:
		
		time_elapsed = 0.0
	
	# Setup move requests
	if dragging and editMode and moveFilter:
		#Request X movement
		if moveFilter == "x": moveRequest.x = snapped( mousePosition.x + moveOffset.x, increments )
		#Request Z movement
		elif moveFilter == "z": moveRequest.z = snapped( mousePosition.z + moveOffset.z, increments )
		#Request XZ movement
		elif moveFilter == "xz":
			moveRequest.z = snapped( mousePosition.z + moveOffset.z, increments )
			moveRequest.x = snapped( mousePosition.x + moveOffset.x, increments )
		#Request rotation
		if moveFilter == "r":
			var screenMousePos = get_viewport().get_mouse_position()
			rotationRequest = (screenMousePos.x - screenMousePosLast.x) * 1 * delta
			rotationRequest = snappedf( clamp (rotationRequest, -3.5, 3.5 ), deg_to_rad(90) )

	if editMode:

		if dragging:
			
			#adjust height of active furniture
			moveRequest.y = Global.findMoveHeight(activeFurni)
			
			if spawnedFurni and checkValidity(activeFurni) and spawnedFurni.get_child(0).get_child(0) == activeFurni:

				activeFurni.scale = lerp(activeFurni.scale, Vector3(2,2,2), smoothness)
				
			else:

				activeFurni.scale =lerp(activeFurni.scale,  Vector3(1,1,1), smoothness)
				
		#execute movement/rotation
		activeFurni.global_position = lerp(activeFurni.global_position, moveRequest, smoothness)
		activeFurni.rotation.y = lerp(activeFurni.rotation.y, rotationRequest, smoothness)
		#bring in gizmo
		$gizmo.position = activeFurni.global_position
		$gizmo.position.y = activeFurni.global_position.y + 0.1
		
		#setup icon camera
		%iconCamera.position.x = activeFurni.global_position.x + 5	
		%iconCamera.position.y = activeFurni.global_position.y + 5
		%iconCamera.position.z = activeFurni.global_position.z + 5
		

func deleteActiveFurni(target):
		if target:
			target.queue_free()
			print("deleted : ", target)
			setActiveFurni(false, null)
		
func checkValidity(furni):

	var legs = furni.get_child(1).get_children()
	var check = []
	var stackable = []
	
	#Loop through the legs
	for i in legs.size():
		
		#Lets build an array and figure out if all the legs are colliding, or not colliding with a valid surface.
		#Check if it's collding with anything at all, and what it is colliding is valid
		if legs[i].is_colliding() and legs[i].get_collider().get_owner():
			
			#Insert into array
			check.insert(i, 1)
			
			#The leg is on something stackable, rad.
			if legs[i].get_collider().get_owner().get_meta("Stackable"):
				stackable.insert(i, 1)
			#The leg isn't on something stackable..
			else:
				stackable.insert(i, 0)
		#This shouldn't even happen, but if it does, it's for invalid.
		else:
			check.insert(i, 0)
		
	#Check if array	to see if all legs were colliding with a valid surface, return the result.
	if check.min() == 0 or stackable.min() == 0:
		return false
	else:
		return true
	
func setActiveFurni(check, target, spawned = false):
	
	#Check [true | false]: Are setting active furni or not
	#target: The ray used to intersect with the furni
	#Spawned [true | false]: Did we just spawn it
	
	#Check came back true, we want to set an active furniture
	if check == true:
		
		#The furniture was just spawned.
		if spawned:
			
			#set up variables
			activeFurni = spawnedFurni.get_child(0)
			activeFurni_collider = spawnedFurni.get_child(0).get_child(0).get_child(0)
			activeFurni_history = spawnedFurni.global_position
			activeFurni_rotation = spawnedFurni.rotation
			activeFurni_collider.collision_layer = 4
		
		#Furniture already existed
		else:
			#set up variables
			activeFurni = target.collider.get_owner()
			activeFurni_collider = target.collider
			activeFurni_history = target.collider.get_owner().global_position
			activeFurni_rotation = target.collider.get_owner().rotation.y
			activeFurni_collider.collision_layer = 4 #change collision layer to 3, aka edit
		
		#icon camera mask
		activeFurni.get_child(0).layers = 1 | 2 # layer 1, and 2
		$UI/edit/PanelContainer/SubViewportContainer/SubViewport/iconCamera/MeshInstance3D.visible = true
			
		#Enable the UI
		$UI/edit/buttons.visible = true
		
		#UI title description
		if activeFurni.get_parent().get_meta("Name"): $UI/edit/VBoxContainer/Name.text = String( activeFurni.get_parent().get_meta("Name") )
		if activeFurni.get_parent().get_meta("Desc"): $UI/edit/VBoxContainer/Desc.text = String( activeFurni.get_parent().get_meta("Desc") )
		
		#deal with requests
		moveRequest = activeFurni.global_position
		rotationRequest = activeFurni.rotation.y
			
		#enable edit mode
		editMode = true
		print("Set active furniture: ", activeFurni )
		
	elif check == false:
		if activeFurni_collider: activeFurni_collider.collision_layer = 2 #change back collision layer to 2, aka furni
		
		#icon camera mask
		if activeFurni and activeFurni.get_child_count(): activeFurni.get_child(0).layers = 1
		$UI/edit/PanelContainer/SubViewportContainer/SubViewport/iconCamera/MeshInstance3D.visible = false
		
		#null active furni
		activeFurni = null
		activeFurni_collider = null
		activeFurni_history = null
		activeFurni_rotation = null
		
		#go away gizmo
		$gizmo.position = Vector3(10,0,10)
		$gizmo.visible = false
		
		$UI/edit/buttons.visible = false
		
		#reset UI title/desc
		$UI/edit/VBoxContainer/Name.text = String("")
		$UI/edit/VBoxContainer/Desc.text = String("")
		
		#deal with requests
		moveRequest = Vector3(0,0,0)
		rotationRequest = 0.0
		moveOffset = Vector3(0,0,0)
		rotationOffset = Vector3(0,0,0)
		
		spawnedFurni = false
		
		#disable edit mode
		editMode = false
		print("Deactivated active furniture")

func itemSpawner(item, position, rotation, scale):
	
	var obj
	
	if item:
		
		#spawn setup
		obj = item.instantiate()
		obj.position = position
		obj.rotation = rotation
		obj.scale = Vector3(scale, scale, scale)
		
		#Lets deal with seperators.
		if item == furni_seperator:
			
			#duplicate mesh
			var model = obj.get_child(0).get_child(0)
			model.mesh = model.mesh.duplicate()
			
			#grab material
			var material = model.mesh.surface_get_material(1)
			
			if material:
				
				#duplicate material
				var newMaterial = material.duplicate()
				#change seperator color
				newMaterial.albedo_color = colorToFloat( sep_colors[icon_sep_count] )
				#apply it to mesh
				model.mesh.surface_set_material(1, newMaterial)


	#if everything is good, spawn it.
	if obj:
		setActiveFurni(false, null)
		
		$Room.add_child(obj)
		
		spawnedFurni = obj
		
		#unset active furni
		setActiveFurni(true, obj, true)
		
		dragging = true
		editMode = true
		moveFilter = "xz"
		
		print("Created Object : ", obj)
	else:
		print("Object could not be created.")		

func colorToFloat(array):
	var newColor = sep_colors[icon_sep_count]
	newColor.x = snappedf(newColor.x/255, 0.01)
	newColor.y = snappedf(newColor.y/255, 0.01)
	newColor.z = snappedf(newColor.z/255, 0.01)
	return Color(newColor.x, newColor.y, newColor.z)

func _edit_delete() -> void:
	if activeFurni:
		deleteActiveFurni(activeFurni)

func _edit_move() -> void:
	if activeFurni:
		$gizmo.visible = true
		$gizmo.global_position = activeFurni.global_position
		$gizmo.global_position.y = activeFurni.global_position.y + 0.1

func _spawn_mixer() -> void:
	itemSpawner(furni_mixer, Vector3(-3,10,3), Vector3(0,0,0), 1 )
	pass

func _spawn_sep() -> void:
	itemSpawner(furni_seperator, Vector3(-3,10,3), Vector3(0,0,0), 1 )
	pass

func _change_sep_color(event):

	#mouse input click
	if event is InputEventMouseButton:

		#hand left clicking
		var rightButtonPressed = event.button_index == MOUSE_BUTTON_RIGHT && event.pressed
		var rightButtonReleased = event.button_index == MOUSE_BUTTON_RIGHT && !event.pressed
		
		if rightButtonPressed:
			
			#increase counter
			icon_sep_count += 1
			
			#set texture
			var sepTextureRect = $UI/spawner/sep/Button/TextureRect
			sepTextureRect.texture = icon_sep[icon_sep_count]
			
			#reset
			if icon_sep_count > 6:
				icon_sep_count = 0

func _spawn_cc() -> void:
	itemSpawner(furni_cokecouch, Vector3(-3,10,3), Vector3(0,0,0), 1 )
	pass


func _spawn_cables() -> void:
	itemSpawner(furni_cables, Vector3(-3,10,3), Vector3(0,0,0), 1 )
	pass
