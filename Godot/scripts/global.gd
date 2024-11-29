extends Node3D


func find_3D_degrees(mouseRay, target):
	
	var target_position = mouseRay.position
	target_position.y = global_transform.origin.y

	# Calculate the direction vector from the cube to the target position
	var direction = (target_position - target.global_transform.origin).normalized()

	# Calculate the Y-axis angle in radians and convert to degrees
	var target_rotation_y = atan2(direction.x, direction.z)
	var rotation_degrees_y = rad_to_deg(target_rotation_y)

	# Set the rotation only on the Y-axis
	return rotation_degrees_y

func findMoveHeight(furni):
	
	var legs = furni.get_child(1).get_children()
	var check = []
	
	for i in legs.size():

		if legs[i].is_colliding() and legs[i].get_collider().get_owner():
			
			check.insert(i, snappedf(legs[i].get_collision_point().y, 0.01 ) )
				
		else:
				
			check.insert(i, 0)
	
	if check.max():
		return check.max()
	else:
		return 0

func get_mouse_intersect(mousePos, mask):
	
	if mousePos:
	
		var currentCamera = get_viewport().get_camera_3d()
		var params = PhysicsRayQueryParameters3D.new()
		
		params.from = currentCamera.project_ray_origin(mousePos)
		params.to = currentCamera.project_position(mousePos, 1000)
		params.collision_mask = mask
		
		var worldspace = get_world_3d().direct_space_state
		var result = worldspace.intersect_ray(params)
		
		return result
	
	else :
		
		return null
