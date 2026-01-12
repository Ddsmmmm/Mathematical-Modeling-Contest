# import numpy as np
# import matplotlib.pyplot as plt
# from scipy.integrate import solve_ivp
#
# G = 6.67430e-11
# M_sun = 1.989e30
# AU = 1.496e11
#
# M_jupiter_initial = 1.898e27
# r_jupiter_initial = 5.2 * AU
#
# a_asteroid = 3.0 * AU
# v_asteroid = np.sqrt(G * M_sun / a_asteroid)
#
#
# def asteroid_orbit(t, y, M_jupiter):
#     x, y_pos, vx, vy = y
#
#     r_sun = np.array([x, y_pos])
#     r_j = np.array([x - r_jupiter[0],y_pos])
#
#     a_sun = -G * M_sun * r_sun / np.linalg.norm(r_sun) ** 3
#     a_jupiter = -G * M_jupiter * r_j / np.linalg.norm(r_j) ** 3
#
#     return [vx, vy, a_sun[0] + a_jupiter[0],a_sun[1] +a_jupiter[1]]

#
# import numpy as np
# import matplotlib.pyplot as plt
# from scipy.integrate import solve_ivp
#
# G = 6.67430e-11
# M_sun = 1.989e30
# AU = 1.496e11
#
# M_jupiter_initial = 1.898e27
#
# r_jupiter_initial = 5.2 * AU
#
# a_asteroid = 3.0 * AU
#
# v_asteroid = np.sqrt(G * M_sun / a_asteroid)
#
# def asteroid_orbit(t, y, M_jupiter):
# x, y_pos, vx, vy = y
#
# r_sun = np.array([x, y_pos])
# r_j = np.array([x - r_jupiter[0],y_pos])
# a_sun = -G * M_sun * r_sun / np.linalg.norm(r_sun) ** 3
# a_jupiter = -G * M_jupiter * r_j / np.linalg.norm(r_j) ** 3
#
# return [vx, vy, a_sun[0] + a_jupiter[0],a_sun[1] + a_jupiter[1]]
#
# t_span = (0, 1e8)
# t_eval = np.linspace(0, 1e8, 1000)
#
# y0 = np.array([a_asteroid, 0, 0, v_asteroid])
#
# def simulate_orbit(M_jupiter):
# sol = solve_ivp(asteroid_orbit, t_span, y0, t_eval=t_eval,
# args=(M_jupiter,))
# return sol
#
# M_jupiters = np.linspace(1.8e27, 2.0e27, 5)
#
#
# orbits = []
#
# plt.figure(figsize=(10, 8))
# for M_jupiter in M_jupiters:
# sol = simulate_orbit(M_jupiter)
# orbits.append(sol)
# plt.plot(sol.y[0] / AU, sol.y[1] / AU, label=f'M_jupiter = {M_jupi
# ter / 1e27:.2f} M_Ͱ')
# plt.title('The effects of different Jupiter masses on asteroid orbits')
# plt.xlabel('x (AU)')
# plt.ylabel('y (AU)')
# plt.axhline(0, color='black', lw=1)
# plt.axvline(0, color='black', lw=1)
# plt.legend()
# plt.grid(True)
# plt.show()