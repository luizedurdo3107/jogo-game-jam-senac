extends Node3D

const MAX_LIFE := 6
const STRIKE_RANGE := 2.15
const ATLAS := preload("res://assets/processados/nova_eden_rc4/exercito_atlas.png")

var world: Node3D
var departure := false
var soldiers: Array[Dictionary] = []
var max_life := MAX_LIFE
var life := MAX_LIFE
var hard_mode := true
var stamina := 6.0
var recovery := 0.0
var cooldown := 0.0
var invulnerable := 1.0
var attack_time := 0.0
var elapsed := 0.0
var mask := 0
var active := false
var weapon: Node3D
var impact: MeshInstance3D
var impact_time := 0.0
var hurt_flash := 0.0
var sound: AudioStreamPlayer3D

func _ready() -> void:
	hard_mode = StationJourney.value("nova_difficulty")==1
	max_life = 4 if hard_mode else 6
	life = max_life
	mask = StationJourney.value("departure_security" if departure else "nova_security")
	if StationJourney.value("departure_legacy_clear" if departure else "nova_legacy_passage")==1:mask = 7
	for index in range(3):_make_soldier(index)
	weapon = world.environment.make_baton(self,Vector3.ZERO)
	weapon.hide()
	var flash := BoxMesh.new()
	flash.size = Vector3(0.36,0.36,0.06)
	impact = world.environment.mesh(self,flash,Vector3.ZERO,Color("ffe2a0"),true)
	impact.rotation.z = PI*0.25
	impact.hide()
	sound = AudioStreamPlayer3D.new()
	sound.bus = "SFX"
	sound.unit_size = 8
	sound.volume_db = -8
	sound.stream = _impact_sound()
	add_child(sound)

func armed() -> bool:
	return StationJourney.value("nova_weapon")==1

func _enemy_life(index: int) -> int:
	if departure:return ([4,5,8] if hard_mode else [3,3,6])[index]
	return ([4,4,6] if hard_mode else [3,3,4])[index]

func configure_difficulty() -> void:
	var full_and_safe := not active and life==max_life
	hard_mode = StationJourney.value("nova_difficulty")==1
	max_life = 4 if hard_mode else 6
	life = max_life if full_and_safe else mini(life,max_life)
	for index in range(soldiers.size()):
		var soldier: Dictionary = soldiers[index]
		var damage: int = soldier.max_life-soldier.life
		if soldier.life>0:soldier.life = maxi(1,_enemy_life(index)-damage)
		soldier.max_life = _enemy_life(index)
		_health(soldier)

func _make_soldier(index: int) -> void:
	var body := CharacterBody3D.new()
	body.name = (["GuardaDoca","InterceptorDoca","ComandanteDoca"] if departure else ["Sentinela","Interceptor","CapitaoVarek"])[index]
	body.position = Vector3([13.5,19.5,25.0][index],0.05,0)
	body.collision_layer = 4
	body.collision_mask = 3
	add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.92
	body.add_child(collision)
	var visual := Node3D.new()
	body.add_child(visual)
	var sprite := Sprite3D.new()
	sprite.texture = ATLAS
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.frame = 4 if index==2 else 0
	sprite.pixel_size = 0.0054
	sprite.position.y = 1.08
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	visual.add_child(sprite)
	var shadow := CylinderMesh.new()
	shadow.top_radius = 0.48
	shadow.bottom_radius = 0.48
	shadow.height = 0.012
	world.environment.mesh(body,shadow,Vector3(0,0.015,0),Color("142033"))
	var health: Array[MeshInstance3D] = []
	for health_index in range(8 if departure else 6):
		var segment := BoxMesh.new()
		segment.size = Vector3(0.13,0.045,0.025)
		health.append(world.environment.mesh(body,segment,Vector3((health_index-2.5)*0.17,2.5,0.1),Color("df7289"),true))
	var label := Label3D.new()
	label.text = (["GUARDA DA DOCA","INTERCEPTOR","COMANDANTE / NOVA ÉDEN"] if departure else ["SENTINELA","INTERCEPTOR","CAP. VAREK"])[index]
	label.font_size = 20
	label.pixel_size = 0.008
	label.modulate = Color("efa4bf") if index==2 else Color("bad5e6")
	label.position = Vector3(0,2.75,0)
	body.add_child(label)
	var zone := BoxMesh.new()
	zone.size = Vector3(2.4,0.025,2.3)
	var warning: MeshInstance3D = world.environment.mesh(self,zone,Vector3.ZERO,Color("dfb562"),true)
	warning.hide()
	var disabled := (mask&(1<<index))!=0
	var soldier := {"body":body,"visual":visual,"sprite":sprite,"label":label,"health":health,"warning":warning,"life":0 if disabled else _enemy_life(index),"max_life":_enemy_life(index),"clock":0.0,"stun":0.0,"flash":0.0,"aim":0.0,"strikes":0,"index":index}
	soldiers.append(soldier)
	_health(soldier)
	if disabled:
		_knock_out(index)
		if StationJourney.value("departure_legacy_clear" if departure else "nova_legacy_passage")==1:body.hide()

func tick(delta: float) -> void:
	elapsed += delta
	cooldown = maxf(0,cooldown-delta)
	invulnerable = maxf(0,invulnerable-delta)
	attack_time = maxf(0,attack_time-delta)
	impact_time = maxf(0,impact_time-delta)
	hurt_flash = maxf(0,hurt_flash-delta)
	recovery = maxf(0,recovery-delta)
	if recovery<=0:stamina = minf(6,stamina+delta*(1.9 if hard_mode else 2.6))
	world.player.sprite.modulate = Color("ea7f8b") if hurt_flash>0 else Color.WHITE
	var facing := -1.0 if world.player.sprite.flip_h else 1.0
	weapon.visible = armed()
	weapon.position = world.player.position+Vector3(facing*0.43,1.0,0.3)
	weapon.rotation.z = facing*(-0.3-sin(attack_time/0.26*PI)*1.7)
	world.player.sprite.rotation.z = facing*sin(attack_time/0.26*PI)*-0.12
	impact.visible = impact_time>0
	if mask==7:return
	if world.player.position.x>10.5:active = true
	if not active:return
	if not GameState.gaia_active and Input.is_action_pressed("attack") and cooldown<=0:strike()
	var current := current_enemy()
	for index in range(soldiers.size()):
		var soldier: Dictionary = soldiers[index]
		if soldier.life<=0:continue
		soldier.stun = maxf(0,soldier.stun-delta)
		soldier.flash = maxf(0,soldier.flash-delta)
		soldier.sprite.modulate = Color("ff839a") if soldier.flash>0 else Color.WHITE
		if index==current or hard_mode and index==current+1 and world.player.position.x>12:_tick_enemy(soldier,delta)
		else:soldier.warning.hide()

func current_enemy() -> int:
	for index in range(soldiers.size()):
		if soldiers[index].life>0:return index
	return -1

func _windup(soldier: Dictionary) -> float:
	return (0.44 if hard_mode else 0.68)+(0.08 if soldier.index==1 else 0.0)

func _tick_enemy(soldier: Dictionary, delta: float) -> void:
	var body: CharacterBody3D = soldier.body
	var distance: float = world.player.position.x-body.position.x
	var windup := _windup(soldier)
	var captain: bool = soldier.index==2 and hard_mode
	var warning_end := windup+0.68 if captain else windup+0.22
	var cycle_end := warning_end+0.72
	body.velocity = Vector3(0,body.velocity.y-18*delta,0)
	soldier.sprite.flip_h = distance>0
	var pose := 0
	if soldier.stun<=0:
		if soldier.clock<=0 and absf(distance)>1.65:
			body.velocity.x = signf(distance)*(3.5 if hard_mode else 2.65)
			pose = 1 if sin(elapsed*12)>-0.2 else 0
		else:
			if soldier.clock<=0:
				soldier.aim = body.position.x+signf(distance)*1.3
				soldier.strikes = 0
			soldier.clock += delta
			var second: bool = captain and soldier.clock>=windup+0.5
			var strike_index := 2 if second else 1
			var attacking: bool = soldier.clock>=windup and soldier.clock<windup+0.18 or captain and soldier.clock>=windup+0.5 and soldier.clock<warning_end
			soldier.warning.visible = soldier.clock<warning_end
			soldier.warning.position = Vector3(soldier.aim,0.04,0)
			soldier.warning.material_override = world.environment.material(Color("f65d7c") if attacking else Color("e7b75b"),true)
			pose = 3 if attacking else (2 if soldier.clock<warning_end else 0)
			if attacking and soldier.strikes<strike_index:
				soldier.strikes = strike_index
				if absf(world.player.position.x-soldier.aim)<1.2 and world.player.position.y<1.1:take_hit()
			if attacking:body.velocity.x = signf(distance)*2.2
			if soldier.clock>cycle_end:
				soldier.clock = 0.0
				soldier.warning.hide()
	else:soldier.warning.hide()
	body.move_and_slide()
	body.position.x = clampf(body.position.x,9.8,27.2)
	body.position.z = 0
	soldier.sprite.frame = (4 if soldier.index==2 else 0)+pose

func strike() -> bool:
	if world.finished or world.hud.modal_open or world.hud.portrait.visible or GameState.gaia_active or cooldown>0 or mask==7:return false
	cooldown = 0.42
	if not armed():
		world.hud.notify("Pegue o bastão no equipamento da doca [E]." if departure else "A armadura resiste a socos. Abra o arsenal à esquerda e pegue o bastão [E].")
		return false
	if stamina<2:
		world.hud.notify("Sem fôlego. Recue e espere a barra recuperar.")
		return false
	stamina -= 2
	recovery = 0.8
	attack_time = 0.26
	var facing := -1.0 if world.player.sprite.flip_h else 1.0
	var target := -1
	var nearest := STRIKE_RANGE
	for index in range(soldiers.size()):
		var soldier: Dictionary = soldiers[index]
		var distance: float = soldier.body.position.x-world.player.position.x
		if soldier.life>0 and absf(distance)<=nearest and distance*facing>=-0.35 and absf(world.player.position.y-soldier.body.position.y)<1.3:
			target = index
			nearest = absf(distance)
	if target<0:return true
	var soldier: Dictionary = soldiers[target]
	_impact_at(soldier.body.position+Vector3(0,1.1,0.25))
	if target==2 and soldier.clock>0 and soldier.clock<_windup(soldier) and (world.player.position.x-soldier.body.position.x)*(1 if soldier.sprite.flip_h else -1)>0:
		world.hud.notify("O capitão bloqueou! Desvie do combo e ataque na recuperação.")
		return true
	soldier.life -= 1
	_health(soldier)
	soldier.stun = 0.12
	soldier.flash = 0.18
	soldier.body.position.x += facing*0.2
	if soldier.life==0:
		mask |= 1<<target
		_knock_out(target)
		world.security_progress(mask)
	return true

func take_hit() -> void:
	if invulnerable>0 or world.finished:return
	life = maxi(0,life-1)
	invulnerable = 0.72 if hard_mode else 1.1
	hurt_flash = 0.18
	world.player.velocity.y = 2.0
	_impact_at(world.player.position+Vector3(0,1.0,0.2))
	world.hud.notify("VIDA %d/%d. Amarelo avisa: salte ou recue. Golpeie depois do ataque."%[life,max_life])
	if life==0:world._capture()

func _health(soldier: Dictionary) -> void:
	for index in range(soldier.health.size()):soldier.health[index].visible = index<soldier.life

func _knock_out(index: int) -> void:
	var soldier: Dictionary = soldiers[index]
	soldier.body.collision_layer = 0
	soldier.body.collision_mask = 0
	soldier.sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	soldier.visual.rotation.z = PI*0.5
	soldier.visual.position.y = 0.35
	soldier.warning.hide()
	soldier.label.hide()
	_health(soldier)

func _impact_at(point: Vector3) -> void:
	impact.position = point
	impact_time = 0.13
	sound.position = point
	if AudioDirector.output_enabled:sound.play()

func _impact_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(3087*2)
	var random := RandomNumberGenerator.new()
	random.seed = 404
	for index in range(3087):
		var progress := float(index)/3087
		var signal_value := (sin(index*TAU*95.0/22050)*0.6+random.randf_range(-0.3,0.3))*exp(-progress*9)*minf(1,progress*80)
		samples.encode_s16(index*2,int(signal_value*24000))
	stream.data = samples
	return stream
