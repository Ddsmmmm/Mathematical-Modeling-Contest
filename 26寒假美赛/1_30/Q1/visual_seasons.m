% visual_seasons_heatmap_separated.m
% 将综合异常得分从主热力图中分离：
% - 主图只显示三个原始特征：F1 (首周未淘汰), F2 (多人淘汰周计数), F3 (非首周无淘汰周计数)
% - 新图单独显示 anomalyScore（0->1），使用自定义白->浅红->红的 colormap
%
% 使用：保存为 visual_seasons_heatmap_separated.m，切换到该目录并在 MATLAB 中运行：
%   visual_seasons_heatmap_separated
%
% 说明：图中不显示每个单元格的数值，仅用颜色表示强弱；主图会用黑边框标注被判定为异常的赛季。

clearvars; close all; clc;

%% --------------------- 0. 基本设置 ---------------------
nSeasons = 34;
seasonLabels = arrayfun(@(k) sprintf('s%d',k), 1:nSeasons, 'UniformOutput', false);

%% --------------------- 1. 原始异常条目（从 md 手工粘贴） ---------------------
% F1: 首周没有淘汰（binary）
list_I = {'s1','s4','s6','s10','s12','s14','s8','s16','s17','s18','s20','s21','s22','s23','s24','s25','s28','s29','s30','s33','s34'};

% F2: 某周淘汰多人（>=2人）
list_III = { ...
's6w2','s7w1','s8w4','s9w6','s9w1','s14w8','s15w3','s15w8','s15w9', ...
's18w2','s20w8','s21w2','s22w7','s22w9','s23w4','s24w7','s25w2','s25w7', ...
's26w1','s26w2','s26w3','s27w7','s27w8','s29w10','s30w4','s30w8','s30w9', ...
's31w8','s31w9','s33w2','s33w3','s34w2' };

% F3: 非首周没有淘汰
list_IV = { ...
's3w6','s7w3','s15w5','s15w7','s17w6','s18w3','s18w4','s19w5', ...
's21w3','s21w5','s21w10','s22w5','s23w5','s25w3','s27w5','s28w3','s28w5','s34w5' };

%% --------------------- 2. 计算特征向量 F1,F2,F3 ---------------------
F1 = zeros(nSeasons,1); % binary
F2 = zeros(nSeasons,1); % counts
F3 = zeros(nSeasons,1); % counts

% 填充 F1
for i = 1:numel(list_I)
    sNum = sscanf(list_I{i}, 's%d');
    if ~isempty(sNum) && sNum>=1 && sNum<=nSeasons
        F1(sNum) = 1;
    end
end

% 解析 F2
for i = 1:numel(list_III)
    tokens = regexp(list_III{i}, 's(\d+)w(\d+)', 'tokens');
    if ~isempty(tokens)
        sNum = str2double(tokens{1}{1});
        if sNum>=1 && sNum<=nSeasons
            F2(sNum) = F2(sNum) + 1;
        end
    end
end

% 解析 F3
for i = 1:numel(list_IV)
    tokens = regexp(list_IV{i}, 's(\d+)w(\d+)', 'tokens');
    if ~isempty(tokens)
        sNum = str2double(tokens{1}{1});
        if sNum>=1 && sNum<=nSeasons
            F3(sNum) = F3(sNum) + 1;
        end
    end
end

%% --------------------- 3. 计算综合异常得分（独立变量） ---------------------
% 这里用简单等权重加和并归一化，结果放在 anomalyScore 中（0-1）
weights = [1, 1, 1]; % 可按需调整
rawScore = weights(1)*F1 + weights(2)*F2 + weights(3)*F3;
if max(rawScore) == min(rawScore)
    anomalyScore = zeros(size(rawScore));
else
    anomalyScore = (rawScore - min(rawScore)) ./ (max(rawScore) - min(rawScore));
end

% 阈值判定（仅用于标注）
threshold = mean(anomalyScore) + std(anomalyScore);
anomalyFlag = anomalyScore > threshold;

%% --------------------- 4. 为主热力图准备数据（仅 F1,F2,F3） ---------------------
% 原始矩阵：每行 = 赛季，列 = 特征
X3_raw = [F1, F2, F3]; % size = 34 x 3

% 对每一列（特征）做列归一化到 [0,1] 以在同一色标下比较
X3_norm = nan(size(X3_raw));
for j = 1:size(X3_raw,2)
    col = X3_raw(:,j);
    if max(col) == min(col)
        X3_norm(:,j) = zeros(size(col));
    else
        X3_norm(:,j) = (col - min(col)) ./ (max(col) - min(col));
    end
end

% 转置为 imagesc 所需维度： rows = 特征(3)， cols = 赛季(34)
HM_main = X3_norm'; % 3 x 34

%% --------------------- 5. 绘制主热力图（仅三特征） ---------------------
figure('Name','Main Heatmap: F1-F3','NumberTitle','off','Position',[150 200 1100 300]);
imagesc(HM_main);
% 默认映射为按值从低到高变色，colormap 可按需更改
colormap(parula); 
cb1 = colorbar('eastoutside');
cb1.Label.String = 'Normalized feature value';

% 标签与刻度
yticks(1:3);
yticklabels({'Season with no eliminating in the first week','Season of Multiplayer Elimination Week','Season with a week of non-elimination'});
xticks(1:nSeasons);
xticklabels(seasonLabels);
xtickangle(45);
title('Main heatmap, per-feature normalized');
set(gca,'FontSize',10);


%% --------------------- 6. 绘制单独的 anomalyScore 热力图（白->红 colormap） ---------------------
% anomalyScore 已在 [0,1]，构建 1 x 34 的矩阵用于 imagesc
HM_anom = anomalyScore'; % size 1 x 34

figure('Name','Anomaly Score Heatmap','NumberTitle','off','Position',[150 520 1100 180]);
imagesc(HM_anom);
% 构建白->红的 colormap：从白 [1 1 1] 到浅红 到纯红 [1 0 0]
nColors = 256;
r = ones(nColors,1);
g = linspace(1,0,nColors)'; % 1 -> 0
b = linspace(1,0,nColors)'; % 1 -> 0
cmap_white2red = [r g b];
colormap(cmap_white2red);
cb2 = colorbar('eastoutside');
cb2.Label.String = 'Anomaly score';

% 标签与刻度
yticks(1); yticklabels({'Anomaly Score'});
xticks(1:nSeasons);
xticklabels(seasonLabels);
xtickangle(45);
title(sprintf('Anomaly season', threshold));
set(gca,'FontSize',10);


%% --------------------- 7. 控制台输出异常赛季详情 ---------------------
fprintf('异常阈值\n', threshold);
anoms = find(anomalyFlag);
if isempty(anoms)
    fprintf('无赛季被标注为异常（当前阈值）。\n');
else
    fprintf('被标注为异常的赛季：\n');
    for k = 1:numel(anoms)
        s = anoms(k);
        fprintf('  %s: score=%.3f, rawSum=%.2f, F1=%d, F2=%d, F3=%d\n', ...
            seasonLabels{s}, anomalyScore(s), rawScore(s), F1(s), F2(s), F3(s));
    end
end

%% --------------------- 结束 ---------------------
% 可选：保存图片
% saveas(figure(1),'main_heatmap_F1F3.png');
% saveas(figure(2),'anomaly_heatmap_white_to_red.png');
