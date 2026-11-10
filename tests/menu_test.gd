extends "res://tests/test_fixture.gd"

var menu: Control

func open_menu() -> void:
	if is_instance_valid(menu):
		menu.queue_free()
		await frames(3)
	menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await frames(5)

func run() -> void:
	SceneRouter.test_mode = true
	AudioDirector.persistence_enabled = false
	StationJourney.persistence_enabled = true
	StationJourney.save_path = "user://menu_test_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	StationJourney.reset()
	await open_menu()
	verify(menu.continuing.disabled and not menu.existing,"Sem save, continuar fica desabilitado")
	verify(menu.fresh.has_focus(),"Nova jornada recebe foco inicial")
	verify(menu.background.texture.resource_path.begins_with("res://assets/referencias_aprovadas/"),"Menu preserva arte aprovada")
	for dimensions in [Vector2(960,540),Vector2(1168,540),Vector2(960,1230),Vector2(640,360)]:
		menu.size = dimensions
		menu._reflow()
		await frames(3)
		verify(menu.menu_scroll.position.x>=0 and menu.menu_scroll.get_rect().end.x<=menu.size.x,"Coluna cabe na largura / "+str(dimensions))
		verify(menu.menu_scroll.get_rect().end.y<menu.footer.position.y,"Menu não cobre rodapé / "+str(dimensions))
		verify(menu.layout.get_combined_minimum_size().x<=menu.menu_scroll.size.x,"Textos e botões não exigem rolagem horizontal / "+str(dimensions))
	verify(not menu.location.visible,"Composição compacta esconde decoração lateral")
	menu.fresh.pressed.emit()
	verify(SceneRouter.last_requested=="cinematic" and StationJourney.stage=="cinematic","Nova jornada inicia introdução")
	StationJourney.finish_intro()
	var before := StationJourney.snapshot()
	await open_menu()
	verify(menu.existing and not menu.continuing.disabled,"Save habilita continuação")
	verify(menu.continuing.has_focus(),"Continuar recebe foco com progresso")
	menu.continuing.pressed.emit()
	verify(StationJourney.stage=="nova" and SceneRouter.last_requested=="nova_eden","Continuar recupera região correta")
	menu.fresh.pressed.emit()
	await frames(4)
	verify(menu.confirmation.visible,"Reinício pede confirmação sem apagar a tela inicial")
	verify(menu.confirmation_panel.position.y>=0 and menu.confirmation_panel.get_rect().end.y<=menu.size.y,"Confirmação permanece dentro da tela")
	verify(menu.cancel_new.get_global_rect().intersects(menu.confirmation_panel.get_global_rect()),"Opção de cancelar é visível")
	verify(menu.confirm_new.get_global_rect().intersects(menu.confirmation_panel.get_global_rect()),"Opção de confirmar é visível")
	verify(StationJourney.snapshot()==before,"Abrir confirmação não altera o save")
	menu._cancel_new_game()
	verify(not menu.confirmation.visible and menu.fresh.has_focus(),"Cancelar mantém progresso e devolve foco")
	menu._new_game()
	menu.confirm_new.pressed.emit()
	verify(StationJourney.stage=="cinematic" and StationJourney.choices.values().count("PENDING")==3,"Confirmação inicia nova jornada")
	menu._cancel_new_game()
	menu._show_credits()
	await frames(2)
	var credits: Node = menu.get_child(menu.get_child_count()-1)
	verify(credits is CanvasLayer,"Créditos abrem pelo menu")
	credits.dismiss()
	await frames(2)
	AudioDirector.open_settings(menu)
	await frames(2)
	verify(is_instance_valid(AudioDirector.options),"Áudio abre pelo menu")
	AudioDirector.options.dismiss()
	await frames(2)
	menu.size = Vector2(960,540)
	menu._reflow()
	if "--capture" in OS.get_cmdline_user_args():
		await frames(50)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png("res://outputs/qa/restoration/00_menu.png")
	menu.queue_free()
	await frames(5)
	DirAccess.remove_absolute(StationJourney.save_path)
	print("MENU / RESPONSIVIDADE / NAVEGAÇÃO: %d verificações, %d falhas"%[assertions,failures])
	if failures>0:get_tree().quit(1)
	else:await AudioDirector.quit_game()
