function obj = parenAssign(obj, rhs, varargin)
%This method  is for internal use only. It may be removed in the future.

%parenAssign Invoked when assigning data into the object array
%   If A inherits from matlab.mixin.internal.indexing.ParenAssign,
%   then a(indices) = rhs is rewritten as a = a.parenAssign(rhs, indices).
%   "rhs" here is assumed to be an se3 object.
%
%   See also parenReference.

%   Copyright 2022-2024 The MathWorks, Inc.

    obj = parenAssignSim(obj, rhs, "se3", varargin{:});

end
