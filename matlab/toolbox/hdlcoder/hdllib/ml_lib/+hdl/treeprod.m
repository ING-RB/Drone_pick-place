function y = treeprod(u, DIM)
%HDL.TREEPROD Product of elements in tree order
% S = hdl.treeprod(X) is the product of the elements of the vector X. If X
% is a 2-D matrix, S is a row vector with the product over each column.
%
% S = hdl.treeprod(X, 'all') computes the product of all elements of X.
%
% S = hdl.treeprod(X, DIM) computes the product along the dimension DIM.
%
% The output of hdl.treeprod has the same class as the input.
%
% See also hdl.treesum, prod.

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen

% Check input args (if any)
coder.internal.assert(nargin >= 1, ...
    'hdlmllib:hdlmllib:TreeSumProdNotEnoughInputArgs');

% Check number of dims in first argument
coder.internal.assert(isvector(u) || ismatrix(u), ...
    'hdlmllib:hdlmllib:TreeSumProdInvalidInputArray');

if nargin < 2
    if isvector(u)
        DIM = 'all';
    else
        DIM = 1;
    end
end

prodAll = false;

% Check to make sure DIM is a constant
coder.internal.prefer_const(DIM);
coder.internal.assert(coder.internal.isConst(DIM), ...
    'hdlmllib:hdlmllib:TreeSumProdDimArgMustBeConst');

if ischar(DIM)
    coder.internal.assert(strcmp(DIM, 'all'), ...
        'hdlmllib:hdlmllib:TreeSumProdInvalidDimArg');
    prodAll = true;
else
    % Check that the DIM arg is a positive integer scalar
    coder.internal.assert( ...
        isscalar(DIM) && isnumeric(DIM) ...
        && DIM > 0 && mod(DIM, 1) == 0, ...
        'hdlmllib:hdlmllib:TreeSumProdInvalidDimArg');

    if ~(DIM == 1 || DIM == 2) % DIM values >2 are an identity operation (as in prod function)
        y = u;
        return;
    else
        DIM = double(DIM);
    end
end

% Perform treeprod
if prodAll
    y = treeprod_1D(u(:));
else
    assert(DIM == 1 || DIM == 2);
    y = treeprod_2D(u, DIM);
end
end


% treeprod across a 1D array
function y = treeprod_1D(u)

if numel(u) == 1
    y = u(1);
else
    numStages = ceil(log2(numel(u)));
    elems = cell(1, numStages+1);
    elems{1} = u;
    numInputs = numel(u);

    % Prod elements in tree order (stage by stage)
    for i=coder.unroll(1:numStages)
        assert(numInputs > 1);
        numOps = floor(numInputs / 2);
        oddInput = mod(numInputs, 2) == 1;

        if oddInput
            numOutputs = numOps + 1;
        else
            numOutputs = numOps;
        end
        
        % add elements from this stage in pairs to the next stage
        elems{i+1} = repmat(elems{i}(1) * elems{i}(2), 1, numOutputs);
        for j=2:numOps
            elems{i+1}(j) = elems{i}(j*2-1) * elems{i}(j*2);
        end
        
        % pass extra element through to next stage if needed
        if oddInput
            elems{i+1}(end) = elems{i}(end);
        end
        
        numInputs = numOutputs;

    end

    y = elems{end}(1);

end
end

% treeprod across a 2D array
function y = treeprod_2D(u, DIM)

if DIM == 1
    % If we are multiplying rows, then the output has 1 row and many
    % columns
    numCols = size(u, 2);

    firstCol = treeprod_1D(u(:, 1));
    y = repmat(firstCol, 1, numCols);

    for ii = 2:numCols
        y(ii) = treeprod_1D(u(:, ii));
    end
else
    assert(DIM == 2);

    % If we are multiplying columns, then the output has 1 column and many
    % rows
    numRows = size(u, 1);

    firstRow = treeprod_1D(u(1, :));
    y = repmat(firstRow, numRows, 1);

    for ii = 2:numRows
        y(ii) = treeprod_1D(u(ii, :));
    end
end
end

% LocalWords:  treesum
