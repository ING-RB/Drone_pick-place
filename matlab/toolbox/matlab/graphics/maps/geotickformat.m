function tickLabelFormat = geotickformat(input1, input2)
%GEOTICKFORMAT Set or query geographic tick label format
%
%   GEOTICKFORMAT(fmt) sets the format of the latitude and longitude tick
%   labels in the current (geographic) axes. The tick label format, fmt,
%   can be specified as one of the following:
%
%     'dd'  - Decimal degrees plus compass direction
%     'dm'  - Degrees and (decimal) minutes plus compass direction
%     'dms' - Degrees, minutes and (decimal) seconds plus compass direction
%     '-dd' - Decimal degrees with "-" sign for south or west
%     '-dm' - Degrees and (decimal) minutes with "-" sign for south or west
%     '-dms' - Degrees, minutes and (decimal) seconds with "-" sign for
%              south or west
%
%   tickLabelFormat = GEOTICKFORMAT returns the tick label format of the
%   current axes.
%
%   GEOTICKFORMAT(gx,fmt) applies the format to the geographic axes
%   specified by gx.
%
%   tickLabelFormat = GEOTICKFORMAT(gx) returns the tick label format of
%   the geographic axes specified by gx.
%
%   Example
%   -------
%   % Mark the largest cities in Brazil with blue squares, using minus
%   % signs to indicate south latitude and west longitude
%   lat = [-23.5500   -22.9083   -15.7939];
%   lon = [-46.6333   -43.1964   -47.8828];
%   geoplot(lat,lon,'bs','MarkerSize',12)
%   geolimits([-25 -16], [-54 -38])
%   geotickformat -dd
%
%   See also GEOAXES

% Copyright 2018-2022 The MathWorks, Inc.
    
    switch nargin
        case 0
            % Query: fmt = geotickformat -- assign value to output fmt
            gx = getGeographicAxes();
            tickLabelFormat = gx.TickLabelFormat;
            
        case 1
            classes = {'string', 'char', 'matlab.graphics.axis.GeographicAxes'};
            if isa(input1,'map.graphics.axis.MapAxes')
                classes{end+1} = 'map.graphics.axis.MapAxes';
            end
            validateattributes(input1, classes, {})
            if isstring(input1) || ischar(input1)
                % Set: geotickformat(fmt) -- leave fmt unassigned
                fmt = input1;
                % Be sure to validate format input before trying to get an
                % axes, to make sure we don't create a new geographic axes
                % and then throw an error about invalid input.
                fmt = validatestring(fmt, ...
                    ["dd", "dm", "dms", "-dd", "-dm", "-dms"], mfilename);
                gx = getGeographicAxes();
                gx.TickLabelFormat = fmt;
            else
                % Query: fmt = geotickformat(gx) -- assign value to fmt
                gx = input1;
                classes(1:2) = []; % remove 'string' and 'char'
                matlab.graphics.internal.validateScalarArray(gx, classes, mfilename,'gx')
                tickLabelFormat = gx.TickLabelFormat;
            end
             
        case 2
            % Set: geotickformat(gx, fmt) -- leave fmt unassigned
            gx = input1;
            fmt = input2;
            % Validate formatInput first to avoid a confusing error in the
            % case both inputs are valid but their order is reversed.
            fmt = validatestring(fmt, ...
                ["dd", "dm", "dms", "-dd", "-dm", "-dms"], mfilename, 'fmt', 2);
            classes = {'matlab.graphics.axis.GeographicAxes'};
            if isa(gx,'map.graphics.axis.MapAxes')
                classes{end+1} = 'map.graphics.axis.MapAxes';
            end
            matlab.graphics.internal.validateScalarArray(gx, classes, mfilename,'gx')
            gx.TickLabelFormat = fmt;
    end
    
    % At this point, in the cases:
    %
    %    geotickformat
    %    geotickformat(gx)
    %
    % where a query syntax is used but no output is assigned and there's no
    % trailing semicolon, fmt has a value which will display at the command
    % line. But fmt is not yet assigned in the following cases:
    %
    %    geotickformat(fmt)
    %    geotickformat(gx,fmt)
    %
    % We want to leave things that way, suppressing command-line output,
    % unless an output is explitly requested. And, when an output is
    % requested, the simplest thing is to treat all four cases:
    %
    %    tickLabelFormat = geotickformat
    %    tickLabelFormat = geotickformat(gx)
    %    tickLabelFormat = geotickformat(fmt)     <== Undocumented, but allowed
    %    tickLabelFormat = geotickformat(gx,fmt)  <== Undocumented, but allowed
    %
    % the same way, as in the following, even though it means getting
    % TickLabelFormat from the axes a second time for the query syntaxes.
    if nargout > 0
        tickLabelFormat = gx.TickLabelFormat;
    end
end


function gx = getGeographicAxes()
% There's a current axes:
%   Return it if it's geographic (or map)
%   Error if it's not geographic (or map)
% Construct a GeographicAxes, otherwise.

    cf = get(groot,'CurrentFigure');
    if isempty(cf)
        gx = geoaxes;
    else
        gx = cf.CurrentAxes;
        if isempty(gx)
            gx = geoaxes(cf);
        elseif gx.Type ~= "geoaxes" && gx.Type ~= "mapaxes"
            msgID = 'MATLAB:graphics:maps:NotGeographicAxes';
            throwAsCaller(MException(message(msgID,mfilename)))
        end
    end
end
