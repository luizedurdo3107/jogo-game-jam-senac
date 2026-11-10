extends "res://scripts/puzzles/station_system.gd"

func sync_access() -> void:
	if value("water_pump")==1:set_value("water_open",1)

func pressure() -> int:
	return value("water_a")*20+value("water_b")*10

func interact(command: String) -> Dictionary:
	match command:
		"route":
			return {"ok":true,"panel":"water_route"}
		"memory":
			set_value("water_memory",1)
			return {"ok":true,"memory":"CAPIBARIBE / REGISTRO DE 2034","message":"Reconstrução histórica, não viagem no tempo. O canal B alimentava o filtro comunitário. Regime seguro: 60 kPa, válvulas A=2 e B=2. A água menos contaminada deste registro não altera o rio atual."}
		"drain":
			if value("water_route")!=1:
				return blocked("Canal incompatível. GAIA precisa conectar o canal B ao filtro, não o esgoto ou o bypass da ARCA.")
			set_value("water_drained",1)
			return accepted("Comando remoto autorizado: câmara drenada. O módulo está acessível na sala inferior.")
		"module":
			if value("water_drained")!=1:
				return blocked("Câmara alagada. Use o controlador de drenagem de GAIA antes de descer.")
			if value("water_module")>0:
				return blocked("O módulo já está transportado ou instalado. Nenhuma duplicação.")
			set_value("water_module",1)
			return accepted("Módulo transportado pelo corpo. Instale na bomba da rua.")
		"install":
			if value("water_module")!=1:
				return blocked("Recolha o módulo na câmara inferior já drenada.")
			set_value("water_module",2)
			return accepted("Módulo encaixado. Abra os dois registros e observe a pressão. A faixa segura está marcada na bomba.")
		"valve_a","valve_b":
			if value("water_pump")==1:
				return blocked("Registros travados em regime seguro após a abertura.")
			var key := "water_a" if command=="valve_a" else "water_b"
			set_value(key,(value(key)+1)%3)
			set_value("water_authorized",0)
			return accepted("Registro %s = %d. Pressão combinada: %d kPa. Meta: 60 kPa."%["A" if command=="valve_a" else "B",value(key),pressure()])
		"authorize":
			if value("water_route")!=1 or value("water_module")!=2 or pressure()!=60:
				return blocked("Pressão insegura: %d / 60 kPa. Exige canal B, módulo instalado e A=2 / B=2. Nada foi consumido."%pressure())
			set_value("water_authorized",1)
			return accepted("GAIA validou pressão e contaminação. O corpo pode ligar a bomba.")
		"pump":
			if value("water_authorized")!=1 or pressure()!=60 or value("water_module")!=2 or value("water_route")!=1:
				return blocked("Bomba intertravada: valide a rede e os 60 kPa com GAIA antes da partida física.")
			set_value("water_pump",1)
			set_value("water_open",1)
			return accepted("Bomba em movimento. Água circulando e passagem automática liberada. Escolha o destino do núcleo.")
	return super.interact(command)

func configure(panel: String, argument: int) -> Dictionary:
	if panel!="water_route" or argument<0 or argument>2:
		return blocked("Canal inexistente.")
	if value("water_pump")==1:
		return blocked("A rede já foi estabilizada; configuração preservada.")
	set_value("water_route",argument)
	set_value("water_authorized",0)
	return accepted("Canal B conectado ao filtro. Agora autorize a drenagem remota." if argument==1 else "Falha de conexão: rota contaminada ou bypass. Escolha outro canal; a tentativa não consome o módulo.")

func diagnostic() -> String:
	return "REDE HÍDRICA / %s\nPRESSÃO %d / 60 kPa · CONTAMINAÇÃO %d%%\nCÂMARA %s · MÓDULO %d/2"%["CANAL B" if value("water_route")==1 else "FALHA DE ROTA",pressure(),18 if journey.choices.water=="RESTORE" else 82,"DRENADA" if value("water_drained")==1 else "ALAGADA",value("water_module")]

func objective() -> String:
	if journey.choices.water!="PENDING":return "Água: destino registrado. Siga pela saída para o Banco Verde."
	if value("water_route")!=1:return "GAIA: encontre um caminho de água limpa."
	if value("water_drained")==0:return "GAIA: autorize a drenagem da câmara inferior."
	if value("water_module")==0:return "Físico: desça à câmara drenada e recolha o módulo."
	if value("water_module")==1:return "Físico: instale o módulo na bomba da rua."
	if pressure()!=60:return "Corpo: ajuste os registros até a faixa segura da bomba."
	if value("water_authorized")==0:return "GAIA: analise a pressão e autorize o controlador."
	if value("water_pump")==0:return "Físico: ligue a bomba e observe o reservatório."
	return "Decida o destino do núcleo e siga para o Banco Verde."
