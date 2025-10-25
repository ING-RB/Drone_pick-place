function varargout = geobasemap(varargin)
%GEOBASEMAP Set or query basemap
%
%   GEOBASEMAP(basemap) sets the basemap of the current geographic axes or
%   chart to the value specified by basemap.
%
%   GEOBASEMAP(gx,___) sets the basemap of the geographic axes or chart
%   specified by gx.
%
%   basemap = GEOBASEMAP returns the basemap value for the current
%   geographic axes or chart.
%
%   basemap = GEOBASEMAP(gx) returns the basemap value for the geographic
%   axes or chart specified by gx.
%
%   Example
%   -------
%   tsunamis = readtable('tsunamis.xlsx');
%   geobubble(tsunamis,'Latitude','Longitude','SizeVariable','MaxHeight')
%   geobasemap colorterrain
%
%   See also GEOAXES, GEOBUBBLE, GEODENSITYPLOT, GEOPLOT, GEOSCATTER

% Copyright 2018-2024 The MathWorks, Inc.

    narginchk(0,2)
    nargoutchk(0,1)

    % Parse inputs.
    [gx, basemap, usingBasemapSyntax] = parseInputs(varargin);

    % Validate gx.
    classes = { ...
        'matlab.graphics.axis.GeographicAxes' ...
        'matlab.graphics.chart.GeographicBubbleChart'};
    if isa(gx,'globe.graphics.GeographicGlobe')
        classes{end+1} = 'globe.graphics.GeographicGlobe';
    end
    matlab.graphics.internal.validateScalarArray(gx, classes, mfilename, 'gx')

    % Set Basemap property, if required.
    if usingBasemapSyntax
        % geobasemap(basemap)
        % basemap(gx,basemap)
        set(gx, 'Basemap', basemap);
    end

    % Return output if required.
    if nargout > 0 || ~usingBasemapSyntax
        % geobasemap
        % basemap = geobasemap(gx)
        varargout{1} = gx.Basemap;
    end
end


function [gx, basemap, usingBasemapSyntax] = parseInputs(inputs)
% Parses INPUTS cell array. 
%
% GX is either the first element in INPUTS or the current axes or
% an empty GraphicsPlaceholder if there is no current figure.
%
% BASEMAP is either '' if a basemap syntax is not being used or it is the
% first or second element in INPUTS.
% 
% usingBasemapSyntax is true if using the following syntaxes:
%    geobasemap(basemap) or geobasemap(gx,basemap)

    switch length(inputs)
        case 0
            % basemap = geobasemap
            gx = getCurrentAxes;
            basemap = '';
            usingBasemapSyntax = false;

        case 1
            % geobasemap(basemap)
            % geobasemap(gx)
            if isstring(inputs{1}) || ischar(inputs{1})
                % geobasemap(basemap)
                gx = getCurrentAxes;
                basemap = inputs{1};
                usingBasemapSyntax = true;
            else
                % geobasemap(gx)
                gx = inputs{1};
                basemap = '';
                usingBasemapSyntax = false;
            end

        case 2
            % geobasemap(gx,basemap)
            gx = inputs{1};
            basemap = inputs{2};
            usingBasemapSyntax = true;
    end
end


function cx = getCurrentAxes
% Returns the current axes, if there is one, and validates it as a
% supported geographic data container. Otherwise, constructs a
% GeographicAxes.

    cf = get(groot,'CurrentFigure');
    if ~isempty(cf)
        cx = cf.CurrentAxes;
        if isempty(cx)
            cx = geoaxes;
        elseif ~any(cx.Type == ["geobubble", "geoaxes", "globe"])
            e = MException(message('MATLAB:graphics:maps:NotGeographic',mfilename));
            throwAsCaller(e)
        end
    else
        cx = geoaxes;
    end
end
