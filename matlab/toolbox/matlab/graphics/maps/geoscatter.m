function s = geoscatter(varargin)
%GEOSCATTER Geographic scatter plot
%   GEOSCATTER(lat,lon) displays colored circles in a geographic axes at
%   the latitude-longitude locations in degrees specified by the vectors
%   lat and lon, where lat and lon are the same size.
%
%   GEOSCATTER(lat,lon,A) sets the marker sizes, using A to specify the
%   area of each marker (in points^2). To draw all the markers with the
%   same size, specify A as a scalar. To draw the markers with different
%   sizes, specify A as a vector the same length as lat and lon. If A is
%   empty, the default size is used.
%
%   GEOSCATTER(lat,lon,A,C) sets the marker colors using C. When C is a
%   vector the same length as lat and lon, the values in C are linearly
%   mapped to the colors in the current colormap. When C is a
%   length(lat)-by-3 matrix, it directly specifies the colors of the
%   markers as RGB triplet values. C can also be a color string or
%   character vector. See ColorSpec.
%
%   GEOSCATTER(___,M) where M specifies the marker M instead of 'o'.
%
%   GEOSCATTER(___,'filled') fills the markers.
%
%   GEOSCATTER(tbl,latvar,lonvar) creates a geographic scatter plot with
%   the variables latvar and lonvar from table tbl. To plot one data set,
%   specify one variable for latvar and one variable for lonvar. To plot
%   multiple data sets, specify multiple variables for latvar, lonvar, or
%   both. If both arguments specify multiple variables, they must specify
%   the same number of variables.
%
%   GEOSCATTER(tbl,latvar,lonvar,'filled') specifies data in a table and
%   fills in the markers.
%
%   GEOSCATTER(___,Name,Value) sets scatter properties using one or more
%   name-value pair arguments. For example, the following creates a plot
%   with dark blue markers: GEOSCATTER(lat,lon,'MarkerEdgeColor',[0 0 0.6])
%
%   GEOSCATTER(gx,___) plots into the geographic axes gx instead of the
%   current axes.
%
%   S = GEOSCATTER(___) returns the Scatter object. Use S to modify
%   properties of the object after it is created.
% 
%   Use geoplot for single color, single marker size scatter plots.
% 
%   Example
%   -------
%   lon = (-170:10:170);
%   lat = 50 * cosd(3*lon);
%   A = 101 + 100*(sind(2*lon));
%   C = cosd(4*lon);
%   geoscatter(lat,lon,A,C,'^')
%
%   See also GEOAXES, GEOBASEMAP, GEOBUBBLE, GEOLIMITS, GEOPLOT, SCATTER

% Copyright 2017-2022 The MathWorks, Inc.
    
    matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
    narginchk(2,inf)
    [gx, args, nargs] = axescheck(varargin{:});
    if ~isempty(gx) ...
            && ~isa(gx, 'matlab.graphics.axis.GeographicAxes') ...
            && ~isa(gx, 'map.graphics.axis.MapAxes')
        error(message('MATLAB:graphics:geoscatter:AxesInput'))
    end

    v = matlab.graphics.chart.internal.maps.GeographicDataValidator("variables");
    if nargs > 0 && istabular(args{1})
        if nargs < 3
            error(message('MATLAB:graphics:geoscatter:LongitudeRequired'))
        end

        % Check the first two inputs are valid latitude and longitude,
        % remaining input validation will be done by the scatter command.
        dataSource = matlab.graphics.data.DataSource(args{1});
        dataMap = matlab.graphics.data.DataMap(dataSource);
        dataMap = dataMap.addChannel('lat', args{2});
        dataMap = dataMap.addChannel('lon', args{3});

        for k = 1:dataMap.NumObjects
            sliceStruct = dataMap.slice(k);
            lat = dataSource.getData(sliceStruct.lat);
            lon = dataSource.getData(sliceStruct.lon);
            validateLatitude(v,lat{1});
            validateLongitude(v,lon{1});
        end
    else
        % Check for lat.
        if ~isnumeric(args{1})
            validateattributes(args{1},{'numeric'},{},'','lat')
        end
        
        % Check for lon.
        if nargs == 1 || ~isnumeric(args{2})
            error(message('MATLAB:graphics:geoscatter:LongitudeRequired'))
        end
        
        % Check that lat and lon are equal length.
        if length(args{1}) ~= length(args{2})
            error(message('MATLAB:graphics:geoscatter:DataLengthMismatch','lon','lat'));
        end
        
        validateLatitude(v,args{1});
        validateLongitude(v,args{2});
        
        % Check that if not scalar or empty, lat and A are vectors of equal 
        % length.
        if nargs > 2 && isnumeric(args{3}) && ~isempty(args{3}) && ~isscalar(args{3}) ...
                && ~(isvector(args{3}) && numel(args{1}) == numel(args{3}))
            error(message('MATLAB:graphics:geoscatter:DataLengthMismatch','A','lat'));
        end
        
        % Check that if C is not [1 3], [n 3] or empty, lat and C are vectors
        % of equal length.
        if nargs > 3 && isnumeric(args{4}) && ~isempty(args{4}) && ...
                ~isequal(size(args{4}),[1 3]) && ...
                ~isequal(size(args{4}),[numel(args{1}) 3]) && ...
                ~(isvector(args{4}) && numel(args{1}) == numel(args{4}))
            error(message('MATLAB:graphics:geoscatter:DataLengthMismatch','C','lat'));
        end
    end
    
    try
        gx = matlab.graphics.internal.maps.prepareAxesParent(gx);
        obj = scatter(gx, args{:});
    catch e
        if strcmp(e.identifier,'MATLAB:scatter:NoDataInputs')
            error(message('MATLAB:graphics:geoscatter:NoDataInputs'))
        end
        throw(e)
    end
    
    if nargout > 0
        s = obj;
    end
end
