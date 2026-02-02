% 读取Markdown文件
filename = '赛季粉丝投票数结果.md';
fid = fopen(filename, 'r', 'n', 'UTF-8');
content = fread(fid, '*char')';
fclose(fid);

% 初始化Excel写入对象
excelFilename = 'tem.xlsx';
if exist(excelFilename, 'file')
    delete(excelFilename); % 删除已存在的文件
end

% 按行分割内容
lines = strsplit(content, {'\n', '\r'});
lines = lines(~cellfun('isempty', lines)); % 移除空行

% 初始化变量
currentTable = {};
currentSheet = '';
inTable = false;
tableStartIdx = 0;
seasonCount = 0;

% 遍历每一行
for i = 1:length(lines)
    line = strtrim(lines{i});
    
    % 检测新赛季标题（以#开头）
    if startsWith(line, '#')
        % 如果正在处理表格，先保存上一个表格
        if inTable
            writeTableToExcel(currentTable, currentSheet, excelFilename);
            inTable = false;
            currentTable = {};
        end
        
        % 提取赛季名称作为sheet名
        seasonCount = seasonCount + 1;
        currentSheet = strrep(line, '# ', '');
        currentSheet = strrep(currentSheet, '#', '');
        continue;
    end
    
    % 检测表格开始（包含 |--- 或 | --- 的行）
    if contains(line, '|---') || contains(line, '| ---')
        inTable = true;
        tableStartIdx = i;
        % 表头行在表格开始行的上一行
        if i > 1
            headerLine = lines{i-1};
            headers = parseTableLine(headerLine);
            currentTable = [headers]; % 初始化表格
        end
        continue;
    end
    
    % 如果是表格数据行（包含 | 但不包含 ---）
    if inTable && contains(line, '|') && ~contains(line, '---')
        rowData = parseTableLine(line);
        if ~isempty(rowData)
            currentTable = [currentTable; rowData];
        end
    end
end

% 保存最后一个表格
if inTable
    writeTableToExcel(currentTable, currentSheet, excelFilename);
end

disp(['数据已保存至：' excelFilename]);

%% 辅助函数：解析表格行
function cells = parseTableLine(line)
    % 去除行首尾的 |
    line = strtrim(line);
    if startsWith(line, '|')
        line = line(2:end);
    end
    if endsWith(line, '|')
        line = line(1:end-1);
    end
    
    % 按 | 分割
    parts = strsplit(line, '|');
    
    % 清理每个单元格
    cells = cell(1, length(parts));
    for j = 1:length(parts)
        cellContent = strtrim(parts{j});
        % 去除可能存在的粗体标记 **
        cellContent = strrep(cellContent, '**', '');
        % 如果内容为空或为0，则设为空字符串
        if strcmp(cellContent, '0')
            cells{j} = '';
        else
            cells{j} = cellContent;
        end
    end
end

%% 辅助函数：将表格写入Excel
function writeTableToExcel(tableData, sheetName, filename)
    if isempty(tableData)
        return;
    end
    
    % 将cell数组转换为表格
    % 第一行为表头
    headers = tableData(1, :);
    data = tableData(2:end, :);
    
    % 创建表格对象
    T = cell2table(data, 'VariableNames', headers);
    
    % 写入Excel
    writetable(T, filename, 'Sheet', sheetName, 'WriteRowNames', false);
end