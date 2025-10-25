function tf = isequal(varargin)
%ISEQUAL True if quaternion arrays are numerically equal

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

narginchk(2,inf);
[q,idx] = findFirstQuaternion(varargin{:});
tf = true;
for ii = 1:nargin
    if (ii~=idx)  % don't bother comparing with itself
        u = varargin{ii};
        tf = tf && binaryIsEqual(q,u);
    end
end
end
