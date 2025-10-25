function x = matricize(x,char2cellstr)
%MATRICIZE Reshape an array to 2D.

%   Copyright 2014-2020 The MathWorks, Inc.

% Unlike ':', reshape preserves memory by using a shared-data copy.

if ischar(x) && nargin > 1 && char2cellstr
    [n,m,d] = size(x);
    if d > 1
        % Convert the N-D char into an N*DxM "column" of char rows.
        x = permute(x,[1 3:ndims(x) 2]);
        % It is generally faster to let reshape calculate the remaining dimension,
        % but reshape(x,[],...) on an empty would zero out the height, so we need
        % to preserve the correct height explicitly.
        if m == 0 % empty case
            x = reshape(x, n*d, m);
        else
            x = reshape(x, [], m);
        end
    end
    % Convert the N*DxM char matrix to an N*Dx1 cellstr and reshape to NxD.
    x = reshape(num2cell(x,2), n, d); % use num2cell, cellstr(x) turns 0xM into 1x1
elseif ~ismatrix(x)
    % Matricize by putting pages as more columns. Assume that any N-D array has
    % a reshape method. It is generally faster to let reshape calculate the
    % remaining dimension, but reshape(x,size(x,1),[]) on an empty would zero
    % out the width, so we need to preserve the correct width explicitly.
    sz = size(x);
    if sz(1) == 0 % empty case
        x = reshape(x,sz(1),prod(sz(2:end)));
    else
        x = reshape(x,sz(1),[]);
    end
end