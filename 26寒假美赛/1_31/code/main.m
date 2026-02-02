% % extract_votes.m
% % 读取 Markdown 文件中的表格，按赛季写入 Data.xlsx（每个赛季一个 sheet）
% %
% % 使用:
% %   将本文件和 "赛季粉丝投票数结果.md" 放在同一目录，运行本脚本
% %
% function extract_votes()
%     mdfile = '赛季粉丝投票数结果.md';
%     outFile = 'Data.xlsx';
%     try
%         content = fileread(mdfile);
%     catch ME
%         error('无法读取文件 "%s": %s', mdfile, ME.message);
%     end
% 
%     % 分割为行
%     lines = regexp(content, '\r\n|\r|\n', 'split');
%     n = numel(lines);
% 
%     seasonTitle = '';
%     i = 1;
%     sheetsWritten = {};
%     while i <= n
%         line = strtrim(lines{i});
% 
%         % 检测标题行（以 # 开头）
%         if startsWith(line, '#')
%             seasonTitle = strtrim(regexprep(line, '^#+\s*', '')); % 去掉 #
%             i = i + 1;
%             continue;
%         end
% 
%         % 检测表格头：当前行为以 | 开头的行，且下一行包含 ---（分隔符）
%         if startsWith(line, '|') && i+1 <= n && contains(lines{i+1}, '-')
%             headerLine = lines{i};
%             sepLine = lines{i+1}; %#ok<NASGU>
%             % 解析 header
%             headerParts = split_table_row(headerLine);
% 
%             % 读取后续数据行
%             rows = {};
%             j = i + 2;
%             while j <= n
%                 rline = strtrim(lines{j});
%                 if isempty(rline)
%                     break;
%                 end
%                 if startsWith(rline, '|')
%                     % 如果是分隔线（全是 - 或 : -），跳过
%                     if all(ismember(regexprep(rline,'\|',''), ' -:'))
%                         j = j + 1;
%                         continue;
%                     end
%                     rowParts = split_table_row(rline);
%                     rows(end+1, :) = rowParts; %#ok<AGROW>
%                     j = j + 1;
%                 else
%                     break;
%                 end
%             end
% 
%             % 将读取到的数据转为可写入 Excel 的 cell 数组
%             if ~isempty(seasonTitle)
%                 sheetName = sanitize_sheet_name(seasonTitle);
%             else
%                 sheetName = sprintf('Sheet_%d', i);
%             end
% 
%             % 确定列数，使用 header 的列数
%             ncol = numel(headerParts);
%             nrow = size(rows,1);
% 
%             outCell = cell(nrow+1, ncol);
%             % 写 header（保留原始 header 字符串）
%             for c = 1:ncol
%                 outCell{1,c} = strtrim(headerParts{c});
%             end
%             % 写每一行：列1为选手名（去掉 ** 等），其余列尽量转换为数字（去掉逗号）
%             for r = 1:nrow
%                 % 有时解析得到的 row 列数少于 header，补空
%                 rowParts = rows(r, :);
%                 % Ensure rowParts length equals ncol
%                 if numel(rowParts) < ncol
%                     rowParts(end+1:ncol) = {''};
%                 end
%                 % 第一列：名字，去掉加粗标记和多余空格
%                 name = rowParts{1};
%                 name = regexprep(name, '\*\*', ''); % 去掉**
%                 name = regexprep(name, '^[`"\'']+|[`"\'']+$', ''); % 去掉首尾可能的引号或反引号
%                 name = strtrim(name);
%                 outCell{r+1,1} = name;
% 
%                 % 其余列：数字处理
%                 for c = 2:ncol
%                     s = rowParts{c};
%                     s = strtrim(s);
%                     % 如果是空或仅为 '-'，保持空白
%                     if isempty(s) || strcmp(s, '-')
%                         outCell{r+1,c} = '';
%                         continue;
%                     end
%                     % 去掉千分位逗号，并尝试转换为数字
%                     sClean = regexprep(s, ',', '');
%                     % 有时末尾可能有非数字字符，进一步保守抽取数字部分
%                     sNum = regexp(sClean, '[-+]?\d+(\.\d+)?', 'match', 'once');
%                     if isempty(sNum)
%                         outCell{r+1,c} = s; % 原样写回
%                     else
%                         numVal = str2double(sNum);
%                         outCell{r+1,c} = numVal;
%                     end
%                 end
%             end
% 
%             % 写入 Excel（会覆盖指定 sheet）
%             try
%                 writecell(outCell, outFile, 'Sheet', sheetName);
%                 sheetsWritten{end+1} = sheetName; %#ok<AGROW>
%             catch ME
%                 warning('写入 Excel 时出错（sheet=%s）：%s', sheetName, ME.message);
%             end
% 
%             % 跳到表格后继续
%             i = j;
%             continue;
%         end
% 
%         i = i + 1;
%     end
% 
%     if isempty(sheetsWritten)
%         fprintf('未找到任何表格，未生成 %s\n', outFile);
%     else
%         fprintf('已将 %d 个表格写入 "%s"（Sheets: %s）\n', numel(sheetsWritten), outFile, strjoin(sheetsWritten, ', '));
%     end
% end
% 
% %% 辅助函数：解析一行 Markdown 表格（返回中间的单元格，不含首尾空单元）
% function parts = split_table_row(line)
%     % 保留原始内容的中间单元格，去掉首尾可能的竖线后再分割
%     % 例如: "| a | b | c |" -> {'a','b','c'}
%     % 也能处理没有首尾竖线但以竖线分隔的情况
%     % 首先确保是字符型
%     if ~ischar(line) && ~isstring(line)
%         line = char(line);
%     end
%     % 去掉行首行尾的竖线（如果有）
%     if startsWith(strtrim(line), '|')
%         line = regexprep(line, '^\s*\|', '');
%     end
%     if endsWith(strtrim(line), '|')
%         line = regexprep(line, '\|\s*$', '');
%     end
%     rawParts = regexp(line, '\|', 'split');
%     % 如果没有竖线分割（单列），则尝试按空格分割为单元素
%     if isempty(rawParts)
%         parts = {strtrim(line)};
%         return;
%     end
%     % trim each part
%     parts = cellfun(@(s) strtrim(s), rawParts, 'UniformOutput', false);
% end
% 
% %% 辅助函数：清理并限制 sheet 名称（Excel 限制）
% function name = sanitize_sheet_name(title)
%     % Excel sheet 名称不能包含: \ / * ? : [ ]
%     % 且长度 <= 31
%     if ~ischar(title)
%         title = char(title);
%     end
%     name = regexprep(title, '[:\\/*?\[\]]', '_');
%     name = strtrim(name);
%     % 替换空字符串为默认名
%     if isempty(name)
%         name = 'Sheet';
%     end
%     % 截断到 31 个字符（保留末尾有意义部分）
%     maxLen = 31;
%     if numel(name) > maxLen
%         name = name(1:maxLen);
%     end
% end



function parse_md_to_excel()
% PARSE_MD_TO_EXCEL  Parse Markdown tables from all .md files in current folder
% and write them into rankofperson.xlsx (one sheet per table).
%
% Usage:
%   parse_md_to_excel()
%
% Notes:
% - Sheets are named using the nearest preceding markdown heading (# ...).
% - Numeric columns will be converted to numeric type when possible.
% - Existing rankofperson.xlsx will be overwritten.

outFile = 'rankofperson.xlsx';
mdFiles = dir('*.md');
if isempty(mdFiles)
    error('No .md files found in current directory.');
end

% Remove existing output file to avoid appending to old sheets
if exist(outFile,'file')
    delete(outFile);
end

usedSheets = {};

for f = 1:numel(mdFiles)
    fname = mdFiles(f).name;
    txt = fileread(fname);
    lines = regexp(txt, '\r\n|\r|\n', 'split');
    n = numel(lines);
    i = 1;
    lastHeading = ''; % track last seen heading for naming tables without heading line
    while i <= n
        L = strtrim(lines{i});
        % capture headings like "# 第2赛季" (one or more leading #)
        if ~isempty(L) && L(1) == '#'
            % strip leading #'s and whitespace
            lastHeading = regexprep(L, '^#+\s*', '');
            i = i + 1;
            continue;
        end

        % find a table start: a line starting with '|' (allow leading spaces)
        if startsWith(L, '|')
            % collect contiguous table lines
            tlines = {};
            while i <= n && ~isempty(strtrim(lines{i})) && startsWith(strtrim(lines{i}), '|')
                tlines{end+1} = lines{i}; %#ok<AGROW>
                i = i + 1;
            end

            % parse table if found at least header + one row (or header + separator)
            if numel(tlines) >= 1
                try
                    T = parse_md_table(tlines);
                catch ME
                    warning('Failed to parse table in %s near line %d: %s', fname, i, ME.message);
                    continue;
                end

                % decide sheet name
                if isempty(lastHeading)
                    baseName = sprintf('Sheet_%s', fname);
                else
                    baseName = lastHeading;
                end
                sheetName = sanitize_sheet_name(baseName);
                % ensure unique sheet name
                uniq = sheetName;
                idx = 1;
                while any(strcmp(usedSheets, uniq))
                    uniq = sprintf('%s_%d', sheetName, idx);
                    idx = idx + 1;
                end
                sheetName = uniq;
                usedSheets{end+1} = sheetName; %#ok<AGROW>

                % write table to excel
                try
                    writetable(T, outFile, 'Sheet', sheetName);
                    fprintf('Wrote table to %s (sheet: %s)\n', outFile, sheetName);
                catch ME
                    warning('Failed to write sheet %s: %s', sheetName, ME.message);
                end
            end
        else
            i = i + 1;
        end
    end
end

fprintf('Done. Output file: %s\n', outFile);
end

%% Helper: parse a block of markdown table lines into a MATLAB table
function T = parse_md_table(tlines)
% tlines: cell array of lines (strings) that form the markdown table
% Expecting first line = header, second line maybe separator (---), subsequent lines data

% Trim trailing/leading spaces but keep pipes for splitting
for k = 1:numel(tlines)
    tlines{k} = strtrim(tlines{k});
end

% header is first line
headerLine = tlines{1};
headers = split_pipe_line(headerLine);

% determine start of data rows
startIdx = 2;
if numel(tlines) >= 2
    sep = tlines{2};
    % treat as separator line if it contains three or more '-' between pipes
    if ~isempty(regexp(sep, '(^\s*\|)|(^-)|(:?-+:?)', 'once')) && contains(sep, '-')
        startIdx = 3;
    end
end

% collect data rows
dataLines = {};
for k = startIdx:numel(tlines)
    dataLines{end+1} = tlines{k}; %#ok<AGROW>
end

nCols = numel(headers);
nRows = numel(dataLines);
data = cell(nRows, nCols);
for r = 1:nRows
    cols = split_pipe_line(dataLines{r});
    % pad or trim to match header columns
    if numel(cols) < nCols
        cols(end+1:nCols) = {''};
    elseif numel(cols) > nCols
        cols = cols(1:nCols);
    end
    for c = 1:nCols
        data{r,c} = cols{c};
    end
end

% attempt to convert columns to numeric when possible
vars = cell(1, nCols);
colsOut = cell(1, nCols);
for c = 1:nCols
    colCells = data(:,c);
    nums = nan(nRows,1);
    isNumericCandidate = true;
    for r = 1:nRows
        s = strtrim(colCells{r});
        % treat empty strings as missing -> NaN
        if isempty(s)
            nums(r) = NaN;
            continue;
        end
        % remove commas and spaces
        s2 = regexprep(s, '[,\s]', '');
        % remove possible non-digit characters except dot and minus
        % but keep digits; if not match numeric pattern, mark not numeric
        if ~isempty(regexp(s2, '^[-+]?\d+(\.\d+)?$', 'once'))
            nums(r) = str2double(s2);
        else
            isNumericCandidate = false;
            break;
        end
    end
    varName = matlab.lang.makeValidName(headers{c});
    if isempty(varName)
        varName = sprintf('Var%d', c);
    end
    vars{c} = varName;
    if isNumericCandidate
        colsOut{c} = nums;
    else
        colsOut{c} = colCells;
    end
end

% build table
T = table();
for c = 1:nCols
    T.(vars{c}) = colsOut{c};
end
end

%% Utility: split a markdown table line by pipes and trim entries
function cells = split_pipe_line(line)
% Remove leading/trailing pipe if present, then split by '|' and trim
line2 = regexprep(line, '^\s*\|\s*', '');   % remove leading |
line2 = regexprep(line2, '\s*\|\s*$', '');  % remove trailing |
parts = regexp(line2, '\|', 'split');
% trim each part
cells = cellfun(@(s)strtrim(s), parts, 'UniformOutput', false);
end

%% Utility: sanitize sheet name for Excel (max 31 chars, remove invalid chars)
function nameOut = sanitize_sheet_name(nameIn)
if isempty(nameIn)
    nameIn = 'Sheet';
end
% remove illegal characters \ / ? * [ ]
nameOut = regexprep(nameIn, '[\\\/\?\*\[\]\:]', '_');
% trim whitespace
nameOut = strtrim(nameOut);
% limit length to 31
maxlen = 31;
if numel(nameOut) > maxlen
    nameOut = nameOut(1:maxlen);
end
% ensure non-empty
if isempty(nameOut)
    nameOut = 'Sheet';
end
end