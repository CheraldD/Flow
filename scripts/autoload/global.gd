# global.gd (версия с Картой Ввода)
extends Node

func _unhandled_input(event):
	# Просто проверяем, было ли ТОЛЬКО ЧТО нажато действие "toggle_fullscreen"
	if event.is_action_pressed("toggle_fullscreen"):
		var window = get_window()
		if window.mode == Window.MODE_FULLSCREEN:
			window.mode = Window.MODE_WINDOWED
		else:
			window.mode = Window.MODE_FULLSCREEN
