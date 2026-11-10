extends Node

const FPS := 30
const OUTPUT := "res://outputs/pitch/"
const EDIT := OUTPUT+"mvp_edit/"
const ACTIONS := ["move_left","move_right","jump","climb_up","climb_down","interact","perspective"]

var world: Node3D
var frame := 0
var shot_start := 0
var shots: Array[Dictionary] = []
var evidence: Array[Dictionary] = []

func _ready() -> void:
	process_priority = 1000
	call_deferred("_edit_only" if "--edit-only" in OS.get_cmdline_user_args() else "_run")

func _process(_delta: float) -> void:
	frame += 1
	if not is_instance_valid(world) or not world.get("hud"):return
	var hud: CanvasLayer = world.hud
	hud.toast_time = 0
	hud.toast.hide()
	hud.interaction_panel.hide()
	hud.header.offset_left = 48
	hud.header.offset_top = 30
	var columns: HBoxContainer = hud.header.get_child(0)
	columns.get_child(2).hide()
	columns.get_child(3).hide()
	if hud.get("diagnostic_panel"):hud.diagnostic_panel.hide()

func _wait(seconds: float) -> void:
	await _until(frame+roundi(seconds*FPS))

func _until(target: int) -> void:
	while frame<target:await get_tree().process_frame

func _release() -> void:
	for action in ACTIONS:Input.action_release(action)

func _tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	get_viewport().push_input(press)
	await _wait(1.0/FPS)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	get_viewport().push_input(release)
	await _wait(1.0/FPS)

func _walk_to(destination: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	var direction := "move_right" if destination>world.player.position.x else "move_left"
	Input.action_press(direction)
	var deadline := frame+FPS*5
	while absf(world.player.position.x-destination)>0.1:
		assert(frame<deadline,"Movimentação bloqueada no plano")
		await _wait(1.0/FPS)
	Input.action_release(direction)
	await _wait(0.1)

func _click(prefix: String) -> void:
	var found: Button
	for control in world.hud.modal_box.find_children("*","Button",true,false):
		if control.text.begins_with(prefix):found = control
	assert(is_instance_valid(found),"Botão real ausente: "+prefix)
	await _wait(0.1)
	var at := found.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var mouse := InputEventMouseButton.new()
		mouse.position = at
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = pressed
		get_viewport().push_input(mouse,true)
		await _wait(1.0/FPS)

func _verify(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_release()
		get_tree().quit(1)
		return
	evidence.append({"frame":frame,"region":StationJourney.region(),"check":description,"ok":condition})
	print("MVP VERIFIED: ",description)

func _checkpoint(region: String, stage: String, point: Vector3) -> void:
	_release()
	if is_instance_valid(world):
		SceneRouter.prepare_scene(world)
		world.queue_free()
		await _wait(0.2)
	StationJourney.stage = stage
	if region in StationJourney.ORDER:StationJourney.station = region
	StationJourney.checkpoints[region] = [point.x,point.y]
	_verify(StationJourney.validate(StationJourney.snapshot()),"Checkpoint válido / "+region)
	world = load(StationJourney.SCENES[region]).instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	world.hud.touch.persistence_enabled = false
	world.hud.touch.set_manual_mode(2)
	if world.hud.modal_open:world.hud.close_modal()
	await _wait(0.9)
	shot_start = frame
	print("MVP SHOT: ",region," / ",frame)

func _end(name: String, seconds: float, message: String, location: String, style := "caption") -> void:
	assert(frame<=shot_start+roundi(seconds*FPS),"Plano excedeu o tempo: "+name)
	await _until(shot_start+roundi(seconds*FPS))
	_release()
	shots.append({"name":name,"start_frame":shot_start,"frames":roundi(seconds*FPS),"message":message,"location":location,"style":style})

func _system(region: String, commands: Array, panel := "", argument := 0) -> RefCounted:
	var system: RefCounted = load("res://scripts/puzzles/%s_system.gd"%region).new()
	system.journey = StationJourney
	if not panel.is_empty():assert(system.configure(panel,argument).ok)
	for command in commands:assert(system.interact(command).ok)
	return system

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(EDIT)
	DirAccess.make_dir_recursive_absolute(OUTPUT+"capturas")
	SceneRouter.test_mode = true
	StationJourney.persistence_enabled = false
	GameState.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	AudioDirector.set_muted(false)
	AudioDirector.set_volume("Master",0.8,false)
	AudioDirector.set_volume("Ambience",0.65,false)
	AudioDirector.set_volume("SFX",0.85,false)
	AudioDirector.set_volume("UI",0.3,false)
	StationJourney.reset()
	StationJourney.put("intro_seen",1)
	StationJourney.put("nova_armory",3)
	StationJourney.put("nova_weapon",1)
	StationJourney.put("nova_security",7)
	for flag in ["nova_contact","nova_open","nova_escaped"]:StationJourney.put(flag,1)
	await _checkpoint("recife","ruins",Vector3(5,0.05,0))
	world.hud.hide()
	await _wait(3.7)
	Input.action_press("move_right")
	await _end("01_abertura",5,"LAST SIGNAL: EARTH_404","Recife, 2187.","opening")

	StationJourney.reset()
	StationJourney.put("intro_seen",1)
	await _checkpoint("nova_eden","nova",Vector3(2,0.05,0))
	Input.action_press("move_right")
	await _wait(1.8)
	Input.action_release("move_right")
	await _end("02_nova_eden",3,"A Terra está à beira do colapso.","NOVA ÉDEN / CIDADE SOB A CÚPULA")

	StationJourney.put("nova_armory",3)
	StationJourney.put("nova_weapon",1)
	StationJourney.put("nova_security",7)
	for flag in ["nova_contact","nova_open","nova_escaped","ruins_contact"]:StationJourney.put(flag,1)
	await _checkpoint("recife","ruins",Vector3(2.8,0.05,0))
	Input.action_press("move_right")
	await _wait(1.1)
	Input.action_press("jump")
	await _wait(0.4)
	Input.action_release("jump")
	await _wait(2.5)
	Input.action_release("move_right")
	_verify(world.player.position.x>17,"Caminhada e salto com física no Recife")
	await _end("03_recife",5,"A Terra está à beira do colapso.","RECIFE ANTIGO / MARCO ZERO")

	await _checkpoint("recife","ruins",Vector3(7.6,0.05,0))
	await _walk_to(8.9)
	await _tap("interact")
	_verify(GameState.has_flag("ruins_water"),"E acionou a bomba comunitária por proximidade")
	await _wait(0.8)
	await _tap("interact")
	await _walk_to(11)
	Input.action_press("climb_up")
	await _wait(1.1)
	Input.action_release("climb_up")
	_verify(world.player.position.y>2.5,"Subida real até a passarela")
	Input.action_press("move_right")
	await _wait(0.7)
	Input.action_press("jump")
	await _wait(0.4)
	Input.action_release("jump")
	await _walk_to(18.2)
	await _tap("interact")
	_verify(GameState.has_flag("ruins_drone"),"Interação da passarela redirecionou a inspeção")
	await _wait(0.9)
	await _tap("interact")
	Input.action_press("move_right")
	await _wait(0.4)
	_release()
	await _walk_to(21)
	Input.action_press("climb_down")
	await _wait(1.05)
	Input.action_release("climb_down")
	Input.action_press("move_left")
	await _end("04_exploracao",9,"Explore um Recife transformado.","RUA, ESCADAS E PASSARELAS")

	for flag in StationJourney.INTRO_FLAGS:StationJourney.put(flag,1)
	await _checkpoint("water","stations",Vector3(4.8,0.05,0))
	await _wait(0.8)
	await _tap("perspective")
	_verify(world.perspectives.active,"Q revelou a rede GAIA")
	await _wait(1.1)
	await _tap("interact")
	_verify(world.hud.modal_open,"E abriu o seletor exclusivo de GAIA")
	await _wait(1.4)
	await _click("B / Filtro")
	_verify(StationJourney.value("water_route")==1,"Clique no botão real conectou o filtro comunitário")
	await _walk_to(8.9)
	await _tap("interact")
	_verify(StationJourney.value("water_drained")==1,"Comando digital drenou a câmara inferior")
	await _wait(1.7)
	await _tap("perspective")
	_verify(not world.perspectives.active,"Retorno ao físico com drenagem preservada")
	Input.action_press("move_right")
	await _wait(0.3)
	_release()
	await _end("05_gaia",10,"Duas perspectivas. Novas possibilidades.","CAPIBARIBE / REDE DIGITAL E DRENAGEM")

	_system("water",["module","install","valve_a","valve_a","valve_b","valve_b","authorize"])
	await _checkpoint("water","stations",Vector3(18.7,0.05,0))
	await _walk_to(19.9)
	await _tap("interact")
	_verify(StationJourney.value("water_pump")==1,"E ligou a bomba física validada por GAIA")
	await _wait(1.6)
	_verify(world.environment.reservoir.scale.y>3.2,"Reservatório encheu após a ação física")
	Input.action_press("move_right")
	await _wait(0.5)
	_release()
	await _end("06_bomba",4,"Cada ação transforma o ambiente.","CAPIBARIBE / BOMBA EM FUNCIONAMENTO")
	assert(StationJourney.decide("RESTORE"))

	_system("soil",["filter","install","humidity"])
	await _checkpoint("soil","stations",Vector3(10.8,2.65,0))
	await _tap("perspective")
	await _tap("interact")
	_verify(world.hud.modal_open,"Seletor real de sementes acessível em GAIA")
	await _wait(0.4)
	await _click("B / viabilidade")
	await _wait(0.3)
	await _click("D / viabilidade")
	await _wait(0.3)
	await _click("Aplicar rede")
	_verify(StationJourney.value("soil_mask")==10,"Botões reais selecionaram somente B e D")
	await _end("07_sementes",3,"Cada ação transforma o ambiente.","BANCO VERDE / SEMENTES VIÁVEIS")
	var soil := _system("soil",[],"soil_temperature",1)
	assert(soil.interact("authorize").ok)
	assert(soil.interact("irrigate").ok)
	assert(StationJourney.decide("RESTORE"))

	var air := _system("air",["scan","module","install","coarse","carbon","turbine","filter"])
	assert(air.configure("air_team",0).ok)
	StationJourney.station = "air"
	assert(StationJourney.decide("RESTORE"))
	await _checkpoint("air","stations",Vector3(8,0.05,0))
	await _wait(0.3)
	await _tap("interact")
	_verify(world.lift_moving,"E iniciou o elevador da Torre Atmos")
	await _wait(1.8)
	_verify(world.player.position.y>2.4,"Elevador transportou o personagem sem teleporte")
	Input.action_press("move_right")
	await _wait(0.3)
	_release()
	await _end("08_atmos",3,"Cada ação transforma o ambiente.","ATMOS / FILTRAGEM E TRANSPORTE VERTICAL")

	_system("nexus",["nexus_voss"])
	await _checkpoint("nexus","nexus",Vector3(28.6,0.05,0))
	Input.action_press("move_right")
	await _wait(0.45)
	Input.action_press("jump")
	await _wait(0.35)
	Input.action_release("jump")
	await _walk_to(31.8)
	await _until(shot_start+roundi(3.2*FPS))
	await _tap("interact")
	_verify(world.hud.modal_open,"Transmissor abriu a decisão real entre Terra e Marte")
	await _end("09_escolha",9,"Restaurar a Terra ou partir?","NEXUS / UMA DECISÃO HUMANA")

	StationJourney.reset()
	StationJourney.put("intro_seen",1)
	StationJourney.put("nova_armory",3)
	StationJourney.put("nova_weapon",1)
	StationJourney.put("nova_security",7)
	for flag in ["nova_contact","nova_open","nova_escaped"]:StationJourney.put(flag,1)
	await _checkpoint("recife","ruins",Vector3(11.5,2.65,0))
	world.hud.hide()
	Input.action_press("move_right")
	await _wait(1.3)
	_release()
	await _end("10_encerramento",7,"LAST SIGNAL: EARTH_404","O futuro depende das suas escolhas.","closing")
	_write_edit()
	print("MVP CAPTURE COMPLETE / 58 seconds / ",evidence.size()," verificações")
	await AudioDirector.quit_game()

func _edit_only() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EDIT+"planos.json"))
	shots.assign(manifest.shots)
	evidence.assign(manifest.evidence)
	_write_edit()
	get_tree().quit()

func _write_edit() -> void:
	FileAccess.open(EDIT+"planos.json",FileAccess.WRITE).store_string(JSON.stringify({"fps":FPS,"shots":shots,"evidence":evidence},"  "))
	var commands: Array[String] = ["#!/usr/bin/env bash","set -euo pipefail","cd '"+ProjectSettings.globalize_path("res://")+"'"]
	var concat: Array[String] = []
	for index in range(shots.size()):
		var shot: Dictionary = shots[index]
		var seconds := float(shot.frames)/FPS
		var raw := "outputs/pitch/capturas/"+str(shot.name)+".mkv"
		var base := "outputs/pitch/mvp_edit/%02d"%index
		FileAccess.open("res://"+base+"_mensagem.txt",FileAccess.WRITE).store_string(shot.message)
		FileAccess.open("res://"+base+"_local.txt",FileAccess.WRITE).store_string(shot.location)
		var video := "setsar=1,format=yuv420p"
		if shot.style=="caption":
			video += ",drawbox=x=0:y=900:w=iw:h=180:color=0x091521@0.94:t=fill"
			video += ",drawbox=x=96:y=924:w=4:h=80:color=0x82EAD7:t=fill"
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:textfile='%s_local.txt':fontsize=22:fontcolor=0x82EAD7:x=120:y=919"%base
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile='%s_mensagem.txt':fontsize=42:fontcolor=white:x=120:y=959"%base
			if shot.name=="09_escolha":
				video = video.replace(":t=fill",":t=fill:enable='lt(t,3)'")
				video = video.replace(":x=120:y=919",":x=120:y=919:enable='lt(t,3)'")
				video = video.replace(":x=120:y=959",":x=120:y=959:enable='lt(t,3)'")
		else:
			video += ",drawbox=x=64:y=72:w=1470:h=250:color=0x091521@0.88:t=fill"
			video += ",drawbox=x=96:y=116:w=4:h=160:color=0x82EAD7:t=fill"
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile='%s_mensagem.txt':fontsize=72:fontcolor=white:x=124:y=130"%base
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:textfile='%s_local.txt':fontsize=40:fontcolor=0x82EAD7:x=128:y=241"%base
		video += ",fade=t=in:st=0:d=0.16,fade=t=out:st=%.6f:d=0.12"%(seconds-0.12)
		FileAccess.open("res://"+base+".filtro",FileAccess.WRITE).store_string(video)
		commands.append("echo 'Plano %02d / %s'"%[index+1,shot.name])
		commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -ss %.6f -i outputs/pitch/mvp_bruta.avi -frames:v %d -c:v copy -c:a pcm_s16le -ar 48000 '%s'"%[float(shot.start_frame)/FPS,shot.frames,raw])
		commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -i '%s' -t %.6f -vf \"$(cat %s.filtro)\" -af 'afade=t=in:st=0:d=0.04,afade=t=out:st=%.6f:d=0.08' -c:v libx264 -threads 2 -preset veryfast -crf 17 -pix_fmt yuv420p -r 30 -c:a pcm_s16le -ar 48000 %s.mkv"%[raw,seconds,base,seconds-0.08,base])
		concat.append("file '%02d.mkv'"%index)
	FileAccess.open(EDIT+"concat.txt",FileAccess.WRITE).store_string("\n".join(concat)+"\n")
	commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -f concat -safe 0 -i outputs/pitch/mvp_edit/concat.txt -vf 'fade=t=out:st=57.2:d=0.8' -af 'loudnorm=I=-22:TP=-2:LRA=9,aresample=48000,afade=t=out:st=57.2:d=0.8' -c:v libx264 -threads 2 -preset medium -crf 19 -pix_fmt yuv420p -r 30 -c:a aac -b:a 160k -ar 48000 -movflags +faststart -t 58 outputs/pitch/LAST_SIGNAL_MVP_PITCH_60S.mp4")
	FileAccess.open(EDIT+"renderizar.sh",FileAccess.WRITE).store_string("\n".join(commands)+"\n")
