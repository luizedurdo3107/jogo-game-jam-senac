extends SceneTree

var edit_folder := "outputs/pitch/contexto_edit"
var movie_name := "LAST_SIGNAL_AUTOEXPLICATIVO_60S"
var source_manifest := "res://outputs/pitch/acao_edit/planos.json"
var method := "Reedição de capturas reais do motor, com comandos automatizados e checkpoints isolados. Sem recaptura, aceleração ou mecânica nova."
const CONTEXT := [
	{"start":0.0,"end":6.0,"phase":"01 · NOVA ÉDEN | RECIFE, 2187","text":"Em uma Terra em colapso, Kairo tenta deixar a cidade."},
	{"start":6.0,"end":12.0,"phase":"01 · NOVA ÉDEN | COMBATE","text":"O exército bloqueia a saída. Vença o capitão para escapar."},
	{"start":12.0,"end":15.0,"phase":"SAÍDA DE NOVA ÉDEN","text":"Passagem livre: siga para o Recife Antigo."},
	{"start":15.0,"end":18.0,"phase":"02 · RECIFE ANTIGO | COMUNIDADE","text":"Bomba comunitária reparada. Caminho até GAIA liberado."},
	{"start":18.0,"end":23.0,"phase":"03 · LABORATÓRIO GAIA | DUAS PERSPECTIVAS","text":"GAIA revela circuitos. Volte ao corpo para abrir a comporta."},
	{"start":23.0,"end":28.0,"phase":"04 · CAPIBARIBE | ÁGUA","text":"Ligue a bomba e devolva água à comunidade."},
	{"start":28.0,"end":33.0,"phase":"05 · BANCO VERDE | SEMENTES","text":"Preserve as sementes: os primeiros brotos voltam a crescer."},
	{"start":33.0,"end":38.0,"phase":"06 · TORRE ATMOS | AR","text":"Reative turbina e filtros para devolver ar limpo aos bairros."},
	{"start":38.0,"end":42.0,"phase":"07 · NEXUS | SUA ESCOLHA","text":"As estações foram restauradas. Agora, ficar na Terra ou partir?"},
	{"start":42.0,"end":48.0,"phase":"DOCA TERRESTRE | GAIA PROTEGE A TERRA","text":"GAIA bloqueia a partida. Supere as travas com comandos locais."},
	{"start":48.0,"end":51.0,"phase":"ARCA-01 | EMBARQUE","text":"Kairo embarca: o destino agora é Marte."},
	{"start":51.0,"end":55.5,"phase":"DECOLAGEM | DEIXANDO A TERRA","text":"GAIA fica na Terra, ajudando quem não partiu."},
	{"start":55.5,"end":60.0,"phase":"RUMO A MARTE | UM DOS FINAIS","text":"Este é um dos finais. Suas escolhas mudam o desfecho."}
]

var context: Array = CONTEXT

func _configure() -> void:
	pass

func _segments(original: Dictionary) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var cursor := 0.0
	for shot in original.shots:
		if shot.name=="09_partir":
			segments.append({"name":"09_nexus_contexto","source":"outputs/pitch/capturas/09_escolha.mkv","source_start":3.4,"seconds":2.0,"timeline_start":cursor,"decision":true})
			cursor += 2.0
		var seconds := float(shot.frames)/30.0
		segments.append({"name":shot.name,"source":"outputs/pitch/capturas_acao/"+str(shot.name)+".mkv","source_start":0.0,"seconds":seconds,"timeline_start":cursor,"decision":shot.name=="09_partir"})
		cursor += seconds
	assert(is_equal_approx(cursor,60.0))
	return segments

func _initialize() -> void:
	_configure()
	var output := "res://"+edit_folder+"/"
	DirAccess.make_dir_recursive_absolute(output)
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source_manifest))
	var segments := _segments(original)
	var manifest := {"fps":30,"seconds":60,"segments":segments,"context":context,"original_capture_checks":original.evidence,"method":method}
	FileAccess.open(output+"planos.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"  "))
	FileAccess.open(output+"titulo.txt",FileAccess.WRITE).store_string("LAST SIGNAL: EARTH_404")
	var subtitles: Array[String] = []
	for index in range(context.size()):
		var cue: Dictionary = context[index]
		FileAccess.open(output+"%02d_fase.txt"%index,FileAccess.WRITE).store_string(cue.phase)
		FileAccess.open(output+"%02d_contexto.txt"%index,FileAccess.WRITE).store_string(cue.text)
		subtitles.append("%d\n%s --> %s\n%s\n%s\n"%[index+1,_timestamp(cue.start),_timestamp(cue.end),cue.phase,cue.text])
	FileAccess.open("res://outputs/pitch/"+movie_name+".srt",FileAccess.WRITE).store_string("\n".join(subtitles))
	var commands: Array[String] = ["#!/usr/bin/env bash","set -euo pipefail","cd '"+ProjectSettings.globalize_path("res://")+"'"]
	var concat: Array[String] = []
	for index in range(segments.size()):
		var segment: Dictionary = segments[index]
		var base := edit_folder+"/%02d"%index
		var video := "setsar=1,format=yuv420p"
		if segment.decision:video += ",scale=1600:900:flags=lanczos,pad=1920:1080:160:0:color=0x07141E"
		video += ",drawbox=x=0:y=900:w=iw:h=180:color=0x091521@0.97:t=fill"
		video += ",drawbox=x=64:y=920:w=5:h=99:color=0x82EAD7:t=fill"
		for cue_index in range(context.size()):
			var cue: Dictionary = context[cue_index]
			var local_start := maxf(0,float(cue.start)-float(segment.timeline_start))
			var local_end := minf(float(segment.seconds),float(cue.end)-float(segment.timeline_start))
			if local_end<=local_start:continue
			var enable := "gte(t,%.6f)*lt(t,%.6f)"%[local_start,local_end]
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile=%s/%02d_fase.txt:fontsize=28:fontcolor=0x82EAD7:x=96:y=918:enable='%s'"%[edit_folder,cue_index,enable]
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:textfile=%s/%02d_contexto.txt:fontsize=42:fontcolor=white:x=96:y=970:enable='%s'"%[edit_folder,cue_index,enable]
		if index==0 or index==segments.size()-1:
			var show := "lt(t,2.5)" if index==0 else "gte(t,2.7)"
			video += ",drawbox=x=700:y=64:w=1156:h=82:color=0x091521@0.90:t=fill:enable='%s'"%show
			video += ",drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile=%s/titulo.txt:fontsize=42:fontcolor=white:x=736:y=86:enable='%s'"%[edit_folder,show]
		video += ",fade=t=in:st=0:d=0.06,fade=t=out:st=%.6f:d=0.06"%(float(segment.seconds)-0.06)
		FileAccess.open("res://"+base+".filtro",FileAccess.WRITE).store_string(video)
		commands.append("echo 'Contexto %02d / %s'"%[index+1,segment.name])
		commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -ss %.6f -i '%s' -t %.6f -frames:v %d -vf \"$(cat %s.filtro)\" -af 'afade=t=in:st=0:d=0.03,afade=t=out:st=%.6f:d=0.06' -c:v libx264 -threads 2 -preset veryfast -crf 17 -pix_fmt yuv420p -r 30 -c:a pcm_s16le -ar 48000 %s.mkv"%[segment.source_start,segment.source,segment.seconds,roundi(float(segment.seconds)*30),base,float(segment.seconds)-0.06,base])
		concat.append("file '%02d.mkv'"%index)
	FileAccess.open(output+"concat.txt",FileAccess.WRITE).store_string("\n".join(concat)+"\n")
	commands.append("ffmpeg -nostdin -y -hide_banner -loglevel error -threads 2 -filter_threads 1 -f concat -safe 0 -i %s/concat.txt -vf 'fade=t=out:st=59.4:d=0.6' -af 'loudnorm=I=-21:TP=-2:LRA=9,aresample=48000,afade=t=out:st=59.4:d=0.6' -c:v libx264 -threads 2 -preset fast -crf 19 -profile:v main -level:v 4.0 -bf 0 -refs 2 -g 60 -keyint_min 30 -pix_fmt yuv420p -r 30 -fps_mode cfr -c:a aac -b:a 160k -ar 48000 -movflags +faststart -video_track_timescale 30000 -t 60 %s/final_validavel.mp4"%[edit_folder,edit_folder])
	commands.append("ffmpeg -nostdin -v error -xerror -threads 2 -i %s/final_validavel.mp4 -f null - 2> %s/decodificacao.log"%[edit_folder,edit_folder])
	commands.append("mv %s/final_validavel.mp4 outputs/pitch/%s.mp4"%[edit_folder,movie_name])
	FileAccess.open(output+"renderizar.sh",FileAccess.WRITE).store_string("\n".join(commands)+"\n")
	print("CONTEXT EDIT READY / 60 segundos / ",segments.size()," planos / ",context.size()," explicações")
	quit()

func _timestamp(seconds: float) -> String:
	var milliseconds := roundi(seconds*1000)
	return "%02d:%02d:%02d,%03d"%[milliseconds/3600000,milliseconds/60000%60,milliseconds/1000%60,milliseconds%1000]
