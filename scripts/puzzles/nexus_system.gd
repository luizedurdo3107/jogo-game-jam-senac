extends "res://scripts/puzzles/station_system.gd"

const STEPS := ["nexus_voss"]

func sync_access() -> void:
	if value("nexus_voss")==1:
		for key in ["nexus_scan","nexus_locks","nexus_authorized","nexus_open"]:set_value(key,1)

func interact(command: String) -> Dictionary:
	if journey.choices.values().has("PENDING"):return blocked("Registre primeiro os três destinos ambientais.")
	if command=="nexus_scan":
		return {"ok":true,"dialogue":"GAIA / PRESENTE","message":"Estamos em 2187. Vou ajudar a restaurar a Terra. O transmissor já está acessível; não há outro circuito ou porta para destravar. Só bloquearei a saída se você insistir em partir para Marte."}
	if command!="nexus_voss":return blocked("Esse painel de acesso não é mais necessário.")
	for key in ["nexus_voss","nexus_scan","nexus_locks","nexus_authorized","nexus_open"]:set_value(key,1)
	return {"ok":true,"dialogue":"HELENA VOSS / NEXUS","message":"O exército tentou impedir sua saída de Nova Éden. Aqui, vou deixar você decidir. Os três núcleos já têm seus destinos; não vou apagá-los. O caminho ao transmissor está livre.\n\nLyra: ficar na Terra ou partir para Marte ainda é sua escolha."}

func objective() -> String:
	return "Ouça Voss no rádio da recepção." if value("nexus_voss")==0 else "Siga ao transmissor e escolha: ficar na Terra ou partir para Marte."

func diagnostic() -> String:
	return "NEXUS / DESTINOS REGISTRADOS\nÁgua: %s\nSementes: %s\nAr: %s"%[journey.choices.water,journey.choices.soil,journey.choices.air]
