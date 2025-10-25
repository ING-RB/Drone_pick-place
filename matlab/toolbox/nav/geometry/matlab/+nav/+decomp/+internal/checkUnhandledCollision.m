function [isCollision, endEventIdx] = checkUnhandledCollision(refPoint, startEventIdx, eventIndices, points, pds)
%checkUnhandledCollision - Identifies all points that match the refPoint
%   [isCollision, endEventIdx] = checkUnhandledCollision(refPoint, startEventIdx, eventIndices, points, pds)
%   returns isCollision==true if the vertex of the startEventIdx'th event 
%   is the same as the refPoint. In the case of multiple coincident events, 
%   endEventIdx is the index of the last coincident event

%   Copyright 2024 The MathWorks, Inc.
%#codegen
  
    numCoincident = 0;
    % Keep looking until we find an event that is not a collision
    for curEventIdx = startEventIdx:numel(eventIndices)
        curPd = pds(eventIndices(curEventIdx));
        checkPoint = points(curPd.vertexId, :);
        % stop looking if a bypass is hit; indicates we have been here
        % already and dealt with collisions
        if curPd.bypassCoincidenceCheck || ~ismember(refPoint, checkPoint, 'rows')
            break;
        else
            % do not use tolerance, looking for exact collisions only
            numCoincident = numCoincident + 1;
        end

    end

    endEventIdx = startEventIdx+numCoincident-1;
    isCollision = numCoincident > 0;
end
