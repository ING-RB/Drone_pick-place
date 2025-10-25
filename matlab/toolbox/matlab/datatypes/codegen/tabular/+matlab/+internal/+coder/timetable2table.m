function t = timetable2table(tt,varargin)  %#codegen
%TIMETABLE2TABLE Convert timetable to table.

%   Copyright 2019-2021 The MathWorks, Inc.

coder.extrinsic('getString', 'message', 'matlab.internal.i18n.locale');

coder.internal.assert(istimetable(tt), 'MATLAB:timetable2table:NonTimetable');

ttprops = tt.Properties;
varNames1 = ttprops.VariableNames;

if nargin == 1
    convertRowTimes = true;
else
    pnames = {'ConvertRowTimes'};
    poptions = struct( ...
        'CaseSensitivity',false, ...
        'PartialMatching','unique', ...
        'StructExpand',false);
    pstruct = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});
    convertRowTimes = coder.internal.getParameterValue(pstruct.ConvertRowTimes,true,varargin{:});
end
coder.internal.assert(coder.internal.isConst(convertRowTimes), ...
    'MATLAB:timetable2table:NonconstantConvertRowTimes');

% Use the default table row dim name and take the var dim name from the timetable.
rowsDimName = coder.const(getString(message('MATLAB:table:uistrings:DfltRowDimName'),...
            matlab.internal.i18n.locale('en_US'))); % table.defaultDimNames{1}
dimNames = {rowsDimName,ttprops.DimensionNames{2}};

vars1 = getVars(tt, false);
vardesc1 = ttprops.VariableDescriptions;
varunits1 = ttprops.VariableUnits;
varcont1 = ttprops.VariableContinuity;
if coder.const(convertRowTimes)
    % Create a variable from the row times, named according to the input's row
    % dim name, at the front of the table.
    nvars = numel(vars1)+1;
    vars = cell(1,nvars);
    varNames = cell(1,nvars);
    vardesc = cell(1,nvars);
    varunits = cell(1,nvars);
    varcont = repmat(matlab.internal.coder.tabular.Continuity.unset,1,nvars);
    vars{1} = ttprops.RowTimes;
    varNames{1} = tt.Properties.DimensionNames{1};
    vardesc{1} = '';
    varunits{1} = '';
    for i = 2:nvars
        vars{i} = vars1{i-1};
        varNames{i} = varNames1{i-1};
        vardesc{i} = vardesc1{i-1};
        varunits{i} = varunits1{i-1};
        varcont(i) = varcont1(i-1);
    end
else
    nvars = numel(vars1);
    vars = vars1;
    varNames = varNames1;
    vardesc = vardesc1;
    varunits = varunits1;
    varcont = varcont1;
end

% Create a table from the timetable's variables. No need to check if they are
% all the same height, they are all vars in one timetable.
t = table.init(vars,height(tt),{},nvars,varNames,dimNames);

% Copy over the per-array and per-var metadata, but not the row or dim names.
tprops = t.Properties;
tprops.VariableDescriptions = vardesc;
tprops.VariableUnits = varunits;
tprops.VariableContinuity = varcont;
tprops.Description = ttprops.Description;
% Cannot copy UserData, because of a limitation UserData cannot be assigned
% after table/timetable construction
%tprops.UserData = ttprops.UserData;
t.Properties = tprops;