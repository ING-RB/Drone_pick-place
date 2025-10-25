function map = colormap(arg1,arg2)
%COLORMAP Color look-up table.
%   COLORMAP(MAP) sets the current figure's colormap to MAP.
%
%   COLORMAP('default') sets the current figure's colormap to
%   the root's default, whose setting is PARULA.
%
%   COLORMAP(TARGET,...) sets the colormap for the figure, axes, or chart
%   specified by TARGET. After setting the axes colormap, the figure
%   colormap does not affect the axes.
%
%   MAP = COLORMAP(...) returns the three-column matrix of RGB triplets
%   defining the colormap of the target or the current figure.
%
%   A colormap matrix may have any number of rows, but it must have
%   exactly 3 columns. Each row is interpreted as a color, with the
%   first element specifying the intensity of red light, the second
%   green, and the third blue. Color intensity can be specified on the
%   interval 0.0 to 1.0.
%   For example, [0 0 0] is black, [1 1 1] is white,
%   [1 0 0] is pure red, [.5 .5 .5] is gray, and
%   [127/255 1 212/255] is aquamarine.
%
%   Graphics objects that use pseudocolor -- SURFACE and PATCH objects,
%   which are created by the functions MESH, SURF, and PCOLOR -- map
%   a color matrix, C, whose values are in the range [Cmin, Cmax],
%   to an array of indices, k, in the range [1, m].
%   The values of Cmin and Cmax are either min(min(C)) and max(max(C)),
%   or are specified by CLIM. The mapping is linear, with Cmin
%   mapping to index 1 and Cmax mapping to index m. The indices are
%   then used with the colormap to determine the color associated
%   with each matrix element. See CLIM for details.
%
%   Type HELP GRAPH3D to see a number of useful colormaps.
%
%   COLORMAP is a function that sets the Colormap property of a figure.
%
%   See also HSV, CLIM, BRIGHTEN, RGBPLOT, FIGURE, COLORMAPEDITOR.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.graphics.internal.isCharOrString;
arg = 0;
if nargin == 0
    figH = gcf;
elseif isCharOrString(arg1) || length(arg1) > 1 || isempty(arg1)
    % string input (check for valid option later)
    if nargin == 2
        error(message('MATLAB:colormap:InvalidFirstArgument'));
    end
    figH = gcf;
    if isCharOrString(arg1)
        arg = lower(arg1);
    else
        arg = arg1;
    end
else
    % figH can be any object that can contain a colormap
    figH = getMapContainer(arg1);
    if isempty(figH)
        error(message('MATLAB:colormap:NeedScalarHandle'));
    end

    % check for string option
    if nargin == 2
        if isCharOrString(arg2)
            arg = lower(arg2);
        else
            arg = arg2;
        end
    end
end

if isequal(arg,0)
    map = get(figH, 'Colormap');
    return
end
if isCharOrString(arg)
    % For indexing purpose, convert arg to char.
    arg = char(arg);
    if strcmp(arg,'default')
        p = findprop(figH, 'Colormap');
        if isa(figH, 'matlab.graphics.chart.Chart') && p.HasDefault
            arg = p.DefaultValue;
        else
            fig = ancestor(figH,'figure');
            arg = get(fig,'defaultfigureColormap');
        end
    else
        k = min(strfind(arg,'('));
        if ~isempty(k)
            arg = feval(arg(1:k-1),str2double(arg(k+1:end-1)));
        else
            arg = feval(arg);
        end
    end
end
if ~isempty(arg)
    if size(arg,2) ~= 3
        error(message('MATLAB:colormap:InvalidNumberColumns'));
    end

    if ~isa(arg,'uint8') && (min(arg,[],'all') < 0 || max(arg,[],'all') > 1)
        error(message('MATLAB:colormap:InvalidInputRange'))
    end
end
set(figH, 'Colormap', arg);
if nargout == 1
    map = get(figH, 'Colormap');
end
end
