extends Control

var play_button: Button
var quit_button: Button 
var github_button: Button

func _init() -> void:
	play_button = $Panel/Play
	quit_button = $Panel/Quit
	github_button = $Github_Button
	
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_github_button_pressed() -> void:
	OS.shell_open("https://github.com/Eugene0-dev/TeamTestProject")
