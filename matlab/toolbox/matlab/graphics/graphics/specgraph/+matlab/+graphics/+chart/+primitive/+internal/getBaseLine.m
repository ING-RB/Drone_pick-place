function result = getBaseLine(obj, isInternal, axis)
%

%   Copyright 2023 The MathWorks, Inc.
result = matlab.graphics.GraphicsPlaceholder;
if ~isempty(obj)
    ax = ancestor(obj, 'matlab.graphics.axis.AbstractAxes','node');
    if ~isempty(ax)
        xyzname = 'YBaseline';
        abcname = 'BaselineB';
        if (axis == 0)
            xyzname = 'XBaseline';
            abcname = 'BaselineA';
        elseif (axis == 2)
            xyzname = 'ZBaseline';
            abcname = 'BaselineC';
        end

        tm = ax.TargetManager;

        if isInternal
            % For 'xyzname', avoid causing an update by querying _IS
            % property. Ignore 'abcname' since it's used for yyaxis which
            % doesn't cause an update when querying its baseline.
            xyzname = [xyzname '_IS'];
        end

        if isempty(tm) || isscalar(tm.Targets)
            % Non-yyaxis case
            result = get(ax,xyzname);
        else
            % For yy-axis case, need to figure out which one
            pt = tm.whichTargetContains(obj);
            if ~isempty(pt)
                result = get(pt,abcname);
            end
        end
    end
end
end