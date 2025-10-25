function h = swarmchart3(varargin)
%SWARMCHART3 3-d swarm chart.
%   SWARMCHART3(x,y,z) displays a scatter plot in a 3-D view where points
%   are jittered in the x and y dimensions based on an estimate of the
%   kernel density in the z dimension for each unique combination of x and
%   y. 3-D swarm charts provide a visualization for discrete x-y data that
%   captures the distribution of z data. SWARMCHART3 sets the maximum
%   jitter width in the x and y dimensions to be 90% of the minimum
%   difference between distinct values in the respective dimensions.
%
%   SWARMCHART3(x,y,z,sz) draws the markers at the specified sizes (sz)
%   SWARMCHART3(x,y,z,sz,c) uses c to specify color, see SCATTER for a
%   description of how to manipulate color.
%
%   SWARMCHART3(...,M) uses the marker M instead of 'o'.
%   SWARMCHART3(...,'filled') fills the markers
%
%   SWARMCHART3(tbl,xvar,yvar,zvar) creates a swarm chart using the
%   variables xvar, yvar, and zvar from table tbl. Multiple swarm charts
%   are created if xvar, yvar, or zvar reference multiple variables. For
%   example, this command creates two swarm charts:
%   swarmchart3(tbl, {'var1', 'var2'}, {'var3', 'var4'}, {'var5', 'var6'})
%   
%   SWARMCHART3(tbl,xvar,yvar,zvar,'filled') specifies data in a table and
%   fills in the markers.
%
%   SWARMCHART3(AX,...) plots into AX instead of GCA.
%   S = SWARMCHART3(...) returns handles to the scatter object created.
%
%   Example:
%       x=randi(4,1000,1);
%       y=randi(4,1000,1);
%       z=randn(1000,1);
%       SWARMCHART3(x,y,z)
%
%   See also SCATTER3, SWARMCHART, BUBBLECHART3.

%   Copyright 2020-2022 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
if nargin > 0
    validateJitterable(varargin);
end

try
    obj = scatter3(varargin{:});
catch ME
    throw(ME)
end

if ~isempty(obj)
    % Collect diffs from all created series and use the minimum to set
    % XJitterWidth/YJitterWidth
    if strcmp(obj(1).XJitterWidthMode, 'auto')
        xjitwidth = nan(1, numel(obj));
        for i = 1:numel(obj)
            x = obj(i).XData;
            if iscategorical(x) || isempty(x)
                uniquex = 1;
            elseif ~isnumeric(x)
                error('MATLAB:scatter3:InvalidSwarm3XData', getString(message('MATLAB:scatter:InvalidSwarmData','X')))
            else
                uniquex=unique(x);
            end
            if numel(uniquex) == 1
                xjitwidth(i) = .9;
            else
                xjitwidth(i) = .9*min(diff(uniquex));
            end
        end
        minxjitwidth = min(xjitwidth);
    end
    
    if strcmp(obj(1).YJitterWidthMode, 'auto')
        yjitwidth = nan(1, numel(obj));
        for i = 1:numel(obj)
            y = obj(i).YData;
            if iscategorical(y) || isempty(y)
                uniquey = 1;
            elseif ~isnumeric(y)
                error('MATLAB:scatter3:InvalidSwarm3YData', getString(message('MATLAB:scatter:InvalidSwarmData','Y')))
            else
                uniquey = unique(y);
            end
            if numel(uniquey) == 1
                yjitwidth(i) = .9;
            else
                yjitwidth(i) = .9*min(diff(uniquey));
            end
        end
        minyjitwidth = min(yjitwidth);
    end

    if strcmp(obj(1).XJitterMode, 'auto')
        set(obj,'XJitter', 'density');
    end
    if strcmp(obj(1).XJitterWidthMode,'auto')
        set(obj,'XJitterWidth', minxjitwidth);
    end
    if strcmp(obj(1).YJitterMode, 'auto')
        set(obj,'YJitter', 'density');
    end
    if strcmp(obj(1).YJitterWidthMode,'auto')
        set(obj,'YJitterWidth', minyjitwidth);
    end
end

if nargout > 0
    h = obj;
end

end

function validateJitterable(args)
    % To calculate JitterWidth the Data must be categorical or numeric.
    % Validate here (when possible) before creating any Scatter objects. 

    % The user may have specified JitterWidth, in which case these values
    % shouldn't be validated. However, the combination of renameable
    % properties (e.g. ThetaJitterWidth), partial matching rules (e.g.
    % LatitudeJitterW), and the possiblity of table variables with property
    % names makes resolving this difficult. Ignore validation if there are
    % any Char or String args that begin XJitterW, ThetaJitterW,
    % LatitudeJitterW. This leans towards accepting data and letting
    % scatter throw exceptions for things that are missed here.
    textargs = string(args(cellfun(@(x)ischar(x) || (isstring(x) && isscalar(x)), args)));
    validateX = ~any(startsWith(textargs,{'XJitterW' 'ThetaJitterW' 'LatitudeJitterW'}, 'IgnoreCase',true));
    validateY = ~any(startsWith(textargs,{'YJitterW' 'RJitterW' 'LongitudeJitterW'}, 'IgnoreCase',true));
    ind = 1;
    if isgraphics(args{1})
        ind = ind + 1;
    end
    
    if numel(args) < ind
        return
    end

    if ~istabular(args{ind}) 
        if validateX && ~iscategorical(args{ind}) && ~isnumeric(args{ind})
            ME = MException('MATLAB:scatter3:InvalidSwarm3XData', message('MATLAB:scatter:InvalidSwarmData','X'));
            throwAsCaller(ME);
        end
        if validateY && numel(args) >= ind + 1 && ~iscategorical(args{ind + 1}) && ~isnumeric(args{ind + 1})
            ME = MException('MATLAB:scatter3:InvalidSwarm3YData', message('MATLAB:scatter:InvalidSwarmData','Y'));
            throwAsCaller(ME);
        end
    else
        if numel(args) < ind + 2
            return
        end

        tbl = args{ind};
        xvar = args{ind+1};
        yvar = args{ind+2};
        
        try
            dataSource = matlab.graphics.data.DataSource(tbl);
            dataMap = matlab.graphics.data.DataMap(dataSource);
            dataMap = dataMap.addChannel('X', xvar);
            dataMap = dataMap.addChannel('Y', yvar);
        catch
            % If anything is wrong with making the dataMap, defer to
            % Scatter to throw
            return
        end
        for i = 1:dataMap.NumObjects
            xdata = dataSource.getData(dataMap.slice(i).X);
            if validateX && ~iscategorical(xdata{1}) && ~isnumeric(xdata{1})
                ME = MException('MATLAB:scatter3:InvalidSwarm3XData', message('MATLAB:scatter:InvalidSwarmData','X'));
                throwAsCaller(ME);
            end
            ydata = dataSource.getData(dataMap.slice(i).Y);
            if validateY && ~iscategorical(ydata{1}) && ~isnumeric(ydata{1})
                ME = MException('MATLAB:scatter3:InvalidSwarm3YData', message('MATLAB:scatter:InvalidSwarmData','Y'));
                throwAsCaller(ME);
            end
        end
    end
end
