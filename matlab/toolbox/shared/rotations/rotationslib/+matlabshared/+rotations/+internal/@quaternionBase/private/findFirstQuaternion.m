function [q,idx] = findFirstQuaternion(varargin)
%This function is for internal use only. It may be removed in the future. 
%FINDFIRSTQUATERNION find the first quaternion in a csl

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

% Local function called from binaryIsEqualn()
for ii = 1:nargin
    if isa(varargin{ii},'matlabshared.rotations.internal.quaternionBase')
        q = varargin{ii};
        idx = ii;
        return
    end
end

end
