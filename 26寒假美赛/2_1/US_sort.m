clc; close all; clear;
%% 读取数据，保留原始列名
filename = '2026_MCM_Problem_C_Data.xlsx';
opts = detectImportOptions(filename);
opts.VariableNamingRule = 'preserve';  % 保留原始列名
data = readtable(filename, opts);

%% 定义地区分类
us_east = {'Maine', 'New York', 'New Jersey', 'Pennsylvania', 'Connecticut', ...
           'Massachusetts', 'Rhode Island', 'Delaware', 'Maryland', 'Washington D.C.', ...
           'Virginia', 'West Virginia', 'North Carolina', 'South Carolina', ...
           'Georgia', 'Florida'};

us_south = {'Texas', 'Oklahoma', 'Arkansas', 'Louisiana', 'Mississippi', ...
            'Alabama', 'Tennessee', 'Kentucky', 'Florida'};

us_midwest = {'Illinois', 'Indiana', 'Ohio', 'Michigan', 'Wisconsin', ...
              'Minnesota', 'Iowa', 'Missouri', 'Kansas', 'Nebraska', ...
              'South Dakota', 'North Dakota'};

us_west = {'California', 'Washington', 'Oregon', 'Nevada', 'Arizona', ...
           'Utah', 'Colorado', 'Wyoming', 'Montana', 'Idaho', ...
           'New Mexico', 'Alaska', 'Hawaii'};

%% 初始化地区列
region = cell(height(data), 1);

%% 遍历每一行并分类
for i = 1:height(data)
    % 获取州和国家信息（注意列名有斜杠）
    if ismember('celebrity_homestate', data.Properties.VariableNames)
        state_cell = data{i, 'celebrity_homestate'};
        state = toScalarString(state_cell);   % 确保为标量 string
    else
        state = "";
    end
    
    if ismember('celebrity_homecountry/region', data.Properties.VariableNames)
        country_cell = data{i, 'celebrity_homecountry/region'};
        country = toScalarString(country_cell);   % 确保为标量 string
    else
        country = "";
    end
    
    % 处理缺失值（state 和 country 此时是标量 string）
    if ismissing(state) || strlength(state) == 0
        state = "";
    end
    
    if ismissing(country) || strlength(country) == 0
        country = "";
    end
    
    % 分类逻辑
    if ~strcmp(country, 'United States') && ~strcmp(country, "")
        region{i} = 'International';
    elseif strcmp(state, "")
        region{i} = 'US (state unknown)';
    elseif ismember(state, us_east)
        region{i} = 'US East';
    elseif ismember(state, us_south)
        region{i} = 'US South';
    elseif ismember(state, us_midwest)
        region{i} = 'US Midwest';
    elseif ismember(state, us_west)
        region{i} = 'US West';
    else
        region{i} = 'US (unclassified state)';
    end
end

%% 添加地区列到表格
data.region = region;

%% 保存为新文件
writetable(data, '2026_MCM_Problem_C_Data_with_Region.xlsx', 'FileType', 'spreadsheet');

%% 显示分类统计
disp('地区分类统计:');
fprintf('\n');
unique_regions = unique(region);
for i = 1:length(unique_regions)
    count = sum(strcmp(region, unique_regions{i}));
    percentage = count / length(region) * 100;
    fprintf('%s: %d (%.1f%%)\n', unique_regions{i}, count, percentage);
end

%% 显示前几行数据示例
fprintf('\n前10行分类示例:\n');
for i = 1:min(10, height(data))
    if ismember('celebrity_name', data.Properties.VariableNames)
        name_cell = data{i, 'celebrity_name'};
        name_str = toScalarString(name_cell);
        % 如果需要显示普通字符，可用 char(name_str) 或 sprintf('%s', name_str)
    else
        name_str = "";
    end
    fprintf('%d. %s: %s\n', i, char(name_str), region{i});
end

%% 辅助函数：把表中单元格或其它类型转换为标量 string
function s = toScalarString(x)
    % x 可能是 cell、string、char、numeric、missing 等
    if iscell(x)
        if isempty(x) || isempty(x{1})
            s = "";
            return;
        end
        val = x{1};
    else
        val = x;
    end

    if isnumeric(val)
        % 数字转为 string
        s = string(val);
    elseif isstring(val)
        if isempty(val)
            s = "";
        else
            % 如果是多元素 string 数组，取第一个元素
            s = val(1);
        end
    elseif ischar(val)
        if isempty(val)
            s = "";
        else
            s = string(val);
        end
    elseif ismissing(val)
        s = "";
    else
        % 默认尝试转换为 string
        try
            s = string(val);
            if isempty(s)
                s = "";
            else
                s = s(1);
            end
        catch
            s = "";
        end
    end
end