extends Control

@onready var background: WorldMap = $"../../WorldMap"
@onready var play_button: Button = $Panel/Play
@onready var quit_button: Button = $Panel/Quit
@onready var github_button: TextureButton = $Github_Button

func _on_play_pressed() -> void:
	for thread in background.threads:
		WorkerThreadPool.wait_for_task_completion(thread)
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_github_button_pressed() -> void:
	OS.shell_open("https://github.com/Eugene0-dev/TeamTestProject")
