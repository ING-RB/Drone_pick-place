function hh = violinplot(varargin)
%

%   Copyright 2024-2025 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV

narginchk(1,Inf);
funcName = 'violinplot';

[parent,args] = peelFirstArgParent(varargin,false);

if isempty(args)
    error(message('MATLAB:narginchk:notEnoughInputs'))
end

% Inspect, validate and prepare data:
usePDF = matlab.graphics.internal.isCharOrString(args{1});
useTable = istabular(args{1});

if usePDF
    [~, pvpairs] = splitPositionalFromPV(args, 0, false);
    if numel(pvpairs) < 4
        error(message('MATLAB:narginchk:notEnoughInputs'))
    end
elseif useTable
    [posargs, pvpairs] = splitPositionalFromPV(args, 2, true);
    tableArg = posargs{1};
    yVarArg  = posargs{end};
    xVarProvided = false;
    if numel(posargs) == 3
        xVarArg  = posargs{2};
        xVarProvided = true;
    end

    dataSource = matlab.graphics.data.DataSource(tableArg);
    dataMap = matlab.graphics.data.DataMap(dataSource);
    if xVarProvided
        dataMap = dataMap.addChannel('X', xVarArg);
    end
    dataMap = dataMap.addChannel('Y', yVarArg);
    % Validate the data by looking at the data itself, not just the subscripts:
    matlab.graphics.chart.primitive.ViolinPlot.validateData(dataMap);
else
    [posargs, pvpairs] = splitPositionalFromPV(args, 1, true);

    ydata = posargs{end};
    yIsMatrix = ~isvector(ydata);
    validateattributes(ydata,{'numeric'},{'2d','real'},funcName,'ydata');
    if ~yIsMatrix
        ydata = ydata(:);
    end

    if numel(posargs) == 2
        xgroupdataProvided = true;
        xgroupdata = posargs{1};
        validateattributes(xgroupdata,{'numeric','categorical'},{'2d'},funcName,'xgroupdata');
    else
        xgroupdata = [];
        xgroupdataProvided = false;
    end

    if xgroupdataProvided  % otherwise the object handles this
        if yIsMatrix
            ydatadim = size(ydata);
            if isvector(xgroupdata)
                numelx = numel(xgroupdata);
                % xgroupdata must match up with the number of rows or columns:
                if numelx == ydatadim(2)
                    xgroupdata = repelem(xgroupdata(:)', ydatadim(1), 1);
                elseif numelx == ydatadim(1)
                    xgroupdata = repelem(xgroupdata(:), 1, ydatadim(2));
                else
                    error(message('MATLAB:graphics:violinplot:InvalidXYData'))
                end
            elseif ~isequal(size(xgroupdata), ydatadim)
                error(message('MATLAB:graphics:violinplot:InvalidXYData'))
            end
        else
            if isscalar(xgroupdata)
                xgroupdata = repelem(xgroupdata,numel(ydata),1);
            end
            if isvector(xgroupdata)
                if numel(xgroupdata) ~= numel(ydata)
                    error(message('MATLAB:graphics:violinplot:InvalidXYData'))
                end
                xgroupdata = xgroupdata(:);
            else % xgroupdata is a matrix. Rows must match ydata
                sizeX = size(xgroupdata);
                if sizeX(1) == numel(ydata)
                    ydata = repmat(ydata,1,sizeX(2));
                    yIsMatrix = true;
                else
                    error(message('MATLAB:graphics:violinplot:InvalidXYData'))
                end
            end
        end
    end
end

% Check if GroupByColor specified:
colGrps = [];
colGrpsIdx = [];
for i = 1:2:numel(pvpairs)
    if startsWith('GroupByColor',pvpairs{i},'IgnoreCase',true)
        colGrpsIdx = [colGrpsIdx,i];
    end
end
colorGrouping = ~isempty(colGrpsIdx);
if colorGrouping
    if useTable
        error(message('MATLAB:graphics:violinplot:ColGrpsNotWithTables'))
    elseif usePDF
        error(message('MATLAB:graphics:violinplot:ColGrpsNotWithPDFs'))
    elseif ~isvector(ydata)
        % This covers the case where xgroupdata was provided as a matrix
        error(message('MATLAB:graphics:violinplot:ColGrpsOnlyWithYvec'))
    end
    colGrps = pvpairs{colGrpsIdx(end) + 1};
    validateattributes(colGrps,{'numeric','categorical','logical',...
        'char','string','cell'},{'real','nonsparse','vector'},funcName,'GroupByColor');
    if numel(colGrps) ~= numel(ydata)
        error(message('MATLAB:graphics:violinplot:BadColGroupVectorY'))
    end

    % Obtain group indices and names
    [gnum,gnames] = findgroups(colGrps);
    gnames = gnames(:);

    pvpairs([colGrpsIdx,colGrpsIdx+1]) = [];
end


% validatePartialPropertyNames will throw if there are any invalid property
% names (i.e. a name that doesn't exist on ViolinPlot or is ambiguous) and
% return full capitalized property names
propNames = matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.ViolinPlot', pvpairs(1:2:end));
pvpairs(1:2:end) = cellstr(propNames);

% Inspect if pdfs were given
evalPtsIdx = find(propNames == "EvaluationPoints",1,"last");
densValIdx = find(propNames == "DensityValues",1,"last");

if (~usePDF || useTable) && (~isempty(evalPtsIdx) || ~isempty(densValIdx))
    error(message("MATLAB:graphics:violinplot:NoPDFWithData"))
end
if usePDF
    if isempty(evalPtsIdx) || isempty(densValIdx)
        error(message("MATLAB:graphics:violinplot:BothPDFPartsNeeded"))
    end

    evalPts = pvpairs{2*evalPtsIdx};
    densVal = pvpairs{2*densValIdx};

    validateattributes(evalPts,{'double','single'},...
        {'2d','real','nonsparse','finite'},funcName,'',2*evalPtsIdx);
    validateattributes(densVal,{'numeric'},{'2d','real'},funcName,'',2*densValIdx);
end

% Prepare axes once all has been validated above:
[parent, hasParent] = getParent(parent, pvpairs);
[parent,ancestorAxes] = prepareAxes(parent, hasParent);

% Inspect if the orientation is given
userSpecifiedOrientation = [];
orIdx = find(propNames == "Orientation");
if ~isempty(orIdx)
    % Extract the last value:
    userSpecifiedOrientation = pvpairs{2*orIdx(end)};
    % Remove all references:
    propNames(orIdx) = [];
    pvpairs([2*(orIdx-1)+1,2*orIdx]) = [];
end

% Get number of objects:
if usePDF
    nObjects = 1;
    % Configure x-axis
    if isscalar(ancestorAxes)
        tmpXData = categorical(1);
        if ~isvector(evalPts)
            tmpXData = categorical(1:size(evalPts,2));
        end
        matlab.graphics.internal.configureAxes(ancestorAxes,tmpXData,evalPts);
    end
elseif useTable
    nObjects = dataMap.NumObjects;
else
    if colorGrouping
        nObjects = numel(gnames);
    else
        nObjects = size(ydata,2);
    end
    % Configure x-axis
    if isscalar(ancestorAxes)
        if xgroupdataProvided
            tmpXData = xgroupdata;
        elseif colorGrouping
            tmpXData = categorical(1);
        else
            tmpXData = categorical(1:nObjects);
        end
        matlab.graphics.internal.configureAxes(ancestorAxes,tmpXData,ydata);
    end
end
h = gobjects(1, nObjects);

% Create violins:
for i = 1:nObjects

    if usePDF
        h(i) = matlab.graphics.chart.primitive.ViolinPlot('Parent', parent, ...
            'EvaluationPoints', evalPts, 'DensityValues', densVal,...
            'PeerID', i, pvpairs{:});
    elseif useTable
        sliceStruct = dataMap.slice(i);
        if isscalar(ancestorAxes)
            if xVarProvided
                x = dataSource.getData(sliceStruct.X);
            else
                x = {categorical(1:nObjects)};
            end
            y = dataSource.getData(sliceStruct.Y);
            matlab.graphics.internal.configureAxes(ancestorAxes, x{1}, y{1});
        end
        tableArgs = {'SourceTable',dataSource.Table, 'YVariable', sliceStruct.Y};
        if xVarProvided
            tableArgs= [tableArgs(:)', {'XVariable'},{sliceStruct.X}];
        end
        h(i) = matlab.graphics.chart.primitive.ViolinPlot( ...
            'Parent', parent, tableArgs{:}, 'PeerID', i, pvpairs{:});

    else % Use Data
        if colorGrouping
            ind = gnum == i;
            dataArgs = {'YData',ydata(ind)};
            if xgroupdataProvided
                dataArgs = [{'XData'},{xgroupdata(ind)}, dataArgs(:)'];
            end
            colorArgs = {'NumColorGroups', nObjects,'GroupByColorMode','manual'};
        else
            dataArgs = {'YData',ydata(:,i)};
            if xgroupdataProvided
                dataArgs = [{'XData'},{xgroupdata(:,i)}, dataArgs(:)'];
            end
            colorArgs = {};
        end
        h(i) = matlab.graphics.chart.primitive.ViolinPlot('Parent', parent, ...
            dataArgs{:}, colorArgs{:}, 'PeerID',i, pvpairs{:});
    end
    h(i).assignSeriesIndex;
end

if nObjects==0
    h = matlab.graphics.chart.primitive.ViolinPlot.empty(1,0);
else
    % Set the peers if there are more than one object:
    if nObjects > 1
        for i = 1:nObjects
            h(i).ViolinPeers = h(i ~= 1:nObjects);
        end
    end

    % Set orientation, if given
    if ~isempty(userSpecifiedOrientation)
        set(h,'Orientation',userSpecifiedOrientation);
    end
    % Find a sensible unit:
    if colorGrouping
        % We have to find the units and widths from
        % xgroupdata, which must be a vector:
        if iscategorical(xgroupdata) || isempty(xgroupdata)
            uniquex = 1;
        else
            uniquex=unique(xgroupdata);
            % Remove Inf and NaN:
            uniquex=uniquex(isfinite(uniquex));
        end
        xunit = 1;
        if numel(uniquex) > 1
            xunit = min(diff(uniquex));
        end
    else
        xunits = ones(1, nObjects);
        for i = 1:nObjects
            x = h(i).XData_I;
            % ... and their unique values:
            if iscategorical(x) || isempty(x)
                uniquex = 1;
            elseif ~isnumeric(x)
                error(message('MATLAB:graphics:violinplot:BadXData'))
            else
                uniquex=unique(x);
                % Remove Inf and NaN:
                uniquex=uniquex(isfinite(uniquex));
            end
            if numel(uniquex) > 1
                xunits(i) = min(diff(uniquex));
            end
        end
        xunit = min(xunits);
    end
    set(h,'XDataUnit_I',xunit);

    % Inspect if the width was set:
    if h(1).DensityWidthMode == "auto"
        set(h,'DensityWidth_I',0.9*xunit);
    end

end

% Return handle only if requested
if nargout>0
    hh = h;
end

end
