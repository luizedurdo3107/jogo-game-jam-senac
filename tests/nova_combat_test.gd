extends "res://tests/restoration_gameplay_test.gd"

func key_event(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F
	event.keycode = KEY_F
	event.pressed = pressed
	get_viewport().push_input(event,true)

func run() -> void:
	SceneRouter.test_mode = true
	AudioDirector.persistence_enabled = false
	StationJourney.persistence_enabled = true
	StationJourney.save_path = "user://nova_combat_test_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	StationJourney.reset()
	await open_region("nova_eden","nova")
	verify(game.combat.hard_mode and game.combat.life==4,"Difícil é o padrão da primeira fase")
	verify(game.combat.soldiers.size()==3 and game.combat.soldiers[2].life==6,"Capitão tem resistência maior")
	verify(game.environment.traffic.size()==3 and game.environment.find_child("SkylineNovaEden",false,false)!=null,"Cidade tem panorama próprio e tráfego 2.5D")
	verify(game.combat.soldiers[0].sprite.texture.get_image().get_pixel(0,0).a==0 and game.combat.soldiers[0].sprite.hframes==4,"Soldados humanos usam atlas transparente de quatro poses")
	verify(not game.attack() and game.combat.soldiers[0].life==4,"Sem arma não atravessa a armadura")
	game.combat.cooldown = 0
	verify(game.interact_object("armory") and game.hud.modal_open,"Arsenal abre interface do puzzle")
	verify(not game.armory_relay(2) and StationJourney.value("nova_armory")==0,"Ordem errada reinicia os relés")
	var first_button: Button = game.hud.modal_box.get_child(2).get_child(1)
	verify("VENTILAÇÃO" in first_button.text,"Botões mostram os relés da pista, não números secretos")
	first_button.pressed.emit()
	verify(StationJourney.value("nova_armory")==1,"Botão da interface conecta o primeiro relé")
	game.hud.close_modal()
	verify(StationJourney.load_game() and StationJourney.value("nova_armory")==1,"Relé parcial persiste")
	await open_region("nova_eden","nova")
	verify(StationJourney.value("nova_armory")==1 and not game.combat.armed(),"Continuar não concede arma antes do puzzle")
	game.interact_object("armory")
	verify(game.armory_relay(1) and game.armory_relay(2),"Sequência da etiqueta abre o arsenal")
	await frames(45)
	verify(game.environment.armory_door.position.y>2.4,"Porta do arsenal abre visivelmente")
	verify(not game.combat.armed() and not game.attack(),"Abrir não equivale a pegar a arma")
	game.combat.cooldown = 0
	verify(game.interact_object("armory") and game.combat.armed(),"E coleta e equipa o bastão")
	await frames(2)
	verify(game.combat.weapon.visible and not game.environment.weapon_display.visible,"Arma sai do armário e aparece na mão")
	game.hud.show_pause()
	verify(not game.attack(),"Pausa impede ataques")
	game.hud.close_modal()
	game.player.position = Vector3(3,0.05,0)
	key_event(true)
	await frames(2)
	key_event(false)
	verify(game.combat.attack_time>0 and game.combat.soldiers[0].life==4,"F anima bastão; alcance é respeitado")
	verify(not game.attack(),"Recarga impede repetição instantânea")
	await frames(30)
	var soldier: Dictionary = game.combat.soldiers[0]
	game.combat.stamina = 6
	game.player.position = Vector3(soldier.body.position.x-1,0.05,0)
	game.player.sprite.flip_h = false
	key_event(true)
	await frames(2)
	key_event(false)
	verify(soldier.life==3 and soldier.stun>0 and game.combat.stamina==4,"F causa dano, reação e consome fôlego")
	game.combat.cooldown = 0
	game.player.sprite.flip_h = true
	verify(game.attack() and soldier.life==3,"Ataque exige direção correta")
	game.player.sprite.flip_h = false
	game.combat.cooldown = 0
	game.player.position = Vector3(soldier.body.position.x-1,0.05,0)
	verify(game.attack() and game.combat.stamina==0,"Três golpes esgotam fôlego mesmo errando um")
	game.combat.cooldown = 0
	verify(not game.attack(),"Segurar F sem fôlego não dá dano infinito")
	game.player.position = Vector3(6.5,0.05,0)
	await frames(240)
	verify(game.combat.stamina>5.9,"Fôlego se recupera sem ficar atacando")
	soldier.stun = 0
	soldier.clock = 0.43
	soldier.aim = 12.2
	soldier.strikes = 0
	game.player.position = Vector3(12.2,0.05,0)
	game.combat.invulnerable = 0
	game.combat._tick_enemy(soldier,0.03)
	verify(game.combat.life==3,"Soldado causa dano mais rápido no Difícil")
	game.combat.take_hit()
	verify(game.combat.life==3,"Proteção curta evita dano duplicado no mesmo instante")
	game.player.position.y = 1.3
	soldier.clock = 0.43
	soldier.strikes = 0
	game.combat.invulnerable = 0
	game.combat._tick_enemy(soldier,0.03)
	verify(game.combat.life==3,"Salto evita o golpe")
	game.player.position = Vector3(12.5,0.05,0)
	game.combat.invulnerable = 100
	var support_x: float = game.combat.soldiers[1].body.position.x
	await frames(30)
	verify(game.combat.soldiers[1].body.position.x<support_x-0.8,"Difícil ativa um segundo soldado simultaneamente")
	game.hud.show_pause()
	var difficulty: OptionButton = game.hud.modal_box.get_child(3)
	difficulty.item_selected.emit(0)
	verify(not game.combat.hard_mode and game.combat.max_life==6,"Pausa muda para Padrão")
	game.hud.close_modal()
	support_x = game.combat.soldiers[1].body.position.x
	await frames(20)
	verify(is_equal_approx(game.combat.soldiers[1].body.position.x,support_x),"Padrão mantém um inimigo ativo")
	game.set_combat_difficulty(true)
	var captain: Dictionary = game.combat.soldiers[2]
	game.player.position = Vector3(captain.body.position.x-1,0.05,0)
	game.player.sprite.flip_h = false
	captain.sprite.flip_h = false
	captain.clock = 0.2
	game.combat.cooldown = 0
	game.combat.stamina = 6
	var captain_life: int = captain.life
	verify(game.attack() and captain.life==captain_life,"Capitão bloqueia ataque frontal durante preparação")
	captain.clock = 1.3
	game.combat.cooldown = 0
	verify(game.attack() and captain.life==captain_life-1,"Capitão fica vulnerável durante recuperação")
	captain.stun = 0
	captain.clock = 0.93
	captain.strikes = 1
	captain.aim = game.player.position.x
	game.combat.invulnerable = 0
	var previous_life: int = game.combat.life
	game.combat._tick_enemy(captain,0.03)
	verify(game.combat.life==previous_life-1 and captain.strikes==2,"Capitão executa segundo golpe no combo Difícil")
	game.player.position = Vector3(6.5,0.05,0)
	game.hud.touch.set_manual_mode(1)
	game.hud.touch._layout()
	verify(game.hud.touch.buttons.has("attack") and not game.hud.touch.buttons.has("perspective"),"Touch mantém GOLPE na primeira fase")
	game.combat.cooldown = 0
	game.combat.stamina = 6
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.position = game.hud.touch.buttons.attack.rect.get_center()
	touch.pressed = true
	get_viewport().push_input(touch,true)
	await frames(2)
	verify(Input.is_action_pressed("attack") and game.combat.attack_time>0,"Toque aciona o bastão")
	touch = InputEventScreenTouch.new()
	touch.index = 4
	touch.position = game.hud.touch.buttons.attack.rect.get_center()
	touch.pressed = false
	get_viewport().push_input(touch,true)
	await frames(2)
	verify(not Input.is_action_pressed("attack"),"Soltar toque não deixa ataque preso")
	game.hud.touch.set_manual_mode(2)
	await defeat_nova(game)
	await frames(85)
	verify(game.environment.gate.collision_layer==0 and game.environment.gate_visual.position.y>3,"Vitória abre a saída animada")
	verify(StationJourney.load_game() and StationJourney.value("nova_weapon")==1,"Vitória, dificuldade e arma persistem")
	await open_region("nova_eden","nova")
	verify(game.combat.mask==7 and game.combat.armed(),"Retomar preserva soldados derrotados e bastão")
	StationJourney.reset()
	await open_region("nova_eden","nova")
	for hit_index in range(4):
		game.combat.invulnerable = 0
		game.combat.take_hit()
	await frames(55)
	verify(game.finished and game.hud.modal_open,"Quatro danos provocam derrota no Difícil")
	StationJourney.reset()
	await open_region("nova_eden","nova")
	await arm_nova(game)
	game.player.position = Vector3(12.2,0.05,0)
	game.player.sprite.flip_h = false
	Input.action_press("attack")
	var spam_frames := 0
	while not game.finished and spam_frames<900:
		await frames(1)
		spam_frames += 1
	Input.action_release("attack")
	verify(game.finished and game.combat.mask!=7,"F parado e segurado não vence o modo Difícil")
	await frames(55)
	var old := {"version":5,"station":"water","stage":"nova","values":{"intro_seen":1,"nova_contact":1,"nova_module":1,"nova_credential":1,"nova_power":1,"nova_open":1},"choices":{"water":"PENDING","soil":"PENDING","air":"PENDING"},"checkpoints":{"nova_eden":[30,0.05]}}
	var file := FileAccess.open(StationJourney.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	verify(StationJourney.load_game() and StationJourney.value("nova_legacy_passage")==1,"Save v5 preserva saída conquistada")
	await open_region("nova_eden","nova")
	for previous in game.combat.soldiers:verify(not previous.body.visible,"Legado não inventa soldados derrotados")
	StationJourney.reset()
	StationJourney.put("nova_security",2)
	await open_region("nova_eden","nova")
	verify(game.combat.armed() and game.combat.soldiers[1].life==0,"Save v6 em combate ganha arma sem perder adversários derrotados")
	verify(StationJourney.validate(StationJourney.snapshot()),"Vitória fora de ordem é um checkpoint válido")
	var corrupt := StationJourney.snapshot()
	corrupt.values.nova_armory = 0
	verify(not StationJourney.validate(corrupt),"Save recusa arma antes do arsenal")
	var opening_count := 0
	for region_id in ["nova_eden","recife","laboratory","water","soil","air","nexus","boss"]:
		var region: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/%s.json"%region_id))
		if region.get("opening_puzzle",false):opening_count += 1
	verify(opening_count==3,"Arsenal é a única abertura acrescentada às duas anteriores")
	game.queue_free()
	await frames(5)
	DirAccess.remove_absolute(StationJourney.save_path)
	print("NOVA ÉDEN / ARSENAL / DIFICULDADE: %d verificações, %d falhas"%[assertions,failures])
	if failures>0:get_tree().quit(1)
	else:await AudioDirector.quit_game()
