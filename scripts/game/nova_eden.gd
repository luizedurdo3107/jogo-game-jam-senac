extends "res://scripts/game/recife_world.gd"

var combat: Node3D
var stamina_bar: ProgressBar

func _ready() -> void:
	region_id = "nova_eden"
	if not StationJourney.values.has("nova_difficulty"):StationJourney.put("nova_difficulty",1)
	if not StationJourney.values.has("nova_armory"):
		if StationJourney.value("nova_security")>0:
			StationJourney.put("nova_armory",3)
			StationJourney.put("nova_weapon",1)
		elif StationJourney.checkpoints.has(region_id) and StationJourney.checkpoint().x>9:
			StationJourney.checkpoints[region_id] = [2.0,0.05]
	super._ready()
	drone.hide()
	markers.lyra.hide()
	player.collision_mask = 5
	combat = Node3D.new()
	combat.set_script(preload("res://scripts/game/nova_combat.gd"))
	combat.world = self
	add_child(combat)
	camera.size = 9.8
	camera.position = Vector3(7,6.8,22)
	camera.look_at(Vector3(5,2.3,-1))
	hud.touch.combat_enabled = true
	hud.touch._layout()
	var identity: VBoxContainer = hud.perspective.get_parent()
	identity.get_child(0).text = "PRESENTE / NOVA ÉDEN · 2187"
	identity.get_child(0).add_theme_font_size_override("font_size",14)
	hud.perspective.add_theme_font_size_override("font_size",16)
	hud.objective.add_theme_font_size_override("font_size",18)
	hud.context.add_theme_font_size_override("font_size",16)
	hud.toast.add_theme_font_size_override("font_size",16)
	var columns: HBoxContainer = hud.header.get_child(0)
	columns.get_child(2).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	columns.get_child(3).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stamina_bar = ProgressBar.new()
	stamina_bar.max_value = 6
	stamina_bar.show_percentage = false
	stamina_bar.custom_minimum_size.y = 8
	stamina_bar.add_theme_stylebox_override("fill",SignalTheme.box(SignalTheme.TEAL,SignalTheme.TEAL,0))
	stamina_bar.add_theme_stylebox_override("background",SignalTheme.box(Color("233a4a"),Color("233a4a"),0))
	identity.add_child(stamina_bar)
	_refresh()
	StationJourney.save_game()

func _process(delta: float) -> void:
	if not camera or not hud:return
	camera.position.x = lerpf(camera.position.x,clampf(player.position.x+2.4,7,32),1-exp(-delta*5))
	camera.position.y = lerpf(camera.position.y,player.position.y+6.8,1-exp(-delta*3))
	_update_interactions()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		if not event.is_echo():attack()
		get_viewport().set_input_as_handled()
	else:super._unhandled_input(event)

func attack() -> bool:
	return combat.strike() if is_instance_valid(combat) else false

func _nova_security(delta: float) -> void:
	if not is_instance_valid(combat):return
	combat.tick(delta)
	_update_status()

func _update_status() -> void:
	hud.perspective.text = "%s · VIDA %d/%d\n%s"%["DIFÍCIL" if combat.hard_mode else "PADRÃO",combat.life,combat.max_life,"[F] BASTÃO · FÔLEGO" if combat.armed() else "SEM ARMA · ARSENAL [E]"]
	stamina_bar.value = combat.stamina
	hud.objective.text = current_objective()

func _update_interactions() -> void:
	super._update_interactions()
	markers.lyra.hide()
	if nearest.is_empty():hud.context.text = "[F] Bastão · Espaço: esquivar · Não ataque sem fôlego." if StationJourney.value("nova_weapon")==1 else "Encontre o arsenal iluminado. [E] interagir."

func current_objective() -> String:
	if StationJourney.value("nova_legacy_passage")==1:return "Saída anterior preservada. Siga à direita [E]."
	if GameState.has_flag("nova_open"):return "Esquadrão vencido. Saia à direita [E]."
	if StationJourney.value("nova_armory")<3:return "Abra o arsenal: religue os três relés [E]."
	if StationJourney.value("nova_weapon")==0:return "Arsenal aberto. Pegue o bastão [E]."
	var defeated := 0
	if is_instance_valid(combat):
		for soldier in combat.soldiers:
			if soldier.life==0:defeated += 1
	return "Exército: %d/3. Espere a brecha para golpear."%defeated

func interact_object(object_id: String) -> bool:
	if object_id!="armory":return super.interact_object(object_id)
	if hud.modal_open or finished:return false
	if StationJourney.value("nova_armory")<3:
		show_armory()
	elif StationJourney.value("nova_weapon")==0:
		StationJourney.put("nova_weapon",1)
		_persist_armory()
		play_sound("pickup_01")
		hud.notify("BASTÃO EQUIPADO · F ataca · Recue para recuperar fôlego.")
	else:hud.notify("Você já está com o bastão. Enfrente o esquadrão à direita.")
	return true

func show_armory(message := "") -> void:
	var stage := StationJourney.value("nova_armory")
	hud._clear_modal("ARSENAL / RELÉS %d DE 3"%stage,"Etiqueta de manutenção: «Antes de armar a defesa, deixe a cidade respirar. Só então carregue o bastão.»\n\nToque os relés na ordem da etiqueta.\n"+message)
	hud.modal_box.get_child(1).add_theme_font_size_override("font_size",18)
	var relays := HBoxContainer.new()
	relays.add_theme_constant_override("separation",10)
	hud.modal_box.add_child(relays)
	for relay in [2,0,1]:
		var control: Button = hud.button(relays,["O₂\nVENTILAÇÃO","ESCUDO\nDEFESA","RAIO\nCARGA"][relay],func():armory_relay(relay),Vector2(0,72))
		control.disabled = relay<stage
	hud.button(hud.modal_box,"Voltar à rua",hud.close_modal).grab_focus()

func armory_relay(relay: int) -> bool:
	if finished or StationJourney.value("nova_armory")==3:return false
	var step := StationJourney.value("nova_armory")
	var correct := relay==step
	StationJourney.put("nova_armory",step+1 if correct else 0)
	_persist_armory()
	play_sound("install_01" if correct else "scan_02")
	if StationJourney.value("nova_armory")==3:
		hud.close_modal()
		hud.notify("Relés conectados. A porta do arsenal está abrindo. E para pegar o bastão.")
	else:show_armory("Relé conectado." if correct else "Ordem incorreta: os relés foram reiniciados. Releia a etiqueta.")
	return correct

func _persist_armory() -> void:
	StationJourney.store_checkpoint(Vector3(6.5,0.05,0))
	if not StationJourney.save_game():hud.notify("Não foi possível salvar o arsenal. Verifique o armazenamento.")
	_refresh()

func set_combat_difficulty(hard: bool) -> void:
	StationJourney.put("nova_difficulty",1 if hard else 0)
	combat.configure_difficulty()
	if not StationJourney.save_game():hud.notify("Não foi possível salvar a dificuldade.")
	_update_status()

func security_progress(mask: int) -> void:
	StationJourney.put("nova_security",mask)
	if mask==7:
		GameState.apply_effect({"flags":["nova_open"]})
		StationJourney.put("nova_open",1)
		hud.notify("Esquadrão derrotado. A passagem está livre: saia de Nova Éden à direita.")
	StationJourney.store_checkpoint(Vector3(clampf(player.position.x,2,26),0.05,0))
	if not StationJourney.save_game():hud.notify("Não foi possível salvar o confronto. Verifique o armazenamento.")
	_refresh()

func _refresh() -> void:
	super._refresh()
	if is_instance_valid(environment):environment.sync_armory(StationJourney.value("nova_armory")==3,StationJourney.value("nova_weapon")==1)
	if is_instance_valid(hud) and is_instance_valid(combat) and is_instance_valid(stamina_bar):_update_status()
