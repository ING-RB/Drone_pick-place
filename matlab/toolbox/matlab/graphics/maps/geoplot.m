function h = geoplot(varargin)
%GEOPLOT Geographic plot 
%   GEOPLOT(lat,lon) plots a line in a geographic axes with vertices at 
%   the latitude-longitude locations in degrees specified by the vectors
%   lat and lon, where lat and lon are the same size.
%
%   GEOPLOT(lat,lon,LineSpec) uses a LineSpec to specify the line style,
%   marker symbol, and color for the line.
%
%   GEOPLOT(lat1,lon1,...,latN,lonN) combines the plots specified by
%   several sets of latitudes and longitudes.
%
%   GEOPLOT(lat1,lon1,LineSpec1,...,latN,lonN,LineSpecN) combines the
%   plots specified by several sets of latitudes and longitudes, with a
%   separate LineSpec for each line.
%
%   GEOPLOT(tbl,latvar,lonvar) plots the variables latvar and lonvar from
%   the table tbl. To plot one data set, specify one variable for latvar
%   and one variable for lonvar. To plot multiple data sets, specify
%   multiple variables for latvar, lonvar, or both. If both arguments
%   specify multiple variables, they must specify the same number of
%   variables.
%
%   GEOPLOT(___,Name,Value) specifies line properties using one or more
%   name-value arguments.
%
%   GEOPLOT(gx,___) plots in the geographic axes specified by gx instead of
%   the current axes.
%
%   H = GEOPLOT(___) returns a column vector of Chart Line objects, one
%   object per plotted line. Use H to modify the properties of the objects
%   after they area created.
%
%   These next syntaxes require Mapping Toolbox (TM). You can use these
%   syntaxes with the additional LineSpec, Name,Value, and gx inputs and
%   the H output.
%
%   GEOPLOT(SHAPE) plots the shapes specified by the scalar or vector
%   geopointshape, geolineshape, geopolyshape, mappointshape, maplineshape,
%   or mappolyshape object SHAPE. For more information see the help for
%   each shape object, such as "help geopolyshape/geoplot".
%
%   GEOPLOT(GT) plots the point, line, or polygon shapes in the Shape table
%   variable specified by the geospatial table GT.
%
%   Example
%   -------
%   latSeattle = 47.62;
%   lonSeattle = -122.33;
%   latAnchorage =  61.20;
%   lonAnchorage = -149.9;
%   geoplot([latSeattle latAnchorage],[lonSeattle lonAnchorage],'g-*')
%
%   Example (requires Mapping Toolbox)
%   -------
%   GT = readgeotable("worldlakes.shp");
%   geoplot(GT)
%
%   See also GEOAXES, GEOBASEMAP, GEOBUBBLE, GEOSCATTER, PLOT

% Copyright 2017-2022 The MathWorks, Inc.

    matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
    narginchk(1,inf)
    [gx, args, nargs] = axescheck(varargin{:});
    if ~isempty(gx) ...
            && ~isa(gx, 'matlab.graphics.axis.GeographicAxes') ...
            && ~isa(gx, 'map.graphics.axis.MapAxes')
        error(message('MATLAB:graphics:geoplot:AxesInput'))
    end
    
    if nargs > 0
        v = matlab.graphics.chart.internal.maps.GeographicDataValidator("variables");

        % Check for tabular input.
        if isa(args{1},'tabular')
            % Check for Mapping Toolbox geospatial table input.
            if matlab.graphics.internal.maps.isgeotable(args{1})
                % Forward on to Mapping Toolbox.
                obj = map.graphics.internal.geotableplot(gx, args);
                if nargout > 0
                    h = obj;
                end
                return
            end

            % Core MATLAB support for non-geospatial tables.
            if nargs < 3
                error(message('MATLAB:graphics:geoplot:LongitudeRequired'))
            end
    
            % Check the first two inputs are valid latitude and longitude,
            % remaining input validation will be done by the plot command.
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
            % Throw an error if we encounter any of the following patterns:
            %
            %    geoplot(<numeric>)                geoplot(gx, <numeric>)
            %    geoplot(<numeric>, LineSpec)      geoplot(gx, <numeric>, LineSpec)
            %    geoplot(<numeric>, Name, Value)   geoplot(gx, <numeric>, Name, Value)
            %
            % plot (and polarplot) support syntaxes like these -- where the numeric
            % placeholder is Y (for plot) and R or Z (for polarplot) -- but there
            % is no geoplot counterpart. Both latitude and longitude are required
            % when calling geoplot.
    
            % Check for lat.
            if ~isnumeric(args{1})
                validateattributes(args{1},{'numeric'},{},'','lat')
            end
            
            % Check for lon.
            if nargs == 1 || ~isnumeric(args{2})
                error(message('MATLAB:graphics:geoplot:LongitudeRequired'))
            end
            
            % Check that lat and lon are equal length.
            if numel(args{1}) ~= numel(args{2})
                error(message('MATLAB:graphics:geoplot:DataLengthMismatch','lon','lat'));
            end
            
            validateLatitude(v,args{1});
            validateLongitude(v,args{2});
        end
    end
    
    try
        gx = matlab.graphics.internal.maps.prepareAxesParent(gx);
        obj = plot(gx, args{:});
    catch e
        if strcmp(e.identifier,'MATLAB:plot:DataPairsMismatch')
            error(message('MATLAB:graphics:geoplot:DataPairsMismatch'))
        end
        throw(e)
    end
    
    if nargout > 0
        h = obj;
    end
end
