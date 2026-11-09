extends SceneTree

const RATE := 48000
const ROOT := "res://assets/audio/"
var catalogue: Dictionary = {}
var measurements: Dictionary = {}

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	for folder in ["ambience","sfx","ui","music","voices"]:
		DirAccess.make_dir_recursive_absolute(ROOT+folder)
		DirAccess.make_dir_recursive_absolute("res://work/audio_sources/"+folder)
	for region in ["nova","recife","lab","water","soil","air","nexus","recife_after","water_after","soil_after","air_after"]:
		create("amb_"+region,region,"ambience",24.0,1,true)
	for machine in ["pump_rough","pump_steady","irrigation","fan_rough","fan_steady","lift_motor","drone_rotor","gaia_layer"]:
		create(machine,machine,"ambience" if machine=="gaia_layer" else "sfx",12.0,1,true)
	for surface in ["concrete","metal","wet"]:
		create("step_"+surface,"step_"+surface,"sfx",0.38,4)
		create("land_"+surface,"land_"+surface,"sfx",0.62,2)
	for definition in [["jump",0.32,2],["ladder",0.28,3],["pickup",0.48,2],["install",0.6,2],["valve",0.85,2],["pressure",1.45,2],["gate",2.1,1],["door",1.1,2],["capsule",1.2,1],["pump_start",1.5,1],["irrigation_start",1.1,1],["fan_start",1.5,1],["lift_start",0.7,1],["lift_stop",0.7,1],["power_restore",1.65,1],["reserve",1.8,1],["archive",1.15,1],["scan",0.65,2],["circuit",0.3,2],["gaia_switch",0.75,2],["drone_alert",0.8,1],["object_move",0.65,2]]:
		create(definition[0],definition[0],"sfx",definition[1],definition[2])
	for action in ["hover","confirm","cancel","notify"]:
		create("ui_"+action,"ui_"+action,"ui",0.08 if action=="hover" else 0.17,2)
	var file := FileAccess.open("res://data/audio/catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(catalogue,"\t"))
	file.close()
	file = FileAccess.open("res://outputs/AUDIO_ANALISE_FONTES.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements,"\t"))
	file.close()
	print("ÁUDIO ORIGINAL: %d famílias, %d arquivos PCM medidos"%[catalogue.size(),measurements.size()])
	quit()

func create(sound_id: String, kind: String, folder: String, seconds: float, variants: int, looping := false) -> void:
	var paths: Array[String] = []
	for variant in range(variants):
		var name := sound_id+("_%02d"%(variant+1) if variants>1 else "")
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(("EARTH404/audio/v1/"+name).hash())
		var stereo := looping
		var buffer: PackedFloat32Array
		if looping:
			buffer = bed(kind,seconds+2,rng)
			buffer = close_loop(buffer,int(seconds*RATE),2*RATE)
		else:
			buffer.resize(int(seconds*RATE))
			impact(buffer,0,seconds,kind,rng,1.0)
			if kind in ["valve","gate","door","capsule","install","power_restore","lift_stop"]:
				impact(buffer,seconds*0.63,minf(0.24,seconds*0.3),"latch",rng,0.48)
		var target := -22.0 if looping else (-27.0 if folder=="ui" else -20.0)
		var stats := finish(buffer,target,looping,stereo)
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = RATE
		stream.stereo = stereo
		var samples := PackedByteArray()
		samples.resize(buffer.size()*2)
		for sample_index in range(buffer.size()):samples.encode_s16(sample_index*2,int(clampf(buffer[sample_index],-0.98,0.98)*32767))
		stream.data = samples
		var destination := ("res://work/audio_sources/" if looping else ROOT)+folder+"/"+name+".wav"
		stream.save_to_wav(destination)
		var runtime := ROOT+folder+"/"+name+(".ogg" if looping else ".wav")
		paths.append(runtime)
		stats["source"] = "Sound design procedural original: ruído filtrado, modelos modais, grãos e camadas; não é gravação de campo."
		stats["seed"] = absi(("EARTH404/audio/v1/"+name).hash())
		stats["license"] = "LicenseRef-LastSignal-Original"
		stats["runtime"] = runtime
		measurements[name] = stats
	var gain := -5.0 if sound_id.begins_with("step_") else (-8.0 if folder=="ui" else -3.0)
	if looping:gain = -2.0 if folder=="ambience" else -8.0
	catalogue[sound_id] = {"paths":paths,"loop":looping,"bus":"UI" if folder=="ui" or sound_id in ["scan","circuit","archive","gaia_switch"] else ("Ambience" if folder=="ambience" else "SFX"),"gain_db":gain,"seconds":seconds,"pitch_variation":0.025 if not looping else 0.0,"cooldown":0.12 if folder=="ui" else 0.05}
	print("Gerado: "+sound_id)

func bed(kind: String, seconds: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	var count := int(seconds*RATE)
	result.resize(count*2)
	var profiles := {"nova":[0.9,0.18,0.38,0.06],"recife":[0.28,0.48,0.03,0.46],"lab":[0.65,0.2,0.16,0.04],"water":[0.28,0.18,0.02,0.88],"soil":[0.15,0.22,0.01,0.19],"air":[0.55,0.75,0.06,0.06],"nexus":[1.0,0.28,0.55,0.12],"recife_after":[0.22,0.3,0.01,0.6],"pump_rough":[0.8,0.23,0.6,0.35],"pump_steady":[0.6,0.12,0.3,0.48],"irrigation":[0.08,0.16,0.0,1.0],"fan_rough":[0.8,0.9,0.5,0.0],"fan_steady":[0.55,0.65,0.15,0.0],"lift_motor":[0.85,0.3,0.6,0.0],"drone_rotor":[0.24,0.75,0.2,0.0],"gaia_layer":[0.12,0.15,0.02,0.02]}
	var base_kind := kind.trim_suffix("_after") if kind!="recife_after" else kind
	var profile: Array = profiles[base_kind].duplicate()
	if kind=="water_after":profile = [0.12,0.12,0.01,1.2]
	elif kind=="soil_after":profile = [0.07,0.32,0.0,0.48]
	elif kind=="air_after":profile = [0.3,0.5,0.01,0.0]
	for channel in range(2):
		var bass := 0.0
		var body := 0.0
		var air := 0.0
		var flow := 0.0
		var gust := 0.4
		var target := 0.5
		var phase := rng.randf()*TAU
		for sample_index in range(count):
			var time := sample_index/float(RATE)
			if sample_index%12000==0:target = rng.randf_range(0.15,0.95)
			gust += (target-gust)*0.00011
			var noise := rng.randf_range(-1,1)
			bass += (noise-bass)*0.006
			body += (noise-body)*0.075
			air += (noise-air)*0.34
			flow += (noise-flow)*0.025
			var wash: float = (air-body)*(0.35+gust)*profile[1]
			var fluid: float = (body-flow)*(0.4+0.6*pow(sin(time*0.71+phase),2))*profile[3]
			var mechanical: float = (sin(time*TAU*53.25+phase)*0.025+sin(time*TAU*107.125+phase)*0.012+(body-bass)*0.13)*profile[2]
			if kind.begins_with("pump") or kind.begins_with("fan") or kind=="drone_rotor":
				var wobble := 0.42+0.58*pow(sin(time*TAU*(6.1 if "rough" in kind else 2.7)+phase),2)
				wash *= wobble
				mechanical += sin(time*TAU*81.3+phase)*0.015*wobble
			if kind=="gaia_layer":
				wash = (air-body)*(0.16+0.12*sin(time*0.37+phase))
				mechanical = (sin(time*TAU*173.125+phase)+sin(time*TAU*259.6875-phase))*0.003*(0.4+gust)
			result[sample_index*2+channel] = bass*profile[0]+wash*0.28+fluid*0.85+mechanical
	var density: float = {"nova":2.1,"recife":3.4,"lab":0.16,"water":4.1,"soil":0.42,"air":0.08,"nexus":0.2,"recife_after":1.6,"irrigation":5.0,"water_after":6.0,"soil_after":1.5,"air_after":0.0}.get(kind,0.0)
	var event_time := 0.1
	while event_time<seconds:
		var grain := PackedFloat32Array()
		var duration := rng.randf_range(0.055,0.18)
		grain.resize(int(duration*RATE))
		var grain_kind := "drop" if base_kind in ["water","recife","recife_after","irrigation","soil"] else "latch"
		impact(grain,0,duration,grain_kind,rng,rng.randf_range(0.02,0.1) if kind!="soil" else 0.03)
		var pan := rng.randf_range(0.2,0.8)
		for grain_index in range(grain.size()):
			var offset := (int(event_time*RATE)+grain_index)*2
			if offset+1>=result.size():break
			result[offset] += grain[grain_index]*sqrt(pan)
			result[offset+1] += grain[grain_index]*sqrt(1-pan)
		event_time += rng.randf_range(0.4,1.6)/maxf(0.03,density)
	return result

func impact(buffer: PackedFloat32Array, at: float, seconds: float, kind: String, rng: RandomNumberGenerator, gain: float) -> void:
	var metallic := kind in ["step_metal","land_metal","ladder","latch","valve","gate","door","install","lift_start","lift_stop","object_move"]
	var fluid := kind in ["drop","step_wet","land_wet","irrigation_start","pressure","capsule"]
	var electronic := kind in ["gaia_switch","scan","archive","circuit","drone_alert"]
	var extended := kind in ["valve","gate","door","pump_start","fan_start","power_restore","reserve","object_move","pressure","irrigation_start","capsule"]
	var frequencies: Array = [137.0,283.0,641.0,1277.0] if metallic else [73.0,163.0,352.0,931.0]
	if fluid:frequencies = [249.0,611.0,1483.0,2191.0]
	if electronic:frequencies = [373.0,847.0,1429.0,2389.0]
	var coefficients: Array[float] = []
	var radii: Array[float] = []
	var previous := [0.0,0.0,0.0,0.0]
	var older := [0.0,0.0,0.0,0.0]
	for frequency in frequencies:
		var radius := exp(-1.0/(RATE*(0.045 if metallic else 0.018)))
		radii.append(radius*radius)
		coefficients.append(2*radius*cos(TAU*frequency*rng.randf_range(0.93,1.07)/RATE))
	var low := 0.0
	var mid := 0.0
	var high := 0.0
	var count := int(seconds*RATE)
	for sample_index in range(count):
		var index := int(at*RATE)+sample_index
		if index>=buffer.size():break
		var time := sample_index/float(RATE)
		var noise := rng.randf_range(-1,1)
		low += (noise-low)*0.028
		mid += (noise-mid)*0.17
		high += (noise-high)*0.55
		var envelope := (1-exp(-time*850))*exp(-time*(18 if kind.begins_with("step") else 11))
		if extended:envelope = pow(maxf(0,sin(PI*time/seconds)),0.65)*(0.55+0.45*pow(sin(time*31.7+0.4),2))
		if electronic:envelope = pow(maxf(0,sin(PI*time/seconds)),1.6)*exp(-time*1.5)
		var excitation := (mid-low)*envelope
		var modes := 0.0
		for mode_index in range(4):
			var resonant: float = excitation*0.003+coefficients[mode_index]*previous[mode_index]-radii[mode_index]*older[mode_index]
			older[mode_index] = previous[mode_index]
			previous[mode_index] = resonant
			modes += resonant/(mode_index+1)
		var value := low*envelope*2.0+(mid-low)*envelope*0.24+modes*(0.23 if metallic else 0.06)
		if fluid:value = (mid-low)*envelope*0.75+low*envelope+modes*0.055
		if kind=="drop":value = (high-mid)*envelope*0.08+modes*0.1
		if electronic:value = (high-mid)*envelope*0.12+(mid-low)*envelope*0.2+modes*0.015
		if kind=="jump" or kind.begins_with("ui_"):value = low*envelope+(mid-low)*envelope*0.2
		if kind.begins_with("land"):value += low*envelope*1.5
		if kind in ["pump_start","fan_start","power_restore","reserve"]:value += sin(TAU*(35*time+19*time*time))*envelope*0.04
		var fade := minf(1,(seconds-time)/0.025)
		buffer[index] += value*gain*fade

func close_loop(source: PackedFloat32Array, frames: int, overlap: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(frames*2)
	for frame_index in range(frames):
		for channel in range(2):
			var value := source[frame_index*2+channel]
			if frame_index<overlap:
				var progress := frame_index/float(overlap)*PI*0.5
				value = value*sin(progress)+source[(frames+frame_index)*2+channel]*cos(progress)
			result[frame_index*2+channel] = value
	return result

func finish(buffer: PackedFloat32Array, target_db: float, looping: bool, stereo: bool) -> Dictionary:
	var mean := 0.0
	for value in buffer:mean += value
	mean /= buffer.size()
	var energy := 0.0
	var peak := 0.0
	for sample_index in range(buffer.size()):
		buffer[sample_index] -= mean
		energy += buffer[sample_index]*buffer[sample_index]
		peak = maxf(peak,absf(buffer[sample_index]))
	var rms := sqrt(energy/buffer.size())
	var gain := minf(db_to_linear(target_db)/maxf(0.000001,rms),0.79/maxf(0.000001,peak))
	for sample_index in range(buffer.size()):
		buffer[sample_index] *= gain
		if not looping:
			buffer[sample_index] *= minf(1,sample_index/96.0)*minf(1,(buffer.size()-1-sample_index)/240.0)
	return {"rate":RATE,"stereo":stereo,"loop":looping,"seconds":buffer.size()/float(RATE*(2 if stereo else 1)),"rms_dbfs":linear_to_db(maxf(0.000001,rms*gain)),"peak_dbfs":linear_to_db(maxf(0.000001,peak*gain)),"dc_removed":mean,"clipped_samples":0}
