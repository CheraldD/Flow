extends CharacterBody2D

# --- Переменные Настройки Движения ---
@export var max_speed = 1000.0
@export var acceleration = 40.0
@export var friction = 37.0
# Jump Velocity теперь определяет МАКСИМАЛЬНУЮ высоту прыжка
@export var jump_velocity = -800.0 
var gravity = 1000.0

@export_range(0.0, 1.0) var air_control_factor = 0.8
@export var fall_gravity_multiplier = 1.3
@export var jump_hang_gravity_multiplier = 1.0

# --- Переменные Камеры ---
@export var camera_max_offset_x = 150.0
@export var camera_lerp_speed = 25.0

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


func _ready():
	# Настройки узлов Timer...
	pass


func _physics_process(delta):
	# --- ИЗМЕНЕННЫЙ БЛОК: Гравитация и Переменный Прыжок ---
	# Мы немного перестраиваем логику для лучшего контроля

	# Если игрок отпускает кнопку прыжка в момент взлета, "обрубаем" скорость
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		# Мы не ставим скорость в 0, а просто сильно ее уменьшаем (например, вдвое),
		# чтобы прыжок не прерывался слишком резко.
		velocity.y *= 0.5
		
	# Применяем гравитацию
	if velocity.y > 0:
		velocity.y += gravity * fall_gravity_multiplier * delta
	else:
		velocity.y += gravity * jump_hang_gravity_multiplier * delta
	# ------------------------------------

	# --- Буферизация Прыжка ---
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer.start()

	# --- Выполнение Прыжка ---
	if not jump_buffer_timer.is_stopped() and is_on_floor():
		velocity.y = jump_velocity
		jump_buffer_timer.stop()

	# --- Проверка Приземления для Тряски Камеры ---
	if is_on_floor() and was_in_air:
		start_camera_shake(landing_shake_strength, landing_shake_duration)
	was_in_air = not is_on_floor()

	# --- Движение Влево-Вправо ---
	var direction = Input.get_axis("ui_left", "ui_right")
	var current_acceleration = acceleration
	if not is_on_floor():
		current_acceleration *= air_control_factor

	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, current_acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, friction)
	
	move_and_slide()
	update_camera_offset(delta)


# Эта функция вызывается в _physics_process
func update_camera_offset(delta):
	# Рассчитываем целевое смещение от скорости
	var target_offset_x = - (velocity.x / max_speed) * camera_max_offset_x
	
	# Плавно двигаем текущее смещение к целевому.
	# Это смещение будет комбинироваться со смещением от тряски в _process.
	var final_offset_x = lerp(camera.offset.x, target_offset_x, camera_lerp_speed * delta)
	
	# Применяем итоговое смещение по X.
	# Ось Y будет управляться только функцией тряски.
	camera.offset.x = final_offset_x


# Эта функция запускает тряску
func start_camera_shake(strength, duration):
	self.current_shake_strength = strength
	camera_shake_timer.wait_time = duration
	camera_shake_timer.start()


# _process используется для визуальных эффектов, не зависящих от физики
func _process(delta):
	if not camera_shake_timer.is_stopped():
		# Если таймер тряски работает...
		var random_offset_x = randf_range(-current_shake_strength, current_shake_strength)
		var random_offset_y = randf_range(-current_shake_strength, current_shake_strength)
		
		# Прибавляем случайное смещение к камере.
		# Это не перезапишет смещение от скорости, а добавится к нему.
		camera.offset.x += random_offset_x
		camera.offset.y = random_offset_y
	else:
		# Если таймер не работает, сбрасываем силу тряски...
		self.current_shake_strength = 0.0
		# ...и плавно возвращаем камеру в центр по оси Y.
		camera.offset.y = lerp(camera.offset.y, 0.0, camera_lerp_speed * delta)

# Пустая функция для сигнала timeout от CameraShakeTimer
# Ты должен подключить этот сигнал к этой функции в редакторе
func _on_camera_shake_timer_timeout():
	pass
