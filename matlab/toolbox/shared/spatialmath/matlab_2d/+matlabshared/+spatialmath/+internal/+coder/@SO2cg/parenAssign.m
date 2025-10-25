function outObj = parenAssign(obj, rhs, varargin)
%This method  is for internal use only. It may be removed in the future.

%parenAssign Invoked when assigning data into the object array
%   If A inherits from coder.mixin.internal.indexing.ParenAssign,
%   then a(indices) = rhs is rewritten as a = a.parenAssign(rhs, indices).
%   "rhs" here is assumed to be an SO2cg object.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Find the indices where to assign values
    indices = obj.MInd(varargin{:});

    % Assign values and return new object
    sM3 = size(rhs.M,3);
    lInd = numel(indices);
    if lInd ~= sM3 && sM3 == 1
        % Do scalar expansion of right side if same matrix is going
        % into several indices.
        obj.M(:,:,indices) = repmat(rhs.M,1,1,lInd);
    else
        obj.M(:,:,indices) = rhs.M;
    end
    outObj = obj;

end
