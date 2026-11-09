extends "res://scripts/ui/game_hud.gd"

var diagnostic_panel: PanelContainer
var diagnostic_text: Label

func _ready() -> void:
	super._ready()
	objective.add_theme_font_size_override("font_size",16)
	context.add_theme_font_size_override("font_size",14)
	diagnostic_panel = PanelContainer.new()
	diagnostic_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	diagnostic_panel.offset_left = -405
	diagnostic_panel.offset_right = -70
	diagnostic_panel.offset_top = 160
	root.add_child(diagnostic_panel)
	diagnostic_text = SignalTheme.label("",15,SignalTheme.TEAL)
	diagnostic_panel.add_child(diagnostic_text)
	root.move_child(modal,root.get_child_count()-1)
	root.move_child(portrait,root.get_child_count()-1)

func _process(delta: float) -> void:
	super._process(delta)
	if diagnostic_panel:
		diagnostic_panel.visible = world.perspectives.active and not modal_open and not portrait.visible
		diagnostic_text.text = world.system.diagnostic()

func refresh() -> void:
	super.refresh()
	perspective.text = ("[G] GAIA / " if GameState.gaia_active else "[F] CORPO / ")+"CAPIBARIBE / ÚLTIMO SINAL"

func show_help() -> void:
	_clear_modal("CORPO + CAMADA DIGITAL",world.system.objective()+"\n\nQ: perspectiva · E: interagir · A/D: mover\nEspaço: salto · W/S: escadas.\nGAIA seleciona redes e comandos remotos. O corpo carrega módulos, conversa e move mecanismos. Memórias são arquivos, nunca viagens no tempo.")
	button(modal_box,"Continuar",close_modal).grab_focus()

func show_pause() -> void:
	_clear_modal("CAPIBARIBE / PAUSA","Progresso técnico, escolhas e checkpoints são salvos neste dispositivo.")
	var row := HBoxContainer.new()
	modal_box.add_child(row)
	button(row,"Continuar",close_modal).grab_focus()
	button(row,"Checkpoint",world.restart)
	button(row,"Menu",world.menu)
	var controls := OptionButton.new()
	for title in ["Toque: automático","Toque: sempre visível","Toque: ocultar"]:
		controls.add_item(title)
	controls.selected = touch.manual_mode
	controls.custom_minimum_size.y = 48
	controls.item_selected.connect(touch.set_manual_mode)
	modal_box.add_child(controls)
	button(modal_box,"Áudio / volumes",func():AudioDirector.open_settings(self))

func show_system_panel(panel_id: String) -> void:
	match panel_id:
		"water_route":
			_clear_modal("GAIA / SELECIONAR CIRCUITO","Três canais independentes. A memória histórica registra a conexão segura do filtro comunitário.")
			for index in range(3):
				var names := ["A / Esgoto industrial · contaminação 92%","B / Filtro comunitário · regime 60 kPa","C / Bypass ARCA · sem tratamento local"]
				var channel := button(modal_box,names[index],func(): _apply(panel_id,index))
				if index==world.journey.value("water_route"):channel.grab_focus()
	button(modal_box,"Cancelar / voltar",close_modal,Vector2(0,56))

func _apply(panel: String, argument: int) -> void:
	var result: Dictionary = world.configure_system(panel,argument)
	close_modal()
	notify(result.message)

func show_decision() -> void:
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/dialogue.json"))
	var dialogue: Dictionary = story[world.station_id+"_decision"]
	_clear_modal(str(dialogue.speaker),"\n".join(dialogue.lines))
	for option in dialogue.choices:
		var choice := str(option.effect.choice)
		var destination := button(modal_box,str(option.text),func():
			close_modal()
			world.finish(choice))
		if modal_box.get_child_count()==3:destination.grab_focus()

func show_signal_summary() -> void:
	var restored: bool = world.journey.choices.water=="RESTORE"
	var consequence := "O núcleo permanece no Recife. A água sustentará as casas; {player} e Lyra ficam com a comunidade." if restored else "O núcleo alimentará os reservatórios da ARCA-01. {player} e Lyra poderão partir, mas o Recife ainda precisa de água."
	_clear_modal("O ÚLTIMO SINAL",consequence.replace("{player}",GameState.player_name)+"\n\nEsta é a conclusão da jornada. Transmita para ver o desfecho da sua escolha.")
	button(modal_box,"Transmitir e ver o final",func():
		touch.release_all()
		if not world.journey.complete_signal():
			notify("Não foi possível concluir o salvamento. Verifique o armazenamento e tente novamente.")).grab_focus()
	button(modal_box,"Voltar e conferir",close_modal)
