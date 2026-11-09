extends "res://scripts/puzzles/station_system.gd"

const STEPS := ["nexus_voss","nexus_scan","nexus_locks","nexus_authorized","nexus_open"]
const OBJECTIVES := ["Ouça Helena Voss no canal de recepção.","GAIA: suba à passarela e analise os três destinos.","Corpo: desça à sala técnica e libere as travas.","GAIA: valide o roteamento no terminal superior.","Corpo: abra o painel protegido da NEXUS."]

func interact(command: String) -> Dictionary:
	var index := STEPS.find(command)
	if index<0:return blocked("Comando desconhecido.")
	if value(command)==1:return blocked("Etapa já concluída. "+objective())
	if index>0 and value(STEPS[index-1])!=1:return blocked(objective())
	if journey.choices.values().has("PENDING"):return blocked("Registre primeiro os três destinos ambientais.")
	set_value(command,1)
	match command:
		"nexus_voss":return {"ok":true,"memory":"HELENA VOSS / NEXUS","message":"A ARCA-01 pode partir, mas não pode levar todos. Vocês distribuíram três núcleos. Não vou apagar essas escolhas. Confiram o roteamento antes de transmitir.\n\nLyra: partir ou ficar não elimina nossa responsabilidade por quem continua aqui."}
		"nexus_scan":return {"ok":true,"memory":"GAIA / TRÊS DESTINOS","message":"Os destinos estão registrados. Os condutores passam pela sala inferior. Eu consigo validá-los, mas só seu corpo pode soltar as travas mecânicas. Desça pela escada amarela."}
		"nexus_authorized":return accepted("Destinos validados. Volte ao corpo e abra o painel no cais.")
		"nexus_open":return accepted("Painel aberto. Siga à direita, confira os três núcleos e confirme a transmissão.")
	return accepted("Travas liberadas. Suba e peça a validação de GAIA.")

func objective() -> String:
	for index in range(STEPS.size()):
		if value(STEPS[index])!=1:return OBJECTIVES[index]
	return "Confira os três destinos no transmissor e confirme o sinal final."

func diagnostic() -> String:
	return "NEXUS / ROTEAMENTO\nÁgua: %s\nSementes: %s\nAr: %s"%[journey.choices.water,journey.choices.soil,journey.choices.air]
