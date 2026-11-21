extends Node3D
## ISLAND-ART-04: simple GL Compatibility-compatible ocean and atmosphere.
## All meshes are visuals only. WORLD-001's existing landing and cover collision
## remains unchanged; no screen textures, compute shaders, or native addons.

const OCEAN_Y := -1.84
const SEA_COLOR := Color(0.09, 0.40, 0.52, 0.82)

func _ready() -> void:
    _create_ocean()
    _create_shoreline()
    _create_atmosphere()

func _ocean_shader() -> Shader:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 water_color : source_color = vec4(0.09, 0.40, 0.52, 1.0);
uniform float wave_height : hint_range(0.0, 0.2) = 0.055;
void vertex() {
    float wave = sin(VERTEX.x * 0.18 + TIME * 0.65) * cos(VERTEX.z * 0.14 + TIME * 0.53);
    VERTEX.y += wave * wave_height;
}
void fragment() {
    ALBEDO = water_color.rgb;
    ROUGHNESS = 0.35;
    METALLIC = 0.02;
}
"""
    return shader

func _create_ocean() -> void:
    var surface := MeshInstance3D.new()
    surface.name = "OceanSurface"
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(190.0, 190.0)
    mesh.subdivide_width = 24
    mesh.subdivide_depth = 24
    surface.mesh = mesh
    surface.position = Vector3(0.0, OCEAN_Y, 10.0)
    var mat := ShaderMaterial.new()
    mat.shader = _ocean_shader()
    surface.material_override = mat
    # The plane never collides with or alters the existing walkable route.
    add_child(surface)

func _create_shoreline() -> void:
    # Shallow blue bands beyond the existing beach (z > 50).
    # Place these above the new ocean and below the original water blockout.
    for i in range(3):
        var band := MeshInstance3D.new()
        band.name = "ShoreFoam_%d" % i
        var quad := PlaneMesh.new()
        quad.size = Vector2(98.0, 0.28 + 0.14 * float(i))
        band.mesh = quad
        band.position = Vector3(0.0, -1.62 + float(i) * 0.008, 50.8 + float(i) * 1.4)
        var foam := StandardMaterial3D.new()
        foam.albedo_color = Color(0.68, 0.86, 0.81, 1.0 - float(i) * 0.12)
        foam.roughness = 1.0
        foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        band.material_override = foam
        add_child(band)

func _create_atmosphere() -> void:
    # Local environment belongs to this island; no project settings modified.
    var environment_node := WorldEnvironment.new()
    environment_node.name = "IslandEnvironment"
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.47, 0.69, 0.79)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.78, 0.74)
    environment.ambient_light_energy = 0.75
    environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    environment_node.environment = environment
    add_child(environment_node)

    var sunlight := DirectionalLight3D.new()
    sunlight.name = "IslandSun"
    sunlight.rotation_degrees = Vector3(-48.0, -25.0, 0.0)
    sunlight.light_color = Color(1.0, 0.94, 0.79)
    sunlight.light_energy = 0.8
    sunlight.shadow_enabled = false
    add_child(sunlight)
