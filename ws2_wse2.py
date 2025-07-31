from ase.build import mx2  # noqa: I001
from ase import Atoms
from ase.io import write
import numpy as np

a_WS2 = 3.19
a_WSe2 = 3.282

# Build strained supercells
unit_ws2: Atoms = mx2("WS2", kind="2H", a=3.19)
wse2: Atoms = mx2("WSe2", kind="2H", a=a_WS2, size=(8, 8, 1))
wse2_upper: Atoms = mx2("WSe2", kind="2H", a=a_WS2, size=(8, 8, 1))
ws2: Atoms = mx2("WS2", kind="2H", a=a_WSe2, size=(8, 16, 1))


to_shift_w = [
    (id, coord)
    for (id, coord) in enumerate(wse2.get_scaled_positions())
    if -0.01 < coord[0] < 0.01
]
print(to_shift_w)


def translate_part(to_apply_atoms, to_shift_atom_idx, fractions, translation_vec):
    assert len(to_shift_atom_idx) == len(fractions)
    for (id, _), trans in zip(
        to_shift_atom_idx, [translation_vec * frac for frac in fractions]
    ):
        to_apply_atoms[id].position += trans


translation_vec_by_a_wse2 = np.array([-1 / 6, 3**0.5 / 6, 0.0]) * a_WSe2
# Stretch the row of W up
# to_shift_w is ordered from bottom to top
# the bottom one receives the strongest displacement
print("WSe2 upper w")
translate_part(
    wse2_upper,
    to_shift_w,
    [i / 8 for i in range(8, 0, -1)],
    translation_vec_by_a_wse2 * 0.7,
)
# Stretch the row of W down
# to_shift_w is ordered from bottom to top
# the top one receives the strongest displacement
print("WSe2 lower w")
translate_part(
    wse2, to_shift_w, [i / 8 for i in range(1, 9)], translation_vec_by_a_wse2 * -1 * 0.7
)
translation_vec_by_a_ws2 = np.array([-1 / 6, 3**0.5 / 6, 0.0]) * a_WS2
# Stretch the row of S up
to_shift_s_upper = [
    (id, coord)
    for (id, coord) in enumerate(ws2.get_scaled_positions())
    if 0.875 < coord[0] < 1.00 and coord[1] > 0.50
]
to_shift_s_upper_len = int(len(to_shift_s_upper) / 2)
# the displacement becomes stronger
# since we have two layers of S, and S atoms with same (x,y) are adjacent, use
# `np.repeat` to create [1, 1, 2, 2, ... 8, 8]
s_fractions_upper = np.repeat(
    [i / to_shift_s_upper_len for i in range(1, to_shift_s_upper_len + 1)],
    2,
)
translate_part(ws2, to_shift_s_upper, s_fractions_upper, translation_vec_by_a_ws2 * -1)
# Stretch the row of S down
to_shift_s_lower = [
    (id, coord)
    for (id, coord) in enumerate(ws2.get_scaled_positions())
    if 0.875 < coord[0] < 1.00 and coord[1] < 0.4
]
to_shift_s_lower_len = int(len(to_shift_s_lower) / 2)
# the displacement becomes weaker
# since we have two layers of S, and S atoms with same (x,y) are adjacent, use
# `np.repeat` to create [8, 8, 7, 7, ... 1, 1]
s_fractions_lower = np.repeat(
    [i / to_shift_s_lower_len for i in range(to_shift_s_lower_len, 0, -1)], 2
)
translate_part(ws2, to_shift_s_lower, s_fractions_lower, translation_vec_by_a_ws2)

# Shift whole WS2
ws2.positions[:] += translation_vec_by_a_wse2 * 0.7
wse2.positions[:, 0] += ws2.cell[0, 0] + 1.1
wse2_upper.positions[:, 0] += ws2.cell[0, 0] + 1.1
# Shift wse2 to the bottom of wse2_b
wse2_upper.positions[:] += wse2.cell[1]
wse2.cell[2, 2] += 10
hetero = ws2 + wse2 + wse2_upper
new_cell = [wse2.cell[0] + ws2.cell[0], 2 * wse2.cell[1], wse2.cell[2]]
hetero.set_cell(new_cell)
hetero.set_pbc([False, True, False])
hetero.center(10, axis=2)
hetero.center(20, axis=0)
hetero.positions[:, 2] -= 9.5
unit_ws2.positions[0] += hetero.cell[0] * 0.50
unit_ws2.positions[0] += hetero.cell[1] * 0.4548
unit_ws2.positions[0] += hetero.cell[2] * 0.09034
unit_ws2.positions[1:3] += hetero.cell[0] * 0.505
unit_ws2.positions[1:3] += hetero.cell[1] * 0.459
unit_ws2.positions[1:3] += hetero.cell[2] * 0.09034
unit_ws2.set_cell(hetero.cell)
print(unit_ws2.get_scaled_positions())
print(unit_ws2.get_positions()[1:3])
hetero += unit_ws2


write("ws2_wse2_57_disloc_single.cif", hetero)
write("ws2_wse2_57_disloc_single.lmp", hetero, format="lammps-data")
