function [msg, varargout] = findMatchingDimensions(varargin)
% This function is undocumented and may change in a future release.

%   Copyright 2019-2023 The MathWorks, Inc.

narginchk(2,inf);

% Default outputs
msg = '';
numVars = numel(varargin);
varargout = [varargin {numVars+1}]; % Last output indicates index of first bad input.

% Collect the sizes of all the input matrices and make sure they are all
% either 1D or 2D matrices.
sz = zeros(numVars, 2);
for n = 1:numVars
    if ~ismatrix(varargin{n})
        msg = 'MATLAB:xychk:non2DInput';
        varargout{numVars+1} = n;
        return
    end
    sz(n,:) = size(varargin{n});
end
numElements = prod(sz,2);
isVector = sz(:,1) == 1 | sz(:,2) == 1;
isScalar = numElements == 1;

% Make sure the size of all 2D matrices are the same.
matrixSizes = sz(~isVector,:);
[~,uniqueRows] = unique(matrixSizes,'rows','stable');

% If more than one matrix size, then error.
if numel(uniqueRows) > 1
    % Find the first matrix input that doesn't match the rest.
    badMatrixRow = uniqueRows(2);
    matrixLocs = find(~isVector);
    varargout{numVars+1} = matrixLocs(badMatrixRow);
    if numVars == 2
        msg = 'MATLAB:xychk:XAndYSizeMismatch'; 
    elseif numVars > 2
        msg = 'MATLAB:graphics:chart:MatrixSizeMismatch';
    end 
    return
end

% If all the inputs are matrices that are the same size then return early.
if all(~isVector) || all(isScalar)
    return
end

% For performance reasons (in the case of large matrices), instead of
% transposing matrices, keep track of whether each input needs to be
% transposed or not. If inputs are valid, the matrices returned will have 
% one column for each object to be created and one row for each data point.
flip = false(numVars, 1);

firstVector = find(isVector & ~isScalar, 1);

% Check if there are any scalar inputs.
if any(isScalar)
    % If any input is scalar, then all objects will have 1 data point each.
    % Flag that any vertically oriented vectors will need to be flipped.
    refNumPoints = 1;
    flip(isVector & sz(:,2) == 1) = true;
else
    % No input is scalar, so all objects will have >1 data points. 
    % Flag that any horizontally oriented vectors will need to be flipped.
    refNumPoints = numElements(firstVector);
    flip(isVector & sz(:,1) == 1) = true;
end

% Transpose any matrices whose first dimension doesn't match refNumPoints.
flip(~isVector & sz(:,1) ~= refNumPoints) = true;

% At this point, the "number of points" in all the inputs should match. If
% they don't, then error.
numPoints = sz(:,1);
numPoints(flip) = sz(flip,2);
if any(numPoints ~= refNumPoints)
    % Find the first input that doesn't match the rest.
    varargout{numVars+1} = find(numPoints ~= numPoints(1),1);
    if numVars == 2
        if isScalar(1)
            msg = 'MATLAB:xychk:YNotAVectorScalarX';
        elseif isVector(1) && isVector(2)
            msg = 'MATLAB:xychk:XAndYLengthMismatch';
        elseif isVector(1)
            % For compatibility, throw existing error when first input is a 
            % vector and 2nd input is a matrix.
            msg = 'MATLAB:xychk:lengthXDoesNotMatchNumAnyDimY';
        else
            % One vector is present which does not match any dimension of 
            % the other matrix. (Matrix dimension mismatches were handled 
            % earlier.)
            msg = 'MATLAB:graphics:chart:VectorDoesNotMatchDimOtherInputs';
        end
    else % 3+ inputs
        if any(isScalar)
            msg = 'MATLAB:graphics:chart:ScalarOtherInputsVectors';
        elseif all(isVector)
            msg = 'MATLAB:graphics:chart:AllVectorSizeMismatch';
        else 
            % At least one vector is present which does not match any 
            % dimension of the other matrices. (Matrix dimension mismatches
            % were handled earlier.)
            msg = 'MATLAB:graphics:chart:VectorDoesNotMatchDimOtherInputs';
        end
    end
    return
end

numObjects = sz(:,2);
numObjects(flip) = sz(flip,1);

% At this point, the "number of objects" in all the inputs should either 
% match each other or equal 1. If not, error.
refNumObjects = 1;
firstNumObjGreaterThan1 = find(numObjects ~= 1, 1);
if ~isempty(firstNumObjGreaterThan1)
    refNumObjects = numObjects(firstNumObjGreaterThan1);
    if ~all(numObjects == 1 | numObjects == refNumObjects)
        % Find the first input that doesn't match the rest.
        varargout{numVars+1} = find(numObjects ~= 1 & numObjects ~= refNumObjects,1);
        msg = 'MATLAB:graphics:chart:AllVectorSizeMismatch';
        return
    end
end

% If necessary, transpose each input and replicate the number of columns of
% each input to match.
for n = 1:numVars
    if flip(n)
        varargout{n} = varargout{n}.';
    end
    if numObjects(n) == 1
        varargout{n} = repmat(varargout{n},1,refNumObjects);
    end
end

end
