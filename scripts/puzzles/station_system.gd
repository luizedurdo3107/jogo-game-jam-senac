extends RefCounted

var journey: Node

func sync_access() -> void:
	pass

func value(key: String) -> int:
	return journey.value(key)

func set_value(key: String, number: int) -> void:
	journey.put(key,number)

func accepted(message: String) -> Dictionary:
	return {"ok":true,"message":message}

func blocked(message: String) -> Dictionary:
	return {"ok":false,"message":message}

func interact(_command: String) -> Dictionary:
	return blocked("Este equipamento não responde.")

func configure(_panel: String, _argument: int) -> Dictionary:
	return blocked("Não há controle digital disponível.")

func diagnostic() -> String:
	return "SISTEMA OFFLINE"

func objective() -> String:
	return "Investigue os equipamentos."
