# Escena simple del condominio para el render de prueba de srv-render (Blender, modo consola).
# Uso: blender -b -P render-casa.py -- <salida.png> <escena.blend>
import math
import sys

import bpy

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
salida = args[0] if args else "/tmp/casa.png"
escena_blend = args[1] if len(args) > 1 else None

bpy.ops.wm.read_factory_settings(use_empty=True)
esc = bpy.context.scene


def material(nombre, color, rugosidad=0.6):
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = rugosidad
    return m


def caja(nombre, ubicacion, escala, mat):
    bpy.ops.mesh.primitive_cube_add(location=ubicacion)
    o = bpy.context.object
    o.name = nombre
    o.scale = escala
    o.data.materials.append(mat)
    return o


pasto = material("Pasto", (0.22, 0.38, 0.18), 0.9)
muro = material("Muro", (0.86, 0.82, 0.74))
techo = material("Techo", (0.45, 0.18, 0.12))
vidrio = material("Vidrio", (0.25, 0.4, 0.55), 0.1)

bpy.ops.mesh.primitive_plane_add(size=60)
bpy.context.object.data.materials.append(pasto)

# Tres casas del condominio
for i, x in enumerate((-7, 0, 7)):
    caja(f"Casa{i}", (x, 0, 1.5), (2.6, 2.2, 1.5), muro)
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=3.9, depth=1.8, location=(x, 0, 3.9), rotation=(0, 0, math.pi / 4))
    bpy.context.object.scale = (1, 0.85, 1)
    bpy.context.object.data.materials.append(techo)
    caja(f"Ventana{i}", (x, -2.21, 1.6), (0.9, 0.02, 0.6), vidrio)

bpy.ops.object.light_add(type="SUN", location=(10, -10, 20))
bpy.context.object.data.energy = 4
bpy.context.object.rotation_euler = (math.radians(50), 0, math.radians(35))

bpy.ops.object.camera_add(location=(0, -24, 9), rotation=(math.radians(72), 0, 0))
esc.camera = bpy.context.object

mundo = bpy.data.worlds.new("Cielo")
mundo.use_nodes = True
mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.72, 0.9, 1)
esc.world = mundo

esc.render.engine = "CYCLES"
esc.cycles.device = "CPU"
esc.cycles.samples = 32
esc.render.resolution_x = 1280
esc.render.resolution_y = 720
esc.render.image_settings.file_format = "PNG"
esc.render.filepath = salida

if escena_blend:
    bpy.ops.wm.save_as_mainfile(filepath=escena_blend)
bpy.ops.render.render(write_still=True)
print(f"RENDER LISTO: {salida}")
