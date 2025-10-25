function labelVertex = calcLabelVertexData(ax, lw, va, ha)
%Calculates label vertex relative to anchor point and adjusts for the
%linewidth

%   Copyright 2018 The MathWorks, Inc.

    labelVertex = single([0;0;0]);           
    adjust = lw/2;
    keys = {'top', 'middle', 'bottom', 'right', 'center', 'left'};
    values = {adjust, 0, -adjust, adjust, 0, -adjust};
    map = containers.Map(keys, values);
    switch ax
        case 'y'
            labelVertex(2) = map(va);
        case 'x'
            labelVertex(1) = map(ha);
    end
end
