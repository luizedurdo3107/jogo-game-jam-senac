extends "res://tools/mvp_capture.gd"

const ACTION_EDIT := "res://outputs/pitch/acao_edit/"
var cinematic := false

func _process(delta: float) -> void:
	if cinematic:
		frame += 1
		if is_instance_valid(world):
			world.hud.hide()
			if world.shot==1:
				world.camera.position.y = lerpf(world.camera.position.y,world.ship.position.y+3,delta*3)
				world.camera.look_at(Vector3(22,world.ship.position.y,-3))
		return
	super._process(delta)
	if is_instance_valid(world) and world.get("region_id")!="nova_eden":world.hud.header.hide()

func _release() -> void:
	super._release()
	Input.action_release("attack")

func _clip(name: String, start: int, seconds: float, location: String) -> void:
	await _until(start+roundi(seconds*FPS))
	_release()
	shots.append({"name":name,"start_frame":start,"frames":roundi(seconds*FPS),"location":location})

func _camera(center: Vector3, size := 11.8) -> void:
	world.set_process(false)
	world.camera.size = size
	world.camera.position = center+Vector3(2,5.2,23)
	world.camera.look_at(center+Vector3(0,0,-1))

func _fight_captain() -> void:
	var deadline := frame+FPS*55
	var previous_life := 6
	while world.combat.mask!=7:
		if world.finished or frame>=deadline:
			print("ACTION STOP / hero=",world.combat.life," / position=",world.player.position," / captain=",world.combat.soldiers[2])
			_verify(false,"Piloto de combate não concluiu o confronto")
			return
		var enemy: Dictionary = world.combat.soldiers[2]
		var clock := float(enemy.clock)
		var warning_end: float = world.combat._windup(enemy)+0.68
		var target: float = enemy.body.position.x-(3.0 if clock>0 and clock<warning_end else 1.88)
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(target-world.player.position.x)>0.12:Input.action_press("move_right" if target>world.player.position.x else "move_left")
		var separation: float = enemy.body.position.x-world.player.position.x
		if (clock<=0 or clock>=warning_end) and separation>0.2 and separation<2.12 and world.combat.stamina>=2 and world.combat.cooldown<=0:
			Input.action_release("move_left")
			Input.action_press("move_right")
			await _tap("attack")
		else:await _wait(1.0/FPS)
		if enemy.life!=previous_life:
			print("ACTION HIT / captain=",enemy.life," / hero=",world.combat.life," / frame=",frame)
			previous_life = enemy.life
	_release()
	_verify(world.combat.life>0 and StationJourney.value("nova_security")==7,"Capitão derrotado com F no Difícil, sem alterar vida ou dano")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ACTION_EDIT)
	DirAccess.make_dir_recursive_absolute("res://outputs/pitch/capturas_acao")
	SceneRouter.test_mode = true
	StationJourney.persistence_enabled = false
	GameState.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	AudioDirector.set_muted(false)
	AudioDirector.set_volume("Master",0.8,false)
	AudioDirector.set_volume("Ambience",0.65,false)
	AudioDirector.set_volume("SFX",0.9,false)
	AudioDirector.set_volume("UI",0.25,false)
	StationJourney.reset()
	for item in [["intro_seen",1],["nova_contact",1],["nova_armory",3],["nova_weapon",1],["nova_security",3],["nova_difficulty",1]]:StationJourney.put(item[0],item[1])
	await _checkpoint("nova_eden","nova",Vector3(22.5,0.05,0))
	var battle_start := frame
	await _fight_captain()
	var defeated_at := frame
	await _wait(1.4)
	if frame<battle_start+12*FPS:
		Input.action_press("move_right")
		await _until(battle_start+12*FPS)
		_release()
	await _clip("01_combate",battle_start,4,"NOVA ÉDEN · COMBATE")
	await _clip("02_capitao",maxi(battle_start+4*FPS,defeated_at-roundi(6.6*FPS)),8,"CAPITÃO VAREK · CONFRONTO FINAL")
	var escape_start := frame
	await _walk_to(34.3)
	await _tap("interact")
	_verify(StationJourney.stage=="ruins","Saída física de Nova Éden alcançou Recife")
	await _wait(0.2)
	await _until(escape_start+3*FPS)
	await _clip("03_saida_cidade",frame-3*FPS,3,"FORA DA CÚPULA")

	for flag in ["ruins_contact","ruins_water","ruins_gate","ruins_drone"]:StationJourney.put(flag,1)
	await _checkpoint("recife","ruins",Vector3(24.8,0.05,0))
	var recife_start := frame
	await _walk_to(31.8)
	await _tap("interact")
	_verify(StationJourney.stage=="intro","Passagem final do Recife levou ao laboratório")
	await _clip("04_recife_final",recife_start,3,"RECIFE · RUMO A GAIA")

	for flag in ["recife_awake","recife_scan","recife_cell","recife_power"]:StationJourney.put(flag,1)
	await _checkpoint("laboratory","intro",Vector3(25.4,0.05,0))
	var laboratory_start := frame
	await _tap("perspective")
	await _tap("interact")
	_verify(GameState.has_flag("recife_authorized"),"GAIA autorizou a saída do laboratório")
	await _tap("interact")
	await _tap("perspective")
	await _walk_to(26.9)
	await _tap("interact")
	_verify(GameState.has_flag("recife_gate"),"Mecanismo físico abriu a comporta do laboratório")
	await _tap("interact")
	await _wait(0.8)
	await _walk_to(31.8)
	await _tap("interact")
	_verify(StationJourney.stage=="stations","Fim do laboratório alcançou Capibaribe")
	await _clip("05_laboratorio_final",laboratory_start,5,"GAIA + CORPO · COMPORTA LIBERADA")

	_system("water",["drain","module","install","valve_a","valve_a","valve_b","valve_b","authorize"],"water_route",1)
	await _checkpoint("water","stations",Vector3(19.8,0.05,0))
	var water_start := frame
	await _tap("interact")
	await _wait(1.4)
	_verify(world.environment.reservoir.scale.y>3.2,"Bomba encheu o reservatório no final de Capibaribe")
	await _walk_to(30.9)
	await _tap("interact")
	await _click("Água para a comunidade")
	await _tap("interact")
	_verify(StationJourney.choices.water=="RESTORE","Núcleo de água destinado à comunidade")
	await _clip("06_capibaribe_final",water_start,5,"CAPIBARIBE · ÁGUA RECUPERADA")

	_system("soil",["filter","install","humidity"])
	var soil := _system("soil",[],"soil_capsules",10)
	assert(soil.configure("soil_temperature",1).ok)
	assert(soil.interact("authorize").ok)
	await _checkpoint("soil","stations",Vector3(22.9,0.05,0))
	_camera(Vector3(24.2,2.5,0),12.0)
	await _tap("interact")
	_verify(StationJourney.value("soil_irrigation")==1,"Irrigação foi iniciada pelo corpo")
	await _walk_to(30.9)
	await _tap("interact")
	await _click("Sementes para a estufa")
	await _tap("interact")
	var soil_start := frame
	await _walk_to(19.8)
	await _wait(0.5)
	_verify(StationJourney.choices.soil=="RESTORE" and world.environment.young_plants[1].scale.y>0.66,"Broto cresceu após restaurar o Banco Verde")
	Input.action_press("move_left")
	await _clip("07_banco_verde_final",soil_start,5,"BANCO VERDE · A VIDA VOLTA")

	var air := _system("air",["scan","module","install","coarse","carbon","filter"])
	assert(air.configure("air_team",0).ok)
	await _checkpoint("air","stations",Vector3(14.8,7.85,0))
	_camera(Vector3(19,8.5,0),11.8)
	var air_start := frame
	await _tap("perspective")
	await _tap("interact")
	_verify(StationJourney.value("air_sequence")==3,"Último estágio ligou a turbina de Atmos")
	await _tap("perspective")
	await _walk_to(21.9)
	await _tap("interact")
	await _click("Ar limpo para os bairros")
	await _tap("interact")
	await _wait(2.1)
	_verify(StationJourney.choices.air=="RESTORE" and world.environment.fan_speed==1.0,"Filtragem acelerou e a névoa recuou em Atmos")
	await _clip("08_atmos_final",air_start,5,"ATMOS · AR PARA A CIDADE")

	_system("nexus",["nexus_voss"])
	await _checkpoint("nexus","nexus",Vector3(31.8,0.05,0))
	var choice_start := frame
	await _tap("interact")
	await _wait(0.35)
	await _click("Partir para Marte")
	await _wait(0.35)
	await _click("Confirmar")
	_verify(StationJourney.stage=="boss" and StationJourney.value("final_destination")==2,"Escolha real de partir ativou a contenção terrestre")
	await _clip("09_partir",choice_start,2,"")

	StationJourney.put("boss_mask",3)
	StationJourney.put("departure_security",7)
	await _checkpoint("boss","boss",Vector3(21.3,0.05,0))
	while world.hazard_time<9.8:await _wait(1.0/FPS)
	await _walk_to(22.7)
	while world.hazard_time<12.72:await _wait(1.0/FPS)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _wait(0.4)
	Input.action_release("jump")
	await _wait(0.3)
	_release()
	while world.hazard_time<14.24:await _wait(1.0/FPS)
	await _walk_to(23.9)
	await _tap("interact")
	_verify(StationJourney.value("boss_mask")==7,"Bloqueio final desligado depois do pulso")
	await _walk_to(34.4)
	await _tap("interact")
	_verify(StationJourney.stage=="ending" and StationJourney.value("boss_done")==1,"Embarque real foi confirmado depois da contenção")
	_verify(world.hits<3 and not world.finished,"Contenção superada sem reiniciar ou alterar dano e invulnerabilidade")
	await _clip("10_fuga_terra",frame-6*FPS,6,"TERRA · SUPERE O BLOQUEIO")

	_release()
	SceneRouter.prepare_scene(world)
	world.queue_free()
	await _wait(0.2)
	_verify(StationJourney.validate(StationJourney.snapshot()),"Estado final de Marte válido")
	world = load(StationJourney.SCENES.ending).instantiate()
	cinematic = true
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await _wait(0.2)
	_verify(not world.earth and world.shot==0,"Cinemática original de embarque carregada")
	var boarding_start := frame
	await _clip("11_embarque",boarding_start,3,"ARCA-01 · EMBARQUE")
	var launch_start := frame
	await _tap("interact")
	_verify(world.shot==1,"Decolagem original iniciada")
	await _clip("12_decolagem",launch_start,4.5,"DEIXANDO A TERRA")
	while world.shot==1:await _wait(1.0/FPS)
	_verify(world.shot==2,"A Terra ficou para trás na sequência original")
	var earth_start := frame
	await _clip("13_terra_distancia",earth_start,4.5,"RUMO A MARTE")
	_write_edit()
	print("ACTION CAPTURE COMPLETE / 58 seconds / ",evidence.size()," verificações")
	await AudioDirector.quit_game()

func _edit_only() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ACTION_EDIT+"planos.json"))
	shots.assign(manifest.shots)
	evidence.assign(manifest.evidence)
	_write_edit()
	get_tree().quit()

func _write_edit() -> void:
	for shot in shots:
		if shot.name=="02_capitao":shot.location = "CAPITÃO VAREK · CONFRONTO FINAL"
	FileAccess.open(ACTION_EDIT+"planos.json",FileAccess.WRITE).store_string(JSON.stringify({"fps":FPS,"shots":shots,"evidence":evidence},"  "))
	FileAccess.open(ACTION_EDIT+"titulo.txt",FileAccess.WRITE).store_string("LAST SIGNAL: EARTH_404")
	var commands: Array[String] = ["#!/usr/bin/env bash","set -euo pipefail","cd '"+ProjectSettings.globalize_path("res://")+"'"]
	var concat: Array[String] = []
	for index in range(shots.size()):
		var shot: Dictionary = shots[index]
		var seconds := float(shot.frames)/FPS
		var raw := "outputs/pitch/capturas_acao/"+str(shot.name)+".mkv"
		var base := "outputs/pitch/acao_edit/%02d"%index
		FileAccess.open("res://"+base+"_local.txt",FileAccess.WRITE).store_string(shot.location)
		var video := "setsar=1,format=yuv420p"
		if not str(shot.location).is_empty():
			video += ",drawbox=x=1050:y=64:w=806:h=76:color=0x091521@0.88:t=fill:enable='lt(t,1.5)'"
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile='%s_local.txt':fontsize=29:fontcolor=0xB2F0E1:x=1080:y=87:enable='lt(t,1.5)'"%base
		if index==0:
			video += ",drawbox=x=64:y=922:w=1320:h=104:color=0x091521@0.88:t=fill:enable='lt(t,2)'"
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile=outputs/pitch/acao_edit/titulo.txt:fontsize=56:fontcolor=white:x=96:y=950:enable='lt(t,2)'"
		if index==shots.size()-1:
			video += ",drawbox=x=420:y=840:w=1080:h=130:color=0x091521@0.88:t=fill:enable='gte(t,2.6)'"
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile=outputs/pitch/acao_edit/titulo.txt:fontsize=56:fontcolor=white:x=(w-tw)/2:y=879:enable='gte(t,2.6)'"
		video += ",fade=t=in:st=0:d=0.06,fade=t=out:st=%.6f:d=0.06"%(seconds-0.06)
		FileAccess.open("res://"+base+".filtro",FileAccess.WRITE).store_string(video)
		commands.append("echo 'Ação %02d / %s'"%[index+1,shot.name])
		commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -ss %.6f -i outputs/pitch/acao_bruta.avi -frames:v %d -c:v copy -c:a pcm_s16le -ar 48000 '%s'"%[float(shot.start_frame)/FPS,shot.frames,raw])
		commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -i '%s' -t %.6f -vf \"$(cat %s.filtro)\" -af 'afade=t=in:st=0:d=0.03,afade=t=out:st=%.6f:d=0.06' -c:v libx264 -threads 2 -preset veryfast -crf 17 -pix_fmt yuv420p -r 30 -c:a pcm_s16le -ar 48000 %s.mkv"%[raw,seconds,base,seconds-0.06,base])
		concat.append("file '%02d.mkv'"%index)
	FileAccess.open(ACTION_EDIT+"concat.txt",FileAccess.WRITE).store_string("\n".join(concat)+"\n")
	commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -f concat -safe 0 -i outputs/pitch/acao_edit/concat.txt -vf 'fade=t=out:st=57.4:d=0.6' -af 'loudnorm=I=-21:TP=-2:LRA=9,aresample=48000,afade=t=out:st=57.4:d=0.6' -c:v libx264 -threads 2 -preset fast -crf 19 -profile:v main -level:v 4.0 -bf 0 -refs 2 -g 60 -keyint_min 30 -pix_fmt yuv420p -r 30 -fps_mode cfr -c:a aac -b:a 160k -ar 48000 -movflags +faststart -video_track_timescale 30000 -t 58 outputs/pitch/acao_edit/final_validavel.mp4")
	commands.append("mv outputs/pitch/acao_edit/final_validavel.mp4 outputs/pitch/LAST_SIGNAL_COMBATE_E_FUGA_58S.mp4")
	FileAccess.open(ACTION_EDIT+"renderizar.sh",FileAccess.WRITE).store_string("\n".join(commands)+"\n")
