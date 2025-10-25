function isWithin = isPositionWithinBounds(position, bounds)
    % Check if a giving position is within a bounds
    % All input are 1x4 array

    %    Copyright 2023 The MathWorks, Inc.
    
    isWithin = false;

    if position(1) >= bounds(1) ...
            && (abs(position(1) - bounds(1)) + position(3)) <= bounds(3) ...
            && position(2) >= bounds(2) ...
            && (abs(position(2) - bounds(2)) + position(4)) <= bounds(4)
        isWithin = true;
    end
end

