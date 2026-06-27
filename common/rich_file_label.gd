class_name RichFileLabel
extends RichTextLabel

##########################################################
## A label that replaces its text with the contents of a file
## if the file exists. If not, it keeps the existing text.
##########################################################


## Path to the file that will define this label's text if present
@export_file("*.txt") var file_path: String


func _ready() -> void:
	if file_path and FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		text = file.get_as_text()
