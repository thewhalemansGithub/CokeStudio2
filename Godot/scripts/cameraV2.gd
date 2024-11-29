extends Node3D

@export var zoomFov_max = 45
@export var zoomFov = 45
@export var zoomFov_min = 10
@export var zoomFov_amount = 2.5

@export var sensitivity = 300
@export var default = Vector3(0,-45,45)

var intersect_floor

var update
var target

var mousePosition
var resolution
var clickPosition
var cameraRotation

var moveX = deg_to_rad(-45)
var moveY = deg_to_rad(45)

func _ready() -> void:
	resolution = DisplayServer.window_get_size()
	self.rotation = Vector3(deg_to_rad(default.x),deg_to_rad(default.y),deg_to_rad(default.z))
	cameraRotation = self.rotation

func _unhandled_input(event: InputEvent):
	
	#zoom stuff
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP && event.pressed:
			
			if zoomFov > zoomFov_min:
				zoomFov -= zoomFov_amount
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN && event.pressed:
			
			if zoomFov < zoomFov_max:
				zoomFov += zoomFov_amount
	
	if event is InputEventMouse:
		#setup mouse ray
		if event.position:
			intersect_floor = Global.get_mouse_intersect( event.position, 1 ) # playable ground
			
	#mouse input click
	if event is InputEventMouseButton:

		#press/release code
		var middleButtonPressed = event.button_index == MOUSE_BUTTON_MIDDLE && event.pressed
		var middleButtonReleased = event.button_index == MOUSE_BUTTON_MIDDLE && !event.pressed
		
		if middleButtonPressed:
			
			update = true
			clickPosition = get_viewport().get_mouse_position()
			resolution = DisplayServer.window_get_size()
			
		if middleButtonReleased:
			
			clickPosition = null
			update = false
			cameraRotation = self.rotation
	

			
func _process(delta: float) -> void:

	
	$Camera3D.fov = lerp(int($Camera3D.fov), int(zoomFov), 0.125)
	
	if update:
		
		mousePosition = get_viewport().get_mouse_position()
		
		var middle_v = resolution.y / 2
		var middle_v_percent = middle_v / mousePosition.y
		
		#I hit my head against the keyboard till it worked.
		moveX = ( mousePosition.x - clickPosition.x ) * -1.0
		moveX = ( moveX / ( resolution.x - clickPosition.x ) ) * sensitivity
		moveX = rad_to_deg(cameraRotation.y) + moveX
		
		moveY = ( clickPosition.y - mousePosition.y ) * -1.0
		moveY = ( moveY / ( resolution.y - clickPosition.y ) ) * sensitivity
		moveY = rad_to_deg(cameraRotation.z) + moveY
		
		
		#snapper
		moveY = snappedf(moveY, 45)
		moveX = snappedf(moveX, 45)
		
		#limiter, probably could have done this a better way..
		if moveY < 15: moveY = 15
		if moveY > 90: moveY = 90
		if moveX < -90: moveX = -90
		if moveX > 0: moveX = 0
		
		#convert
		moveX = deg_to_rad(moveX)
		moveY = deg_to_rad(moveY)

	#rotate stuff
	if moveX != self.rotation.y : self.rotation.y = lerp(self.rotation.y, moveX, 0.25)
	if moveY != self.rotation.z: self.rotation.z = lerp(self.rotation.z, moveY, 0.25)
