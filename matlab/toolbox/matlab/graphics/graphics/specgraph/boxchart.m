function h = boxchart(varargin)
% BOXCHART Creates box and whisker plot.
%
%   BOXCHART(YDATA) creates a box chart, or box plot, for each column of
%   the matrix YDATA. If YDATA is a vector, then boxchart returns a single
%   box chart. Each box chart displays the following information: the
%   median, first and third quartiles, outliers (computed using the
%   interquartile range), and minimum and maximum values that are not
%   outliers.
%
%   BOXCHART(XGROUPDATA,YDATA) groups the data in vector YDATA according to
%   the unique values in XGROUPDATA and plots each group of data as a
%   separate box chart. XGROUPDATA determines the position of each box
%   chart along the x-axis. XGROUPDATA must be a vector of the same length
%   as YDATA.
%
%   BOXCHART(___,Name,Value) specifies additional chart options using one
%   or more name-value pair arguments. Specify the name-value pair
%   arguments after all other input arguments. For example, you can compare
%   sample medians using notches by specifying 'Notch','on'.
%
%   BOXCHART(AX,___) plots into the axes specified by AX instead of the
%   current axes (gca). The option AX can precede any of the input
%   argument combinations in the previous syntaxes.
%
%   H = BOXCHART(___) returns a BoxChart object. Use H to set properties of
%   the box charts after creating them.
%
%   H = BOXCHART(___,'GroupByColor',cgroupdata) uses the data specified by
%   cgroupdata for grouping YDATA. The function returns a vector of
%   BoxChart objects, one for each distinct category in cgroupdata.
%
%   Example:
%       % Display two box charts in a tiled chart layout.
%       tiledlayout(2,1);
%       nexttile
%       boxchart(rand(10,5))
%       nexttile
%       boxchart(randi(2,50,1),rand(50,1))
%
%   See also HISTOGRAM, PLOT, BAR, BARH, BAR3, BAR3H.

%   Copyright 2019-2025 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV

narginchk(1,Inf);
[parent,args] = peelFirstArgParent(varargin,false);

if isempty(args)
    error(message('MATLAB:narginchk:notEnoughInputs'))
end

useTable = istabular(args{1});

% Split input arguments before creating figure
if useTable
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
    matlab.graphics.chart.primitive.BoxChart.validateData(dataMap);
    % Validate that table values do not contain matrices for Y:
    for idx = 1:dataMap.NumObjects
        tblY = dataSource.getData((dataMap.slice(idx).Y));
        if ~isvector(tblY{:})
            error(message('MATLAB:graphics:boxchart:NoY2DInTable'))
        end
    end
else
    [posargs, pvpairs] = splitPositionalFromPV(args, 1, true);

    % Obtain xgroupdata and ydata from posargs
    ydata = posargs{1};
    if numel(posargs)>1
        xgroupdata = ydata;
        ydata = posargs{2};
        xgroupdataProvided = true;
        validateattributes(xgroupdata,{'numeric','categorical'},{'vector','real'},mfilename,'xgroupdata');

        % xgroupdata may only be supplied when ydata is a vector
        if ~isvector(ydata)
            error(message('MATLAB:graphics:boxchart:NoXGDataWhenY2D'));
        end

        % Check that the sizes of xgroupdata and ydata are consistent
        if isvector(ydata) && (numel(xgroupdata) ~= numel(ydata))
            error(message('MATLAB:graphics:boxchart:BadXVectorY'));
        end
    else
        xgroupdataProvided = false;
        xgroupdata = [];
    end
    validateattributes(ydata,{'numeric'},{'2d','real'},mfilename,'ydata');
    if isvector(ydata)
        ydata = ydata(:);
    end

end

% Check for (and extract) color grouping:
colGrpIdx = [];
for i = 1:2:numel(pvpairs)
    if startsWith('GroupByColor',pvpairs{i},'IgnoreCase',true) && (i+1 <= numel(pvpairs))
        % Obtain color group data
        grp = pvpairs{i+1};
        colGrpIdx = [colGrpIdx,i];
        % Validate GroupByColor
        validateattributes(grp,{'numeric','categorical','logical',...
            'char','string','cell'},{'real','nonsparse','vector'},'','GroupByColor');

        % GroupByColor is only supported when ydata is provided and as vector
        if useTable
            error(message('MATLAB:graphics:boxchart:NoColGDataWhenTable'))
        elseif ~isvector(ydata)
            error(message('MATLAB:graphics:boxchart:NoColGDataWhenY2D'));
        end

        % Check that the sizes of grp and ydata are consistent
        if isvector(ydata) && (numel(grp) ~= numel(ydata))
            error(message('MATLAB:graphics:boxchart:BadColGroupVectorY'));
        end

        % Obtain group indices and names
        [gnum,gnames] = findgroups(grp);
        gnames = gnames(:);
    end
end
pvpairs([colGrpIdx,colGrpIdx+1]) = [];
colorGrouping = ~isempty(colGrpIdx);
if ~colorGrouping && ~useTable
    gnum = ones(size(ydata,1),1);
end

% validatePartialPropertyNames will throw if there are any invalid property
% names (i.e. a name that doesn't exist on BoxChart or is ambiguous) and
% return full capitalized property names
propNames = matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.BoxChart', pvpairs(1:2:end));
pvpairs(1:2:end) = cellstr(propNames);

% Prepare axes once all has been validated above:
[parent, hasParent] = getParent(parent, pvpairs);
[parent,ancestorAxes] = prepareAxes(parent, hasParent);

% Get number of objects:
if useTable
    ngrp = dataMap.NumObjects;
else
    if colorGrouping
        ngrp = numel(gnames);
    else
        ngrp = 1;
    end
    % Configure x-axis
    if isscalar(ancestorAxes)
        tmpXData = categorical(1:size(ydata,2));
        if xgroupdataProvided
            tmpXData = xgroupdata;
        end
        matlab.graphics.internal.configureAxes(parent,tmpXData,ydata);
    end
end

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

% Create the objects:
if useTable
    H = gobjects(ngrp,1);
    for idx = 1:ngrp
        sliceStruct = dataMap.slice(idx);
        if isscalar(ancestorAxes)
            if xVarProvided
                x = dataSource.getData(sliceStruct.X);
            else
                x = {categorical(1:ngrp)};
            end
            y = dataSource.getData(sliceStruct.Y);
            matlab.graphics.internal.configureAxes(ancestorAxes, x{1}, y{1});
        end
        tableArgs = {'SourceTable',dataSource.Table, 'YVariable', sliceStruct.Y};
        if xVarProvided
            tableArgs= [tableArgs(:)', {'XVariable'},{sliceStruct.X}];
        end
        H(idx) = matlab.graphics.chart.primitive.BoxChart( ...
            'Parent', parent, tableArgs{:}, ...
            'PeerID', idx, pvpairs{:});
        H(idx).assignSeriesIndex();
    end
else
    if isvector(ydata)
        grpargs = {};
        H = gobjects(ngrp,1);
        for idx = 1:ngrp
            ind = gnum == idx;
            dataArgs = {'YData',ydata(ind)};
            if xgroupdataProvided
                dataArgs = [{'XData'},{xgroupdata(ind)}, dataArgs(:)'];
            end
            if colorGrouping
                % Display name is used to populate the legend's text
                grpargs = {'DisplayName',string(gnames(idx,:)),...
                    'NumColorGroups', ngrp, 'GroupByColorMode','manual'};
            end

            % Call the class constructor
            H(idx) = matlab.graphics.chart.primitive.BoxChart('Parent', parent,...
                dataArgs{:}, 'PeerID', idx, pvpairs{:}, grpargs{:});
            H(idx).assignSeriesIndex();
        end
    else
        dataArgs = {'YData',ydata};
        if xgroupdataProvided
            dataArgs = [{'XData'},{xgroupdata}, dataArgs(:)'];
        end
        H = matlab.graphics.chart.primitive.BoxChart('Parent', parent,...
            dataArgs{:}, 'PeerID', 1, pvpairs{:});
        H.assignSeriesIndex();
    end
end

if ~isempty(H)
    % Ensure that each boxchart stores handles to its peers, if any
    if ngrp > 1
        for idx = 1:ngrp
            H(idx).BoxPeers = H(idx ~= 1:ngrp);
        end
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
        xunitwidth = 1;
        if numel(uniquex) > 1
            xunitwidth = min(diff(uniquex));
        end
    else
        xunitwidths = ones(1, numel(H));
        for i = 1:numel(H)
            x = H(i).XData_I;
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
                xunitwidths(i) = min(diff(uniquex));
            end
        end
        xunitwidth = min(xunitwidths);
    end
    set(H,'XDataUnitWidth_I',xunitwidth);

    % Inspect if the BoxWidth was set:
    if H(1).BoxWidthMode == "auto"
        set(H,'BoxWidth_I',0.5*xunitwidth);
    end

    % Set orientation, if given
    if ~isempty(userSpecifiedOrientation)
        set(H,'Orientation',userSpecifiedOrientation);
    end

end

% Return handle only if the user asks for it
if nargout > 0
    h = H;
end
end