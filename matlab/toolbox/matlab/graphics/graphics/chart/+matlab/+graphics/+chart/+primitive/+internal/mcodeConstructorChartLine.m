function mcodeConstructorChartLine(obj,code)
% Internal code generation method

% Generate code for "plot", "plot3", "loglog", & "semilog[x,y]"

% Copyright 2003-2021 The MathWorks, Inc.

import matlab.graphics.chart.primitive.internal.mcodeConstructorHelper

channels = ["X", "Y", "Z"];

% Valid matrix syntaxes in order of priority:
matrixSyntaxes = logical([
    1, 1, 1; % plot3(x, y, z)
    1, 1, 0; % plot(x, y)
    0, 1, 0; % plot(y)
    ]);

% Valid table syntaxes in order of priority:
tableSyntaxes = logical([
    1, 1, 1; % plot3(tbl, x, y, z)
    1, 1, 0; % plot(tbl, x, y)
    0, 1, 0; % plot(tbl, y)
    ]);

% Find out which syntax to use by inspecting the object.
[positionalChannels, propertyNames] = mcodeConstructorHelper.getPositionalArguments(obj, channels, matrixSyntaxes, tableSyntaxes);

% Check for 2D vs. 3D syntaxes by looking for whether "Z" is included.
if any(positionalChannels == "Z")
    setConstructorName(code,'plot3');
else
    isLogX = false;
    isLogY = false;
    ax = ancestor(obj,'axes');
    if isscalar(ax)
        isLogX = ax.XScale == "log";
        isLogY = ax.YScale == "log";
    end

    % The axes mcodeConstructor method will ignore the XScale and YScale
    % properties if it is a simple log plot.
    if (isLogX && isLogY)
        setConstructorName(code, 'loglog');
    elseif (isLogX)
        setConstructorName(code, 'semilogx');
    elseif (isLogY)
        setConstructorName(code, 'semilogy');
    else
        setConstructorName(code, 'plot');
    end
end

% Merge together objects that are compatible.
[objs, momentoList] = mcodeConstructorHelper.findCompatibleObjects(obj, code, channels);

% Make sure 'Color' is generated as a name/value pair when necessary.
% If the value of 'Color' happens to equal black (the default), the default
% behavior will skip the property.
for n = 1:numel(objs)
    if objs(n).ColorMode == "manual"
        prop = findobj(momentoList(n).PropertyObjects, 'Name', 'Color');
        if isempty(prop)
            prop = codegen.momentoproperty;
            prop.Name = 'Color';
            prop.Value = objs(n).Color;
            momentoList(n).PropertyObjects = [momentoList(n).PropertyObjects prop];
        end
    end
end

% Finish generating the code.
mcodeConstructorHelper.generateCode(objs, code, channels, positionalChannels, propertyNames, momentoList);

end
