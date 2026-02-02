import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm

# ==========================================
# 1. 定义模拟函数 (模拟 Task 4 的核心逻辑)
# ==========================================
def calculate_fairness(K, beta):
    # 这里模拟一次比赛结果
    # 假设有 10 名选手
    # 选手 A (Bobby类型): 技术分极低(0.1), 粉丝分极高(1.0)
    # 选手 B (Milo类型): 技术分极高(1.0), 粉丝分中等(0.5)
    # 其他选手随机分布
    
    # 模拟数据 (简化版)
    # 真实场景下，你应该用 S27 的真实数据循环跑
    judge_scores = np.array([10, 20, 15, 18, 12, 14, 16, 19, 11, 13]) # 原始分
    fan_percentiles = np.array([1.0, 0.5, 0.2, 0.8, 0.1, 0.3, 0.6, 0.4, 0.9, 0.0]) # 粉丝排名百分位
    
    # 1. 计算粉丝加成系数 (Sigmoid)
    # Tier = K / (1 + exp(-beta * (P - 0.5)))
    tiers = K / (1 + np.exp(-beta * (fan_percentiles - 0.5)))
    
    # 2. 计算最终分
    # S_final = S_judge * (1 + Tier)
    final_scores = judge_scores * (1 + tiers)
    
    # 3. 计算排名 (分数越高排名越靠前，即 rank 数值越小)
    # argsort 两次得到排名 (0-9)
    final_ranks = np.argsort(np.argsort(-final_scores)) 
    judge_ranks = np.argsort(np.argsort(-judge_scores))
    
    # 4. 计算 Spearman 相关系数 (作为公平性指标)
    # 简单的 Pearson 相关近似 Spearman (为了代码简洁)
    correlation = np.corrcoef(final_ranks, judge_ranks)[0, 1]
    
    return correlation

# ==========================================
# 2. 生成网格数据 (X, Y)
# ==========================================
K_values = np.linspace(0.1, 1.0, 40)    # X轴: K 从 0.1 到 1.0
Beta_values = np.linspace(1, 20, 40)    # Y轴: Beta 从 1 到 20
X, Y = np.meshgrid(K_values, Beta_values)

# ==========================================
# 3. 计算 Z 值 (遍历每一个点)
# ==========================================
Z = np.zeros_like(X)

for i in range(X.shape[0]):
    for j in range(X.shape[1]):
        Z[i, j] = calculate_fairness(X[i, j], Y[i, j])

# ==========================================
# 4. 绘制 3D 曲面图
# ==========================================
fig = plt.figure(figsize=(12, 8))
ax = fig.add_subplot(111, projection='3d')

# 绘制曲面 (cmap='viridis' 或 'coolwarm' 是美赛常用的配色)
surf = ax.plot_surface(X, Y, Z, cmap='Spectral_r', edgecolor='none', alpha=0.9, antialiased=True)

# 添加等高线投影 (让图看起来更高级，像您上传的图1)
ax.contourf(X, Y, Z, zdir='z', offset=np.min(Z)-0.1, cmap='Spectral_r', alpha=0.5)

# 标注我们选择的参数点 (0.5, 10)
ax.scatter([0.5], [10], [calculate_fairness(0.5, 10)], color='red', s=100, marker='*', label='Selected Parameters (0.5, 10)', zorder=10)

# 设置坐标轴标签
ax.set_xlabel('Max Bonus K (Fan Weight)', fontsize=12, labelpad=10)
ax.set_ylabel('Intensity Beta (Steepness)', fontsize=12, labelpad=10)
ax.set_zlabel('Fairness Score (Spearman Corr.)', fontsize=12, labelpad=10)

# 设置视角 (调整到最好看的位置)
ax.view_init(elev=30, azim=225)

# 添加标题和色条
plt.title('Sensitivity Analysis: Impact of K and Beta on Fairness', fontsize=14, fontweight='bold')
fig.colorbar(surf, ax=ax, shrink=0.5, aspect=10, label='Fairness Stability')
ax.legend()

# 保存
plt.tight_layout()
plt.savefig('Sensitivity_Analysis_3D.png', dpi=300)
plt.show()