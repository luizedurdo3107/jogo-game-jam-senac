extends "res://scripts/game/recife_world.gd"

var hazard_time := 0.0
var hazard_lane := 0
var hazard: MeshInstance3D
var hits := 0
var safe_time := 3.0
var pulsing := false
var boss_scan := false
var combat: Node3D
var stamina_bar: ProgressBar

func _ready() -> void:
	region_id = "boss"
	if not StationJourney.values.has("nova_difficulty"):StationJourney.put("nova_difficulty",1)
	if not StationJourney.values.has("departure_started"):
		if StationJourney.value("boss_mask")==7:
			StationJourney.put("departure_security",7)
			StationJourney.put("departure_legacy_clear",1)
		StationJourney.put("departure_started",1)
	super._ready()
	GameState.gaia_unlocked = true
	drone.hide()
	player.collision_mask = 5
	if StationJourney.value("departure_security")==0 and player.position.x>10:player.position = Vector3(7,0.05,0)
	combat = Node3D.new()
	combat.set_script(preload("res://scripts/game/nova_combat.gd"))
	combat.world = self
	combat.departure = true
	add_child(combat)
	camera.size = 9.8
	var identity: VBoxContainer = hud.perspective.get_parent()
	identity.get_child(0).text = "PRESENTE / DOCA TERRESTRE · 2187"
	identity.get_child(0).add_theme_font_size_override("font_size",13)
	hud.perspective.add_theme_font_size_override("font_size",16)
	hud.objective.add_theme_font_size_override("font_size",18)
	hud.context.add_theme_font_size_override("font_size",16)
	stamina_bar = ProgressBar.new()
	stamina_bar.max_value = 6
	stamina_bar.show_percentage = false
	stamina_bar.custom_minimum_size.y = 8
	stamina_bar.add_theme_stylebox_override("fill",SignalTheme.box(SignalTheme.TEAL,SignalTheme.TEAL,0))
	identity.add_child(stamina_bar)
	_update_combat_controls()
	var stripe := BoxMesh.new()
	stripe.size = Vector3(3.0,0.07,2.5)
	hazard = environment.mesh(self,stripe,Vector3(8,0.08,0),Color("dfae57"),true)
	for index in range(3):
		if (StationJourney.value("boss_mask")&(1<<index))!=0:markers[["breaker","redirect","shutdown"][index]].scale.y = 0.65
	if StationJourney.value("boss_mask")==7:environment.open_gate()
	environment.sign_text("TERRA / EMBARQUE SUSPENSO",Vector3(8,3,-2),26,SignalTheme.GOLD)
	hud.notify("O exército de Nova Éden bloqueia a doca. F: bastão; salte ou recue para esquivar. GAIA continua cuidando da Terra.")
	_refresh()
	StationJourney.save_game()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		if not event.is_echo():attack()
		get_viewport().set_input_as_handled()
	else:super._unhandled_input(event)

func attack() -> bool:
	return combat.strike() if is_instance_valid(combat) else false

func set_combat_difficulty(hard: bool) -> void:
	StationJourney.put("nova_difficulty",1 if hard else 0)
	combat.configure_difficulty()
	StationJourney.save_game()
	_refresh()

func _update_combat_controls() -> void:
	hud.touch.release_all()
	hud.touch.combat_enabled = combat.mask!=7
	hud.touch._layout()
	environment.weapon_display.visible = not combat.armed()

func security_progress(mask: int) -> void:
	StationJourney.put("departure_security",mask)
	StationJourney.store_checkpoint(Vector3(8,0.05,0))
	if not StationJourney.save_game():hud.notify("Não foi possível salvar o combate. Verifique o armazenamento.")
	if mask==7:
		_update_combat_controls()
		hud.notify("Guarnição derrotada. Agora desative a contenção por comandos locais; GAIA não participa da fuga.")
	_refresh()

func _capture() -> void:
	finished = true
	player.locked = true
	hud.touch.release_all()
	player.sprite.rotation.z = -0.8
	hud._clear_modal("DERROTADO NA DOCA","O exército impediu o embarque. Retome com vida e fôlego recuperados: soldados vencidos e travas já desligadas permanecem salvos. Ataque na recuperação, recue e salte para esquivar.")
	hud.button(hud.modal_box,"Retomar o combate",restart).grab_focus()
	hud.button(hud.modal_box,"Menu",menu)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hud) or hud.modal_open or hud.portrait.visible or finished or not is_instance_valid(combat):return
	combat.tick(delta)
	stamina_bar.value = combat.stamina
	if combat.mask!=7:
		hazard.hide()
		hud.perspective.text = "%s · VIDA %d/%d\n[F] BASTÃO · FÔLEGO"%["DIFÍCIL" if combat.hard_mode else "PADRÃO",combat.life,combat.max_life]
		return
	if StationJourney.value("boss_mask")==7:
		hazard.hide()
		return
	safe_time = maxf(0,safe_time-delta)
	hazard_time += delta
	var cycle := fmod(hazard_time,5.0)
	hazard_lane = floori(hazard_time/5.0)%3
	hazard.position.x = [8.0,16.0,24.0][hazard_lane]
	pulsing = cycle>=3.0 and cycle<4.2
	hazard.visible = cycle<4.2
	hazard.material_override = environment.material(Color("ed6374") if pulsing else Color("d7b65f"),true)
	if pulsing and safe_time<=0 and absf(player.position.x-hazard.position.x)<1.5 and player.position.y<1.15:
		hits += 1
		safe_time = 3
		player.velocity.y = 4
		hud.notify("Bloqueio de contenção! Salte sobre o pulso vermelho. Progresso preservado.")
		soundscape.emit("drone_alert",player.global_position)
		if hits>=3:
			finished = true
			hud._clear_modal("RESPIRAR E RECOMEÇAR","O sistema entrou em contenção. Os circuitos já desligados continuam seguros. Não há dano a pessoas nem ao núcleo de GAIA.")
			hud.button(hud.modal_box,"Retomar o confronto",restart).grab_focus()
			hud.button(hud.modal_box,"Menu",menu)

func current_objective() -> String:
	if is_instance_valid(combat) and combat.mask!=7:
		if not combat.armed():return "Pegue o bastão no equipamento à esquerda [E]."
		return "Guarnição da doca: %d/3. Vença o comandante para embarcar."%[int((combat.mask&1)!=0)+int((combat.mask&2)!=0)+int((combat.mask&4)!=0)]
	match StationJourney.value("boss_mask"):
		0:return "Análise local: leia a trava. Depois, desligue-a com o corpo."
		1:return "Interface local: desvie a energia da barreira de embarque."
		3:return "Corpo: desligue o bloqueio no painel da direita."
	return "Saída liberada. Confirme o embarque para Marte."

func _refresh() -> void:
	super._refresh()
	if hud and (not is_instance_valid(combat) or combat.mask==7):hud.perspective.text = "PRESENTE / "+("ANÁLISE LOCAL" if GameState.gaia_active else "TRAVAS DE EMBARQUE")

func toggle_gaia() -> bool:
	if is_instance_valid(combat) and combat.mask!=7:
		hud.notify("Confronto físico: vença a guarnição antes de operar os circuitos locais. GAIA não combate pessoas.")
		return false
	if not super.toggle_gaia():return false
	hud.notify("Leitura local dos circuitos de agora. GAIA não está autorizando sua fuga." if GameState.gaia_active else "Corpo: opere as travas de embarque.")
	return true

func interact_object(object_id: String) -> bool:
	if hud.modal_open or finished or not objects.has(object_id):return false
	if object_id=="equipment":
		StationJourney.put("nova_armory",3)
		StationJourney.put("nova_weapon",1)
		StationJourney.save_game()
		_update_combat_controls()
		hud.notify("Bastão equipado. F: golpear; Espaço: saltar. Não ataque sem fôlego.")
		return true
	if combat.mask!=7:
		hud.notify("O exército bloqueia os comandos de embarque. Derrote a guarnição primeiro.")
		return false
	if pulsing and absf(player.position.x-hazard.position.x)<1.5 and player.position.y<1.15:
		hud.notify("Espere o pulso terminar ou salte para um lugar seguro.")
		return false
	var mask := StationJourney.value("boss_mask")
	if object_id=="breaker":
		if GameState.gaia_active:
			boss_scan = true
			hud.show_dialogue("IMPLANTE / LEITURA LOCAL","Seu implante lê o circuito atual, mesmo sem autorização de GAIA. A análise não é uma memória nem uma previsão. O desvio da barreira será uma ação sua, não ajuda da IA para fugir.")
			return true
		if not boss_scan:
			hud.notify("Use a análise local [Q] para localizar a ligação antes de tocar na trava.")
			return false
		mask |= 1
	elif object_id=="redirect":
		if not GameState.gaia_active or (mask&1)==0:
			hud.notify("Desligue a primeira trava e use a interface local [Q] neste painel.")
			return false
		mask |= 2
	elif object_id=="shutdown":
		if GameState.gaia_active or (mask&3)!=3:
			hud.notify("Redirecione a energia do painel central antes de desligar o bloqueio físico.")
			return false
		mask |= 4
	else:
		if mask!=7:return false
		hud.touch.release_all()
		return StationJourney.complete_boss()
	StationJourney.put("boss_mask",mask)
	StationJourney.store_checkpoint(Vector3(player.position.x,0.05,0))
	StationJourney.save_game()
	var target: Node3D = markers[object_id]
	create_tween().tween_property(target,"scale",Vector3(1,0.65,1),0.5)
	soundscape.interaction(object_id,"terminal",GameState.gaia_active,target.global_position)
	if mask==7:
		environment.open_gate()
		hazard.hide()
		hazard_time = 4.3
		safe_time = 1000
	hud.refresh()
	hud.notify("Circuito seguro. "+current_objective())
	return true
