function gx = geoaxes(varargin)
%GEOAXES Create geographic axes
%   GEOAXES, by itself, creates a GeographicAxes object in the current
%   figure using default property values.
%
%   GEOAXES(Name,Value) specifies GeographicAxes properties using one or
%   more Name,Value pair arguments.
%
%   GEOAXES(parent,___) creates the axes in the figure, panel, or
%   tab specified by parent.
%
%   gx = GEOAXES(___) returns the GeographicAxes object. Use gx to modify
%   properties of the axes after it is created.
%
%   GEOAXES(gx) makes existing geographic axes gx the current axes.
%
%   Execute get(gx), where gx is a GeographicAxes object, to see a list of
%   GeographicAxes properties and their current values. Execute set(gx) to
%   see a list of GeographicAxes properties and legal property values.
%
%   See also AXES, SUBPLOT, FIGURE, GCA, CLA,
%       GEOBASEMAP, GEOLIMITS, GEOPLOT, GEOSCATTER, GEOTICKFORMAT

% Copyright 2017-2022 The MathWorks, Inc.
    
    if nargin >= 1 && isa(varargin{1}, 'matlab.graphics.axis.GeographicAxes')
        % geoaxes(gx) -- with one input -- makes GeographicAxes gx current.
        if nargin > 1
            error(message('MATLAB:graphics:geoaxes:IncorrectInputArgs'))
        end
        obj = varargin{1};
        % OK to use validateattributes here because gx is homogeneous.
        validateattributes(obj,{'matlab.graphics.axis.GeographicAxes'},{'scalar'},'','gx')
        if ~isgraphics(obj)
            error(message('MATLAB:graphics:geoaxes:InvalidObject'))
        end
        nargoutchk(0,0)
        
        fig = ancestor(obj,'figure');
        if isempty(fig) || ~isvalid(fig)
            error(message('MATLAB:graphics:geoaxes:NoAncestorFigure'))
        else
            fig.CurrentAxes = obj;
            % The following will not show a change in CurrentFigure of
            % groot if HandleVisibilility is 'off' (which is always true in
            % a uifigure), which is consistent with the behavior of axes.
            set(groot,'CurrentFigure',fig)
            if get(groot,'CurrentFigure') == fig
                figure(fig)  % Raise figure to the top.
            end
        end
    else
        % Validate and assign parent.
        if nargin > 0
            firstArg = varargin{1};
            if isa(firstArg, 'matlab.graphics.Graphics') ...
                    && ~isa(firstArg, 'matlab.graphics.axis.AbstractAxes') ...
                    && ~isa(firstArg, 'matlab.graphics.chart.Chart')
                % If the first argument is a valid graphics object, assign
                % it to parent, and remove it from varargin. Other axes and
                % charts are filtered. They result in an InvalidParent
                % error in the else condition. Other invalid parents (e.g.
                % a line object) error in the try-block below.
                parent = firstArg;
                matlab.graphics.internal.validateScalarArray(parent, ...
                    {'matlab.graphics.Graphics'}, '', 'parent')
                if ~isvalid(parent)
                    % Parent cannot be a deleted graphics object.
                    error(message('MATLAB:graphics:geoaxes:DeletedParent'))
                end
                varargin(1) = [];
            else
                % Parent is not the first argument.
                if ~(ischar(firstArg) || isStringScalar(firstArg))
                    % Error because the first argument cannot be the name
                    % in a Name,Value pair.
                    error(message('MATLAB:hg:InvalidParent','geoaxes', ...
                        fliplr(strtok(fliplr(class(firstArg)), '.'))));
                elseif parentIsNameValuePair(varargin)
                    % If parent is specified as a Name,Value pair, we pass
                    % an empty parent that is overriden by the later
                    % Name,Value pair.
                    parent = matlab.graphics.GraphicsPlaceholder.empty;
                else
                    % If parent is not the first argument and not specified
                    % as a Name,Value pair, use gcf.
                    parent = gcf();
                end
            end
        else
            % If there are no inputs, use gcf.
            parent = gcf();
        end
        % parent will be the first input, gcf, or empty.
        
        try
            obj = matlab.graphics.axis.GeographicAxes('Parent',parent,varargin{:});
        catch e
            throw(e)
        end
        
        fig = ancestor(obj,'figure');
        if ~isempty(fig) && isvalid(fig)
            fig.CurrentAxes = obj;
        end
    end
    
    if nargout > 0
        gx = obj;
    end
end


function tf = parentIsNameValuePair(inputs)
% Return true if 'parent' or a partial-name match of 'parent' is contained
% in cell array INPUTS. INPUTS is expected to contain name-value elements.

    if ~isempty(inputs)
        [inputs{:}] = convertStringsToChars(inputs{:});
        
        % Ignore the last value if the length of the name-value list is odd.
        n = 2*floor(numel(inputs)/2);
        parent = 'parent';
        tf = false;
        for k = 1:2:n
            name = inputs{k};
            if strncmpi(parent, name, numel(name))
                % Found a match.
                tf = true;
                break
            end
        end
    else
        tf = false;
    end
end
