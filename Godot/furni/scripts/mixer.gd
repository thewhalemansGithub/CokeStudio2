extends Node3D

@export var on = preload("res://furni/mixer_on.tres")
@export var off = preload("res://furni/mixer_off.tres")

var intersect 
var lightStatus = false

func _ready() -> void:
	#turn light off
	self.get_child(0).set_surface_override_material(0, off)
	$SpotLight3D.light_energy = 0

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
		if intersect and event.is_double_click() and self.get_child(0).get_child(0) == staticBody: #THIS IS WHERE YOU BROKE IT
			
			if lightStatus == true:
				#turn light on
				self.get_child(0).set_surface_override_material(0, on)
				$SpotLight3D.light_energy = 5
					
				lightStatus = false
					
			elif lightStatus == false:
				#turn light off
				self.get_child(0).set_surface_override_material(0, off)
				$SpotLight3D.light_energy = 0
				
				lightStatus = true
