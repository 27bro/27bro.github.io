"""Generate a conceptual figure explaining Equilibrium-Point (EP) theory
for the WCB / RCIL post. Matches the site's navy/teal palette.

Output: website/assets/img/ep_theory.png
"""
import os
import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Circle

NAVY = "#0b1f3a"
NAVY2 = "#12325c"
TEAL = "#2dd4bf"
DEEP = "#0d9488"
MUTED = "#5b6675"
INK = "#1a2230"
LINE = "#c9d3e0"
FAINT = "#aab6c6"

plt.rcParams.update(
    {
        "font.family": "DejaVu Sans",
        "font.size": 12,
        "axes.edgecolor": LINE,
        "text.color": INK,
        "axes.labelcolor": INK,
    }
)


def spring(ax, x0, y0, x1, y1, coils=6, amp=0.05, color=MUTED, lw=1.8):
    """Draw a simple zig-zag spring between two points."""
    x0, y0, x1, y1 = map(float, (x0, y0, x1, y1))
    dx, dy = x1 - x0, y1 - y0
    length = np.hypot(dx, dy)
    ux, uy = dx / length, dy / length
    px, py = -uy, ux  # perpendicular
    n = coils * 2
    pts = [(x0, y0)]
    for i in range(1, n):
        t = i / n
        off = amp * (1 if i % 2 else -1)
        pts.append((x0 + dx * t + px * off, y0 + dy * t + py * off))
    pts.append((x1, y1))
    pts = np.array(pts)
    ax.plot(pts[:, 0], pts[:, 1], color=color, lw=lw, solid_capstyle="round", zorder=2)


def leg(ax, x, y, hip_deg, knee_deg=12, scale=0.9, color=NAVY, alpha=1.0, lw=4):
    """Draw a simple stick leg. hip_deg: thigh angle from vertical (+ forward)."""
    hip = np.radians(hip_deg)
    thigh_len = 0.55 * scale
    shank_len = 0.5 * scale
    kx = x + thigh_len * np.sin(hip)
    ky = y - thigh_len * np.cos(hip)
    knee = np.radians(hip_deg - knee_deg)
    fx = kx + shank_len * np.sin(knee)
    fy = ky - shank_len * np.cos(knee)
    ax.plot([x, kx], [y, ky], color=color, lw=lw, solid_capstyle="round", alpha=alpha, zorder=3)
    ax.plot([kx, fx], [ky, fy], color=color, lw=lw, solid_capstyle="round", alpha=alpha, zorder=3)
    ax.add_patch(Circle((x, y), 0.045 * scale, color=color, alpha=alpha, zorder=4))  # hip
    ax.add_patch(Circle((kx, ky), 0.035 * scale, color=color, alpha=alpha, zorder=4))  # knee
    ax.plot([fx, fx + 0.12 * scale], [fy, fy], color=color, lw=lw, solid_capstyle="round", alpha=alpha, zorder=3)


fig, axes = plt.subplots(1, 2, figsize=(11.6, 5.2), dpi=150)
fig.subplots_adjust(left=0.05, right=0.97, top=0.86, bottom=0.06, wspace=0.16)

# ---------------------------------------------------------------- Panel A
ax = axes[0]
ax.set_title("Muscles set an equilibrium posture",
             fontsize=14.5, fontweight="bold", color=NAVY, pad=14)

R1 = 0.0
theta = np.linspace(-1.15, 1.15, 400)
U = 1.05 * (theta - R1) ** 2
ax.plot(theta, U, color=NAVY, lw=2.6, zorder=1)
# ball at the bottom
ax.add_patch(Circle((R1, 0.0), 0.075, color=TEAL, ec=DEEP, lw=1.5, zorder=5))
ax.annotate("equilibrium point R\n(referent configuration)",
            xy=(R1, 0.0), xytext=(R1 - 0.02, 0.62),
            ha="center", fontsize=11.5, color=DEEP, fontweight="bold",
            arrowprops=dict(arrowstyle="-|>", color=DEEP, lw=1.6))

# springs as "tunable" muscle behaviour
spring(ax, -1.05, 0.9, -0.18, 0.15, coils=7, amp=0.05, color=MUTED)
spring(ax, 1.05, 0.9, 0.18, 0.15, coils=7, amp=0.05, color=MUTED)
ax.text(-0.9, 1.03, "agonist", fontsize=10.5, color=MUTED, ha="center")
ax.text(0.9, 1.03, "antagonist", fontsize=10.5, color=MUTED, ha="center")

ax.text(0.0, 1.28,
        "muscles + reflexes behave like tunable springs",
        ha="center", fontsize=11, color=MUTED, style="italic")

# stick leg at R
leg(ax, 0.0, -0.35, hip_deg=0, color=NAVY)

ax.set_xlim(-1.3, 1.3)
ax.set_ylim(-1.05, 1.5)
ax.axis("off")

# ---------------------------------------------------------------- Panel B
ax = axes[1]
ax.set_title("Movement = shifting the equilibrium point",
             fontsize=14.5, fontweight="bold", color=NAVY, pad=14)

R_old = -0.55
R_new = 0.55
U_old = 1.05 * (theta - R_old) ** 2
U_new = 1.05 * (theta - R_new) ** 2
ax.plot(theta, U_old, color=FAINT, lw=2.0, ls="--", zorder=1)
ax.plot(theta, U_new, color=NAVY, lw=2.6, zorder=1)

# old (faded) ball, new ball
ax.add_patch(Circle((R_old, 0.0), 0.065, color="#dfeaf6", ec=FAINT, lw=1.3, zorder=4))
ax.add_patch(Circle((R_new, 0.0), 0.075, color=TEAL, ec=DEEP, lw=1.5, zorder=6))

# curved arrow: CNS shifts referent
arr = FancyArrowPatch((R_old, 0.80), (R_new, 0.80),
                      connectionstyle="arc3,rad=-0.32",
                      arrowstyle="-|>", mutation_scale=18,
                      color=DEEP, lw=2.0, zorder=5)
ax.add_patch(arr)
ax.text(0.0, 1.48, "CNS shifts referent R over time",
        ha="center", fontsize=11.5, color=DEEP, fontweight="bold")
ax.text(0.0, 1.26, "the body settles toward each new equilibrium",
        ha="center", fontsize=10.5, color=MUTED, style="italic")

# residual Delta-theta: reference R vs corrected true equilibrium
R_ref = R_new
R_true = R_new + 0.26
ax.add_patch(Circle((R_ref, 0.0), 0.05, fc="white", ec=NAVY, lw=1.8, zorder=7))
resid = FancyArrowPatch((R_ref, -0.22), (R_true, -0.22),
                        arrowstyle="-|>", mutation_scale=14,
                        color=DEEP, lw=1.8, zorder=7)
ax.add_patch(resid)
ax.text((R_ref + R_true) / 2, -0.42,
        r"$\Delta\theta$  learned residual",
        ha="center", fontsize=10.5, color=DEEP, fontweight="bold")
ax.text(R_ref, 0.2, "reference R\n(imperfect)", ha="center",
        fontsize=9.5, color=NAVY)

# faded old leg + new leg
leg(ax, R_old, -0.72, hip_deg=-18, color=FAINT, alpha=0.9, lw=3.4)
leg(ax, R_new, -0.72, hip_deg=18, color=NAVY)

ax.set_xlim(-1.3, 1.3)
ax.set_ylim(-1.15, 1.7)
ax.axis("off")

out = os.path.join(os.path.dirname(__file__), "..", "assets", "img", "ep_theory.png")
out = os.path.normpath(out)
fig.savefig(out, dpi=150, facecolor="white", bbox_inches="tight", pad_inches=0.2)
print("saved", out, os.path.getsize(out))
