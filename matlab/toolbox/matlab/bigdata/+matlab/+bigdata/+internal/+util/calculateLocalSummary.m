function summaryInfo = calculateLocalSummary( localTable )
% Calculate summary information for a local piece of a partitioned table.
% Output is a cell array containing one info struct per table variable.

%   Copyright 2016-2024 The MathWorks, Inc.

vars = localTable.Properties.VariableNames;

rowLabelDescr = cell(1, numel(vars));

if istimetable(localTable)
    % Prepend RowTimes
    vars = [localTable.Properties.DimensionNames{1}, vars];
    rowLabelDescr = ['RowTimes', rowLabelDescr];
end

% Add information about table size and class for printSummary
tableInfo = struct('Size', size(localTable), 'Class', class(localTable), 'VarClass', {cell(1, numel(vars))});

summaryInfo = cell(1, numel(vars));
for idx = 1:numel(vars)
    x = localTable.(vars{idx});
    if iscellstr(x) %#ok<ISCLSTR>
        clz = 'cellstr';
    elseif iscategorical(x) && isordinal(x)
        clz = 'ordinal categorical';
    else
        clz = class(x);
    end
    info = struct('Name', vars{idx}, ...
        'Size', size(x), ...
        'Type', class(x), ...
        'RowLabelDescr', rowLabelDescr{idx});
    if islogical(x)
        info = iAddLogicalInfo(info, x);
    elseif iscategorical(x)
        info = iAddCategoricalInfo(info, x);
    elseif isdatetime(x)
        info = iAddDatetimeInfo(info, x);
    elseif isstring(x) || iscell(x) || iscalendarduration(x) || ischar(x)
        info = iAddNumMissingInfo(info, x);
    elseif istabular(x)
        info = iAddTabularInfo(info, x);
    else
        % Numeric/duration
        info = iAddDatatypeInfo(info, x);
    end
    % Add extra infor for RowTimes: SampleRate, StartTime, TimeStep
    if (idx == 1) && istimetable(localTable)
        info.SampleRate = localTable.Properties.SampleRate;
        info.StartTime = localTable.Properties.StartTime;
        info.TimeStep = localTable.Properties.TimeStep;
    end
    summaryInfo{idx} = info;
    tableInfo.VarClass{idx} = clz; % for printTabularSummary
end

% Attach tableInfo as the first element in summaryInfo and wrap into cell
% tableInfo to easily merge different chunks.
summaryInfo = [{tableInfo}, summaryInfo];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = iAddNumMissingInfo(info, x)
% Data is always treated column-wise.
numMissing = sum(ismissing(x), 1);

info.NumMissing = numMissing;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add info for numeric/duration/char types.
function info = iAddDatatypeInfo(info, x)

info = iAddNumMissingInfo(info, x);

% Data is always treated column-wise.
numMissing = sum(ismissing(x), 1);

info.NumMissing = numMissing;
if ~(isinteger(x) && ~isreal(x))
    % Here we rely on the fact that omitnan/omitnat is the default.
    info.MinVal = min(x, [], 1);
    info.MaxVal = max(x, [], 1);
end

if istabular(x) || (isinteger(x) && ~isreal(x))
    % No more statistics are needed.
    return
end

info = iAddMeanInfo(info, x);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = iAddLogicalInfo(info, x)
info.true = sum(x, 1);
info.false = size(x, 1) - info.true;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = iAddCategoricalInfo(info, x)
numundef = sum(ismissing(x), 1);
cats     = categories(x);
counts   = countcats(x, 1);
if any(numundef > 0)
    cats{end+1,1} = 'NumMissing';
    counts(end+1,:) = numundef;
end
info.CategoricalInfo = { cats, counts };
if isordinal(x)
    info.MinVal = min(x, [], 1);
    info.MaxVal = max(x, [], 1);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = iAddDatetimeInfo(info, x)
if isdatetime(x)
    info.TimeZone = x.TimeZone;
end

info = iAddDatatypeInfo(info, x);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = iAddTabularInfo(info, x)
info = iAddDatatypeInfo(info, x); % NumMissing, Min, Max only
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = iAddMeanInfo(info, x)
% To compute mean, keep track of counts and mean per block.
locMean = mean(x, 1, "omitmissing");
locCount = sum(~ismissing(x), 1);
info.MeanInfo = { locMean, locCount};
end