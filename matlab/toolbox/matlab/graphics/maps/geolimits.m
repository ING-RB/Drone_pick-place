function [latitudeLimits, longitudeLimits] = geolimits(varargin)
%GEOLIMITS Set or query geographic limits
%
%   GEOLIMITS(latlim,lonlim) adjusts the geographic limits of the current
%   geographic axes or chart to include latitudes ranging from latlim(1) to
%   latlim(2) and longitudes ranging from lonlim(1) to lonlim(2).
%
%   [latitudeLimits,longitudeLimits] = GEOLIMITS returns the current
%   geographic limits.
%
%   GEOLIMITS('auto') lets the axes or chart choose its geographic limits
%   based on its data locations.
%
%   GEOLIMITS('manual') requests that the chart preserve its current limits
%   as closely as possible when it is resized or when its data locations
%   change.
%
%   ___ = GEOLIMITS(___) returns the new geographic limits.
%
%   ___ = GEOLIMITS(gx,___) operates on the geographic axes or geographic
%   chart specified by gx.
%
%   Example
%   -------
%   tsunamis = readtable('tsunamis.xlsx');
%   lat = tsunamis.Latitude;
%   lon = tsunamis.Longitude;
%   sizedata = tsunamis.MaxHeight;
%   figure
%   geobubble(lat,lon,sizedata,'SizeLegendTitle','Maximum Height')
%   [latlim, lonlim] = geolimits
%   geolimits([50 65],[-175 -130])
%   title 'Tsunamis in Alaska'
%   [latlim, lonlim] = geolimits
%
%   Remark
%   ------
%   Typically, the limits set by GEOLIMITS are greater in extent than the
%   input limit values, in one dimension or the other, in order to maintain
%   a correct north-south/east-west aspect on the map.
%
%   See also GEOAXES, GEOBASEMAP, GEOBUBBLE

% Copyright 2017-2022 The MathWorks, Inc.

    narginchk(0,3)

    try
        % Parse inputs.
        [gx, inputs, gxIsOnlyInput] = parseInputs(varargin);
        
        % Validate GX as a GeographicAxes or GeographicBubbleChart.
        validateGeographicAxesOrChart(gx)
        
        % Getting the limits will force an update. Don't
        % do it unless the limits have been requested.
        if (nargout > 0) || (nargin == 0) || gxIsOnlyInput
            % [latlim, lonlim] = geolimits(_)
            % geolimits
            % geolimits(gx)
            [latitudeLimits, longitudeLimits] = geographicLimits(gx, inputs{:});
        else
            geographicLimits(gx, inputs{:});
        end
    catch e
        throw(e)
    end
end


function [gx, inputs, gxIsOnlyInput] = parseInputs(inputs)
% Parse INPUTS cell array and return outputs.
%
% GX is either the first element in INPUTS, the current axes, a
% GeographicAxes, or a GeographicChart.
%
% INPUTS is the return INPUTS array to be passed to GEOLIMITS without GX.
% 
% gxIsOnlyInput is true if using the following syntaxes:
%    geolimits(gx)
%    [latlim, lonlim] = geolimits(gx)

    gxIsOnlyInput = false;
    switch length(inputs)
        case 0
            % [latlim,lonlim] = geolimits
            gx = getCurrentAxes;

        case 1
            if isstring(inputs{1}) || ischar(inputs{1})
                % geolimits('manual')
                % geolimits('auto')
                gx = getCurrentAxes;
            else
                % geolimits(gx)
                gx = inputs{1};
                inputs = {};
                gxIsOnlyInput = true;
            end

        case 2
            if isscalar(inputs{1}) && ishghandle(inputs{1})
                % geolimits(gx,'manual')
                % geolimits(gx,'auto')
                gx = inputs{1};
                inputs = inputs(2);
            else
                % geolimits(latlim,lonlim)
                gx = getCurrentAxes;
            end
            
        case 3
            % geolimits(gx,latlim,lonlim)
            gx = inputs{1};
            inputs = inputs(2:3);
    end
end


function cx = getCurrentAxes
% Return the current axes, if there is one.
% Construct a GeographicAxes, otherwise.

    cf = get(groot,'CurrentFigure');
    if isempty(cf)
        cx = geoaxes;
    else
        supportedTypes = ["geobubble", "geoaxes", "mapaxes"];
        cx = cf.CurrentAxes;
        if isempty(cx)
            cx = geoaxes(cf);
        elseif ~any(cx.Type == supportedTypes)
            error(message('MATLAB:graphics:maps:NotGeographic',mfilename))
        end
    end
end


function validateGeographicAxesOrChart(gx)
% Validates GX to be a scalar GeographicAxes or GeographicBubbleChart.

    if ~(isscalar(gx) && isa(gx, 'matlab.graphics.chart.GeographicChart'))
        classes = { ...
            'matlab.graphics.axis.GeographicAxes' ...
            'matlab.graphics.chart.GeographicBubbleChart'};
        if isa(gx,'map.graphics.axis.MapAxes')
            classes{end+1} = 'map.graphics.axis.MapAxes';
        end
        matlab.graphics.internal.validateScalarArray(gx, classes, mfilename, 'gx')
    end
end
