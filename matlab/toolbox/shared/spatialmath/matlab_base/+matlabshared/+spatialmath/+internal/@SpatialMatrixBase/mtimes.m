function out = mtimes(obj1,obj2)
%mtimes Pose composition (multiplication)
%   T = T1*T2 composes (multiplies) two different se3 objects, T1
%   and T2. Either T1 or T2 must be a scalar. The scalar object
%   is multiplied with each element of the non-scalar object
%   array.
%   You can use se3 multiplication to compose a sequence of
%   SE(3) transformations, so that T represents a rotation and
%   translation where T2 is applied first, followed by T1.
%
%   See also mrdivide.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if ~isempty(obj1) || ~isempty(obj2)
        coder.internal.assert(isscalar(obj1) || isscalar(obj2), "shared_spatialmath:matobj:ScalarArg", "mtimes,*");
    end
    out = obj1 .* obj2; 

end
