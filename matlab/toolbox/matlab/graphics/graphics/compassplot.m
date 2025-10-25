function hh = compassplot(varargin)
%

%   Copyright 2024 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent

narginchk(1,Inf)
nargoutchk(0,1)

% Check for first argument parent - must be a PolarAxes.
supportDoubleParentHandle = false;
[parent, args] = peelFirstArgParent(varargin, supportDoubleParentHandle);

% When a first-arg parent is provided, check that it was not the only
% argument specified.
if isempty(args)
    error(message('MATLAB:narginchk:notEnoughInputs'))
end

% Determine if we have table or matrix input data.
if istabular(args{1})
    % compassplot(tbl, thetaVar, rhoVar)
    [nObjects, dataPairs, pvpairs] = tableCompassPlot(args);
else
    % compassplot(theta, r)
    % compassplot(Z)
    [nObjects, dataPairs, pvpairs] = matrixCompassPlot(args);
end

% Validate pv-pairs and get parent.
matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.PolarCompassPlot', pvpairs(1:2:end));
[parent, hasParent] = getParent(parent, pvpairs);

doPrepareAxes = true;
if hasParent
    if ~isempty(parent) && ~isa(parent, 'matlab.graphics.axis.PolarAxes')
        % If a non-empty parent was provided or if a parent has been returned by
        % getParent (i.e. a Parent was found in the PV pairs list), validate that
        % it is a PolarAxes. This is necessary to make sure the command errors when
        % a non-polar axes is specified as the parent; if not caught here,
        % prepareCoordinateSystem will swap in a PolarAxes to replace the other.
        error(message('MATLAB:polarplot:AxesInput'));
    elseif isempty(parent)
        % If an empty parent was explicitly specified, plan to skip the
        % prepareAxes code to prevent a new PolarAxes from being created.
        doPrepareAxes = false;
    end
end

% Prepare axes.
if doPrepareAxes
    parent = matlab.graphics.internal.prepareCoordinateSystem('polar', parent);
    parent = newplot(parent);
end

% Construct objects.
h = gobjects(nObjects,1);
for i = 1:nObjects
    h(i) = matlab.graphics.chart.primitive.PolarCompassPlot(dataPairs{i}{:}, pvpairs{:}, 'Parent', parent);
    h(i).assignSeriesIndex();
end

if nObjects==0
    h = matlab.graphics.chart.primitive.PolarCompassPlot.empty(1,0);
end

if nargout == 1
    hh = h;
end

end

function [nObjects, dataPairs, pvpairs] = matrixCompassPlot(args)
import matlab.graphics.chart.primitive.internal.findMatchingDimensions
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
try
    [posargs, pvpairs] = splitPositionalFromPV(args, 1, true);
catch ex
    throwAsCaller(ex);
end
if isscalar(posargs)
    if isnumeric(posargs{1})
        % Treat single positional argument as Z (imaginary)
        imagComp = imag(posargs{1});
        if imagComp == 0
            warning(message('MATLAB:polar:AssumeComplex'))
        end
        [thetaData, rData] = cart2pol(real(posargs{1}), imagComp);
    else
        ex = MException(message('MATLAB:plot:InvalidFirstInput'));
        throwAsCaller(ex);
    end
else
    % In the two arg case, treat them as Theta and R
    thetaData = posargs{1};
    rData = posargs{2};
end

[msg,thetaData,rData] = findMatchingDimensions(thetaData,rData);
if ~isempty(msg)
    ex = MException('MATLAB:compassplot:InvalidXYData',message('MATLAB:scatter:InvalidXYData','Theta','R'));
    throwAsCaller(ex);
end

if ~isnumeric(thetaData) || ~isnumeric(rData)
    ex = MException('MATLAB:compassplot:mustBeNumeric',message('MATLAB:validators:mustBeNumeric'));
    throwAsCaller(ex);
elseif ~isreal(thetaData) || ~isreal(rData)
    ex = MException('MATLAB:compassplot:mustBeReal',message('MATLAB:validators:mustBeReal'));
    throwAsCaller(ex);
end

nObjects = size(thetaData,2);
dataPairs = cell(nObjects,1);
for i = 1:nObjects
    dataPairs{i} = {"ThetaData", thetaData(:,i), "RData", rData(:,i)};
end
end

function [nObjects, dataPairs, pvpairs] = tableCompassPlot(args)
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV

try
    [posargs, pvpairs] = splitPositionalFromPV(args, 3, false);
catch ex
    throwAsCaller(ex);
end

dataSource = matlab.graphics.data.DataSource(posargs{1});
dataMap = matlab.graphics.data.DataMap(dataSource);
dataMap = dataMap.addChannel('Theta', posargs{2});
dataMap = dataMap.addChannel('R', posargs{3});

matlab.graphics.chart.primitive.PolarCompassPlot.validateData(dataMap);

nObjects = dataMap.NumObjects;
dataPairs = cell(nObjects,1);
for i = 1:nObjects
    sliceStruct = dataMap.slice(i);
    dataPairs{i} = {'SourceTable', dataSource.Table, ...
        'ThetaVariable', sliceStruct.Theta, 'RVariable', sliceStruct.R};
end

end