extends Node

var intersect 
var lightStatus = true

func _input(event):
	
	#any mouse input
	if event is InputEventMouse:
		#setup mouse ray
		if event.position:
			#raycast to find lightswitch
			intersect = Global.get_mouse_intersect(event.position, 1 << 3) # Bit shift for layer 4

	#mouse input click
	if event is InputEventMouseButton:
		
		#left click
		var leftButtonPressed = event.button_index == MOUSE_BUTTON_LEFT && event.pressed
		
		#check if we left clicked, we are clicking on the lightswitch, and we've double clicked
		if leftButtonPressed and intersect and event.is_double_click():
			
				if lightStatus == true:
					#turn light off
					$DirectionalLight3D.light_energy = 0.1
					$SpotLight3D.light_energy = 1
					$switch.rotate_x( deg_to_rad( 60 ) )
					
					lightStatus = false
					
				elif lightStatus == false:
					#turn light on
					$DirectionalLight3D.light_energy = 1
					$SpotLight3D.light_energy = 10
					$switch.rotate_x( deg_to_rad( -60 ) )
					lightStatus = true
