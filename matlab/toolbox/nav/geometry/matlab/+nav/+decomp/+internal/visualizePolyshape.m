function visualizePolyshape(m, pds)
%visualizePolyshape - Visualize a polyshape with its events
%
%   visualizePolyshape(M, PDS) plots the given polyshape M along with
%   color-coded vertices based on their event types as defined in PDS

%   Copyright 2024-2025 The MathWorks, Inc.

%#codegen
    arguments
        m (1,1) polyshape
        pds (:, 1) struct
    end

    % Plot the polygon itself    
    plot(m);
    [xp, yp] = boundary(m);
    P = [xp yp];
    
    % Plot the color-coded points
    hold on;
    plotPoints(P(indicesOf(pds, nav.decomp.internal.EventType.In), :),'b', 'In');
    plotPoints(P(indicesOf(pds, nav.decomp.internal.EventType.Out), :),'r', 'Out');
    plotPoints(P(indicesOf(pds, nav.decomp.internal.EventType.Split), :),'c', 'Split');
    plotPoints(P(indicesOf(pds, nav.decomp.internal.EventType.Pinch), :),'m', 'Pinch');
    plotPoints(P(indicesOf(pds, nav.decomp.internal.EventType.Floor), :),'g', 'Floor');
    plotPoints(P(indicesOf(pds, nav.decomp.internal.EventType.Ceiling), :),'y', 'Ceiling');
    drawnow;
    hold off;
end


function plotPoints(points, color, str)
%plotPoints - Plot solid points of a given color
    X = points(:, 1);
    Y = points(:, 2);
    plot(X, Y, color+"O", MarkerFaceColor=color, DisplayName=str);
end


function is = indicesOf(pds, type)
%indicesOf - The indices of the events of the given type
%
%   IS = indicesOf(PDS, TYPE) are the indices of PDS corresponding to
%   events of type TYPE

    arguments (Input)
        pds (:,1) struct
        type (1,1) nav.decomp.internal.EventType
    end
    arguments (Output)
        is (1,:) {mustBeInteger, mustBePositive}
    end

    is = [];
    for i = 1:max(size(pds))
        if pds(i).type == type
            is = [is i]; %#ok<AGROW>
        end
    end
end

