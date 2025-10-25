function varargout = distribute(A,dim,dimDist)
%DISTRIBUTE Divide array among outputs based on optional pattern
%   This function is unsupported and might change or be removed without
%   notice in a future version.
%
%   [A,B,C,...] = matlab.internal.indexing.distribute(X) divides the array
%   X along its last dimension and assigns each subarray to the
%   corresponding output array.
%
%   [A,B,C,...] = matlab.internal.indexing.distribute(X,DIM) divides X
%   along the dimension DIM.
%
%   [A,B,C,...] = matlab.internal.indexing.distribute(X,DIM,dimDist)
%   divides X along DIM into subarrays with sizes specified by the elements
%   of dimDist.
%
%   Example: Distribute the columns of a matrix into equally-sized
%   subarrays
%       X = magic(3);
%       [A,B,C] = matlab.internal.indexing.distribute(X);
%
%   Example: Distribute the pages of an array into subarrays of varying
%   sizes
%       X = reshape(1:48, [2 3 8]);
%       [A,B,C] = matlab.internal.indexing.distribute(X,3,[2 1 5]);
%
%   See also DEAL, MAT2CELL, NUM2CELL

%   Copyright 2023 The MathWorks, Inc.

if nargout == 0 && nargin == 0
    return;
end

narginchk(1,3);

if isa(A,'matlab.mixin.Scalar') || isa(A,'function_handle')
    error(message('MATLAB:distribute:InvalidInput',class(A)));
end

if nargin == 1
    if nargout == 0
        return;
    end
    if isvector(A)
        dim = 1+isrow(A);
    else
        dim = ndims(A);
    end
end
if ~(isscalar(dim) && 1 <= dim && dim <= ndims(A))
    error(message('MATLAB:distribute:InvalidDimension'));
end

if dim ~= round(dim)
    error(message('MATLAB:distribute:DimNotInt'))
end

if nargin < 3 && nargout~=size(A,dim)
    error(message('MATLAB:distribute:NargoutDimSizeMismatch',dim));
end
if nargin == 3
    if ~isvector(dimDist)
        error(message('MATLAB:distribute:InvaliddimDist'));
    end

    if ~all(dimDist == round(dimDist))
        error(message('MATLAB:distribute:DimDistNotInt'))
    end
    
    if nargout~=length(dimDist)
        error(message('MATLAB:distribute:NargoutDimDistSizeMismatch'));
    end

    if sum(dimDist)~=size(A,dim)
        error(message('MATLAB:distribute:DimDistSumMismatch',dim));
    end
    varargout = cell(1,length(dimDist));
else
    varargout = cell(1,size(A,dim));
end

% Optimized for 1D and 2D cases
if ismatrix(A)
    if nargin ~= 3
        if dim == 1
            for i = 1:nargout
                varargout{i} = A(i,:);
            end
        else
            for i = 1:nargout
                varargout{i} = A(:,i);
            end
        end
    else
        numseen=0;
        for i=1:nargout
            idx = numseen+1:numseen+dimDist(i);
            numseen = numseen+dimDist(i);   
            if dim==1
                varargout{i} = A(idx,:);
            else
                varargout{i} = A(:,idx);
            end
        end
    end
    return;
end

% General handling for higher dimensions
idx = cell(1,ndims(A)); % indices for array slice
for j=[1:dim-1 dim+1:ndims(A)] % Extract along all dimensions except for dim
    idx{j} = 1:size(A,j);
end

if nargin == 3
    numseen = 0;
    for i=1:nargout
        idx{dim} = numseen+1:numseen+dimDist(i);
        numseen = numseen+dimDist(i);
        varargout{i} = A(idx{:});
    end
else
    for i=1:nargout
        idx{dim} = i;
        varargout{i} = A(idx{:});
    end
end
end
