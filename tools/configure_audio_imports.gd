extends SceneTree

func _initialize() -> void:
	for folder in ["ambience","sfx","ui"]:
		var directory := DirAccess.open("res://assets/audio/"+folder)
		for filename in directory.get_files():
			if filename.get_extension() not in ["wav","ogg"]:continue
			var path: String = "res://assets/audio/"+folder+"/"+filename+".import"
			var settings := ConfigFile.new()
			if settings.load(path)!=OK:continue
			if filename.ends_with(".wav"):settings.set_value("params","compress/mode",0)
			else:settings.set_value("params","loop",true)
			settings.save(path)
	quit()
