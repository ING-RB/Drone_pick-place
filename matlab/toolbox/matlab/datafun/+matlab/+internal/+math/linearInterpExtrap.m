function yVals = linearInterpExtrap(xVals,yVals,valueToReplace,valueIsPresent,usingSP)
% FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
% Its behavior may change, or it may be removed in a future release.
%
% xVals and yVals should be double or single numeric types. If xVals or
% yVals a different datatype, the function may not work as expected or
% error unhelpfully. Use at your own risk.
%
% All inputs (other than usingSP) are column vectors.
%
% valueToReplace/valueIsPresent are logical maps on xVals/yVals indicating
%     whether the corresponding value of yVals will be replaced or is valid
%     as an anchor point for interpolation/extrapolation. For filloutliers,
%     it is possible for a value to not be replaced AND not be present 
%     (ex: NaN values).
%
% If SamplePoints are NOT used (usingSP=false), then xVals and the vector
%     (1:numel(yVals))' are interchangeable.

% Copyright 2024 The MathWorks, Inc.

firstTwoPresentInds = find(valueIsPresent,2);
lastTwoPresentInds  = find(valueIsPresent,2,'last');
firstPresentInd     = firstTwoPresentInds(1);
secondPresentInd    = firstTwoPresentInds(2);
penultPresentInd    = lastTwoPresentInds(1);
ultimatePresentInd  = lastTwoPresentInds(2);

replaceAllMissing = all(valueToReplace|valueIsPresent);
if replaceAllMissing
    % Every value that is not present will be replaced
    valueIsMissing  = valueToReplace;
    indsExtrapLeft  = (1:firstPresentInd-1)';
    indsExtrapRight = (ultimatePresentInd+1:numel(yVals))';
else
    % There are values that are not present and also not being replaced
    valueIsMissing  = ~valueIsPresent;
    indsExtrapLeft  = find(valueToReplace(1:firstPresentInd-1));
    indsExtrapRight = find(valueToReplace(ultimatePresentInd+1:end))+ultimatePresentInd;
end

if any(valueToReplace(firstPresentInd:ultimatePresentInd)) % Interpolate
    indsInterp = find(valueIsMissing(firstPresentInd:ultimatePresentInd)) + firstPresentInd-1;
    [indsLeft,indsRight] = findNeighbors(valueIsPresent,indsInterp);
    if ~replaceAllMissing
        % This branch is typically hit when there is missing data in filloutliers
        middleMissing = valueIsMissing(firstPresentInd:ultimatePresentInd);
        middleReplace = valueToReplace(firstPresentInd:ultimatePresentInd);
        missingValuesToReplace = middleReplace(middleMissing);
        indsInterp = indsInterp(missingValuesToReplace);
        indsLeft   = indsLeft(missingValuesToReplace);
        indsRight  = indsRight(missingValuesToReplace);
    end
    yVals = performInterpExtrap(xVals, yVals, usingSP, indsLeft, indsRight, indsInterp);
end

if ~isempty(indsExtrapLeft) % Extrapolate left
    yVals = performInterpExtrap(xVals, yVals, usingSP, firstPresentInd, secondPresentInd, indsExtrapLeft);
end

if ~isempty(indsExtrapRight) % Extrapolate right
    yVals = performInterpExtrap(xVals, yVals, usingSP, penultPresentInd, ultimatePresentInd, indsExtrapRight);
end
end

function [indsLeft,indsRight] = findNeighbors(valueIsPresent,indsInterp)
% This block walks through the indicies in indsInterp (missingInd),
% keeping track of the last present index with prevPresentInd, as well
% as the start of each block of missing values with startInd (startInd
% and indsInterpInd are indices of indsInterp).
% When the index preceding missingInd is present, record it into
% startInd. When the index following missingInd is present, record
% the nearest present indices to the left and right of the contiguous
% block of missing indices.
nInds = numel(indsInterp);
indsLeft  = zeros(nInds,1); % Nearest present ind to the left
indsRight = zeros(nInds,1); % Nearest present ind to the right
for indsInterpInd = 1:nInds
    missingInd = indsInterp(indsInterpInd);
    if valueIsPresent(missingInd-1)     % Previous index is present, new block
        startInd = indsInterpInd;
        prevPresentInd = missingInd-1;  % Update previous present ind
    end
    if valueIsPresent(missingInd+1)     % Next index is present, end of block
        nextPresentInd = missingInd+1;  % Update next present ind
        for ind = startInd:indsInterpInd
            indsLeft(ind)  = prevPresentInd;
            indsRight(ind) = nextPresentInd;
        end
    end
end
end

function yVals = performInterpExtrap(xVals, yVals, usingSP, indsLeft, indsRight, missingInds)
if usingSP % SamplePoints
    xValsLeft  = xVals(indsLeft);
    xValsRight = xVals(indsRight);
    xValsQuery = xVals(missingInds);
else
    xValsLeft  = indsLeft;
    xValsRight = indsRight;
    xValsQuery = missingInds;
end
yValsLeft  = yVals(indsLeft);
yValsRight = yVals(indsRight);

denominator = xValsRight-xValsLeft;
weightedDist = (xValsQuery-xValsLeft)./denominator;
yVals(missingInds) = (1-weightedDist).*yValsLeft + weightedDist.*yValsRight;
end
