function obj = permute(obj,order)
%PERMUTE Permute dimensions of so2 array
%   B = PERMUTE(A,ORDER) rearranges the dimensions of A so that they are in
%   the order specified by the vector ORDER.  The resulting array has the
%   same values as A but the order of the subscripts needed to access any
%   particular element is rearranged as specified by ORDER.  For an N-D
%   array A, numel(ORDER)>=ndims(A).  All the elements of ORDER must be
%   unique.
%
%   PERMUTE and IPERMUTE are a generalization of transpose (.')
%   for N-D arrays.
%
%   See also TRANSPOSE, PAGETRANSPOSE.

%   Copyright 2022-2024 The MathWorks, Inc.

% Permute the indices and then reassign data based on new indices
    permInd = permute(obj.MInd,order);
    obj.M = obj.M(:,:,permInd);

    % Regenerate indices
    obj.MInd = obj.newIndices(size(permInd));

end
