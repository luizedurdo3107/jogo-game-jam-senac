extends "res://scripts/environments/nova_environment.gd"

func _build_world() -> void:
	super._build_world()
	for child in get_children():
		if child is Label3D:
			if child.text=="NOVA ÉDEN":child.text = "DOCAS / ARCA-01"
			elif child.text=="OXIGÊNIO É CIDADANIA":child.text = "GAIA / RECUPERAR A TERRA"
			elif child.text.begins_with("SETOR 01"):child.text = "EXÉRCITO / EMBARQUE PROIBIDO"
			elif child.text.begins_with("LYRA"):child.hide()
	var ship := Node3D.new()
	ship.set_script(preload("res://scripts/environments/ark_ship.gd"))
	ship.position = Vector3(31,4.5,-7)
	ship.scale = Vector3.ONE*1.2
	add_child(ship)
	for position_x in [26.0,35.0]:
		box(Vector3(position_x,2,-6),Vector3(0.5,4,1.2),Color("3e5267"))
		box(Vector3(position_x,4,-6),Vector3(2.6,0.3,1.7),Color("d2a269"))
	box(Vector3(30.5,2.4,-6.2),Vector3(12,0.4,3),Color("253b52"))
	_sign("ARCA-01 / ACESSO À DIREITA",Vector3(31,6.9,-6),Vector2(7,0.7),Color("11283c"),TEAL,27)

func _make_armory() -> void:
	_sign("EQUIPAMENTO / BASTÃO [E]",Vector3(5,2.6,-1.4),Vector2(4,0.65),Color("1c2c40"),TEAL,25)
	weapon_display = make_baton(self,Vector3(5,1.1,-1.4))
	box(Vector3(5,0.6,-1.8),Vector3(1.6,1.2,0.55),Color("30465d"))
