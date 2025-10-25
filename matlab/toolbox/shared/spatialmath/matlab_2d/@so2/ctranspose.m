function obj = ctranspose(obj)
%' Complex conjugate transpose of so2 array
%   X' is the complex conjugate transpose of X. For an so2 array, X'
%   behaves the same way as X.'.
%
%   B = CTRANSPOSE(A) is called for the syntax A'
%   when A is an object.
%
%   See also transpose, pagectranspose, permute.

%   Copyright 2022-2024 The MathWorks, Inc.

% Transpose the indices and then reassign data based on new indices
    transpInd = obj.MInd';
    obj.M = obj.M(:,:,transpInd);

    % Regenerate indices
    obj.MInd = obj.newIndices(size(transpInd));

end
