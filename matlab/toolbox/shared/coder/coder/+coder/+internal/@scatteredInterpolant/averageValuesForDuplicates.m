function averagedVal = averageValuesForDuplicates(delTriObj, inputVal)
% Average out the values for duplicate input points.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
if delTriObj.dupesExist
    % Duplicates are present in input set
    coder.internal.warning('MATLAB:mathcgeo_catalog:DupPtsAvValuesWarnId');
    % Number of values to fill for multi-valued interpolations.
    nFuncVal = coder.internal.prodsize(inputVal, 'above', 1);

    % Explicit call using size, so that we can upper-bound the size of averagedVal
    dimsV = size(inputVal);
    dimsV(1) = size(delTriObj.thePoints, 2);

    nIn = coder.internal.indexInt(size(inputVal, 1));
    numUnique = coder.internal.indexInt(dimsV(1));

    averagedVal = zeros(dimsV, 'like', inputVal);
    numDupsOfIdx = zeros(numUnique, 1, 'like', inputVal); % Same class to perform divison.
    numIn = coder.internal.indexInt(length(delTriObj.idxMap));
    for i = 1:numIn
        mappedIdx = coder.internal.indexInt(delTriObj.idxMap(i));
        numDupsOfIdx(mappedIdx) = numDupsOfIdx(mappedIdx) + 1;
        for j = 0:nFuncVal-1
            averagedVal(mappedIdx + j*numUnique) = averagedVal(mappedIdx + j*numUnique) + inputVal(i + j*(nIn));
        end
    end

    for i = 1:numUnique
        for j = 0:nFuncVal-1
            if isinf(averagedVal(i + j*numUnique))
                averagedVal(i + j*numUnique) = nan;
            elseif ~isnan(averagedVal(i + j*numUnique))
                averagedVal(i + j*numUnique) = averagedVal(i + j*numUnique)/numDupsOfIdx(i);
            end
        end
    end
else
    averagedVal = inputVal;
end
