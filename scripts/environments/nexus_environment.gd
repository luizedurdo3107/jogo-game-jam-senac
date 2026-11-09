extends "res://scripts/environments/recife_environment.gd"

var station_id := "nexus"
var fog_root: Node3D
var gate_opened := false

func _build_world() -> void:
	super._build_world()
	for child in get_children():
		if child is Label3D:
			if child.text.begins_with("CAPIBARIBE"):child.text = "NEXUS / LOGÍSTICA PORTUÁRIA"
			elif child.text=="COMPORTA 04":child.text = "PAINEL NEXUS"
	fog_root = Node3D.new()
	add_child(fog_root)
	for position_x in [3,10,17,24,31]:
		box(Vector3(position_x,1.3,-7),Vector3(4.5,2.6,2.5),Color("4f435e"))
		box(Vector3(position_x,3.2,-8),Vector3(4.5,1.1,2.5),Color("343e58"))
		for rib in range(9):
			box(Vector3(position_x-2+rib*0.5,1.3,-5.72),Vector3(0.04,2.4,0.05),Color("786d7e"))
	for position_x in [6,29]:
		box(Vector3(position_x,7,-12),Vector3(0.45,14,0.6),Color("86785c"))
		box(Vector3(position_x+3,13,-12),Vector3(8,0.45,0.6),Color("b59b64"))
		box(Vector3(position_x+5,9.3,-12),Vector3(0.06,7,0.06),Color("858b9f"))
	floor_piece(9.8,26,2.6)
	add_ladder(24.5,0,2.6)
	sign_text("PORTO DO RECIFE / ARCA-01",Vector3(18,9,-9),40,TEAL)
	sign_text("SALA TÉCNICA / ↓",Vector3(13.3,1.7,0.7),22,GOLD)
	var ark := SphereMesh.new()
	ark.radius = 2.3
	ark.height = 4.6
	ark.radial_segments = 16
	ark.rings = 8
	var ship := mesh(self,ark,Vector3(26,14,-17),Color("929eb7"))
	ship.scale = Vector3(4,0.7,1)
	for position_x in [21,26,31]:
		box(Vector3(position_x,13.5,-14.8),Vector3(1.5,0.2,0.1),TEAL,true)

func update_state(journey: Node, instant := false) -> void:
	if journey.value("nexus_open")==1 and not gate_opened:
		gate_opened = true
		open_gate()
		if instant:gate_visual.position.y = 3.6
