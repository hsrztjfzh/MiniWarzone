extends Node3D
# Mini Warzone - Godot 4 version (Android + PC)
# همه چیز با کد ساخته می‌شه؛ فقط فایل‌های .glb کنی رو بریز توی پوشه models

const MAP_HALF := 60.0
const BASE_FOV := 85.0
const SHADOWS := false          # true = سایه (روی گوشی سنگینه)
const FORCE_TOUCH_UI := false   # true = کنترل لمسی روی کامپیوتر هم
const MOUSE_SENS := 0.0025
const TOUCH_SENS := 0.0045
const SETTINGS_PATH := "user://settings.cfg"
const STICK_R := 100.0
const KNOB_R := 44.0

const DARK := Color(0.13, 0.13, 0.15)
const BLACK := Color(0.08, 0.08, 0.09)
const MID := Color(0.2, 0.2, 0.22)
const WOOD := Color(0.3, 0.2, 0.12)
const SLEEVE := Color(0.2, 0.26, 0.17)
const GRAY := Color(0.7, 0.72, 0.78)
const SKIN := Color(0.82, 0.62, 0.48)
const RED := Color(1.0, 0.1, 0.1)
const WHITE := Color(1.0, 1.0, 1.0)


class Enemy extends AnimatableBody3D:
	var hp = 60.0
	var dead = false
	var speed = 3.0
	var pref_dist = 16.0
	var attack_timer = 1.5
	var strafe_dir = 1
	var strafe_timer = 2.0
	var stuck_timer = 0.0
	var walk_phase = 0.0
	var leg_l: Node3D
	var leg_r: Node3D
	var flash: MeshInstance3D


# parts: [موقعیت, اندازه, رنگ] با z مثبت = جلو (موقع ساخت برعکس می‌شه)
var WEAPONS = [
	{
		"key": "rifle", "name": "ASSAULT RIFLE", "desc": "Balanced all-rounder. Full auto.",
		"damage": 20.0, "pellets": 1, "rpm": 600.0, "mag": 30, "reserve": 150, "reload": 1.5,
		"spread": 0.010, "auto": true, "recoil": 0.6, "zoom_fov": 62.0, "length": 0.85,
		"hold": Vector3(0.32, -0.30, -0.70), "muzzle": 0.78,
		"parts": [
			[Vector3(0, 0, 0), Vector3(0.07, 0.1, 0.55), DARK],
			[Vector3(0, 0.012, 0.45), Vector3(0.035, 0.035, 0.35), BLACK],
			[Vector3(0, -0.005, 0.2), Vector3(0.085, 0.08, 0.28), MID],
			[Vector3(0, -0.02, -0.33), Vector3(0.06, 0.11, 0.25), WOOD],
			[Vector3(0, -0.12, 0.02), Vector3(0.05, 0.16, 0.08), BLACK],
			[Vector3(0, -0.09, -0.12), Vector3(0.05, 0.1, 0.06), DARK],
			[Vector3(0, 0.075, 0.05), Vector3(0.025, 0.05, 0.12), BLACK],
		],
	},
	{
		"key": "smg", "name": "SMG", "desc": "Very fast fire, weaker hits, wider spread.",
		"damage": 14.0, "pellets": 1, "rpm": 900.0, "mag": 35, "reserve": 175, "reload": 1.3,
		"spread": 0.018, "auto": true, "recoil": 0.35, "zoom_fov": 70.0, "length": 0.6,
		"hold": Vector3(0.30, -0.28, -0.65), "muzzle": 0.46,
		"parts": [
			[Vector3(0, 0, 0), Vector3(0.07, 0.1, 0.4), DARK],
			[Vector3(0, 0.01, 0.28), Vector3(0.03, 0.03, 0.2), BLACK],
			[Vector3(0, -0.15, 0.04), Vector3(0.045, 0.22, 0.07), BLACK],
			[Vector3(0, -0.09, -0.1), Vector3(0.05, 0.1, 0.06), DARK],
			[Vector3(0, -0.01, -0.27), Vector3(0.04, 0.06, 0.2), MID],
			[Vector3(0, 0.07, 0.05), Vector3(0.025, 0.04, 0.1), BLACK],
		],
	},
	{
		"key": "shotgun", "name": "SHOTGUN", "desc": "Devastating up close. Pump action.",
		"damage": 11.0, "pellets": 8, "rpm": 75.0, "mag": 6, "reserve": 36, "reload": 2.2,
		"spread": 0.045, "auto": false, "recoil": 2.0, "zoom_fov": 76.0, "length": 0.95,
		"hold": Vector3(0.32, -0.30, -0.72), "muzzle": 0.85,
		"parts": [
			[Vector3(0, 0, 0), Vector3(0.07, 0.1, 0.5), DARK],
			[Vector3(0, 0.03, 0.5), Vector3(0.05, 0.05, 0.55), MID],
			[Vector3(0, -0.03, 0.33), Vector3(0.085, 0.06, 0.22), WOOD],
			[Vector3(0, -0.03, -0.35), Vector3(0.06, 0.12, 0.32), WOOD],
			[Vector3(0, -0.09, -0.1), Vector3(0.05, 0.1, 0.06), DARK],
		],
	},
	{
		"key": "sniper", "name": "SNIPER RIFLE", "desc": "One shot, long range. Use ADS to zoom.",
		"damage": 110.0, "pellets": 1, "rpm": 50.0, "mag": 5, "reserve": 25, "reload": 2.4,
		"spread": 0.0015, "auto": false, "recoil": 2.4, "zoom_fov": 20.0, "length": 1.1,
		"hold": Vector3(0.32, -0.30, -0.75), "muzzle": 1.15,
		"parts": [
			[Vector3(0, 0, 0), Vector3(0.06, 0.09, 0.6), DARK],
			[Vector3(0, 0.012, 0.7), Vector3(0.03, 0.03, 0.7), BLACK],
			[Vector3(0, 0.095, 0.05), Vector3(0.05, 0.05, 0.3), BLACK],
			[Vector3(0, 0.095, 0.22), Vector3(0.06, 0.06, 0.04), MID],
			[Vector3(0, -0.03, -0.4), Vector3(0.06, 0.12, 0.35), WOOD],
			[Vector3(0, -0.1, 0.0), Vector3(0.045, 0.09, 0.07), BLACK],
		],
	},
	{
		"key": "pistol", "name": "PISTOL", "desc": "Light and accurate. Semi-auto.",
		"damage": 26.0, "pellets": 1, "rpm": 330.0, "mag": 12, "reserve": 72, "reload": 1.1,
		"spread": 0.008, "auto": false, "recoil": 0.5, "zoom_fov": 72.0, "length": 0.35,
		"hold": Vector3(0.26, -0.26, -0.55), "muzzle": 0.26,
		"parts": [
			[Vector3(0, 0.02, 0.05), Vector3(0.045, 0.06, 0.3), DARK],
			[Vector3(0, -0.07, -0.06), Vector3(0.045, 0.13, 0.07), BLACK],
			[Vector3(0, 0.02, 0.22), Vector3(0.03, 0.03, 0.06), BLACK],
		],
	},
]

var UNIFORMS = [
	[Color(0.36, 0.38, 0.24), Color(0.28, 0.3, 0.2), Color(0.2, 0.25, 0.16)],
	[Color(0.42, 0.37, 0.27), Color(0.34, 0.3, 0.22), Color(0.3, 0.27, 0.2)],
	[Color(0.25, 0.28, 0.33), Color(0.18, 0.2, 0.25), Color(0.16, 0.18, 0.22)],
]

# ---------- وضعیت بازی ----------
var in_lobby := true
var dead := false
var hp := 100.0
var score := 0
var kills := 0
var wave := 0
var wave_pending := false
var epoch := 0
var reload_id := 0
var reloading := false
var ammo := 0
var reserve := 0
var ammo_store := {}
var last_shot := 0.0
var no_fire_until := 0.0
var last_hit_time := 0.0
var weapon_idx := 0
var model_choice := {}
var model_fix := {}
var model_pool := []
var enemies := []
var obstacles := []
var yaw := 0.0
var pitch := 0.0
var is_touch := false
var ads := false
var fire_held := false
var jump_req := false
var moving_flag := false
var msg_id := 0
var bob_t := 0.0
var gun_base := Vector3(0.32, -0.30, -0.70)
var reload_tween: Tween = null

# ---------- نودها ----------
var world: Node3D
var lobby3d: Node3D
var player: CharacterBody3D
var head: Node3D
var cam: Camera3D
var lobby_cam: Camera3D
var gun_root: Node3D
var gun_model: Node3D
var muzzle: MeshInstance3D
var preview_root: Node3D
var preview_model: Node3D
var world_env: Environment
var tex := {}
var color_mats := {}
var unlit_mats := {}
var unit_box: BoxMesh
var unit_sphere: SphereMesh
var shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ---------- رابط کاربری ----------
var hud_layer: CanvasLayer
var touch_layer: CanvasLayer
var lobby_layer: CanvasLayer
var score_label: Label
var wave_label: Label
var ammo_label: Label
var weapon_label: Label
var msg_label: Label
var hp_bg: ColorRect
var hp_fill: ColorRect
var damage_flash: ColorRect
var crosshair_parts := []
var go_box: Control
var go_restart: Button
var go_lobby: Button

var lb_title: Label
var lb_name: Label
var lb_desc: Label
var lb_ammo: Label
var lb_model_title: Label
var lb_model: Label
var lb_hint: Label
var lb_stat_labels := []
var lb_stat_bars := []
var lb_buttons := {}

var touch_buttons := {}
var touch_roles := {}
var stick_vec := Vector2.ZERO
var stick_origin := Vector2(190, 500)
var stick_active := false
var stick_base: Panel
var stick_knob: Panel


func _ready():
	randomize()
	get_tree().set_quit_on_go_back(false)
	is_touch = FORCE_TOUCH_UI or OS.has_feature("mobile")
	if SHADOWS:
		shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	unit_box = BoxMesh.new()
	unit_box.size = Vector3.ONE
	unit_sphere = SphereMesh.new()
	unit_sphere.radius = 0.5
	unit_sphere.height = 1.0
	unit_sphere.radial_segments = 12
	unit_sphere.rings = 6
	load_settings()
	model_pool = discover_models()
	print("[Mini Warzone] glb models found: ", model_pool.size())
	build_textures()
	build_world()
	build_player()
	build_lobby3d()
	build_hud()
	build_touch_ui()
	build_lobby_ui()
	get_viewport().size_changed.connect(layout_ui)
	layout_ui()
	open_lobby()


func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if in_lobby:
			get_tree().quit()
		else:
			open_lobby()


# =====================================================================
#  تنظیمات و مدل‌ها
# =====================================================================
func cw():
	return WEAPONS[clampi(weapon_idx, 0, WEAPONS.size() - 1)]


func load_settings():
	var cf = ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		weapon_idx = int(cf.get_value("s", "weapon", 0))
		var m = cf.get_value("s", "models", {})
		var f = cf.get_value("s", "fix", {})
		if typeof(m) == TYPE_DICTIONARY:
			model_choice = m
		if typeof(f) == TYPE_DICTIONARY:
			model_fix = f
	weapon_idx = clampi(weapon_idx, 0, WEAPONS.size() - 1)


func save_settings():
	var cf = ConfigFile.new()
	cf.set_value("s", "weapon", weapon_idx)
	cf.set_value("s", "models", model_choice)
	cf.set_value("s", "fix", model_fix)
	cf.save(SETTINGS_PATH)


func scan_dir(path, out):
	var d = DirAccess.open(path)
	if d == null:
		return
	for sub in d.get_directories():
		scan_dir(path.path_join(sub), out)
	for f in d.get_files():
		var n = f
		if n.ends_with(".import"):
			n = n.substr(0, n.length() - 7)
		elif n.ends_with(".remap"):
			n = n.substr(0, n.length() - 6)
		if n.to_lower().ends_with(".glb"):
			var p = path.path_join(n)
			if not out.has(p):
				out.append(p)


func discover_models():
	var all = []
	scan_dir("res://models", all)
	all.sort()
	var blasters = []
	for p in all:
		if p.get_file().to_lower().begins_with("blaster"):
			blasters.append(p)
	if blasters.size() > 0:
		return blasters
	return all


func model_for(w):
	if model_pool.size() == 0:
		return ""
	var p = model_choice.get(w["key"], "")
	if not model_pool.has(p):
		p = model_pool[WEAPONS.find(w) % model_pool.size()]
	return p


# =====================================================================
#  بافت و متریال
# =====================================================================
func make_tex(kind):
	var size = 128
	var img = Image.create(size, size, false, Image.FORMAT_RGB8)
	var r = RandomNumberGenerator.new()
	r.seed = hash(kind)
	for y in range(size):
		for x in range(size):
			var n = r.randf()
			var c = Color(0.5, 0.5, 0.5)
			if kind == "ground":
				var patch = float(((x >> 4) * 7 + (y >> 4) * 13) % 5) / 5.0
				c = Color(0.23, 0.28, 0.15).lerp(Color(0.49, 0.53, 0.33), n * 0.6 + patch * 0.4)
			elif kind == "wood":
				c = Color(0.36, 0.24, 0.13).lerp(Color(0.6, 0.43, 0.25), n * 0.6 + 0.2 * float((x >> 3) % 2))
				if x < 4 or y < 4 or x > size - 5 or y > size - 5 or abs(x - y) < 3 or abs(x + y - size) < 3:
					c = Color(0.22, 0.14, 0.08)
			elif kind == "concrete" or kind == "concrete_bld":
				c = Color(0.46, 0.46, 0.45).lerp(Color(0.69, 0.68, 0.66), n)
				if x % 64 == 0 or y % 64 == 0:
					c = c.darkened(0.25)
			elif kind == "brick" or kind == "brick_bld":
				var row = y >> 4
				var off = 16 if (row % 2) == 1 else 0
				var bx = (x + off) % 32
				var by = y % 16
				var bid = (((x + off) >> 5) + row * 3) % 4
				if by < 2 or bx < 2:
					c = Color(0.5, 0.49, 0.46)
				else:
					c = Color(0.55 + 0.04 * bid, 0.26 + 0.02 * bid, 0.2).lerp(Color(0.7, 0.35, 0.28), n * 0.35)
			if kind == "concrete_bld" or kind == "brick_bld":
				var wx = x % 64
				if wx >= 16 and wx < 48 and y >= 36 and y < 84:
					c = Color(0.08, 0.12, 0.18).lerp(Color(0.22, 0.3, 0.4), float(y - 36) / 48.0)
					if wx < 18 or wx >= 46 or y < 38 or y >= 82:
						c = Color(0.75, 0.75, 0.72)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func build_textures():
	for kind in ["ground", "concrete", "brick", "wood", "concrete_bld", "brick_bld"]:
		tex[kind] = make_tex(kind)


func tex_mat(kind, tile_scale):
	var m = StandardMaterial3D.new()
	m.albedo_texture = tex[kind]
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(tile_scale, tile_scale, tile_scale)
	m.roughness = 1.0
	return m


func cmat(c):
	var k = c.to_html()
	if not color_mats.has(k):
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		color_mats[k] = m
	return color_mats[k]


func umat(c):
	var k = c.to_html()
	if not unlit_mats.has(k):
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		unlit_mats[k] = m
	return unlit_mats[k]


func part(parent, pos, size, c, sphere = false):
	var mi = MeshInstance3D.new()
	mi.mesh = unit_sphere if sphere else unit_box
	mi.scale = size
	mi.position = pos
	mi.material_override = cmat(c)
	mi.cast_shadow = shadow_mode
	parent.add_child(mi)
	return mi


func solid_box(parent, pos, size, material, rot_y = 0.0):
	var sb = StaticBody3D.new()
	sb.position = pos
	sb.rotation.y = rot_y
	sb.collision_layer = 1
	sb.collision_mask = 0
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	mi.cast_shadow = shadow_mode
	sb.add_child(mi)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	parent.add_child(sb)
	return sb


func blocked(x, z, margin = 0.6):
	for o in obstacles:
		if abs(x - o[0]) < o[2] + margin and abs(z - o[1]) < o[3] + margin:
			return true
	return false


# =====================================================================
#  دنیای بازی
# =====================================================================
func build_world():
	world = Node3D.new()
	add_child(world)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = SHADOWS
	world.add_child(sun)

	world_env = Environment.new()
	world_env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var skm = ProceduralSkyMaterial.new()
	skm.sky_top_color = Color(0.35, 0.55, 0.85)
	skm.sky_horizon_color = Color(0.72, 0.78, 0.86)
	skm.ground_horizon_color = Color(0.72, 0.78, 0.86)
	skm.ground_bottom_color = Color(0.4, 0.45, 0.4)
	sky.sky_material = skm
	world_env.sky = sky
	world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.ambient_light_color = Color(0.62, 0.64, 0.7)
	world_env.ambient_light_energy = 1.0
	world_env.fog_enabled = true
	world_env.fog_light_color = Color(0.72, 0.78, 0.86)
	world_env.fog_density = 0.006

	var rng = RandomNumberGenerator.new()
	rng.seed = 7

	var m_ground = tex_mat("ground", 0.12)
	var m_conc = tex_mat("concrete", 0.25)
	var m_wood = tex_mat("wood", 0.7)
	var m_roof = cmat(Color(0.35, 0.35, 0.37))
	var m_bld_conc = tex_mat("concrete_bld", 0.25)
	var m_bld_brick = tex_mat("brick_bld", 0.25)

	# زمین
	solid_box(world, Vector3(0, -0.5, 0), Vector3(MAP_HALF * 2.0 + 20.0, 1.0, MAP_HALF * 2.0 + 20.0), m_ground)

	# دیوارهای دور نقشه
	var wl = MAP_HALF * 2.0
	solid_box(world, Vector3(0, 3, MAP_HALF), Vector3(wl, 6, 1), m_conc)
	solid_box(world, Vector3(0, 3, -MAP_HALF), Vector3(wl, 6, 1), m_conc)
	solid_box(world, Vector3(MAP_HALF, 3, 0), Vector3(1, 6, wl), m_conc)
	solid_box(world, Vector3(-MAP_HALF, 3, 0), Vector3(1, 6, wl), m_conc)

	# ساختمان‌ها
	for i in range(28):
		var x = rng.randf_range(-MAP_HALF + 8.0, MAP_HALF - 8.0)
		var z = rng.randf_range(-MAP_HALF + 8.0, MAP_HALF - 8.0)
		var w = rng.randf_range(4.0, 10.0)
		var d = rng.randf_range(4.0, 10.0)
		var h = rng.randf_range(3.0, 8.0)
		var use_brick = rng.randf() < 0.5
		if (abs(x) < 12.0 and abs(z) < 12.0) or blocked(x, z, maxf(w, d) / 2.0 + 2.0):
			continue
		solid_box(world, Vector3(x, h / 2.0, z), Vector3(w, h, d), m_bld_brick if use_brick else m_bld_conc)
		var roof = MeshInstance3D.new()
		var rm = BoxMesh.new()
		rm.size = Vector3(w + 0.5, 0.3, d + 0.5)
		roof.mesh = rm
		roof.material_override = m_roof
		roof.position = Vector3(x, h + 0.15, z)
		world.add_child(roof)
		obstacles.append([x, z, w / 2.0, d / 2.0])

	# سنگرهای بتنی
	for i in range(14):
		var x = rng.randf_range(-MAP_HALF + 5.0, MAP_HALF - 5.0)
		var z = rng.randf_range(-MAP_HALF + 5.0, MAP_HALF - 5.0)
		var long_x = rng.randf() < 0.5
		if (abs(x) < 8.0 and abs(z) < 8.0) or blocked(x, z, 3.0):
			continue
		var lx = 3.2 if long_x else 0.8
		var lz = 0.8 if long_x else 3.2
		solid_box(world, Vector3(x, 0.55, z), Vector3(lx, 1.1, lz), m_conc)
		obstacles.append([x, z, lx / 2.0, lz / 2.0])

	# جعبه‌های چوبی
	for i in range(22):
		var x = rng.randf_range(-MAP_HALF + 4.0, MAP_HALF - 4.0)
		var z = rng.randf_range(-MAP_HALF + 4.0, MAP_HALF - 4.0)
		var s = rng.randf_range(1.1, 2.0)
		var ry = rng.randf_range(0.0, 1.57)
		if (abs(x) < 6.0 and abs(z) < 6.0) or blocked(x, z, 2.0):
			continue
		solid_box(world, Vector3(x, s / 2.0, z), Vector3(s, s, s), m_wood, ry)
		obstacles.append([x, z, s * 0.75, s * 0.75])

	# درخت‌ها
	for i in range(18):
		var x = rng.randf_range(-MAP_HALF + 4.0, MAP_HALF - 4.0)
		var z = rng.randf_range(-MAP_HALF + 4.0, MAP_HALF - 4.0)
		var g = rng.randf_range(0.28, 0.42)
		if (abs(x) < 8.0 and abs(z) < 8.0) or blocked(x, z, 2.5):
			continue
		solid_box(world, Vector3(x, 1.6, z), Vector3(0.5, 3.2, 0.5), cmat(Color(0.3, 0.2, 0.12)))
		part(world, Vector3(x, 4.3, z), Vector3(3.6, 3.2, 3.6), Color(0.12, g, 0.14), true)
		part(world, Vector3(x + 0.5, 5.4, z - 0.3), Vector3(2.4, 2.2, 2.4), Color(0.14, g + 0.06, 0.16), true)
		obstacles.append([x, z, 0.5, 0.5])


# =====================================================================
#  بازیکن و اسلحه
# =====================================================================
func build_player():
	player = CharacterBody3D.new()
	player.collision_layer = 4
	player.collision_mask = 1
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	player.add_child(cs)
	player.position = Vector3(0, 0.1, 0)
	add_child(player)

	head = Node3D.new()
	head.position = Vector3(0, 1.6, 0)
	player.add_child(head)

	cam = Camera3D.new()
	cam.fov = BASE_FOV
	cam.near = 0.05
	cam.far = 220.0
	cam.environment = world_env
	head.add_child(cam)

	gun_root = Node3D.new()
	cam.add_child(gun_root)
	gun_model = Node3D.new()
	gun_root.add_child(gun_model)
	muzzle = MeshInstance3D.new()
	muzzle.mesh = unit_sphere
	muzzle.scale = Vector3(0.12, 0.12, 0.12)
	muzzle.material_override = umat(Color(1.0, 0.8, 0.3))
	muzzle.visible = false
	gun_root.add_child(muzzle)


func _gather_aabb(node, xf, acc):
	var t = xf
	if node is Node3D:
		t = xf * node.transform
	if node is MeshInstance3D and node.mesh != null:
		var a = t * node.mesh.get_aabb()
		if acc["has"]:
			acc["box"] = acc["box"].merge(a)
		else:
			acc["box"] = a
			acc["has"] = true
	for c in node.get_children():
		_gather_aabb(c, t, acc)


func build_weapon_model(parent, w, arms):
	var muzzle_z = w["muzzle"]
	var used_model = false
	var path = model_for(w)
	if path != "" and ResourceLoader.exists(path):
		var res = load(path)
		if res is PackedScene:
			var inst = res.instantiate()
			var acc = {"has": false, "box": AABB()}
			_gather_aabb(inst, Transform3D.IDENTITY, acc)
			var box = acc["box"]
			var s = 1.0
			var base_rot = 0.0
			var center = Vector3.ZERO
			if acc["has"]:
				var big = maxf(box.size.x, maxf(box.size.y, box.size.z))
				if big > 0.0001:
					s = w["length"] / big
				if box.size.x >= box.size.y and box.size.x >= box.size.z:
					base_rot = 90.0
				center = box.get_center()
			var fix = model_fix.get(path, {})
			var sc = s * float(fix.get("scale", 1.0))
			var pivot = Node3D.new()
			pivot.rotation_degrees = Vector3(0.0, base_rot + float(fix.get("rot", 0)), 0.0)
			inst.scale = Vector3(sc, sc, sc)
			inst.position = -center * sc
			pivot.add_child(inst)
			parent.add_child(pivot)
			used_model = true
			muzzle_z = w["length"] / 2.0 + 0.05
	if not used_model:
		for p in w["parts"]:
			part(parent, Vector3(p[0].x, p[0].y, -p[0].z), p[1], p[2])
	if arms:
		var L = w["length"]
		part(parent, Vector3(0.04, -0.17, 0.3), Vector3(0.085, 0.085, 0.42), SLEEVE)
		part(parent, Vector3(0.0, -0.05, -L * 0.28), Vector3(0.075, 0.075, 0.09), BLACK)
	return muzzle_z


func equip_weapon():
	for c in gun_model.get_children():
		c.queue_free()
	var w = cw()
	var mz = build_weapon_model(gun_model, w, true)
	gun_base = w["hold"]
	gun_root.position = gun_base
	gun_root.rotation_degrees = Vector3.ZERO
	muzzle.position = Vector3(0, 0.012, -mz)


# =====================================================================
#  لابی (سه‌بعدی)
# =====================================================================
func build_lobby3d():
	lobby3d = Node3D.new()
	add_child(lobby3d)
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.08, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 1.0
	lobby_cam = Camera3D.new()
	lobby_cam.fov = 45.0
	lobby_cam.position = Vector3(0, 0.05, 2.7)
	lobby_cam.environment = env
	lobby3d.add_child(lobby_cam)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -35, 0)
	light.light_energy = 1.3
	lobby3d.add_child(light)
	preview_root = Node3D.new()
	preview_root.scale = Vector3(2.2, 2.2, 2.2)
	lobby3d.add_child(preview_root)
	preview_model = Node3D.new()
	preview_root.add_child(preview_model)


func rebuild_preview():
	for c in preview_model.get_children():
		c.queue_free()
	build_weapon_model(preview_model, cw(), false)


# =====================================================================
#  HUD
# =====================================================================
func mk_label(parent, text, fsize, align = HORIZONTAL_ALIGNMENT_LEFT, col = Color(1, 1, 1)):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func mk_button(parent, text, fsize, callable):
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", fsize)
	b.pressed.connect(callable)
	parent.add_child(b)
	return b


func mk_rect(parent, col):
	var r = ColorRect.new()
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func place(ctrl, x, y, w, h):
	ctrl.position = Vector2(x, y)
	ctrl.size = Vector2(w, h)


func build_hud():
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	damage_flash = mk_rect(hud_layer, Color(1, 0, 0, 0))
	for i in range(4):
		crosshair_parts.append(mk_rect(hud_layer, WHITE))
	hp_bg = mk_rect(hud_layer, Color(0.1, 0.1, 0.1, 0.7))
	hp_fill = mk_rect(hud_layer, Color(0.2, 0.8, 0.3, 1))
	score_label = mk_label(hud_layer, "", 28)
	wave_label = mk_label(hud_layer, "", 28, HORIZONTAL_ALIGNMENT_CENTER)
	ammo_label = mk_label(hud_layer, "", 44, HORIZONTAL_ALIGNMENT_RIGHT)
	weapon_label = mk_label(hud_layer, "", 24, HORIZONTAL_ALIGNMENT_RIGHT, GRAY)
	msg_label = mk_label(hud_layer, "", 56, HORIZONTAL_ALIGNMENT_CENTER)
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	go_box = Control.new()
	go_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(go_box)
	go_restart = mk_button(go_box, "RESTART", 30, restart_game)
	go_lobby = mk_button(go_box, "LOBBY", 30, open_lobby)
	go_box.visible = false


func update_hud():
	hp_fill.size.x = maxf(1.0, 320.0 * hp / 100.0)
	var a = "RELOADING..." if reloading else "%d / %d" % [ammo, reserve]
	if ammo_label.text != a:
		ammo_label.text = a
	var wn = cw()["name"]
	if not is_touch:
		wn += "   (keys 1-5 / wheel)"
	if weapon_label.text != wn:
		weapon_label.text = wn
	var s = "Score: %d   Kills: %d" % [score, kills]
	if score_label.text != s:
		score_label.text = s
	var wv = "Wave %d   Enemies: %d" % [wave, enemies.size()]
	if wave_label.text != wv:
		wave_label.text = wv


func set_crosshair(c):
	for p in crosshair_parts:
		p.color = c


func show_msg(t, secs):
	msg_id += 1
	msg_label.text = t
	if secs > 0.0:
		get_tree().create_timer(secs).timeout.connect(clear_msg.bind(msg_id))


func clear_msg(id):
	if id == msg_id:
		msg_label.text = ""


# =====================================================================
#  کنترل لمسی
# =====================================================================
func make_circle(text, fsize):
	var p = Panel.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.16)
	sb.set_corner_radius_all(512)
	sb.border_color = Color(1, 1, 1, 0.55)
	sb.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if text != "":
		var l = Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", fsize)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		l.add_theme_constant_override("outline_size", 5)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return p


func add_touch_button(id, text, fsize):
	var node = make_circle(text, fsize)
	node.modulate = Color(1, 1, 1, 0.8)
	touch_layer.add_child(node)
	touch_buttons[id] = {"node": node, "center": Vector2.ZERO, "r": 40.0}


func set_touch_button(id, center, r):
	var b = touch_buttons[id]
	b["center"] = center
	b["r"] = r
	b["node"].position = center - Vector2(r, r)
	b["node"].size = Vector2(r * 2.0, r * 2.0)


func build_touch_ui():
	touch_layer = CanvasLayer.new()
	touch_layer.layer = 6
	add_child(touch_layer)
	stick_base = make_circle("", 20)
	stick_base.modulate = Color(1, 1, 1, 0.55)
	touch_layer.add_child(stick_base)
	stick_knob = make_circle("", 20)
	stick_knob.modulate = Color(1, 1, 1, 0.9)
	touch_layer.add_child(stick_knob)
	add_touch_button("fire", "FIRE", 30)
	add_touch_button("ads", "ZOOM", 22)
	add_touch_button("jump", "JUMP", 22)
	add_touch_button("reload", "RELOAD", 18)
	add_touch_button("prev", "PREV", 16)
	add_touch_button("next", "NEXT", 16)
	add_touch_button("menu", "MENU", 16)
	reset_stick()


func reset_stick():
	stick_active = false
	stick_vec = Vector2.ZERO
	stick_base.position = stick_origin - Vector2(STICK_R, STICK_R)
	stick_base.size = Vector2(STICK_R * 2.0, STICK_R * 2.0)
	stick_knob.position = stick_origin - Vector2(KNOB_R, KNOB_R)
	stick_knob.size = Vector2(KNOB_R * 2.0, KNOB_R * 2.0)


func update_stick(pos):
	var d = pos - stick_origin
	if d.length() > STICK_R:
		d = d.normalized() * STICK_R
	stick_vec = Vector2(d.x / STICK_R, -d.y / STICK_R)
	stick_knob.position = stick_origin + d - Vector2(KNOB_R, KNOB_R)


func classify_touch(pos):
	for id in touch_buttons:
		var b = touch_buttons[id]
		if pos.distance_to(b["center"]) <= b["r"] * 1.15:
			return id
	var vs = get_viewport().get_visible_rect().size
	if pos.x < vs.x * 0.45 and pos.y > vs.y * 0.3 and not stick_active:
		return "stick"
	return "look"


func touch_down(role, pos):
	if role == "stick":
		var vs = get_viewport().get_visible_rect().size
		stick_origin = Vector2(clampf(pos.x, 130.0, vs.x * 0.42), clampf(pos.y, vs.y * 0.4, vs.y - 130.0))
		stick_active = true
		stick_base.position = stick_origin - Vector2(STICK_R, STICK_R)
		update_stick(pos)
	elif role == "fire":
		fire_held = true
		if not cw()["auto"]:
			shoot()
	elif role == "ads":
		ads = not ads
	elif role == "jump":
		jump_req = true
	elif role == "reload":
		start_reload()
	elif role == "prev":
		switch_weapon(weapon_idx - 1)
	elif role == "next":
		switch_weapon(weapon_idx + 1)
	elif role == "menu":
		open_lobby()
	if touch_buttons.has(role):
		touch_buttons[role]["node"].modulate = Color(1, 1, 1, 1.0)


func touch_up(role):
	if role == "stick":
		reset_stick()
	elif role == "fire":
		fire_held = false
	if touch_buttons.has(role):
		touch_buttons[role]["node"].modulate = Color(1, 1, 1, 0.8)


# =====================================================================
#  دشمن‌ها
# =====================================================================
func make_enemy(pos):
	var e = Enemy.new()
	e.collision_layer = 2
	e.collision_mask = 0
	e.position = pos
	e.speed = randf_range(2.6, 3.6)
	e.pref_dist = randf_range(13.0, 22.0)
	e.attack_timer = randf_range(1.2, 2.4)
	e.strafe_dir = 1 if randf() < 0.5 else -1
	e.strafe_timer = randf_range(1.0, 3.0)
	e.walk_phase = randf_range(0.0, 6.28)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(1.0, 2.0, 1.0)
	cs.shape = sh
	cs.position = Vector3(0, 1.0, 0)
	e.add_child(cs)

	var u = UNIFORMS[randi() % UNIFORMS.size()]
	var shirt = u[0]
	var pants = u[1]
	var helmet = u[2]

	e.leg_l = Node3D.new()
	e.leg_l.position = Vector3(-0.13, 0.85, 0)
	e.add_child(e.leg_l)
	e.leg_r = Node3D.new()
	e.leg_r.position = Vector3(0.13, 0.85, 0)
	e.add_child(e.leg_r)
	for leg in [e.leg_l, e.leg_r]:
		part(leg, Vector3(0, -0.42, 0), Vector3(0.2, 0.84, 0.24), pants)
		part(leg, Vector3(0, -0.8, 0.04), Vector3(0.22, 0.16, 0.36), BLACK)
	# بدن و جلیقه
	part(e, Vector3(0, 1.2, 0), Vector3(0.5, 0.6, 0.28), shirt)
	part(e, Vector3(0, 1.22, 0.03), Vector3(0.54, 0.44, 0.26), helmet)
	part(e, Vector3(-0.14, 1.08, 0.17), Vector3(0.12, 0.12, 0.06), BLACK)
	part(e, Vector3(0.14, 1.08, 0.17), Vector3(0.12, 0.12, 0.06), BLACK)
	# سر و کلاه
	part(e, Vector3(0, 1.66, 0), Vector3(0.26, 0.3, 0.28), SKIN, true)
	part(e, Vector3(0, 1.73, -0.01), Vector3(0.34, 0.26, 0.37), helmet, true)
	part(e, Vector3(0, 1.67, 0.13), Vector3(0.24, 0.06, 0.06), BLACK)
	# دست‌ها
	part(e, Vector3(0.3, 1.38, 0), Vector3(0.12, 0.12, 0.12), shirt)
	part(e, Vector3(-0.3, 1.38, 0), Vector3(0.12, 0.12, 0.12), shirt)
	part(e, Vector3(0.17, 1.3, 0.28), Vector3(0.09, 0.09, 0.55), shirt)
	part(e, Vector3(-0.04, 1.28, 0.45), Vector3(0.09, 0.09, 0.5), shirt)
	# تفنگ
	part(e, Vector3(0.06, 1.28, 0.45), Vector3(0.07, 0.1, 0.75), DARK)
	part(e, Vector3(0.06, 1.29, 0.98), Vector3(0.03, 0.03, 0.3), BLACK)
	part(e, Vector3(0.06, 1.25, 0.0), Vector3(0.06, 0.12, 0.22), BLACK)
	part(e, Vector3(0.06, 1.16, 0.4), Vector3(0.05, 0.16, 0.08), BLACK)
	part(e, Vector3(0.06, 1.35, 0.35), Vector3(0.03, 0.05, 0.1), BLACK)
	e.flash = part(e, Vector3(0.06, 1.29, 1.2), Vector3(0.4, 0.4, 0.4), Color(1.0, 0.85, 0.4), true)
	e.flash.material_override = umat(Color(1.0, 0.8, 0.3))
	e.flash.visible = false

	world.add_child(e)
	return e


func try_move(e, dx, dz):
	var lim = MAP_HALF - 2.0
	var nx = clampf(e.position.x + dx, -lim, lim)
	var nz = clampf(e.position.z + dz, -lim, lim)
	if not blocked(nx, nz, 0.6):
		e.position.x = nx
		e.position.z = nz
		return true
	if not blocked(nx, e.position.z, 0.6):
		e.position.x = nx
		return true
	if not blocked(e.position.x, nz, 0.6):
		e.position.z = nz
		return true
	return false


func can_see_player(e):
	var from = e.position + Vector3(0, 1.5, 0)
	var to = cam.global_position
	var q = PhysicsRayQueryParameters3D.create(from, to, 1)
	var res = get_world_3d().direct_space_state.intersect_ray(q)
	return res.is_empty()


func hide_flash(e):
	if is_instance_valid(e):
		e.flash.visible = false


func enemy_shoot(e, dist):
	e.flash.visible = true
	get_tree().create_timer(0.07).timeout.connect(hide_flash.bind(e))
	var chance = clampf(0.45 - dist * 0.010, 0.1, 0.4)
	var got_hit = randf() < chance
	var target = player.position + Vector3(0, 1.2, 0)
	if not got_hit:
		target += Vector3(randf_range(-2.5, 2.5), randf_range(-1.0, 1.5), randf_range(-2.5, 2.5))
	spawn_tracer(e.flash.global_position, target, Color(1.0, 0.7, 0.3), 0.03, 0.08)
	if got_hit:
		hurt_player(randi_range(4, 8))


func update_enemy(e, dt):
	if e.dead:
		return
	var to_p = player.position - e.position
	to_p.y = 0.0
	var dist = to_p.length()
	if dist < 0.01:
		return
	var fwd = to_p / dist
	e.rotation.y = atan2(fwd.x, fwd.z)
	var right = Vector3(fwd.z, 0.0, -fwd.x)
	var moved = false
	if e.stuck_timer > 0.0:
		e.stuck_timer -= dt
		var v = right * (e.strafe_dir * e.speed * dt)
		moved = try_move(e, v.x, v.z)
	elif dist > e.pref_dist + 3.0:
		var v = fwd * (e.speed * dt)
		moved = try_move(e, v.x, v.z)
		if not moved:
			e.stuck_timer = randf_range(0.6, 1.4)
			e.strafe_dir = 1 if randf() < 0.5 else -1
	elif dist < e.pref_dist - 5.0:
		var v = fwd * (-e.speed * 0.6 * dt)
		moved = try_move(e, v.x, v.z)
	else:
		e.strafe_timer -= dt
		if e.strafe_timer <= 0.0:
			e.strafe_dir = -e.strafe_dir
			e.strafe_timer = randf_range(1.2, 3.0)
		var v = right * (e.strafe_dir * e.speed * 0.5 * dt)
		moved = try_move(e, v.x, v.z)
	e.position.y = 0.0
	if moved:
		e.walk_phase += dt * 9.0
		var s = sin(e.walk_phase) * 32.0
		e.leg_l.rotation.x = deg_to_rad(s)
		e.leg_r.rotation.x = deg_to_rad(-s)
	else:
		e.leg_l.rotation.x = 0.0
		e.leg_r.rotation.x = 0.0
	e.attack_timer -= dt
	if e.attack_timer <= 0.0:
		e.attack_timer = randf_range(0.9, 1.8)
		if dist < 55.0 and can_see_player(e):
			enemy_shoot(e, dist)


func damage_enemy(e, amount):
	if e.dead:
		return
	e.hp -= amount
	if e.hp <= 0.0:
		kill_enemy(e)


func kill_enemy(e):
	e.dead = true
	score += 100
	kills += 1
	enemies.erase(e)
	e.collision_layer = 0
	e.flash.visible = false
	var tw = e.create_tween()
	tw.tween_property(e, "rotation_degrees:x", -90.0, 0.45)
	tw.tween_interval(3.0)
	tw.tween_callback(e.queue_free)


func spawn_wave():
	wave += 1
	wave_pending = false
	var count = mini(14, 2 + wave * 2)
	for i in range(count):
		for t in range(40):
			var ang = randf() * TAU
			var r = randf_range(30.0, 55.0)
			var x = player.position.x + cos(ang) * r
			var z = player.position.z + sin(ang) * r
			if abs(x) < MAP_HALF - 3.0 and abs(z) < MAP_HALF - 3.0 and not blocked(x, z, 2.0):
				enemies.append(make_enemy(Vector3(x, 0, z)))
				break
	show_msg("Wave %d" % wave, 1.5)


func next_wave(ep):
	if ep != epoch or dead or in_lobby:
		return
	spawn_wave()


func clear_enemies():
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()


# =====================================================================
#  شلیک، ریلود، آسیب
# =====================================================================
func spawn_tracer(a, b, col, width, life):
	var d = b - a
	var ln = d.length()
	if ln < 0.1:
		return
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(width, width, ln)
	mi.mesh = bm
	mi.material_override = umat(col)
	add_child(mi)
	mi.global_position = (a + b) / 2.0
	var up = Vector3.UP
	if absf(d.normalized().y) > 0.98:
		up = Vector3.RIGHT
	mi.look_at(b, up)
	get_tree().create_timer(life).timeout.connect(mi.queue_free)


func spawn_spark(p):
	var mi = MeshInstance3D.new()
	mi.mesh = unit_sphere
	mi.scale = Vector3(0.14, 0.14, 0.14)
	mi.material_override = umat(Color(1.0, 0.9, 0.4))
	add_child(mi)
	mi.global_position = p
	get_tree().create_timer(0.1).timeout.connect(mi.queue_free)


func hide_muzzle():
	muzzle.visible = false


func hurt_player(amount):
	if dead:
		return
	hp -= amount
	last_hit_time = Time.get_ticks_msec() / 1000.0
	damage_flash.color = Color(1, 0, 0, 0.35)
	var tw = create_tween()
	tw.tween_property(damage_flash, "color:a", 0.0, 0.4)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		fire_held = false
		ads = false
		cam.fov = BASE_FOV
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		show_msg("GAME OVER\nScore: %d" % score, 0.0)
		go_box.visible = true


func finish_reload(id):
	if id != reload_id or not reloading:
		return
	var w = cw()
	var need = w["mag"] - ammo
	var take = mini(need, reserve)
	ammo += take
	reserve -= take
	reloading = false


func start_reload():
	var w = cw()
	if reloading or in_lobby or dead or ammo >= w["mag"] or reserve <= 0:
		return
	reloading = true
	if reload_tween != null and reload_tween.is_valid():
		reload_tween.kill()
	reload_tween = create_tween()
	reload_tween.tween_property(gun_root, "rotation_degrees:x", -40.0, 0.3)
	reload_tween.tween_interval(maxf(0.1, w["reload"] - 0.6))
	reload_tween.tween_property(gun_root, "rotation_degrees:x", 0.0, 0.3)
	get_tree().create_timer(w["reload"]).timeout.connect(finish_reload.bind(reload_id))


func shoot():
	var w = cw()
	if reloading or dead or in_lobby:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now < no_fire_until or now - last_shot < 60.0 / w["rpm"]:
		return
	if ammo <= 0:
		start_reload()
		return
	last_shot = now
	ammo -= 1

	muzzle.visible = true
	get_tree().create_timer(0.04).timeout.connect(hide_muzzle)
	gun_root.position.z = gun_base.z + 0.07
	var kick = create_tween()
	kick.tween_property(gun_root, "position:z", gun_base.z, 0.08)
	pitch = clampf(pitch + deg_to_rad(randf_range(0.7, 1.2) * w["recoil"]), -1.45, 1.45)

	var sp = w["spread"] * (0.5 if ads else 1.0)
	var origin = cam.global_position
	var bs = cam.global_transform.basis
	var muzzle_pos = muzzle.global_position
	var space = get_world_3d().direct_space_state
	var hit_enemy = false
	for i in range(w["pellets"]):
		var dir = (-bs.z + bs.x * randf_range(-sp, sp) + bs.y * randf_range(-sp, sp)).normalized()
		var q = PhysicsRayQueryParameters3D.create(origin, origin + dir * 150.0, 3)
		var res = space.intersect_ray(q)
		var end_pt = origin + dir * 80.0
		if not res.is_empty():
			end_pt = res["position"]
			spawn_spark(end_pt)
			var col = res["collider"]
			if col is Enemy and not col.dead:
				var is_head = (end_pt.y - col.position.y) > 1.5
				damage_enemy(col, w["damage"] * (3.0 if is_head else 1.0))
				if is_head:
					score += 50
				hit_enemy = true
		spawn_tracer(muzzle_pos, end_pt, Color(1.0, 0.85, 0.4), 0.025, 0.05)
	if hit_enemy:
		set_crosshair(RED)
		get_tree().create_timer(0.12).timeout.connect(set_crosshair.bind(WHITE))


func switch_weapon(i):
	if in_lobby or dead:
		return
	i = posmod(i, WEAPONS.size())
	if i == weapon_idx:
		return
	ammo_store[cw()["key"]] = [ammo, reserve]
	reloading = false
	reload_id += 1
	if reload_tween != null and reload_tween.is_valid():
		reload_tween.kill()
	weapon_idx = i
	save_settings()
	var nw = cw()
	var st = ammo_store.get(nw["key"], [nw["mag"], nw["reserve"]])
	ammo = st[0]
	reserve = st[1]
	equip_weapon()
	no_fire_until = Time.get_ticks_msec() / 1000.0 + 0.3


# =====================================================================
#  لابی (رابط)
# =====================================================================
func build_lobby_ui():
	lobby_layer = CanvasLayer.new()
	lobby_layer.layer = 10
	add_child(lobby_layer)
	lb_title = mk_label(lobby_layer, "MINI WARZONE", 56, HORIZONTAL_ALIGNMENT_CENTER)
	lb_name = mk_label(lobby_layer, "", 44, HORIZONTAL_ALIGNMENT_CENTER)
	lb_desc = mk_label(lobby_layer, "", 22, HORIZONTAL_ALIGNMENT_CENTER, GRAY)
	lb_ammo = mk_label(lobby_layer, "", 20, HORIZONTAL_ALIGNMENT_LEFT, GRAY)
	for label in ["DAMAGE", "FIRE RATE", "ACCURACY", "MAGAZINE", "RELOAD"]:
		lb_stat_labels.append(mk_label(lobby_layer, label, 20, HORIZONTAL_ALIGNMENT_LEFT, GRAY))
		var bar = ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lobby_layer.add_child(bar)
		lb_stat_bars.append(bar)
	lb_model_title = mk_label(lobby_layer, "MODEL", 22, HORIZONTAL_ALIGNMENT_CENTER, GRAY)
	lb_model = mk_label(lobby_layer, "", 18, HORIZONTAL_ALIGNMENT_CENTER)
	lb_hint = mk_label(lobby_layer, "A / D: weapon     Enter: play     Esc: quit", 18, HORIZONTAL_ALIGNMENT_CENTER, GRAY)
	lb_hint.visible = not is_touch

	lb_buttons["wprev"] = mk_button(lobby_layer, "PREV", 26, change_weapon.bind(-1))
	lb_buttons["wnext"] = mk_button(lobby_layer, "NEXT", 26, change_weapon.bind(1))
	lb_buttons["mprev"] = mk_button(lobby_layer, "PREV", 22, change_model.bind(-1))
	lb_buttons["mnext"] = mk_button(lobby_layer, "NEXT", 22, change_model.bind(1))
	lb_buttons["rotate"] = mk_button(lobby_layer, "ROTATE", 22, rotate_model)
	lb_buttons["smaller"] = mk_button(lobby_layer, "SIZE -", 22, resize_model.bind(1.0 / 1.15))
	lb_buttons["bigger"] = mk_button(lobby_layer, "SIZE +", 22, resize_model.bind(1.15))
	lb_buttons["play"] = mk_button(lobby_layer, "PLAY", 40, start_game)
	lb_buttons["quit"] = mk_button(lobby_layer, "QUIT", 20, get_tree().quit)
	var green = StyleBoxFlat.new()
	green.bg_color = Color(0.15, 0.5, 0.25)
	green.set_corner_radius_all(8)
	lb_buttons["play"].add_theme_stylebox_override("normal", green)


func stat_value(i, w):
	if i == 0:
		return minf(1.0, pow(w["damage"] * w["pellets"] / 120.0, 0.5))
	if i == 1:
		return minf(1.0, pow(w["rpm"] / 900.0, 0.5))
	if i == 2:
		return maxf(0.05, 1.0 - w["spread"] / 0.06)
	if i == 3:
		return minf(1.0, w["mag"] / 40.0)
	return maxf(0.05, minf(1.0, 1.0 - (w["reload"] - 0.8) / 2.0))


func refresh_lobby():
	var w = cw()
	lb_name.text = w["name"]
	lb_desc.text = w["desc"]
	for i in range(5):
		lb_stat_bars[i].value = stat_value(i, w)
	var t = "%d / %d ammo" % [w["mag"], w["reserve"]]
	if w["pellets"] > 1:
		t += "   x%d pellets" % w["pellets"]
	lb_ammo.text = t
	var p = model_for(w)
	if p != "":
		lb_model.text = "%s  (%d/%d)" % [p.get_file().get_basename(), model_pool.find(p) + 1, model_pool.size()]
	else:
		lb_model.text = "no .glb in models folder\n(using built-in gun)"
	rebuild_preview()


func change_weapon(d):
	weapon_idx = posmod(weapon_idx + d, WEAPONS.size())
	save_settings()
	refresh_lobby()


func change_model(d):
	if model_pool.size() == 0:
		return
	var w = cw()
	var cur = model_pool.find(model_for(w))
	model_choice[w["key"]] = model_pool[posmod(cur + d, model_pool.size())]
	save_settings()
	refresh_lobby()


func rotate_model():
	var p = model_for(cw())
	if p == "":
		return
	var f = model_fix.get(p, {})
	f["rot"] = posmod(int(f.get("rot", 0)) + 90, 360)
	model_fix[p] = f
	save_settings()
	rebuild_preview()


func resize_model(factor):
	var p = model_for(cw())
	if p == "":
		return
	var f = model_fix.get(p, {})
	f["scale"] = clampf(float(f.get("scale", 1.0)) * factor, 0.4, 2.5)
	model_fix[p] = f
	save_settings()
	rebuild_preview()


# =====================================================================
#  چیدمان رابط (با تغییر اندازه‌ی صفحه دوباره اجرا می‌شه)
# =====================================================================
func layout_ui():
	var vs = get_viewport().get_visible_rect().size
	var cx = vs.x * 0.5
	var cy = vs.y * 0.5

	# HUD
	place(damage_flash, 0, 0, vs.x, vs.y)
	place(crosshair_parts[0], cx - 16, cy - 1, 10, 2)
	place(crosshair_parts[1], cx + 6, cy - 1, 10, 2)
	place(crosshair_parts[2], cx - 1, cy - 16, 2, 10)
	place(crosshair_parts[3], cx - 1, cy + 6, 2, 10)
	place(hp_bg, 20, vs.y - 50, 320, 26)
	place(hp_fill, 20, vs.y - 50, 320, 26)
	place(score_label, 20, 14, 520, 44)
	place(wave_label, cx - 260, 14, 520, 44)
	if is_touch:
		place(weapon_label, vs.x - 350, 100, 330, 34)
		place(ammo_label, vs.x - 350, 132, 330, 60)
	else:
		place(weapon_label, vs.x - 520, vs.y - 100, 500, 34)
		place(ammo_label, vs.x - 520, vs.y - 66, 500, 60)
	place(msg_label, 0, vs.y * 0.15, vs.x, 220)
	place(go_restart, cx - 240, vs.y * 0.58, 220, 80)
	place(go_lobby, cx + 20, vs.y * 0.58, 220, 80)

	# لمسی
	stick_origin = Vector2(190, vs.y - 170)
	reset_stick()
	set_touch_button("fire", Vector2(vs.x - 150, vs.y - 170), 85.0)
	set_touch_button("ads", Vector2(vs.x - 345, vs.y - 120), 55.0)
	set_touch_button("jump", Vector2(vs.x - 110, vs.y - 355), 55.0)
	set_touch_button("reload", Vector2(vs.x - 305, vs.y - 290), 50.0)
	set_touch_button("prev", Vector2(vs.x - 270, 52), 38.0)
	set_touch_button("next", Vector2(vs.x - 185, 52), 38.0)
	set_touch_button("menu", Vector2(vs.x - 70, 52), 38.0)

	# لابی
	place(lb_title, 0, 18, vs.x, 70)
	place(lb_name, 0, 92, vs.x, 56)
	place(lb_desc, 0, 148, vs.x, 30)
	place(lb_buttons["wprev"], cx - 330, cy - 35, 130, 70)
	place(lb_buttons["wnext"], cx + 200, cy - 35, 130, 70)
	for i in range(5):
		place(lb_stat_labels[i], 30, 210 + i * 62, 220, 28)
		place(lb_stat_bars[i], 30, 240 + i * 62, 260, 20)
	place(lb_ammo, 30, 210 + 5 * 62, 400, 28)
	var rx = vs.x - 300
	place(lb_model_title, rx, 210, 280, 30)
	place(lb_model, rx - 10, 244, 300, 56)
	place(lb_buttons["mprev"], rx, 312, 130, 56)
	place(lb_buttons["mnext"], rx + 150, 312, 130, 56)
	place(lb_buttons["rotate"], rx, 384, 280, 56)
	place(lb_buttons["smaller"], rx, 456, 130, 56)
	place(lb_buttons["bigger"], rx + 150, 456, 130, 56)
	place(lb_buttons["play"], cx - 140, vs.y - 110, 280, 84)
	place(lb_buttons["quit"], vs.x - 120, 14, 100, 46)
	place(lb_hint, 0, vs.y - 28, vs.x, 24)


# =====================================================================
#  حالت‌ها: لابی <-> بازی
# =====================================================================
func open_lobby():
	in_lobby = true
	epoch += 1
	reload_id += 1
	reloading = false
	dead = false
	fire_held = false
	ads = false
	clear_enemies()
	touch_roles.clear()
	reset_stick()
	world.visible = false
	lobby3d.visible = true
	hud_layer.visible = false
	touch_layer.visible = false
	go_box.visible = false
	lobby_layer.visible = true
	gun_root.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lobby_cam.current = true
	cam.fov = BASE_FOV
	msg_label.text = ""
	refresh_lobby()


func start_game():
	if not in_lobby:
		return
	in_lobby = false
	world.visible = true
	lobby3d.visible = false
	lobby_layer.visible = false
	hud_layer.visible = true
	touch_layer.visible = is_touch
	cam.current = true
	gun_root.visible = true
	equip_weapon()
	restart_game()
	no_fire_until = Time.get_ticks_msec() / 1000.0 + 0.4


func restart_game():
	clear_enemies()
	var w = cw()
	epoch += 1
	reload_id += 1
	ammo_store.clear()
	ammo = w["mag"]
	reserve = w["reserve"]
	reloading = false
	hp = 100.0
	score = 0
	kills = 0
	wave = 0
	dead = false
	wave_pending = false
	last_hit_time = 0.0
	fire_held = false
	ads = false
	player.position = Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	yaw = 0.0
	pitch = 0.0
	go_box.visible = false
	msg_label.text = ""
	if not is_touch:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_wave()
	update_hud()


# =====================================================================
#  ورودی
# =====================================================================
func _input(event):
	if in_lobby:
		if event is InputEventKey and event.pressed and not event.echo:
			var k = event.keycode
			if k == KEY_A or k == KEY_LEFT:
				change_weapon(-1)
			elif k == KEY_D or k == KEY_RIGHT:
				change_weapon(1)
			elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
				start_game()
			elif k == KEY_ESCAPE:
				get_tree().quit()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var k = event.keycode
		if k == KEY_ESCAPE:
			open_lobby()
		elif k == KEY_R:
			start_reload()
		elif k == KEY_T and dead:
			restart_game()
		elif k == KEY_SPACE:
			jump_req = true
		elif k >= KEY_1 and k <= KEY_5:
			switch_weapon(k - KEY_1)
		return

	if dead:
		return

	if is_touch:
		if event is InputEventScreenTouch:
			if event.pressed:
				var role = classify_touch(event.position)
				touch_roles[event.index] = role
				touch_down(role, event.position)
			else:
				var role2 = touch_roles.get(event.index, "")
				touch_roles.erase(event.index)
				touch_up(role2)
		elif event is InputEventScreenDrag:
			var r = touch_roles.get(event.index, "")
			if r == "stick":
				update_stick(event.position)
			elif r == "look":
				yaw -= event.relative.x * TOUCH_SENS
				pitch = clampf(pitch - event.relative.y * TOUCH_SENS, -1.45, 1.45)
		return

	# ماوس (کامپیوتر)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENS
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -1.45, 1.45)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			fire_held = event.pressed
			if event.pressed and not cw()["auto"]:
				shoot()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			ads = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			switch_weapon(weapon_idx - 1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			switch_weapon(weapon_idx + 1)


# =====================================================================
#  حلقه‌ی بازی
# =====================================================================
func _physics_process(delta):
	if in_lobby:
		return
	for e in enemies.duplicate():
		if is_instance_valid(e):
			update_enemy(e, delta)
	if dead:
		return

	var mv = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		mv.y += 1.0
	if Input.is_physical_key_pressed(KEY_S):
		mv.y -= 1.0
	if Input.is_physical_key_pressed(KEY_A):
		mv.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		mv.x += 1.0
	mv += stick_vec
	if mv.length() > 1.0:
		mv = mv.normalized()
	moving_flag = mv.length() > 0.1
	var spd = 7.0
	if Input.is_physical_key_pressed(KEY_SHIFT) or stick_vec.length() > 0.92:
		spd = 10.0
	var bs = player.global_transform.basis
	var wish = (bs.x * mv.x + (-bs.z) * mv.y) * spd
	player.velocity.x = wish.x
	player.velocity.z = wish.z
	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	elif jump_req:
		player.velocity.y = 5.6
	else:
		player.velocity.y = 0.0
	jump_req = false
	player.move_and_slide()


func _process(delta):
	if in_lobby:
		preview_root.rotation.y += 0.7 * delta
		preview_root.position.y = sin(Time.get_ticks_msec() / 1000.0 * 1.5) * 0.03
		return

	player.rotation.y = yaw
	head.rotation.x = pitch
	update_hud()
	if dead:
		return

	var w = cw()
	if fire_held and w["auto"]:
		shoot()

	cam.fov = lerpf(cam.fov, w["zoom_fov"] if ads else BASE_FOV, minf(1.0, 12.0 * delta))
	gun_root.visible = cam.fov > 40.0

	# موج بعدی
	if enemies.size() == 0 and not wave_pending:
		wave_pending = true
		show_msg("Wave cleared", 2.4)
		get_tree().create_timer(2.5).timeout.connect(next_wave.bind(epoch))

	# بازیابی آرام سلامتی
	var now = Time.get_ticks_msec() / 1000.0
	if hp < 100.0 and now - last_hit_time > 5.0:
		hp = minf(100.0, hp + 10.0 * delta)

	# تکان خوردن اسلحه و زوم
	var bob = 0.0
	if moving_flag and not ads:
		bob_t += delta * 10.0
		bob = absf(sin(bob_t)) * 0.014
	gun_root.position.x = lerpf(gun_root.position.x, gun_base.x * (0.15 if ads else 1.0), minf(1.0, 12.0 * delta))
	gun_root.position.y = lerpf(gun_root.position.y, gun_base.y + (0.06 if ads else 0.0) + bob, minf(1.0, 14.0 * delta))

	# ریلود خودکار
	if ammo == 0 and not reloading:
		start_reload()
