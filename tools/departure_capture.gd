extends "res://tools/mvp_capture.gd"

var cinematic := false

func _process(_delta: float) -> void:
	frame += 1
	if not is_instance_valid(world) or not world.get("hud"):return
	if cinematic:
		world.hud.hide()
		return
	world.hud.toast_time = 0
	world.hud.interaction_panel.hide()
	world.hud.header.offset_left = 48
	world.hud.header.offset_top = 30
	var columns: HBoxContainer = world.hud.header.get_child(0)
	columns.get_child(2).hide()
	columns.get_child(3).hide()
	if world.get("region_id")!="boss" or world.combat.mask==7:world.hud.header.hide()

func _release() -> void:
	super._release()
	Input.action_release("attack")

func _clip(name: String, start: int, seconds: float) -> void:
	await _until(start+roundi(seconds*FPS))
	_release()
	shots.append({"name":name,"start_frame":start,"frames":roundi(seconds*FPS)})

func _fight() -> void:
	var deadline := frame+FPS*100
	var previous_mask := 0
	var last_hit := -1
	while world.combat.mask!=7:
		if world.finished or frame>=deadline:
			print("DEPARTURE STOP / hero=",world.combat.life," / player=",world.player.position," / captain=",world.combat.soldiers[2].body.position," / hp=",world.combat.soldiers[2].life)
			_verify(false,"Piloto não venceu o combate final com comandos normais")
			return
		var index: int = world.combat.current_enemy()
		var enemy: Dictionary = world.combat.soldiers[index]
		if enemy.life!=last_hit:
			print("DEPARTURE HIT / enemy=",index," / hp=",enemy.life," / hero=",world.combat.life," / frame=",frame)
			last_hit = enemy.life
		var clock := float(enemy.clock)
		var warning_end: float = world.combat._windup(enemy)+(0.68 if index==2 else 0.22)
		var target: float = enemy.body.position.x-(3.0 if clock>0 and clock<warning_end else 1.88)
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(target-world.player.position.x)>0.12:Input.action_press("move_right" if target>world.player.position.x else "move_left")
		var separation: float = enemy.body.position.x-world.player.position.x
		if (clock<=0 or clock>=warning_end) and separation>0.2 and separation<2.12 and world.combat.stamina>=2 and world.combat.cooldown<=0:
			Input.action_release("move_left")
			Input.action_press("move_right")
			await _wait(1.0/FPS)
			await _tap("attack")
		else:await _wait(1.0/FPS)
		if world.combat.mask!=previous_mask:
			print("DEPARTURE VICTORY / mask=",world.combat.mask," / hero=",world.combat.life," / frame=",frame)
			_verify(world.combat.life>0,"Soldado derrotado com F, dano e fôlego normais / "+str(index))
			previous_mask = world.combat.mask
	_release()
	_verify(StationJourney.value("departure_security")==7 and world.combat.hard_mode,"Guarnição e comandante vencidos no Difícil, sem alterar vida ou invulnerabilidade")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://outputs/pitch/departure_edit")
	SceneRouter.test_mode = true
	StationJourney.persistence_enabled = false
	GameState.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	AudioDirector.set_muted(false)
	AudioDirector.set_volume("Master",0.8,false)
	StationJourney.reset()
	StationJourney.stage = "stations"
	_system("water",["drain","module","install","valve_a","valve_a","valve_b","valve_b","authorize","pump"],"water_route",1)
	assert(StationJourney.decide("RESTORE"))
	StationJourney.station = "soil"
	var soil := _system("soil",["filter","install","humidity"],"soil_capsules",10)
	assert(soil.configure("soil_temperature",1).ok)
	assert(soil.interact("authorize").ok and soil.interact("irrigate").ok)
	assert(StationJourney.decide("RESTORE"))
	StationJourney.station = "air"
	var air := _system("air",["scan","module","install"])
	assert(air.configure("air_team",0).ok)
	for command in ["coarse","carbon","turbine","filter"]:assert(air.interact(command).ok)
	assert(StationJourney.decide("RESTORE"))
	_system("nexus",["nexus_voss"])
	StationJourney.put("nova_armory",3)
	StationJourney.put("nova_weapon",1)
	StationJourney.put("nova_difficulty",1)
	await _checkpoint("nexus","nexus",Vector3(31.8,0.05,0))
	var decision_start := frame
	await _tap("interact")
	await _wait(1.7)
	await _click("Partir para Marte")
	await _wait(0.8)
	await _click("Confirmar")
	_verify(StationJourney.stage=="boss" and StationJourney.value("departure_started")==1,"Escolha real de Marte exige combate final")
	await _clip("final_nexus",decision_start,4)
	await _checkpoint("boss","boss",Vector3(9.5,0.05,0))
	var battle_start := frame
	await _fight()
	var victory := frame
	await _wait(0.8)
	await _clip("final_soldados",battle_start,3)
	await _clip("final_comandante",victory-roundi(4.2*FPS),5)
	await _walk_to(8)
	await _tap("perspective")
	await _tap("interact")
	await _tap("interact")
	await _tap("perspective")
	await _tap("interact")
	await _walk_to(16)
	await _tap("perspective")
	await _tap("interact")
	await _tap("perspective")
	await _walk_to(24)
	var controls_start := frame
	await _tap("interact")
	_verify(StationJourney.value("boss_mask")==7,"Contenção desativada por comandos reais depois da batalha")
	Input.action_press("move_right")
	await _clip("final_comandos",controls_start,2)
	await _walk_to(34.4)
	await _tap("interact")
	_verify(StationJourney.stage=="ending" and StationJourney.validate(StationJourney.snapshot()),"Embarque confirmado após vitória e contenção")
	SceneRouter.prepare_scene(world)
	world.queue_free()
	await _wait(0.2)
	world = load(StationJourney.SCENES.ending).instantiate()
	cinematic = true
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await _wait(0.2)
	await _clip("final_embarque",frame,3)
	await _tap("interact")
	_verify(world.shot==1 and world.ship.flying,"ARCA-01 detalhada decola com motores e trem recolhido")
	await _clip("final_decolagem",frame,4)
	while world.shot==1:await _wait(1.0/FPS)
	_verify(world.shot==2 and not world.player.visible,"Terra com superfície e nuvens, sem personagem flutuando")
	await _clip("final_terra",frame,6)
	FileAccess.open("res://outputs/pitch/departure_edit/planos.json",FileAccess.WRITE).store_string(JSON.stringify({"fps":FPS,"shots":shots,"evidence":evidence},"  "))
	var commands: Array[String] = ["#!/usr/bin/env bash","set -euo pipefail","cd '"+ProjectSettings.globalize_path("res://")+"'","mkdir -p outputs/pitch/capturas_rc5"]
	for shot in shots:
		commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -ss %.6f -i outputs/pitch/departure_bruta.avi -frames:v %d -c:v copy -c:a pcm_s16le -ar 48000 'outputs/pitch/capturas_rc5/%s.mkv'"%[float(shot.start_frame)/FPS,shot.frames,shot.name])
	FileAccess.open("res://outputs/pitch/departure_edit/extrair.sh",FileAccess.WRITE).store_string("\n".join(commands)+"\n")
	print("DEPARTURE CAPTURE COMPLETE / ",evidence.size()," verificações")
	await AudioDirector.quit_game()
