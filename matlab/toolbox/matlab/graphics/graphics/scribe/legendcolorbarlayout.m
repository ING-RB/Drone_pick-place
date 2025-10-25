function hAxOut = legendcolorbarlayout(hAx,action,obj)
%LEGENDCOLORBARLAYOUT Layout legend and/or colorbar around axes
%   This is a helper function for legend and colorbar. Do not call
%   directly.

%   LEGENDCOLORBARLAYOUT(AX,'addToTree',obj) adds obj as a child of the layout
%   manager, but does not add h to the inner or outer list.  The position
%   of h will not be managed by the layout manager.
%   LEGENDCOLORBARLAYOUT(AX,'addToLayout',obj) adds obj to the end of the
%   layout list.

%   Copyright 1984-2024 The MathWorks, Inc.

% First, make sure we have a valid axes:
if ~isvalid(hAx) || ~isgraphics(hAx,'matlab.graphics.axis.AbstractAxes')
    error(message('MATLAB:scribe:legendcolorbarlayout:InvalidAxes'));
elseif nargin > 2
    % Decide if we need a TiledChartLayout (TCL) or AxesLayoutManager
    % (ALM). If the axes has a TCL for a parent, make sure obj also gets
    % parented to it. If the axes isn't parented to TCL and both the axes
    % and obj have a TCL options as a Layout, it indicates we're in a
    % copyobj workflow where the axes and obj are directly being copied but
    % not the TCL. In that case, put them both in an ALM.
    if isa(hAx.Parent, 'matlab.graphics.layout.TiledChartLayout') || (isa(hAx.Layout, 'matlab.graphics.layout.TiledChartLayoutOptions') && ~isa(obj.Layout, 'matlab.graphics.layout.TiledChartLayoutOptions'))
        if nargout > 0
            hAxOut = hAx;
            if isa(hAx.Parent, 'matlab.graphics.layout.TiledChartLayout')
                obj.Parent = hAx.Parent;
            end
        end

        % We don't want to override existing layout options
        if ~isa(obj.Layout, 'matlab.graphics.layout.TiledChartLayoutOptions')
            obj.Layout = hAx.Layout;
            obj.Layout.TileMode = 'auto';
        end
    else
        hManager  = matlab.graphics.shape.internal.AxesLayoutManager.getManager(hAx);

        if nargout > 0
            hAxOut = hManager.Axes;
        end

        switch action
            case 'addToTree'
                hManager.addToTree(obj);
            case 'addToLayout'
                hManager.addToLayout(obj);
        end
    end
end
