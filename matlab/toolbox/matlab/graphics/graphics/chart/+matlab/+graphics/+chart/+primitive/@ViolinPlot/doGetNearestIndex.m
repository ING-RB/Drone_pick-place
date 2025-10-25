function varargout = doGetNearestIndex(obj, index)
%

%  Copyright 2024 The MathWorks, Inc.

numXGroups = obj.XNumGroups;
numPoints = obj.numEvalPts;

if strcmp(obj.DensityDirection_I,'both')
    numIndices = 2*numXGroups*numPoints;
else
    numIndices = numXGroups*numPoints;
end

% Constrain index to be in the range [1 numIndices]
if numIndices>0
    index = max(1, min(index, numIndices));
end
varargout{1} = index;  % What happens if numIndices<=0?
end
