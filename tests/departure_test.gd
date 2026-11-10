extends "res://tests/journey_test.gd"

func open_dock() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await frames(3)
	game = load(StationJourney.SCENES.boss).instantiate()
	add_child(game)
	await frames(5)
	game.hud.touch.persistence_enabled = false
	game.hud.touch.set_manual_mode(2)
	if game.hud.modal_open:game.hud.close_modal()

func run() -> void:
	SceneRouter.test_mode = true
	StationJourney.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	StationJourney.reset()
	for region in StationJourney.ORDER:seed_station(region)
	seed_nexus()
	verify(StationJourney.choose_destination("MARS"),"Escolha de Marte inicia o combate final")
	await open_dock()
	verify(game.combat.departure and game.combat.soldiers.size()==3,"Dois soldados e comandante presentes na doca")
	verify(game.combat.hard_mode and game.combat.soldiers[2].life==8,"Comandante tem oito pontos de vida no Difícil")
	verify(not game.interact_object("transmit") and not game.toggle_gaia(),"Sem embarque ou análise local antes de vencer a guarnição")
	verify(not game.attack(),"Sem bastão não causa dano às armaduras")
	verify(game.interact_object("equipment") and game.combat.armed(),"Jogador sem arma pode pegar bastão na doca")
	verify(StationJourney.validate(StationJourney.snapshot()),"Estado da doca é válido")
	game.hud.touch.set_manual_mode(1)
	verify(game.hud.touch.buttons.has("attack") and not game.hud.touch.buttons.has("perspective"),"Touch oferece GOLPE durante a batalha")
	await frames(30)
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.position = game.hud.touch.buttons.attack.rect.get_center()
	touch.pressed = true
	get_viewport().push_input(touch,true)
	await frames(2)
	verify(Input.is_action_pressed("attack") and game.combat.attack_time>0,"Toque dispara ataque na cena final real")
	touch = InputEventScreenTouch.new()
	touch.index = 7
	touch.position = game.hud.touch.buttons.attack.rect.get_center()
	touch.pressed = false
	get_viewport().push_input(touch,true)
	await frames(2)
	verify(not Input.is_action_pressed("attack"),"Soltar o toque libera F no combate final")
	game.hud.touch.set_manual_mode(2)
	game.combat.invulnerable = 0
	game.combat.take_hit()
	verify(game.combat.life==3,"Soldados causam perda de vida, não só aviso")
	game.hud.show_pause()
	var previous_clock: float = game.combat.elapsed
	await frames(90)
	verify(game.combat.elapsed==previous_clock,"Pausa congela a batalha")
	game.hud.close_modal()
	game.set_combat_difficulty(false)
	verify(game.combat.life==3 and game.combat.soldiers[2].life==6,"Troca para Padrão não cura o jogador")
	game.set_combat_difficulty(true)
	game.combat.invulnerable = 0
	game.combat.take_hit()
	game.combat.invulnerable = 0
	game.combat.take_hit()
	game.combat.invulnerable = 0
	game.combat.take_hit()
	verify(game.finished and game.hud.modal_open,"Perder toda a vida abre retomada na doca")
	await open_dock()
	verify(game.combat.life==4 and game.combat.armed(),"Retomada recupera vida e conserva arma")
	await defeat_departure(game)
	var temporary_save := "user://departure_test_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	StationJourney.save_path = temporary_save
	StationJourney.persistence_enabled = true
	verify(StationJourney.save_game() and StationJourney.load_game() and StationJourney.value("departure_security")==7,"Vitória militar persiste em save validado e leitura real")
	StationJourney.persistence_enabled = false
	DirAccess.remove_absolute(temporary_save)
	game.hud.touch.set_manual_mode(1)
	verify(game.hud.touch.buttons.has("perspective") and not game.hud.touch.buttons.has("attack"),"Após a vitória, touch volta à análise local")
	game.hud.touch.set_manual_mode(2)
	verify(not StationJourney.complete_boss(),"Vitória militar ainda exige desligar contenção")
	verify(game.toggle_gaia() and game.interact_object("breaker"),"Implante lê primeira trava depois da batalha")
	game.hud.close_modal()
	game.toggle_gaia()
	verify(game.interact_object("breaker"),"Corpo desliga primeira trava")
	game.toggle_gaia()
	verify(game.interact_object("redirect"),"Interface local desvia a barreira")
	game.toggle_gaia()
	verify(game.interact_object("shutdown"),"Comando local desliga a contenção final")
	await frames(90)
	verify(game.environment.gate.collision_layer==0,"Batalha e contenção liberam passagem física")
	verify(game.interact_object("transmit") and StationJourney.stage=="ending","Confirmação real abre final de Marte")
	verify(StationJourney.validate(StationJourney.snapshot()),"Final não permite pular vitória ou contenção")
	game.queue_free()
	await frames(3)
	game = load(StationJourney.SCENES.ending).instantiate()
	add_child(game)
	await frames(3)
	verify(game.ship.get_script().resource_path.ends_with("ark_ship.gd"),"Final usa nave detalhada compartilhada com a doca")
	verify(game.ship.exhausts.size()==4 and game.ship.landing_gear.visible,"Nave começa com trem de pouso, sem propulsão")
	game._next()
	verify(game.ship.flying and not game.ship.landing_gear.visible,"Decolagem acende motores e recolhe trem de pouso")
	game._next()
	verify(not game.player.visible,"Pular cinemáticas não deixa o personagem flutuando no espaço")
	verify(game.planet.material_override.albedo_texture.get_width()==1024,"Terra usa superfície detalhada em vez de esferas sobrepostas")
	verify(game.planet.clouds.material_override.albedo_texture!=null,"Nuvens têm camada própria")
	var previous_scale: Vector3 = game.planet.scale
	await frames(30)
	verify(game.planet.scale.x<previous_scale.x and game.planet.visible,"Terra recua durante a viagem sem desaparecer")
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png("res://outputs/qa/rc5/earth.png")
	game.queue_free()
	await frames(4)
	StationJourney.reset()
	for region in StationJourney.ORDER:seed_station(region)
	seed_nexus()
	verify(StationJourney.choose_destination("EARTH") and StationJourney.stage=="ending","Ficar na Terra continua sem combate")
	verify(StationJourney.value("departure_started")==0,"Rota da Terra não cria guarnição final")
	StationJourney.stage = "boss"
	StationJourney.put("final_destination",2)
	StationJourney.put("boss_mask",7)
	await open_dock()
	verify(StationJourney.value("departure_legacy_clear")==1 and game.combat.mask==7,"Save rc4 com embarque liberado não ganha luta retroativa")
	for soldier in game.combat.soldiers:verify(not soldier.body.visible,"Compatibilidade não inventa soldados já derrotados")
	var invalid := StationJourney.snapshot()
	invalid.values.departure_security = 8
	verify(not StationJourney.validate(invalid),"Save rejeita máscara militar inválida")
	game.queue_free()
	await frames(4)
	print("DOCA / COMBATE FINAL / NAVE / TERRA: %d verificações, %d falhas"%[assertions,failures])
	if failures>0:get_tree().quit(1)
	else:await AudioDirector.quit_game()
