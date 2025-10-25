function t = readXLSFile(xlsfile,args)
%READXLSFILE Read in an XLS file and create a table.

%   Copyright 2012-2019 The MathWorks, Inc.

import matlab.internal.datatypes.validateLogical

defaultNVPairs = {
    'ReadVariableNames'    , true; ...
    'ReadRowNames'         , false; ...
    'TreatAsEmpty'         , {}; ...
    'Sheet'                , ''; ...
    'Range'                , ''; ...
    'UseExcel'             , false; ...
    'Basic'                , true; ...
    'TextType'             , 'char'; ...
    'DatetimeType'         , 'datetime'; ...
    'PreserveVariableNames', false;...
    'Format'               , 'auto'};

[readVarNames, readRowNames, treatAsEmpty, ...
    sheet, range, UseExcel, Basic, ...
    textType, datetimeType, preserveVariableNames, fmt, supplied] ...
        = matlab.internal.datatypes.parseArgs(defaultNVPairs(:,1), ...
                                              defaultNVPairs(:,2), args{:});

if supplied.Format && ~strcmpi(fmt,'auto')
    error(message('MATLAB:textio:io:ssFormatAuto'))
end

readRowNames = validateLogical(readRowNames,'ReadRowNames');
readVarNames = validateLogical(readVarNames,'ReadVariableNames');
preserveVariableNames = validateLogical(preserveVariableNames,'PreserveVariableNames');

rowNames = {};
dimNames = {};

% Flag to determine if 'UseExcel' or 'Basic' N-V pair has been provided by user
suppliedUseExcel = false;
if supplied.UseExcel
    UseExcel = validateLogical(UseExcel, 'UseExcel');
    suppliedUseExcel = true;
elseif supplied.Basic
    UseExcel = ~validateLogical(Basic, 'Basic'); % Basic mode means don't use Excel.
    suppliedUseExcel = true;
end


if isempty(treatAsEmpty)
    treatAsEmpty = cell(0,1);
elseif ischar(treatAsEmpty) && ~isrow(treatAsEmpty)
    % textscan does something a little obscure when treatAsEmpty is char but
    % not a row vector, disallow that here.
    error(message('MATLAB:readtable:InvalidTreatAsEmpty'));
elseif ischar(treatAsEmpty) || iscellstr(treatAsEmpty) %#ok<ISCLSTR>
    if ischar(treatAsEmpty), treatAsEmpty = cellstr(treatAsEmpty); end
    % Trim insignificant whitespace to be consistent with what's done for text files.
    treatAsEmpty = strtrim(treatAsEmpty);
    if any(~isnan(str2double(treatAsEmpty))) || any(strcmpi('nan',treatAsEmpty))
        error(message('MATLAB:readtable:NumericTreatAsEmpty'));
    end
else
    error(message('MATLAB:readtable:InvalidTreatAsEmpty'));
end

if (~ischar(sheet) || (~strcmp(sheet, '') && ~isrow(sheet))) && ...
   (~isnumeric(sheet) || ~isscalar(sheet) || (floor(sheet) ~= sheet) || (sheet < 1))
    error(message('MATLAB:readtable:InvalidSheet'));
end

if ~strcmp(range, '') && (~ischar(range) || ~isrow(range))
    error(message('MATLAB:readtable:InvalidRange'));
end

rdOpts.file = xlsfile;
rdOpts.format = matlab.io.spreadsheet.internal.getExtension(xlsfile);
rdOpts.sheet = sheet;
rdOpts.range = range;
rdOpts.readVarNames = readVarNames;
rdOpts.UseExcel = UseExcel;
rdOpts.treatAsEmpty = treatAsEmpty;
rdOpts.logicalType = 'logical';
rdOpts.textType = validatestring(textType, {'char', 'string'});
rdOpts.datetimeType = validatestring(datetimeType, {'text' 'datetime' 'exceldatenum'});

% check to see that the file exists
possExt = {'.xls', '.xlsb', '.xlsm', '.xlsx', '.xltm', '.xltx','.ods'};
try
    matlab.io.internal.validators.validateFileName(xlsfile,possExt);
catch
    error(message('MATLAB:spreadsheet:book:fileOpen',xlsfile));
end

import matlab.io.spreadsheet.internal.readSpreadsheetFile;
out = readSpreadsheetFile(rdOpts, suppliedUseExcel);

data = out.variables;

if isempty(data)
    t = table;
    return;
end

if readVarNames
    varNames = out.varNames;
    if ~iscellstr(varNames) || ~isstring(varNames)
        varNames = stringizeLocal(varNames, UseExcel);
    end
else
    % If reading row names, number remaining columns beginning from 1, we'll drop Var0 below.
    varNames = matlab.internal.tabular.private.varNamesDim.dfltLabels((1:numel(data))-readRowNames);
end

if readRowNames
    rowNames = data{1};
    if isstring(rowNames)
        rowNames = convertStringsToChars(rowNames);
    end
    data(1) = [];
    if ~iscellstr(rowNames) || ~isstring(rowNames)
        rowNames = stringizeLocal(rowNames, UseExcel);
    end
    dimNames = table.empty.Properties.DimensionNames;
    if readVarNames, dimNames{1} = varNames{1}; end
    varNames(1) = [];
end

t = table(data{:});

% Change the table variable name validation rules based on the value of 
% PreserveVariableNames.
t = table.setReadtableMetaData(t, data, readRowNames, ...
                               readVarNames, varNames, rowNames, ...
                               dimNames, ~preserveVariableNames);
end

% ----------------------------------------------------------------------- %
function s = stringizeLocal(c, UseExcel)
    s = matlab.io.spreadsheet.internal.stringize(c, UseExcel);
end
