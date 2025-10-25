function h = geodensityplot(varargin)
%GEODENSITYPLOT Geographic density plot
%
%   GEODENSITYPLOT(lat,lon) creates a density plot in a geoaxes from
%   locations in degrees specified by the coordinate vectors lat and lon.
%
%   GEODENSITYPLOT(lat,lon,weights) weights the data points by weights.
%
%   GEODENSITYPLOT(___,Name,Value) specifies densityplot properties using
%   one or more Name,Value pair arguments. For example,
%
%        GEODENSITYPLOT(lat,lon,'Radius',2000,'FaceColor',[.6 0 0])
%
%   plots a dark red density plot with a radius of 2 kilometers.
%
%   GEODENSITYPLOT(gx,___) operates on the geographic axes specified by gx.
%
%   dp = GEODENSITYPLOT(___) returns a DensityPlot object.
%
%   Example
%   -------
%   lon = linspace(-170,170,3000) + 10*rand(1,3000);
%   lat = 50 * cosd(3*lon) + 10*rand(size(lon));
%   weights = 101 + 100*(sind(2*lon));
%   geodensityplot(lat,lon,weights,'FaceColor','interp')
%
%   See also GEOAXES, GEOBASEMAP, GEOLIMITS, GEOPLOT, GEOSCATTER

% Copyright 2018-2022 The MathWorks, Inc.
    matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
    narginchk(2,inf)
    [cax, args, nargs] = axescheck(varargin{:});
    if ~isempty(cax) && ~isa(cax, 'matlab.graphics.axis.GeographicAxes')
        error(message('MATLAB:graphics:geoplot:AxesInput'));
    end

    % Check for lat.
    if ~isnumeric(args{1})
        validateattributes(args{1},{'numeric'},{},'','lat')
    end

    % Check for lon.
    if nargs == 1 || (nargs > 1 && ~isnumeric(args{2}))
        error(message('MATLAB:graphics:geoplot:LongitudeRequired'))
    end

    % Extract latitude and longitude values.
    lat = args{1};
    lon = args{2};
    args(1:2) = [];
    
    % Check that lat and lon are equal length
    if length(lat) ~= length(lon)
        error(message('MATLAB:graphics:geoplot:DataLengthMismatch','lon','lat'));
    end
    
    v = matlab.graphics.chart.internal.maps.GeographicDataValidator("variables");
    validateLatitude(v,lat);
    validateLongitude(v,lon);
    
    if diff([min(lon) max(lon)]) > 360
       error(message('MATLAB:graphics:geoplot:LongitudeSpans360'))
    end

    if ~isempty(args)
        % Process Name-Value pairs
        if numel(args) > 1
            [args{:}] = convertStringsToChars(args{:});
        end
        
        % Format weight input.
        if isnumeric(args{1})
            % First validate its length
            if ~isempty(args{1}) && ~isscalar(args{1}) && length(lat) ~= length(args{1})
                error(message('MATLAB:graphics:geoplot:DataLengthMismatch','weights','lat'));
            end
            args = [{'WeightData'}, args];
        end
    end

    try
        cax = matlab.graphics.internal.prepareCoordinateSystem(...
            'matlab.graphics.axis.GeographicAxes', cax, @geoaxes);
        cax = newplot(cax);
        
        autoColor = false;
        names = args(1:2:numel(args)-1);
        if iscellstr(names) || isstring(names)
            autoColor = ~startsWith('FaceColor', names, 'IgnoreCase', true);
        end
        [~,nextColor] = matlab.graphics.chart.internal.nextstyle(cax, autoColor, false, true);

        obj = matlab.graphics.chart.primitive.DensityPlot('Parent', cax, ...
            'LatitudeData', lat, 'LongitudeData', lon, 'FaceColor_I', nextColor, ...
            args{:});
    catch e
        throw(e);
    end

    obj.assignSeriesIndex();
    
    if nargout > 0
        h = obj;
    end
end
