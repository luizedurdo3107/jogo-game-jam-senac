extends "res://scripts/ui/game_hud.gd"

func refresh() -> void:
	super.refresh()
	perspective.text = "[G] GAIA / NEXUS" if GameState.gaia_active else "[F] CORPO / PORTO DO RECIFE"

func show_help() -> void:
	_clear_modal("O ÚLTIMO SINAL",world.system.objective()+"\n\nCorpo: conversa e libera travas.\nGAIA: analisa condutores e valida destinos.\nEscadas amarelas ligam cais, passarela e subsolo.\nA maioria dos núcleos determina o final.")
	button(modal_box,"Continuar",close_modal).grab_focus()

func show_final() -> void:
	var lines: Array[String] = []
	for region in StationJourney.ORDER:
		lines.append({"water":"ÁGUA","soil":"SEMENTES","air":"AR"}[region]+": "+("Recife / restauração local" if world.journey.choices[region]=="RESTORE" else "ARCA-01 / evacuação"))
	_clear_modal("TRANSMISSÃO / CONFIRMAR DESTINOS","\n".join(lines)+"\n\nA confirmação não redistribui recursos. Cada decisão permanece registrada.")
	button(modal_box,"Confirmar o último sinal",func():
		touch.release_all()
		world.journey.complete_nexus()).grab_focus()
	button(modal_box,"Voltar e conferir",close_modal)
