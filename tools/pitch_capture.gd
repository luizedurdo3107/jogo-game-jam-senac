extends Node

const FPS := 30
const OUTPUT := "res://outputs/pitch/"
const INPUTS := ["move_left","move_right","jump","attack","climb_up","climb_down"]

var world: Node
var frame := 0
var clips: Array[Dictionary] = []
var clip_start := 0

func _ready() -> void:
	call_deferred("_edit_only" if "--edit-only" in OS.get_cmdline_user_args() else "_run")

func _edit_only() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT+"planos.json"))
	clips.assign(manifest.clips)
	_write_edit()
	get_tree().quit()

func _process(_delta: float) -> void:
	frame += 1

func _wait(seconds: float) -> void:
	var target := frame+roundi(seconds*FPS)
	while frame<target:await get_tree().process_frame

func _release() -> void:
	for action in INPUTS:Input.action_release(action)

func _open(region: String, stage: String, point := Vector3(2,0.05,0)) -> void:
	_release()
	if is_instance_valid(world):
		SceneRouter.prepare_scene(world)
		world.queue_free()
		await _wait(0.15)
	GameState.reset()
	StationJourney.stage = stage
	if region in StationJourney.ORDER:StationJourney.station = region
	StationJourney.checkpoints[region] = [point.x,point.y]
	var path := "res://scenes/ui/main_menu.tscn" if region=="menu" else str(StationJourney.SCENES[region])
	world = load(path).instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await _wait(0.4)
	if world.get("hud") and world.hud.get("modal_open")!=null:
		world.hud.touch.persistence_enabled = false
		world.hud.touch.set_manual_mode(2)
		if world.hud.modal_open:world.hud.close_modal()
		world.hud.toast_time = 0
	await _wait(0.1)
	clip_start = frame
	print("PITCH SHOT: ",region," / frame ",frame)

func _end(name: String, title: String, subtitle: String, caption := true) -> void:
	_release()
	clips.append({"name":name,"start_frame":clip_start,"end_frame":frame,"title":title,"subtitle":subtitle,"caption":caption})

func _seed(region: String, commands: Array, panel := "", argument := 0) -> void:
	var system: RefCounted = load("res://scripts/puzzles/%s_system.gd"%region).new()
	system.journey = StationJourney
	if not panel.is_empty():assert(system.configure(panel,argument).ok)
	for command in commands:assert(system.interact(command).ok)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT+"textos")
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
	await _open("menu","cinematic")
	await _wait(4)
	_end("abertura","","",false)

	StationJourney.put("nova_difficulty",1)
	await _open("nova_eden","nova",Vector3(4.8,0.05,0))
	Input.action_press("move_right")
	await _wait(0.4)
	_release()
	assert(world.interact_object("armory"))
	await _wait(1.7)
	for relay in range(3):
		assert(world.armory_relay(relay))
		await _wait(0.35)
	await _wait(0.7)
	assert(world.interact_object("armory"))
	Input.action_press("move_right")
	await _wait(1.4)
	_release()
	world.player.sprite.flip_h = false
	world.attack()
	await _wait(0.55)
	world.attack()
	Input.action_press("jump")
	await _wait(0.4)
	Input.action_release("jump")
	await _wait(0.5)
	world.attack()
	Input.action_press("move_left")
	await _wait(0.4)
	_release()
	await _wait(0.8)
	Input.action_press("move_right")
	await _wait(0.4)
	_release()
	world.player.sprite.flip_h = false
	world.attack()
	await _wait(11.0-float(frame-clip_start)/FPS)
	_end("nova_eden","FUJA DE NOVA ÉDEN","Abra o arsenal. Encontre sua arma. Enfrente o exército.")

	for key in ["nova_open","nova_escaped"]:StationJourney.put(key,1)
	StationJourney.put("nova_security",7)
	await _open("recife","ruins",Vector3(3.2,0.05,0))
	Input.action_press("move_right")
	await _wait(2)
	Input.action_press("jump")
	await _wait(0.35)
	Input.action_release("jump")
	await _wait(0.65)
	_release()
	await _wait(3)
	_end("recife","RECIFE, 2187","Uma aventura cyberpunk 2.5D com identidade brasileira.")

	StationJourney.put("recife_awake",1)
	await _open("laboratory","intro",Vector3(12.8,0.05,0))
	Input.action_press("move_right")
	await _wait(1)
	_release()
	await _wait(1)
	assert(world.toggle_gaia())
	await _wait(3.5)
	assert(world.toggle_gaia())
	Input.action_press("move_left")
	await _wait(0.8)
	_release()
	await _wait(1.7)
	_end("gaia","DOIS OLHARES. O MESMO MUNDO.","Corpo para agir. GAIA para revelar circuitos e conexões.")

	_seed("water",["drain","module","install","valve_a","valve_a","valve_b","valve_b","authorize"],"water_route",1)
	await _open("water","stations",Vector3(19.5,0.05,0))
	await _wait(1)
	assert(world.interact_object("pump"))
	await _wait(0.5)
	world.finish("RESTORE")
	world.hud.close_modal()
	await _wait(3.5)
	_end("agua","RESTAURE A ÁGUA","Bombas, válvulas e pressão: resolva o desafio do Capibaribe.")

	_seed("soil",["filter","install","humidity"])
	var soil := preload("res://scripts/puzzles/soil_system.gd").new()
	soil.journey = StationJourney
	assert(soil.configure("soil_capsules",10).ok)
	assert(soil.configure("soil_temperature",1).ok)
	assert(soil.interact("authorize").ok)
	await _open("soil","stations",Vector3(22.5,0.05,0))
	await _wait(1)
	assert(world.interact_object("irrigate"))
	world.finish("RESTORE")
	world.hud.close_modal()
	await _wait(4)
	_end("sementes","FAÇA A VIDA VOLTAR","Sementes, clima e irrigação: preserve o futuro do Recife.")

	_seed("air",["scan","module","install","coarse","carbon","turbine","filter"])
	var air := preload("res://scripts/puzzles/air_system.gd").new()
	air.journey = StationJourney
	assert(air.configure("air_team",0).ok)
	await _open("air","stations",Vector3(8,0.05,0))
	await _wait(0.6)
	assert(world.operate_lift())
	await _wait(1.8)
	world.finish("RESTORE")
	world.hud.close_modal()
	await _wait(2.6)
	_end("ar","DEVOLVA O AR À CIDADE","Explore a Torre Atmos e recupere a circulação de ar.")

	StationJourney.choices = {"water":"RESTORE","soil":"RESTORE","air":"RESTORE"}
	_seed("nexus",["nexus_voss"])
	await _open("nexus","nexus",Vector3(30.5,0.05,0))
	Input.action_press("move_right")
	await _wait(0.25)
	_release()
	await _wait(1.25)
	assert(world.interact_object("transmitter"))
	await _wait(4.5)
	_end("decisao","RESTAURAR A TERRA OU PARTIR PARA MARTE?","Sua decisão muda o desfecho. GAIA permanece com a Terra.")

	assert(StationJourney.choose_destination("EARTH"))
	await _open("ending","ending")
	world.hud.hide()
	await _wait(3)
	_end("terra","DOIS FUTUROS POSSÍVEIS","Ficar e reconstruir, ao lado de GAIA e da comunidade.")

	StationJourney.stage = "nexus"
	StationJourney.put("final_destination",0)
	assert(StationJourney.choose_destination("MARS"))
	StationJourney.put("boss_mask",7)
	assert(StationJourney.complete_boss())
	await _open("ending","ending")
	world._next()
	world.hud.hide()
	await _wait(3)
	_end("marte","OU BUSCAR UM NOVO COMEÇO","Partir exige superar o bloqueio de saída da Terra.")

	await _open("menu","ending")
	await _wait(3)
	_end("encerramento","LAST SIGNAL: EARTH_404","O futuro do Recife está nas suas mãos.  •  Godot 4 / GDScript")
	_write_edit()
	print("PITCH READY: ",clips.size()," planos / 59 segundos de edição.")
	_release()
	await AudioDirector.quit_game()

func _write_edit() -> void:
	var manifest := FileAccess.open(OUTPUT+"planos.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"fps":FPS,"clips":clips},"  "))
	manifest.close()
	DirAccess.make_dir_recursive_absolute(OUTPUT+"clipes")
	var commands: Array[String] = ["#!/usr/bin/env bash","set -euo pipefail","cd '"+ProjectSettings.globalize_path("res://")+"'","mkdir -p outputs/pitch/clipes"]
	var concat: Array[String] = []
	for index in range(clips.size()):
		var clip: Dictionary = clips[index]
		var duration := float(clip.end_frame-clip.start_frame)/FPS
		var video := "setsar=1,format=yuv420p"
		if clip.caption:
			var headline := "outputs/pitch/textos/%02d_titulo.txt"%index
			var subtitle := "outputs/pitch/textos/%02d_subtitulo.txt"%index
			FileAccess.open("res://"+headline,FileAccess.WRITE).store_string(clip.title)
			FileAccess.open("res://"+subtitle,FileAccess.WRITE).store_string(clip.subtitle)
			video += ",drawbox=x=0:y=620:w=iw:h=100:color=0x08131F@0.94:t=fill"
			video += ",drawbox=x=42:y=639:w=4:h=61:color=0x82EAD7:t=fill"
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile='%s':fontsize=27:fontcolor=0x82EAD7:x=62:y=637"%headline
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:textfile='%s':fontsize=21:fontcolor=white:x=62:y=678"%subtitle
		video += ",fade=t=in:st=0:d=0.1,fade=t=out:st=%.6f:d=0.1"%(duration-0.1)
		var filter_path := "outputs/pitch/clipes/%02d.filtro"%index
		FileAccess.open("res://"+filter_path,FileAccess.WRITE).store_string(video)
		commands.append("echo 'Plano %02d / %s'"%[index+1,clip.name])
		commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -ss %.6f -i outputs/pitch/captura_bruta.avi -t %.6f -vf \"$(cat %s)\" -af 'afade=t=in:st=0:d=0.04,afade=t=out:st=%.6f:d=0.08' -c:v libx264 -threads 2 -preset veryfast -crf 16 -pix_fmt yuv420p -r 30 -c:a pcm_s16le -ar 48000 outputs/pitch/clipes/%02d.mkv"%[float(clip.start_frame)/FPS,duration,filter_path,duration-0.08,index])
		concat.append("file 'clipes/%02d.mkv'"%index)
	FileAccess.open(OUTPUT+"lista_clipes.txt",FileAccess.WRITE).store_string("\n".join(concat)+"\n")
	commands.append("echo 'Montagem final / 59 segundos'")
	commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -f concat -safe 0 -i outputs/pitch/lista_clipes.txt -vf 'fade=t=out:st=58.5:d=0.5' -af 'loudnorm=I=-22:TP=-2:LRA=9,aresample=48000,afade=t=out:st=58.2:d=0.8' -c:v libx264 -threads 2 -preset medium -crf 18 -pix_fmt yuv420p -c:a aac -b:a 160k -ar 48000 -movflags +faststart -t 59 outputs/pitch/LAST_SIGNAL_EARTH404_PITCH_59s.mp4")
	FileAccess.open(OUTPUT+"renderizar.sh",FileAccess.WRITE).store_string("\n".join(commands)+"\n")
