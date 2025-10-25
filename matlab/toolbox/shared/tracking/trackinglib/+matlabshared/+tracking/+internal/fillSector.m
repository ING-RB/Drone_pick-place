function h = fillSector(center, radius, sector, fillcolor, edgecolor, opacity)
    %fillSector: fills a circular sector
    % center - a two dimensional position [x, y] for the circle's center.
    % radius - a positive scalar for the circle radius
    % sector - a vector with two values, start and end angles of the sector
    % fillcolor - the RGB values for the face color, e.g., [1 0 0] is red.
    %           The default fillcolor is black.
    % edgecolor - the RGB values for the edge color. The default is the
    %           same color as fillcolor.
    % opacity - a value from 0 to 1 of how opaque the face should be. The
    %           default is 1.
    % Example: draw a sector centered at the origin with radius of 50 and
    % angles from 45 degrees (pi/4) to 60 degrees (pi/3). Use red ([1 0 0])
    % for both the face and the edge colors and make it 90% transparent:
    %    h = plotSector([0,0], 50, [pi/4, pi/3], [1 0 0], [1 0 0], 0.1)
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    if nargin < 1
        center = [0 0];
    end
    if nargin < 2
        radius = 1;
    end
    if nargin < 3
        sector = [0 2*pi];
    end
    if nargin < 4
        fillcolor = [0 0 0];
    end
    if nargin < 5
        edgecolor = fillcolor;
    end
    if nargin < 6
        opacity = 1;
    end
    
    validateattributes(center, {'numeric'}, {'real', 'nonempty', 'finite', ...
        'numel', 2}, 'fillSector', 'center', 1);
    validateattributes(radius, {'numeric'}, {'real', 'scalar', 'nonempty', ...
        'positive', 'finite'}, 'fillSector', 'radius', 2);
    validateattributes(sector, {'numeric'}, {'real', 'nonempty', 'finite', ...
        'numel', 2}, 'fillSector', 'sector', 3);
    validateattributes(fillcolor, {'numeric'}, {'real', 'size', [1 3], ...
        'nonnegative', '<=', 1}, 'fillSector', 'fillcolor', 4);
    validateattributes(edgecolor, {'numeric'}, {'real', 'size', [1 3], ...
        'nonnegative', '<=', 1}, 'fillSector', 'edgecolor', 5);
    validateattributes(opacity, {'numeric'}, {'real', 'scalar', ...
        'nonnegative', '<=', 1}, 'fillSector', 'opacity', 6);
    
    % Casting everything to double:
    center = cast(center, 'double');
    radius = cast(radius, 'double');
    sector = cast(sector, 'double');
    fillcolor = cast(fillcolor, 'double');
    edgecolor = cast(edgecolor, 'double');
    opacity = cast(opacity, 'double');
    
    while sector(2) < sector(1)
        sector(2) = sector(2) + 2*pi;
    end
    
    angles = linspace(sector(1), sector(2));
    x = center(1) + radius * cos(angles);
    y = center(2) + radius * sin(angles);
    x = [x, center(1), x(1)];
    y = [y, center(2), y(1)];
    if nargout == 0
        fill(x, y, fillcolor, 'edgecolor', edgecolor, 'FaceAlpha', opacity);
    else
        h = fill(x, y, fillcolor, 'edgecolor', edgecolor, 'FaceAlpha', opacity);
    end
end