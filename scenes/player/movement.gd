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

# --- НОВЫЕ ПЕРЕМЕННЫЕ для "Пружинной" Камеры ---
@export var camera_stiffness = 25.0    # Жесткость пружины. Чем выше, тем резче камера
@export var camera_damping = 8.0     # Затухание. Предотвращает вечные колебания

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
# --- НОВЫЕ ПЕРЕМЕННЫЕ для "Пружинной" Камеры ---
var camera_offset_velocity = 0.0     # Текущая скорость смещения камеры


func _physics_process(delta):
	# --- ... (Код прыжков, гравитации, приземления без изменений) ... ---
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5
	if velocity.y > 0:
		velocity.y += gravity * fall_gravity_multiplier * delta
	else:
		velocity.y += gravity * jump_hang_gravity_multiplier * delta
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer.start()
	if not jump_buffer_timer.is_stopped() and is_on_floor():
		velocity.y = jump_velocity
		jump_buffer_timer.stop()
	if is_on_floor() and was_in_air:
		start_camera_shake(landing_shake_strength, landing_shake_duration)
	was_in_air = not is_on_floor()
	# --------------------------------------------------------------------

	# --- Управление персонажем ---
	var direction = Input.get_axis("ui_left", "ui_right")
	var effective_acc = acceleration if is_on_floor() else acceleration * air_control_factor

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, effective_acc)
	else:
		velocity.x = move_toward(velocity.x, 0, friction)

	move_and_slide()
	
	# --- Вызываем обновление камеры. Оно теперь управляется из _process, 
	# чтобы быть независимым от физики и более плавным
	pass

# --- Функция update_camera_target больше не нужна ---

# --- Функция update_camera_offset больше не нужна ---


func start_camera_shake(strength: float, duration: float) -> void:
	current_shake_strength = strength
	camera_shake_timer.wait_time = duration
	camera_shake_timer.start()


func _process(delta: float) -> void:
	# --- НОВЫЙ БЛОК: Логика Пружинной Камеры ---
	# 1. Определяем целевое смещение, как и раньше, но на основе СКОРОСТИ, а не ввода,
	# т.к. пружине нужна плавная цель, которую обеспечивает velocity
	var desired_offset_x = - (velocity.x / max_speed) * camera_max_offset_x

	# 2. Рассчитываем "силу", которая тянет камеру к цели
	var force = camera_stiffness * (desired_offset_x - camera.offset.x)

	# 3. Обновляем скорость камеры
	camera_offset_velocity += force * delta
	
	# 4. Применяем затухание (трение) к скорости камеры
	camera_offset_velocity -= camera_offset_velocity * camera_damping * delta

	# 5. Двигаем смещение камеры на величину ее скорости
	camera.offset.x += camera_offset_velocity * delta
	# -----------------------------------------------

	if not camera_shake_timer.is_stopped():
		camera.offset.x += randf_range(-current_shake_strength, current_shake_strength)
		camera.offset.y = randf_range(-current_shake_strength, current_shake_strength)
	else:
		camera.offset.y = lerp(camera.offset.y, 0.0, 10 * delta) # Используем фиксированную скорость возврата для Y
		current_shake_strength = 0.0


func _on_CameraShakeTimer_timeout() -> void:
	pass
