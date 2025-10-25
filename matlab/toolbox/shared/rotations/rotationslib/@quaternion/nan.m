function o = nan(varargin)
%D = QUATERNION.NAN(N) is an N-by-N quaternion array with 
%all parts set to NaN.
%
%D = QUATERNION.NAN(M,N) is an M-by-N quaternion array with
%all parts set to NaN.
%
%D = QUATERNION.NAN(M,N,K,...) is an M-by-N-by-K-by-... quaternion array with
%all parts set to NaN. 
%
%D = QUATERNION.NAN(M,N,K,..., CLASSNAME) is an M-by-N-by-K-by-... 
%quaternion array of NaNs of class specified by CLASSNAME.
%
%D = NAN(...,'LIKE',P) for a quaternion argument P returns a quaternion array of NaNs of the
%Same class as P and the requested size. P must be a double or
%single precision element.

%   Copyright 2024 The MathWorks, Inc.    

x = nan(varargin{:});
coder.internal.assert(isa(x,'float'),'shared_rotations:quaternion:SingleDouble',class(x));
o = quaternion(x,x,x,x);
end
