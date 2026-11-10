extends "res://scripts/puzzles/station_system.gd"

func sync_access() -> void:
	_open_access()

func interact(command: String) -> Dictionary:
	match command:
		"scan":
			set_value("air_scan",1)
			return accepted("Falhas localizadas: estágios em andares diferentes. Ordem: PRÉ-FILTRO (andar 2), CARVÃO (andar 1), TURBINA (andar 3). Os comandos digitais movem os dutos remotamente.")
		"memory":
			set_value("air_memory",1)
			return {"ok":true,"memory":"ATMOS / REGISTRO DE OPERAÇÃO 2112","message":"Arquivo reconstruído, sem viagem temporal. Partículas grandes eram retiradas ANTES do carvão ativado; só depois a turbina devolvia ar ao bairro. Pré-filtro → carvão → turbina. A técnica conhece a derivação segura para os alojamentos."}
		"module":
			if value("air_module")>0:return blocked("Módulo já transportado ou instalado.")
			set_value("air_module",1)
			return accepted("Módulo de arranque carregado. Instale no painel do elevador no térreo.")
		"install":
			if value("air_module")!=1:return blocked("Recolha o módulo de arranque no depósito do térreo.")
			set_value("air_module",2)
			return accepted("Elevador energizado. As escadas externas continuam sendo uma rota alternativa.")
		"technician":
			if value("air_module")!=2:return blocked("A técnica pede energia para o arranque antes de negociar a derivação de ar.")
			return {"ok":true,"technician":true}
		"maintenance":
			if value("air_scan")!=1 or value("air_team")!=1:return blocked("Solicitação remota exige diagnóstico e autorização da técnica. Converse no mundo físico.")
			set_value("air_drone",1)
			return accepted("Drone redirecionado à doca de manutenção. Nenhum dano; passarela liberada.")
		"filter":
			if value("air_open")==1:return blocked("Filtro travado na posição de operação segura.")
			set_value("air_filter",(value("air_filter")+1)%3)
			_open_access()
			return accepted("Filtro físico: %s. Regime exigido: FILTRAR."%["ISOLADO","FILTRAR","BYPASS"][value("air_filter")])
		"coarse","carbon","turbine":
			if value("air_scan")!=1 or value("air_module")!=2:return blocked("Primeiro diagnostique a torre com GAIA e instale o módulo físico.")
			var step: int = ["coarse","carbon","turbine"].find(command)
			var progress := value("air_sequence")
			if step<progress:return blocked("Este estágio digital já foi conectado. Siga ao próximo, sem repetir.")
			if step!=progress:
				set_value("air_sequence",0)
				return blocked("Ordem insegura. A sequência foi reiniciada, não o progresso da torre. Use pré-filtro → carvão → turbina; consulte a memória.")
			set_value("air_sequence",progress+1)
			_open_access()
			return accepted("Estágio %d/3 conectado. Duto remoto liberado: %s."%[progress+1,["PRÉ-FILTRO","CARVÃO","TURBINA"][step]])
	return super.interact(command)

func configure(panel: String, argument: int) -> Dictionary:
	if panel=="air_team" and argument in [0,1] and value("air_module")==2:
		set_value("air_team",1)
		_open_access()
		return accepted("A equipe recebeu a derivação de ar. A técnica autorizou manutenção pacífica e acesso aos controles.")
	return super.configure(panel,argument)

func _open_access() -> void:
	if value("air_sequence")==3 and value("air_filter")==1 and value("air_team")==1:set_value("air_open",1)

func diagnostic() -> String:
	return "ATMOS / ESTÁGIOS %d/3\nPARTÍCULAS %d µg/m³ · FILTRO %s\nDRONE %s · EQUIPE %s"%[value("air_sequence"),38 if journey.choices.air=="RESTORE" else 168,["ISOLADO","FILTRAR","BYPASS"][value("air_filter")],"MANUTENÇÃO" if value("air_drone")==1 else "EM PATRULHA","ATENDIDA" if value("air_team")==1 else "SEM DERIVAÇÃO"]

func objective() -> String:
	if journey.choices.air!="PENDING":return "Ar: destino registrado. Siga ao porto NEXUS pela saída superior."
	if value("air_scan")==0:return "GAIA: diagnostique os filtros e a circulação da torre."
	if value("air_module")==0:return "Físico: recolha o módulo de arranque no térreo."
	if value("air_module")==1:return "Físico: instale o módulo no arranque do elevador."
	if value("air_team")==0:return "Físico: negocie a derivação de ar com a técnica."
	if value("air_sequence")==0:return "GAIA: conecte o PRÉ-FILTRO no andar 2 (5,2 m)."
	if value("air_sequence")==1:return "GAIA: conecte CARVÃO no andar 1 (2,6 m)."
	if value("air_sequence")==2:return "GAIA: conecte TURBINA no andar 3 (7,8 m)."
	if value("air_filter")!=1:return "Físico: coloque o filtro mecânico em FILTRAR, andar 2."
	return "Registre o último destino e siga para o porto NEXUS."
