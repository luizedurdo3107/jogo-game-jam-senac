extends SceneTree

func _initialize() -> void:
	call_deferred("analyze")

func pcm(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if not file:return {}
	if file.get_buffer(4).get_string_from_ascii()!="RIFF":return {}
	file.seek(12)
	var rate := 0
	var channels := 0
	var bits := 0
	var format := 0
	var data := PackedByteArray()
	while file.get_position()+8<file.get_length():
		var chunk := file.get_buffer(4).get_string_from_ascii()
		var size := file.get_32()
		var finish := file.get_position()+size+size%2
		if chunk=="fmt ":
			format = file.get_16()
			channels = file.get_16()
			rate = file.get_32()
			file.get_32()
			file.get_16()
			bits = file.get_16()
		elif chunk=="data":data = file.get_buffer(size)
		file.seek(finish)
	if bits!=16 or format!=1 or data.is_empty():return {}
	var peak := 0
	var clipped := 0
	var energy := 0.0
	var total := 0.0
	var differences := 0.0
	var count := data.size()/2
	for index in range(count):
		var value := data.decode_s16(index*2)
		peak = maxi(peak,absi(value))
		if absi(value)>=32760:clipped += 1
		energy += pow(value/32768.0,2)
		total += value/32768.0
		if index>=channels:differences += pow((value-data.decode_s16((index-channels)*2))/32768.0,2)
	var boundary := 0.0
	for channel in range(channels):boundary = maxf(boundary,absf(data.decode_s16(channel*2)-data.decode_s16((count-channels+channel)*2))/32768.0)
	var rms := sqrt(energy/count)
	var derivative := sqrt(differences/maxi(1,count-channels))
	return {"seconds":count/float(channels*rate),"rate":rate,"channels":channels,"peak_dbfs":linear_to_db(maxf(0.000001,peak/32768.0)),"rms_dbfs":linear_to_db(maxf(0.000001,rms)),"dc":total/count,"clipped_samples":clipped,"loop_boundary_jump":boundary,"boundary_vs_normal_derivative":boundary/maxf(0.000001,derivative)}

func analyze() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/catalog.json"))
	var measurements: Dictionary = {}
	var failures := 0
	var inventory := "# Inventário de áudio original\n\nTodos os 79 arquivos são sound design procedural original, não gravações de campo. Sem amostras externas, TTS ou vozes simuladas. Licença: LicenseRef-LastSignal-Original (`assets/audio/ORIGEM_E_LICENCA.md`).\n\nPCM 16-bit/48 kHz mono nos efeitos curtos; Vorbis/48 kHz estéreo nos loops. Os hashes são dos arquivos efetivamente distribuídos.\n\n| Família | Variantes | Duração (s) | Bus | Ganho (dB) | Loop |\n|---|---:|---:|---|---:|---|\n"
	for sound_id in catalog:
		var definition: Dictionary = catalog[sound_id]
		inventory += "| %s | %d | %.2f | %s | %.1f | %s |\n"%[sound_id,definition.paths.size(),definition.seconds,definition.bus,definition.gain_db,"sim" if definition.loop else "não"]
		for runtime in definition.paths:
			var decoded: String = "res://work/audio_decoded/"+str(runtime).get_file().get_basename()+".wav" if str(runtime).ends_with(".ogg") else runtime
			var stats := pcm(decoded)
			if stats.is_empty():
				failures += 1
				push_error("PCM inválido: "+decoded)
				continue
			stats["sha256"] = FileAccess.get_sha256(runtime)
			stats["license"] = "LicenseRef-LastSignal-Original"
			stats["source"] = "Procedural original / sem gravação de campo ou voz humana"
			stats["loop"] = definition.loop
			stats["technical_pass"] = stats.clipped_samples==0 and stats.rms_dbfs> -65 and stats.peak_dbfs< -0.2 and absf(stats.dc)<0.005 and (not definition.loop or stats.loop_boundary_jump<0.15 and stats.boundary_vs_normal_derivative<8)
			if not stats.technical_pass:
				failures += 1
				push_error("Métrica fora do limite: "+str(runtime))
			measurements[runtime] = stats
	var output := FileAccess.open("res://outputs/AUDIO_ANALISE_DISTRIBUICAO.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"files":measurements,"count":measurements.size(),"failures":failures,"note":"Teste técnico, não substitui avaliação humana de naturalidade/timbre com fones e caixas."},"\t"))
	output = FileAccess.open("res://outputs/INVENTARIO_AUDIO.md",FileAccess.WRITE)
	output.store_string(inventory)
	print("ANÁLISE PCM/VORBIS: %d arquivos, %d falhas"%[measurements.size(),failures])
	quit(0 if failures==0 else 1)
