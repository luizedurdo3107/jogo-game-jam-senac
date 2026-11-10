extends "res://tools/context_pitch.gd"

func _configure() -> void:
	edit_folder = "outputs/pitch/rc5_edit"
	movie_name = "LAST_SIGNAL_RC5_COMBATE_E_FUGA_60S"
	source_manifest = "res://outputs/pitch/departure_edit/planos.json"
	method = "Capturas nativas com comandos automatizados e checkpoints isolados. Primeiras fases: recortes anteriores. NEXUS, guarnição completa no Difícil e epílogo: nova captura rc5, sem alterar vida, dano ou invulnerabilidade. Sem aceleração."
	context = [
		{"start":0.0,"end":4.0,"phase":"01 · NOVA ÉDEN | RECIFE, 2187","text":"Em uma Terra em colapso, Kairo tenta deixar a cidade."},
		{"start":4.0,"end":8.0,"phase":"01 · NOVA ÉDEN | COMBATE","text":"O exército bloqueia a saída. Vença o capitão para escapar."},
		{"start":8.0,"end":10.0,"phase":"SAÍDA DE NOVA ÉDEN","text":"Passagem livre. Rumo ao Recife Antigo."},
		{"start":10.0,"end":13.0,"phase":"02 · RECIFE ANTIGO | COMUNIDADE","text":"Bomba comunitária reparada. Caminho até GAIA liberado."},
		{"start":13.0,"end":18.0,"phase":"03 · LABORATÓRIO GAIA | DUAS PERSPECTIVAS","text":"GAIA revela circuitos. Volte ao corpo para abrir a comporta."},
		{"start":18.0,"end":23.0,"phase":"04 · CAPIBARIBE | ÁGUA","text":"Ligue a bomba e devolva água à comunidade."},
		{"start":23.0,"end":28.0,"phase":"05 · BANCO VERDE | SEMENTES","text":"Preserve as sementes: os primeiros brotos voltam a crescer."},
		{"start":28.0,"end":33.0,"phase":"06 · TORRE ATMOS | AR","text":"Reative turbina e filtros para devolver ar limpo aos bairros."},
		{"start":33.0,"end":37.0,"phase":"07 · NEXUS | SUA ESCOLHA","text":"As estações foram restauradas. Agora, ficar na Terra ou partir?"},
		{"start":37.0,"end":42.0,"phase":"DOCA TERRESTRE | COMBATE FINAL","text":"O exército de Nova Éden impede a partida para Marte."},
		{"start":42.0,"end":47.0,"phase":"DOCA TERRESTRE | VENÇA PARA EMBARCAR","text":"Vença o comandante e desligue a contenção por comandos locais."},
		{"start":47.0,"end":50.0,"phase":"ARCA-01 | EMBARQUE","text":"Guarnição e contenção superadas. Próxima parada: Marte."},
		{"start":50.0,"end":54.0,"phase":"DECOLAGEM | DEIXANDO A TERRA","text":"GAIA fica restaurando a Terra. A ARCA-01 decola."},
		{"start":54.0,"end":60.0,"phase":"RUMO A MARTE | UM DOS FINAIS","text":"A Terra fica para trás. Este é um dos finais possíveis."}
	]

func _segments(original: Dictionary) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var cursor := 0.0
	for item in [["01_combate",0,4],["02_capitao",4,4],["03_saida_cidade",0.8,2],["04_recife_final",0,3],["05_laboratorio_final",0,5],["06_capibaribe_final",0,5],["07_banco_verde_final",0,5],["08_atmos_final",0,5]]:
		segments.append({"name":item[0],"source":"outputs/pitch/capturas_acao/"+item[0]+".mkv","source_start":item[1],"seconds":item[2],"timeline_start":cursor,"decision":false})
		cursor += float(item[2])
	for shot in original.shots:
		var seconds := float(shot.frames)/30.0
		segments.append({"name":shot.name,"source":"outputs/pitch/capturas_rc5/"+shot.name+".mkv","source_start":0.0,"seconds":seconds,"timeline_start":cursor,"decision":shot.name=="final_nexus"})
		cursor += seconds
	assert(is_equal_approx(cursor,60.0))
	return segments
