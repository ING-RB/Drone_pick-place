function h = swarmchart(varargin)
%SWARMCHART Swarm chart.
%   SWARMCHART(x,y) displays a scatter plot where points are jittered in
%   the x dimension based on an estimate of the  kernel density in the y
%   dimension for each unique x. Swarm charts provide a visualization for
%   discrete x data that captures the distribution of y data. SWARMCHART
%   sets the maximum jitter width to be 90% of the minimum difference
%   between distinct values of x.
%
%   SWARMCHART(x,y,sz) draws the markers at the specified sizes (sz)
%   SWARMCHART(x,y,sz,c) uses c to specify color, see SCATTER for a
%   description of how to manipulate color.
%
%   SWARMCHART(...,M) uses the marker M instead of 'o'.
%   SWARMCHART(...,'filled') fills the markers
%
%   SWARMCHART(tbl,xvar,yvar) creates a swarm chart using the variables
%   xvar and yvar from table tbl. Multiple swarm charts are created if xvar
%   or yvar reference multiple variables. For example, this command creates
%   two swarm charts:
%   swarmchart(tbl, {'var1', 'var2'}, {'var3', 'var4'})
%   
%   SWARMCHART(tbl,xvar,yvar,'filled') specifies data in a table and fills
%   in the markers.
%
%   SWARMCHART(AX,...) plots into AX instead of GCA.
%   S = SWARMCHART(...) returns handles to the scatter object created.
%
%   Example:
%       x=randi(4,1000,1);
%       y=randn(1000,1);
%       SWARMCHART(x,y)
%
%   See also SCATTER, SWARMCHART3, BUBBLECHART.

%   Copyright 2020-2022 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
if nargin > 0
    validateJitterable(varargin);
end

try
    obj = scatter(varargin{:});
catch ME
    throw(ME)
end

if ~isempty(obj)
    dim = "X";
    if obj(1).YJitter == "density" && obj(1).XJitter ~= "density"
        % special case when user has specified denisty YJitter explicitly,
        % pick Jitterwidth from y instead of x
        dim = "Y";
    end

    % Select a JitterWidth based on the diff in the current dimension (or
    % choose 1 for categorical).
    if strcmp(obj(1).(dim + "JitterWidthMode"), 'auto')
        jitwidth = nan(1, numel(obj));
        for i = 1:numel(obj)
            x = obj(i).(dim + "Data_I");
            
            if iscategorical(x) || isempty(x)
                uniquex = 1;
            elseif ~isnumeric(x)
                error("MATLAB:scatter:InvalidSwarm" + dim + "Data", getString(message('MATLAB:scatter:InvalidSwarmData',dim)))
            else
                uniquex=unique(x);
            end
            
            if numel(uniquex)==1
                jitwidth(i) = .9;
            else
                jitwidth(i) = .9 * min(diff(uniquex));
            end
        end
        minjitwidth = min(jitwidth);
    end

    if dim == "X" && strcmp(obj(1).XJitterMode, 'auto')
        set(obj, "XJitter", 'density');
    end
    if strcmp(obj(1).(dim + "JitterWidthMode"), 'auto')
        set(obj, dim + "JitterWidth", minjitwidth);
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
    if any(startsWith(textargs,{'XJitterW' 'ThetaJitterW' 'LatitudeJitterW'},'IgnoreCase',true))
        return
    end
    
    ind = 1;
    if isgraphics(args{1})
        ind = ind + 1;
    end

    if numel(args)<ind
        return
    end

    if ~istabular(args{ind})
        if ~iscategorical(args{ind}) && ~isnumeric(args{ind})
            ME = MException('MATLAB:scatter:InvalidSwarmXData', message('MATLAB:scatter:InvalidSwarmData','X'));
            throwAsCaller(ME);
        end
    else
        if numel(args) < ind + 1
            return
        end
        tbl = args{ind};
        xvar = args{ind+1};
        
        try
            dataSource = matlab.graphics.data.DataSource(tbl);
            dataMap = matlab.graphics.data.DataMap(dataSource);
            dataMap = dataMap.addChannel('X',xvar);
        catch
            % If anything is wrong with making the dataMap, defer to
            % Scatter to throw
            return
        end
        for i = 1:dataMap.NumObjects
            xdata = dataSource.getData(dataMap.slice(i).X);
            if ~iscategorical(xdata{1}) && ~isnumeric(xdata{1})
                ME = MException('MATLAB:scatter:InvalidSwarmXData', message('MATLAB:scatter:InvalidSwarmData','X'));
                throwAsCaller(ME);
            end
        end
    end
end
