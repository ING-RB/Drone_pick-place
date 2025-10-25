function tf = isequaln(varargin)
%ISEQUALN True if arrays are numerically equal, treating NaNs as equal

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

narginchk(2,inf);
[q,idx] = findFirstQuaternion(varargin{:});
tf = true;
for ii = 1:nargin
    if (ii~=idx)  % don't bother comparing with itself
        u = varargin{ii};
        tf = tf && binaryIsEqualn(q,u);
    end
end
end
