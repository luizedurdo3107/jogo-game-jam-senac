extends "res://scripts/puzzles/station_system.gd"

const HUMIDITY := [20,45,80]
const TEMPERATURE := [18,24,35]

func safe_conditions() -> bool:
	return value("soil_filter")==2 and value("soil_mask")==10 and value("soil_humidity")==1 and value("soil_temperature")==1

func interact(command: String) -> Dictionary:
	match command:
		"memory":
			set_value("soil_memory",1)
			return {"ok":true,"memory":"MANGUE EXPERIMENTAL / ARQUIVO 2061","message":"Reconstrução histórica, sem alterar o passado. O mangue mantinha raízes úmidas, não encharcadas. Cápsulas B e D conservam membranas íntegras. Regime registrado: 45% de umidade e 24°C. A cápsula A está contaminada; C perdeu a membrana."}
		"filter":
			if value("soil_filter")>0:return blocked("O filtro já foi recolhido ou está instalado.")
			set_value("soil_filter",1)
			return accepted("Filtro carregado. Leve ao leito de irrigação na passarela da estufa.")
		"install":
			if value("soil_filter")!=1:return blocked("O corpo precisa recolher o filtro do laboratório de sementes antes da instalação.")
			set_value("soil_filter",2)
			return accepted("Filtro colocado. As cápsulas ainda precisam de seleção digital, temperatura e umidade corretas.")
		"humidity":
			if value("soil_irrigation")==1:return blocked("Umidade estabilizada. Não danifique a germinação já iniciada.")
			set_value("soil_humidity",(value("soil_humidity")+1)%3)
			set_value("soil_authorized",0)
			return accepted("Válvula física de umidade: %d%%. A memória registra 45%%, evitando ressecamento e alagamento."%HUMIDITY[value("soil_humidity")])
		"capsules":return {"ok":true,"panel":"soil_capsules"}
		"temperature":return {"ok":true,"panel":"soil_temperature"}
		"authorize":
			if not safe_conditions():return blocked("Cofre intertravado. Exige filtro instalado, SOMENTE B+D, umidade 45% e temperatura 24°C. Nada foi consumido.")
			set_value("soil_authorized",1)
			return accepted("GAIA conectou B+D à rede estéril. O corpo pode iniciar a irrigação com segurança.")
		"irrigate":
			if not safe_conditions() or value("soil_authorized")!=1:return blocked("Não inicie a irrigação antes da validação de cápsulas, filtro e clima por GAIA.")
			set_value("soil_irrigation",1)
			return accepted("Irrigação localizada iniciada. Abra fisicamente o cofre; germinação exige cuidado contínuo.")
		"door":
			if value("soil_irrigation")!=1:return blocked("O cofre precisa da rede estéril e da irrigação validada. Ainda não há acesso seguro às sementes.")
			set_value("soil_open",1)
			return accepted("Cofre biológico aberto. Lyra pergunta se o núcleo ficará na estufa ou será levado para a ARCA.")
	return super.interact(command)

func configure(panel: String, argument: int) -> Dictionary:
	if value("soil_irrigation")==1:return blocked("Condições de preservação já estabilizadas.")
	if panel=="soil_capsules" and argument>=0 and argument<=15:
		set_value("soil_mask",argument)
		set_value("soil_authorized",0)
		return accepted("B e D conectadas. Complete a temperatura e a umidade." if argument==10 else "FALHA BIOLÓGICA: selecione somente B e D. A está contaminada; C está rompida. Você pode refazer sem perder o filtro.")
	if panel=="soil_temperature" and argument>=0 and argument<=2:
		set_value("soil_temperature",argument)
		set_value("soil_authorized",0)
		return accepted("Termostato remoto: %d°C. %s"%[TEMPERATURE[argument],"Regime de germinação correto." if argument==1 else "Fora do regime 24°C; corrija antes de irrigar."])
	return super.configure(panel,argument)

func diagnostic() -> String:
	return "BANCO GENÉTICO / %s\nUMIDADE %d%% · TEMPERATURA %d°C\nB+D %s · FILTRO %d/2"%["REDE ESTÉRIL" if safe_conditions() else "FALHA DE CONDIÇÕES",HUMIDITY[value("soil_humidity")],TEMPERATURE[value("soil_temperature")],"CONECTADAS" if value("soil_mask")==10 else "DESCONECTADAS",value("soil_filter")]

func objective() -> String:
	if journey.choices.soil!="PENDING":return "Sementes: destino registrado. Siga pela saída para a Torre Atmos."
	if value("soil_filter")==0:return "Físico: recolha o filtro no laboratório de sementes."
	if value("soil_filter")==1:return "Físico: instale o filtro na estufa superior."
	if value("soil_mask")!=10:return "GAIA: examine as cápsulas e conecte somente B+D."
	if value("soil_temperature")!=1:return "GAIA: ajuste o controle térmico remoto para 24°C."
	if value("soil_humidity")!=1:return "Físico: regule a umidade para 45%."
	if value("soil_authorized")==0:return "GAIA: valide a rede estéril das cápsulas."
	if value("soil_irrigation")==0:return "Físico: inicie a irrigação localizada."
	if value("soil_open")==0:return "Físico: abra o cofre biológico."
	return "Escolha o destino das sementes e siga à Torre Atmos."
