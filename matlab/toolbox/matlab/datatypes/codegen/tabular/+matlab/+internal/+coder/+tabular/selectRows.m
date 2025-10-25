function rows = selectRows(AIn, idxIn) %#codegen
%SELECTROWS Select rows from an input array.

% Copyright 2020 The MathWorks, Inc.

if islogical(idxIn)
    if coder.internal.isConst(idxIn)
        idx = coder.const(feval('find',idxIn));
    else
        idx = find(idxIn);
    end
else
    idx = idxIn;
end

% If A is a heterogeneous cell array, then we have to make it homogeneous
% to allow non-constant indexing.
A = AIn;
if iscell(A) && coder.internal.isConst(size(AIn)) && ~coder.internal.isConst(idx)
    coder.varsize('A',[],false(1,ndims(AIn)));
end

% A could have any number of dims, no way of knowing, except how many
% rows it has. So just treat A as 2D to get the necessary rows,
% and then reshape the remaining dims to the original values.
sizeOut = size(A);
sizeOut(1) = numel(idx);
if ~iscell(A)
    if coder.internal.isConstTrue(ismatrix(A))
        rows = A(idx,:);
    elseif coder.internal.isConstTrue(isempty(A))
        % If A is empty we cannot reduce the number of dims and then increase it
        % back with a call to reshape in codegen. So to avoid this, simply
        % reshape the original A to sizeOut. Still index into A with idx so that
        % subsref can validate idx.
        temp = A(idx,:); %#ok<NASGU>
        rows = reshape(A,sizeOut);
    else
        rows = reshape(A(idx,:),sizeOut);
    end
else
    rows = coder.nullcopy(cell(sizeOut));
    for i = 1:sizeOut(1)
        for j = 1:prod(sizeOut(2:end))
            rows{i,j} = A{idx(i),j};
        end
    end
end
 