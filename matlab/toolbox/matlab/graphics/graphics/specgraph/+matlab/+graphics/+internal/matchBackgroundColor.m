function matchBackgroundColor(ax, obj, propName)
% This undocumented function may be removed in a future release.

% This internal function is used by charts like waterfall, mesh and fsurf  
% that need to specify a color for part of the visualization that matches 
% the background color that visualization appears on top of. 
%
% Inputs:
%   ax - handle to the axes object the visualization is parented to
%   obj - handle to the visualization object itself, e.g. Surface or Patch.
%   propName - property of the visualization object that should be updated
%              to match the background.

% Copyright 2023 MathWorks, Inc.
arguments
    ax {mustBeValidAxesOrEmpty(ax)}
    obj (1,:) matlab.graphics.primitive.Data {mustBeValidGraphics(obj)}
    propName (1,1) string {mustBeProp(obj,propName)}
end

customColor = [];
if ~isempty(ax) && (ax.ColorMode == "manual" || isequal(ax.Color,"none"))
    customColor = ax.Color;

    % If the axes background is transparent, loop through the axes's
    % ancestors until we find one that has a background color. 
    thisObj = ax;
    while isequal(customColor,"none") 
        parent = thisObj.Parent;
        if isempty(parent) || isa(parent,'matlab.ui.Root')
            % "none" will be retained as the fallback for customColor in 
            % the case where an empty parent is encountered or the case  
            % where even the Figure has a 'none' background color.
            break;
        end

        if isprop(parent,'Color')
            customColor = parent.Color;
        elseif isprop(parent,'BackgroundColor')
            customColor = parent.BackgroundColor;
        end
        thisObj = parent;
    end
end

if isempty(customColor)
    matlab.graphics.internal.themes.specifyThemePropertyMappings(obj, ...
        propName,'--mw-graphics-backgroundColor-axes-primary');
else
    set(obj,propName,customColor);
end

end

function mustBeProp(obj,propName)
    mustBeTextScalar(propName);
    errID = 'MATLAB:noSuchMethodOrField';
    msg = getString(message(errID,propName,class(obj)));
    assert(isprop(obj(1),propName),errID,msg);
end

function mustBeValidGraphics(obj)
    errID = 'MATLAB:class:InvalidHandle';
    msg = getString(message(errID));
    assert(all(isvalid(obj)), errID, msg);
end

function mustBeValidAxesOrEmpty(obj)
    if ~isempty(obj)
        mustBeScalarOrEmpty(obj);
        mustBeA(obj,'matlab.graphics.axis.AbstractAxes'); 
        mustBeValidGraphics(obj);
    end
end