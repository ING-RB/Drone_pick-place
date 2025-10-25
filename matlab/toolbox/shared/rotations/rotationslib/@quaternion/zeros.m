function o = zeros(varargin)
%D = QUATERNION.ZEROS(N) is an N-by-N quaternion array of zeros.
%
%D = QUATERNION.ZEROS(M,N) is an M-by-N quaternion array of zeros.
%
%D = QUATERNION.ZEROS(M,N,K,...) is an M-by-N-by-K-by-... quaternion array of zeros.
%
%D = QUATERNION.ZEROS(M,N,K,...,CLASSNAME) or
%QUATERNION.ZEROS([M,N,K,...], CLASSNAME) is an M-by-N-by-K-by-...
%quaternion of zeros of underlying class specified by CLASSNAME.
%
%D = ZEROS(...,"like",P) for a quaternion argument P returns a quaternion of zeros of the
%same underlying class as P and the requested size.

%   Copyright 2018-2024 The MathWorks, Inc.    

x = zeros(varargin{:});
coder.internal.assert(isa(x,'float'),'shared_rotations:quaternion:SingleDouble',class(x));
o = quaternion(x,x,x,x);
end
