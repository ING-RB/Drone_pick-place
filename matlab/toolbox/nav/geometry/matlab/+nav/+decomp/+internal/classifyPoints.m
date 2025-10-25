function pds = classifyPoints(x, y)
%This function is for internal use only. It may be removed in the future.

%classifyPoints Classify each point for the given polygon.
%
%   PDS = classifyPoints(X, Y) classifies each point as a EventType
%   where X and Y are the ordered lists of x and y points, respectively

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    arguments (Input)
        x (:,1) double
        y (:,1) double
    end
    arguments (Output)
        pds (:,1) struct
    end

    P = [x y];

    % check if there is a duplicate end
    duplicateEnd = all(P(1, :) == P(end, :));

    % Remove duplicate end if it exists
    if duplicateEnd
            P = P(1:end-1, :);
    end

    nPts = size(P,1);

    % Get A and B as diff of P
    A = diff([P(end,:); P]);
    B = circshift(A, -1, 1);
    [E, dirFlags] = nav.decomp.internal.classifyAB(A,B);

    % Indices of vertices and event itself
    idxV = 1:numel(E);
    % Get next ceil/floors
    C = nav.decomp.internal.EventClassificationMatrices.NextCeilDelta;
    F = nav.decomp.internal.EventClassificationMatrices.NextFloorDelta;
    ceils = idxV + C(double(E)+1);
    floors = idxV + F(double(E)+1);
    % Must loop around if over/under
    ceils(ceils > nPts) = 1;
    floors(floors < 1) = nPts;

    % Get the indices of the friends before/after us in the winding order
    before = idxV-1;
    after = idxV+1;
    before(before < 1) = nPts;
    after(after > nPts) = 1;

    % Make the point data struct
    pds = arrayfun(@(i) nav.decomp.internal.makePointData(i,E(i),i,...
        ceils(i),floors(i),dirFlags(i),false,before(i),after(i)), idxV);
    % re-add first to the end
    if duplicateEnd
        pds = [pds pds(:,1)];
    end
end
