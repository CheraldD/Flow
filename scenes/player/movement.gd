extends CharacterBody2D

# --- Переменные Настройки Движения ---
@export var max_speed = 1000.0
@export var acceleration = 40.0
@export var friction = 37.0
@export var jump_velocity = -800.0 
var gravity = 1000.0

@export_range(0.0, 1.0) var air_control_factor = 0.8
@export var fall_gravity_multiplier = 1.3
@export var jump_hang_gravity_multiplier = 1.0

# --- Переменные Камеры ---
@export var camera_max_offset_x = 150.0

# скорость «разгона» и «торможения» камеры при смене направления
@export var camera_input_smooth_speed = 6.0    
# скорость смещения уже сглаженной цели камеры
@export var camera_offset_smooth_speed = 100.0  

# --- Переменные Тряски Камеры ---
@export var landing_shake_strength = 5.0
@export var landing_shake_duration = 0.2

# --- Ссылки на узлы ---
@onready var camera = $Camera2D
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var camera_shake_timer = $CameraShakeTimer

# --- Отслеживающие переменные ---
var was_in_air = false
var current_shake_strength = 0.0
# отслеживаем «выход» камеры вперёд/назад
var camera_target_direction = 0.0


func _physics_process(delta):
	# --- Прыжок и вариабельная гравитация ---
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5
	if velocity.y > 0:
		velocity.y += gravity * fall_gravity_multiplier * delta
	else:
		velocity.y += gravity * jump_hang_gravity_multiplier * delta

	# --- Буферизация прыжка ---
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer.start()
	if not jump_buffer_timer.is_stopped() and is_on_floor():
		velocity.y = jump_velocity
		jump_buffer_timer.stop()

	# --- Тряска при приземлении ---
	if is_on_floor() and was_in_air:
		start_camera_shake(landing_shake_strength, landing_shake_duration)
	was_in_air = not is_on_floor()

	# --- Управление персонажем ---
	var direction = Input.get_axis("ui_left", "ui_right")
	var effective_acc = acceleration if is_on_floor() else acceleration * air_control_factor


	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, effective_acc)
	else:
		velocity.x = move_toward(velocity.x, 0, friction)

	move_and_slide()
	update_camera_target(direction, delta)
	update_camera_offset(delta)


# сглаживаем цель камеры на основе входа игрока
func update_camera_target(direction: float, delta: float) -> void:
	# move_toward ведёт себя как реальное ускорение/торможение:
	camera_target_direction = move_toward(
		camera_target_direction,
		direction,
		camera_input_smooth_speed * delta
	)


# плавно смещаем камеру к цели
func update_camera_offset(delta: float) -> void:
	var desired_offset_x = -camera_target_direction * camera_max_offset_x
	camera.offset.x = lerp(
		camera.offset.x,
		desired_offset_x,
		camera_offset_smooth_speed * delta
	)


func start_camera_shake(strength: float, duration: float) -> void:
	current_shake_strength = strength
	camera_shake_timer.wait_time = duration
	camera_shake_timer.start()


func _process(delta: float) -> void:
	if not camera_shake_timer.is_stopped():
		camera.offset.x += randf_range(-current_shake_strength, current_shake_strength)
		camera.offset.y = randf_range(-current_shake_strength, current_shake_strength)
	else:
		# плавно возвращаем Y-смещение на 0 после тряски
		camera.offset.y = lerp(camera.offset.y, 0.0, camera_offset_smooth_speed * delta)
		current_shake_strength = 0.0


func _on_CameraShakeTimer_timeout() -> void:
	# здесь можно сделать дополнительную логику по завершению тряски
	pass
