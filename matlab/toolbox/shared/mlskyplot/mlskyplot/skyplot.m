function hh = skyplot(varargin)
%SKYPLOT Plot satellite azimuth and elevation data
%   SKYPLOT(AZDATA,ELDATA) creates a sky plot using the azimuth and
%   elevation data specified as vectors in degrees.
%
%   SKYPLOT(AZDATA,ELDATA,LABELDATA) specifies data labels as a string
%   array, LABELDATA, with elements corresponding to each data point in the
%   AZDATA and ELDATA inputs.
%
%   SKYPLOT(STATUS) creates a sky plot from the STATUS struct. Fields
%   SatelliteAzimuth and SatelliteElevation are used for azimuth data and
%   elevation data, respectively.
%
%   SKYPLOT(___,"Name",Value) specifies options using one or more
%   name-value arguments in addition to the input arguments in previous
%   syntaxes. The name-value arguments are properties of the SkyPlotChart
%   object.
%
%   SKYPLOT(PARENT,___) creates the SKYPLOT in the figure, panel, or tab
%   specified by PARENT.
%
%   h = SKYPLOT(___) returns the SkyPlotChart object. Use h to modify 
%   properties of the chart after creating it.
%
%   Example
%       az = [10 20 120 255];
%       el = [52 10 44 87];
%       labels = ["G1", "G22", "E17", "E11"];
%       groups = categorical([0 0 1 1], [0 1], ["GPS", "Galileo"]);
%       SKYPLOT(az, el, labels, "GroupData", groups)
%       legend
%
%   See also POLARSCATTER.

%   Copyright 2020-2024 The MathWorks, Inc.

narginchk(1, Inf);

% Capture the input arguments and initialize the extra name/value pairs to
% pass to the SkyPlotChart constructor.
args = varargin;

% Check if the first input argument is a graphics object to use as parent.
isFirstArgParent = ~isempty(args) ...
    && isa(args{1},'matlab.graphics.Graphics');
if isFirstArgParent
    % skyplot(parent,___)
    parent = args{1};
    args = args(2:end);
end

assert((numel(args) >= 1 && isstruct(args{1})) || (numel(args) >= 2), ...
    message('MATLAB:narginchk:notEnoughInputs'));

[extraArgs, args] = parseInputs(args);

% Build the full list of name-value pairs.
args = [extraArgs args];
if isFirstArgParent
    args = [{'Parent'}, {parent}, args(:).'];
end

% Construct skyplot.
try
    h = nav.graphics.chart.SkyPlotChart(args{:});
catch e
    throwAsCaller(e);
end

% Prevent outputs when not assigning to variable.
if nargout > 0
    hh = h;
end

end

function [extraArgs, args] = parseInputs(args)
    if (isa(args{1}, 'numeric') && isa(args{2}, 'numeric'))
        % Matrix syntax
        %   skyplot(azdata,eldata,Name,Value)
        [extraArgs, args] = parseMatrixInputs(args);
    elseif isstruct(args{1})
        % gnssSensor status struct
        status = args{1};
        
        % Check field existence.
        if all(isfield(status, {'SatelliteAzimuth', 'SatelliteElevation'}))
            azCell = arrayfun(@(x) x.SatelliteAzimuth(:).', status, UniformOutput=false);
            elCell = arrayfun(@(x) x.SatelliteElevation(:).', status, UniformOutput=false);
            numAz = cellfun(@numel, azCell);
            numEl = cellfun(@numel, elCell);
            
            % Check field sizes.
            isValidSize = @(x) isempty(x) || all(x == x(1));
            if (isValidSize(numAz) && isValidSize(numEl))
                az = cell2mat(azCell);
                el = cell2mat(elCell);
                extraArgs = {'AzimuthData', az, ...
                    'ElevationData', el};
                args = args(2:end);
            else
                error(message( ...
                    'shared_mlskyplot:SkyPlotChart:InvalidStructFieldSize', ...
                    'SatelliteAzimuth', 'SatelliteElevation'));
            end
        else
            error(message( ...
                'shared_mlskyplot:SkyPlotChart:InvalidStruct', ...
                'SatelliteAzimuth', 'SatelliteElevation'));
        end
    else
        error(message('shared_mlskyplot:SkyPlotChart:InvalidAzElData'));
    end
    try
        nav.graphics.chart.SkyPlotChart.validateAzElData( ...
            extraArgs{2:2:end});
    catch e
        throwAsCaller(e);
    end
end
function [extraArgs, args] = parseMatrixInputs(args)
% Parse the matrix syntax:
%   skyplot(azdata,eldata,Name,Value)
%   skyplot(azdata,eldata,labeldata,Name,Value)

% Parse azdata and eldata.
extraArgs = {'AzimuthData', args{1}, 'ElevationData', args{2}};
args = args(3:end);
if (~isempty(args) && (isnumeric(args{1}) || ischar(args{1}) || iscell(args{1}) || isstring(args{1})))
    % Only parse the labels if there are an even number of remaining
    % arguments. Otherwise, treat the third argument as a "Name" in a
    % Name-Value pair.
    if (mod(numel(args(2:end)), 2) == 0)
        % Parse labels.
        extraArgs(end+1:end+2) = {'LabelData', args{1}};
        args = args(2:end);
    end
end
end
