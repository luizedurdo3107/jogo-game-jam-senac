extends "res://scripts/ui/game_hud.gd"

func refresh() -> void:
	super.refresh()
	perspective.text = "[Q] GAIA / NEXUS" if GameState.gaia_active else "[Q] CORPO / PORTO"

func show_help() -> void:
	_clear_modal("O ÚLTIMO SINAL",world.system.objective()+"\n\nOs recursos distribuídos continuam com seus destinos. Aqui, sua decisão pessoal entre ficar e partir é definitiva.")
	button(modal_box,"Continuar",close_modal).grab_focus()

func show_final() -> void:
	var lines: Array[String] = []
	for region in StationJourney.ORDER:
		lines.append({"water":"Água","soil":"Sementes","air":"Ar"}[region]+": "+("comunidade" if world.journey.choices[region]=="RESTORE" else "ARCA-01"))
	_clear_modal("FUTURO / SUA ESCOLHA",", ".join(lines)+".\n\nGAIA ajuda a recuperar a Terra e bloqueia a saída para Marte.\n\nSão futuros possíveis, não profecias. Sua escolha acontece agora e não redistribui os núcleos.")
	button(modal_box,"Ficar na Terra · Restaurar com GAIA",func():_confirm("EARTH")).grab_focus()
	button(modal_box,"Partir para Marte · Enfrentar o bloqueio",func():_confirm("MARS"))
	button(modal_box,"Pensar mais um pouco",close_modal)

func _confirm(destination: String) -> void:
	_clear_modal("PRESENTE / DECISÃO DEFINITIVA",("GAIA continuará ao seu lado na recuperação da Terra. Não haverá confronto para ficar." if destination=="EARTH" else "O exército de Nova Éden bloqueia a doca: você terá de vencer a guarnição e o comandante antes de embarcar. Depois, desligue a contenção pelos comandos locais. GAIA não é sua inimiga nem ajuda a fuga: ficará restaurando a Terra.")+"\n\nOs recursos já distribuídos não mudam.")
	button(modal_box,"Confirmar",func():
		touch.release_all()
		if not world.journey.choose_destination(destination):notify("Não foi possível salvar. Tente novamente.")).grab_focus()
	button(modal_box,"Voltar",show_final)
