function obj = transpose(obj)
%.' Transpose of so3 array
%   X.' is the non-conjugate transpose.
%
%   B = TRANSPOSE(A) is called for the syntax A.' when A is an object.
%
%   See also CTRANSPOSE, PERMUTE, PAGETRANSPOSE.

%   Copyright 2022-2024 The MathWorks, Inc.

% Transpose the indices and then reassign data based on new indices
    transpInd = obj.MInd.';
    obj.M = obj.M(:,:,transpInd);

    % Regenerate indices
    obj.MInd = obj.newIndices(size(transpInd));

end
