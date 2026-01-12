# import numpy as np
# import matplotlib.pyplot as plt
# from scipy.integrate import solve_ivp
#
# G = 6.67430e-11
# M_sun = 1.989e30
# M_jupiter = 1.898e27
# AU = 1.496e11
#
# a = 5e4 * AU
#
# r_0 = np.array([a, 0])
# v_0 = np.array([0,np.sqrt(G * M_sun / a)])
#
# r_jupiter = np.array([5.2 * AU, 0])
#
# def orbit_eqns(t, y):
#
#     x, y_pos, vx, vy = y
#     r_sun = np.array([x, y_pos])
#     r_j = np.array([x - r_jupiter[0],y_pos])
#
#     a_sun = -G * M_sun * r_sun / np.linalg.norm(r_sun) ** 3
#     a_jupiter = -G * M_jupiter * r_j / np.linalg.norm(r_j) ** 3
#
#     return [vx, vy, a_sun[0] + a_jupiter[0],a_sun[1] +a_jupiter[1]]
#
#
#     t_span = (0, 10 * 365 * 24 * 3600)
#     y0 = np.array([r_0[0],r_0[1],v_0[0],v_0[1]])
#
#     sol = solve_ivp(orbit_eqns, t_span, y0, t_eval=np.linspace(0, 10 *365 * 24 * 3600, 1000))
#
#     plt.figure(figsize=(8, 8))
#     plt.plot(sol.y[0] / AU, sol.y[1] / AU, label='彗星轨道')
#     plt.scatter(0, 0, color='yellow', label='太阳',s = 100)
#     plt.scatter(r_jupiter[0] / AU, r_jupiter[1] / AU, color='blue',label='木星',s = 100)
#     plt.axhline(0, color='gray', lw=1)
#     plt.axvline(0, color='gray', lw=1)
#     plt.xlabel('x (AU)')
#     plt.ylabel('y (AU)')
#     plt.title('彗星轨道和木星位置')
#     plt.legend()
#     plt.grid(True)
#     plt.show()
#
