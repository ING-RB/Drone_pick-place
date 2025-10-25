function varargout = unique(tA, varargin)
%UNIQUE Set unique.
%   C = UNIQUE(A) for vector A
%   C = UNIQUE(A,'rows') for matrix A
%   [C,IA,IC] = UNIQUE(A) for vector A
%   [C,IA,IC] = UNIQUE(A,'rows') for matrix A
%
%   See also tall, unique.

% Copyright 2015-2023 The MathWorks, Inc.

nargoutchk(0, 3);

isTabularInput = any(strcmp(tall.getClass(tA), {'table', 'timetable'}));
% Starting point for the output adaptor - retain type information from input.
outAdaptor = resetSizeInformation(tA.Adaptor);

if nargin == 1
    if ~isTabularInput
        % Non-table inputs without 'rows' specifier must be vectors.
        tA = tall.validateVector(tA, 'MATLAB:bigdata:array:UniqueRequiresVector');
    end
    uniqueFcn = @unique;
else
    tall.checkNotTall(upper(mfilename), 1, varargin{:});
    if all(cellfun(@(x) strcmpi(x, 'rows'), varargin))
        if nargin > 2
            error(message('MATLAB:UNIQUE:RepeatedFlag','rows'));
        end
    else
        error(message('MATLAB:bigdata:array:UniqueUnsupportedSyntax'));
    end

    % If we get here, the flag must have been 'rows'.
    % Here we simply defer to MATLAB's UNIQUE with 'rows' specified. This will throw
    % an appropriate error if A is not a matrix.
    uniqueFcn = @(a) unique(a, 'rows');
    
    % In this case, we want to copy only the small sizes
    outAdaptor = copySizeInformation(outAdaptor, tA.Adaptor);
    outAdaptor = resetTallSize(outAdaptor);
end

if nargout < 2
    tC = reducefun(uniqueFcn, tA);
    tC.Adaptor = outAdaptor;
else
    sliceIds = getAbsoluteSliceIndices(tA);    
    reduceFcn = @(x, ids) iReduceWithIdsInTallDim(x, ids, uniqueFcn);
    [tC,tIdxA] = reducefun(reduceFcn, tA, sliceIds);
    tC.Adaptor = outAdaptor;
    
    % tIdxA is a double column vector with indices
    tIdxA = setKnownType(tIdxA, 'double');
    if isTabularInput || isKnownNotRow(tA.Adaptor)
        tIdxA.Adaptor = copyTallSize(tIdxA.Adaptor, tC.Adaptor);
    end
    tIdxA.Adaptor = setSmallSizes(tIdxA.Adaptor, 1);
    varargout{2} = tIdxA;
end

varargout{1} = tC;

if nargout == 3
    isRowVector = findFirstNonSingletonDim(tA) - 1;
    
    if isTabularInput || nargin == 2
        % Slicefun with 'rows' option for tables & matrices
        [~,tIdxC] = slicefun(@(x, C) ismember(x, C, 'rows'), ...
            tA, matlab.bigdata.internal.broadcast(tC));
    else
        % Elementfun for row & column vectors
        [tIdxC,sliceIds] = elementfun(@(x, idx, C, isRowVector) iComputeICVector(x, idx, C, isRowVector), ...
            tA, sliceIds, matlab.bigdata.internal.broadcast(tC), isRowVector);
    end
    % Handle NaN positions in tIdxC, ismember above returns 0 for NaN
    % positions and we have to get the corresponding indices from sliceIds
    [isUnique, tIdxCUnique] = slicefun(@(I, idx) ismember(I, idx), ...
        sliceIds, matlab.bigdata.internal.broadcast(tIdxA));
    
    % Final processing in tIdxC, fill in NaN positions in tIdxC with the
    % indices in tIdxCUnique. Transpose tIdxC to a column vector when tA is
    % a row vector
    tIdxC = chunkfun(@iChunkProcessICVector, tIdxC, tIdxCUnique, isUnique, isRowVector);
    
    % tIdxC is a double column vector with indices
    tIdxC = setKnownType(tIdxC, 'double');
    if isTabularInput || isKnownNotRow(tA.Adaptor)
        tIdxC.Adaptor = copyTallSize(tIdxC.Adaptor, tA.Adaptor);
    end
    tIdxC.Adaptor = setSmallSizes(tIdxC.Adaptor, 1);
    varargout{3} = tIdxC;
end

end

%--------------------------------------------------------------------------
function [B, varargout] = iReduceWithIdsInTallDim(A, sliceIds, uniqueFcn)

[B, I] = uniqueFcn(A);
% B is a row vector if A also is, otherwise it is a column vector. I is 
% always a column vector of indices.
isRowA = (size(I,1)~=size(B,1));

isSliceIdsInitialized = (length(sliceIds)==length(I));
% When A is a row vector and it is the first visit to reducefun, sliceIds
% is equal to 1 and we have to get the indices from I.
% For subsequent visits to reducefun, map absolute indices in sliceIds
% according to the order in I.
if isSliceIdsInitialized || ~isRowA
    I = sliceIds(I);
end

if nargout > 1
    varargout{1} = I;
end

end

%--------------------------------------------------------------------------
function [idxC, sliceIds] = iComputeICVector(A, sliceIds, C, isRowVector)
% iComputeICVector is only invoked with the syntax unique(A). It only
% handles column and row vector inputs.

if isRowVector 
    % If A is a row vector, sliceIds is equal to 1. Create a vector of
    % indices with the same length as the input row vector.
    if ~isempty(A)
        sliceIds = 1:size(A,2);
    else
        sliceIds = ones(size(A)); % Create empty output as A
    end
end

[~,idxC] = ismember(A,C);
end

%--------------------------------------------------------------------------
function idxC = iChunkProcessICVector(idxC, idxCUnique, isUniqueFlag, isRowVector)

% IsMember returns 0 for NaNs, fill in the gaps with the corresponding
% indices.
if any(idxC==0)
    idxC(isUniqueFlag) = idxCUnique(isUniqueFlag);
end

% Convert C to column vector when the input of unique is a row vector.
if isRowVector 
    if ~isempty(idxC)
        idxC = idxC.'; 
    else
        idxC = ones(0,1); % Create empty column vector
    end
end

end
