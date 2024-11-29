extends Node3D

@export var on = preload("res://furni/mixer_on.tres")
@export var off = preload("res://furni/mixer_off.tres")

var intersect
var colors = [
	Vector3( 217 , 217, 213 ),
	Vector3( 76, 76, 89 ),
	Vector3(58, 123, 215),
	Vector3(119, 160, 49),
	Vector3(209, 139, 37),
	Vector3(111, 160, 152),
	Vector3(218, 206, 56),
	Vector3(196, 146, 77)]
var count = 0

func _ready() -> void:
	$seperator.get_child(0).get_active_material(1).albedo_color = colorToFloat(colors[count])
	pass

func _input(event):
#any mouse input
	if event is InputEventMouse:
		#setup mouse ray
		if event.position:
			#raycast to find lightswitch
			intersect = Global.get_mouse_intersect(event.position, 2 | 4 ) # Bit shift for layer 2

	#mouse input click
	if event is InputEventMouseButton:
		
		var staticBody
		
		if intersect:
			staticBody = intersect.collider
		
		#check if we left clicked, we are clicking on the lightswitch, and we've double clicked
		if intersect and event.is_double_click() and $seperator.get_child(0).get_child(0) == staticBody:

			#colors[count]
			$seperator.get_child(0).get_active_material(1).albedo_color = colorToFloat(colors[count])
			
			if count == ( colors.size() - 1 ):
				count = 0
			else:
				count += 1

func colorToFloat(array):
	var newColor = colors[count]
	newColor.x = snappedf(newColor.x/255, 0.01)
	newColor.y = snappedf(newColor.y/255, 0.01)
	newColor.z = snappedf(newColor.z/255, 0.01)
	return Color(newColor.x, newColor.y, newColor.z)
