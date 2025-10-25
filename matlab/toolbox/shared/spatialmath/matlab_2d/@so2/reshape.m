function obj = reshape(obj,varargin)
%RESHAPE Reshape an so2 array
%   RESHAPE(X,M,N) or RESHAPE(X,[M,N]) returns the M-by-N matrix
%   whose elements are taken column-wise from X. An error results
%   if X does not have M*N elements.
%
%   RESHAPE(X,M,N,P,...) or RESHAPE(X,[M,N,P,...]) returns an
%   N-D array with the same elements as X but reshaped to have
%   the size M-by-N-by-P-by-.... The product of the specified
%   dimensions, M*N*P*..., must be the same as NUMEL(X).
%
%   RESHAPE(X,...,[],...) calculates the length of the dimension
%   represented by [], such that the product of the dimensions
%   equals NUMEL(X). The value of NUMEL(X) must be evenly divisible
%   by the product of the specified dimensions. You can use only one
%   occurrence of [].

%   Copyright 2022-2024 The MathWorks, Inc.

% Reshape the indices and then reassign data based on new indices
    reshapeInd = reshape(obj.MInd,varargin{:});
    obj.M = obj.M(:,:,reshapeInd);

    % Regenerate indices
    obj.MInd = obj.newIndices(size(reshapeInd));

end
