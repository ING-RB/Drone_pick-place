function h = pieConvenienceHelper(className, varargin)
%

%   Copyright 2023 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent

% Check for tables as input.
% piechart(tbl, ...)
% piechart(parent, tbl, ...)
nargs = numel(varargin);
istable = (nargs > 0 && istabular(varargin{1})) ...
    || (nargs > 1 && istabular(varargin{2}));

% Check for first argument parent.
supportDoubleParentHandle = false;
[parent, args] = peelFirstArgParent(varargin, supportDoubleParentHandle);

if istable
    % piechart(tbl, dataVar)
    % piechart(tbl, dataVar, nameVar)
    [posargs, pvpairs] = splitPositionalFromPV(args, 2, true);
    assert(istabular(posargs{1}), message('MATLAB:graphics:piechart:InvalidTableArguments'));

    dataSource = matlab.graphics.data.DataSource(posargs{1});
    dataMap = matlab.graphics.data.DataMap(dataSource);
    dataMap = dataMap.addChannel('Data', posargs{2});
    hasNamesVar = numel(posargs) == 3;
    if hasNamesVar
        dataMap = dataMap.addChannel('Names', posargs{3});
    end

    nObjects = dataMap.NumObjects;
    assert(nObjects==1, message('MATLAB:graphics:piechart:InvalidTableArguments'));
    matlab.graphics.chart.internal.AbstractPieChart.validateTableData(dataMap);

    % DataMap's slice function is intended for multiple series, but
    % piechart will always have one series (see assert above).
    piedata = dataMap.slice(1);
    dataPairs = {'SourceTable', dataSource.Table, 'DataVariable', piedata.Data};
    if hasNamesVar
        dataPairs = [dataPairs {'NamesVariable',piedata.Names}];
    end
else
    [posargs, pvpairs] = splitPositionalFromPV(args, 1, true);
    matlab.graphics.chart.internal.AbstractPieChart.validateMatrixData(posargs{:});
    dataPairs = {'Data',  posargs{1}};
    if numel(posargs)>1
        dataPairs = [dataPairs {"Names",posargs{2}}];
    end
end

matlab.graphics.internal.validatePartialPropertyNames(...
    className, pvpairs(1:2:end));

parent = getParent(parent, pvpairs);


% pass it all to the constructor
pvpairs = {dataPairs{:}, pvpairs{:}};
posProps = ["OuterPosition","InnerPosition","Position"];
posPropsPresent = any(startsWith(posProps, string(pvpairs(1:2:end)), 'IgnoreCase', 1));

constructor = str2func(className);
if posPropsPresent
    if isempty(parent)
        parent = gcf;
    end
    % Position specified, construct without replacing anything
    try
        h = constructor('Parent', parent, pvpairs{:});
    catch me
        throw(me)
    end
else
    % Replace existing plot (depending on hold)
    constructor=@(varargin)constructor(varargin{:},pvpairs{:});

    try
        h = matlab.graphics.internal.prepareCoordinateSystem(className, parent, constructor);
    catch me
        throw(me)
    end
end

% Set as current 'axes' if not already done
fig=ancestor(h,'figure');
if ~isempty(fig)
    fig.CurrentAxes=h;
end

end
