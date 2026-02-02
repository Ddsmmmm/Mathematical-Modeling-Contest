%% 读取Excel数据
filename = '2026_MCM_Problem_C_Data.xlsx';
data = readtable(filename, 'PreserveVariableNames', true);

%% 行业分类
% 获取原始行业数据
original_industry = data.celebrity_industry;

% 初始化分类结果数组
industry_category = cell(height(data), 1);

% 定义四种主要类别
actor_categories = {'Actor/Actress'};
athlete_categories = {'Athlete'};
tv_personality_categories = {'TV Personality'};
singer_categories = {'Singer/Rapper'};

% 遍历所有行进行分类
for i = 1:height(data)
    current_industry = original_industry{i};
    
    % 检查是否属于四种主要类别之一
    if ismember(current_industry, actor_categories)
        industry_category{i} = 'Actor/Actress';
    elseif ismember(current_industry, athlete_categories)
        industry_category{i} = 'Athlete';
    elseif ismember(current_industry, tv_personality_categories)
        industry_category{i} = 'TV Personality';
    elseif ismember(current_industry, singer_categories)
        industry_category{i} = 'Singer/Rapper';
    else
        industry_category{i} = 'Other';
    end
end

%% 创建新表格（保持原顺序）
% 将分类结果添加到表格中
data.industry_category = industry_category;

%% 统计各类别数量
categories = {'Actor/Actress', 'Athlete', 'TV Personality', 'Singer/Rapper', 'Other'};
category_counts = zeros(1, 5);

for i = 1:5
    category_counts(i) = sum(strcmp(industry_category, categories{i}));
end

% 显示统计结果
disp('行业分类统计:');
for i = 1:5
    fprintf('%s: %d 人\n', categories{i}, category_counts(i));
end

%% 保存到新Excel文件
output_filename = 'tem.xlsx';
writetable(data, output_filename);
fprintf('\n数据已保存到: %s\n', output_filename);

%% 可选：创建简化的结果表格（只包含必要列）
% 选择要保存的列
if ismember('celebrity_name', data.Properties.VariableNames)
    % 创建简化表格，包含原行业和新分类
    simplified_data = table(data.celebrity_name, original_industry, industry_category, ...
        'VariableNames', {'celebrity_name', 'original_industry', 'industry_category'});
    
    % 保存简化版本
    simplified_filename = 'tem_simplified.xlsx';
    writetable(simplified_data, simplified_filename);
    fprintf('简化版本已保存到: %s\n', simplified_filename);
end