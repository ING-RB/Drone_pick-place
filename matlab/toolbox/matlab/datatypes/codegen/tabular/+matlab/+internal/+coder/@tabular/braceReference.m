function b2 = braceReference(t,varargin) %#codegen
%BRACEREFERENCE braces subscripted reference for a table. t{...}

% This function is for internal use only and will change in a
% future release.  Do not use this function.

%   Copyright 2019-2021 The MathWorks, Inc.

subsType = matlab.internal.coder.tabular.private.tabularDimension.subsType; % "import" for calls to subs2inds

coder.internal.errorIf(numel(varargin) == 1, 'MATLAB:table:LinearSubscript');
coder.internal.assert(numel(varargin) == t.metaDim.length, 'MATLAB:table:NDSubscript'); % Error for ND indexing

% Translate row labels into indices (leaves logical and ':' alone)
[rowIndices,numRowIndices] = t.rowDim.subs2inds(varargin{1});

% Translate variable (column) names into indices (translates logical and ':')
varIndices = t.varDim.subs2inds(varargin{2},subsType.reference,t.data);

% Extract the specified variables as a single array.
if isscalar(varIndices)
    b1 = t.data{varIndices};
else
    b1 = t.extractData(varIndices);
end

% Retain only the specified rows.
if isa(b1,'matlab.internal.coder.tabular')
    b2 = b1.parenReference(rowIndices,':'); % force dispatch to overloaded table subscripting
elseif ismatrix(b1)
    if iscell(b1)  % cellstr
        if islogical(rowIndices)
            numericRowIndices = find(rowIndices);
        else
            numericRowIndices = rowIndices;
        end   
        % make a local copy within this if block, so that coder can decide
        % whether to make b1_local homogeneous or heterogeneous
        b1_local = b1;
        % If we have an empty 0xM table, b1 would be an empty cell array.
        % Hence, the indexing logic below would result in an error because, 
        % coder would think that we are using a non-empty value to index 
        % into an empty cell array. To avoid this, if b1 is empty, we will 
        % return b1 as it is and error at runtime if the index turns out to
        % be non-empty.
        if coder.internal.isConst(size(b1)) && isempty(b1)
            coder.internal.assert(isempty(numericRowIndices),'MATLAB:table:RowIndexOutOfRange');
            b2 = b1_local;
        else
            b2 = coder.nullcopy(cell(numRowIndices, size(b1, 2)));
            isConstNumRows = coder.internal.isConst(numRowIndices);
            for k = 1:size(b1,2)
                coder.unroll(isConstNumRows);
                for i = 1:numRowIndices
                    b2{i, k} = b1_local{numericRowIndices(i), k};
                end
            end
        end
    else
        b2 = b1(rowIndices,:); % without using reshape, may not have one
    end
else
    % The contents could have any number of dims.  Treat it as 2D to get
    % the necessary row, and then reshape to its original dims.
    outSz = size(b1); 
    outSz(1) = numRowIndices;
    b2 = reshape(b1(rowIndices,:), outSz);
end
