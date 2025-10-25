function b = matricize(a,char2cellstr)  %#codegen
%MATRICIZE Reshape an array to 2D.

%   Copyright 2019-2020 The MathWorks, Inc.

% Unlike ':', reshape preserves memory by using a shared-data copy.

if ischar(a) && nargin > 1 && char2cellstr
    [n,m,d] = size(a);
    if d > 1
        % Convert the N-D char into an N*DxM "column" of char rows.
        a1 = permute(a,[1 3:ndims(a) 2]);
        a2 = reshape(a1, n*d, m);
    else
        a2 = a;
    end
    % Convert the N*DxM char matrix to an N*Dx1 cellstr and reshape to NxD.
    %b = reshape(cellstr(a), n, d);
    a3 = cell(size(a2,1),1);
    for i = 1:numel(a3)
        a3{i} = a2(i,:);
    end
    b = reshape(a3, n, d);
else % non-char case
    if coder.internal.isConst(ismatrix(a)) && ismatrix(a)
        b = a;
    else
        % Matricize by putting pages as more columns. Assume that any N-D array
        % has a reshape method.
        b = reshape(a,size(a,1),[]);
    end
end

