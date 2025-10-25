function o = ones(varargin)
%D = QUATERNION.ONES(N) is an N-by-N quaternion array with the
%real part set to 1 and the imaginary parts set to 0.
%
%D = QUATERNION.ONES(M,N) is an M-by-N quaternion array with the
%real part set to 1 and the imaginary parts set to 0.
%
%D = QUATERNION.ONES(M,N,K,...) is an M-by-N-by-K-by-... quaternion array with the
%real part set to 1 and the imaginary parts set to 0.
%
%D = QUATERNION.ONES(M,N,K,...,CLASSNAME) is an M-by-N-by-K-by-...
%quaternion of ones of underlying class specified by CLASSNAME.
%
%D = ONES(...,'LIKE',P) for a quaternion argument P returns a quaternion of ones of the
%same underlying class as P and the requested size.

%   Copyright 2018 The MathWorks, Inc.    

x = zeros(varargin{:});
coder.internal.assert(isa(x,'float'),'shared_rotations:quaternion:SingleDouble',class(x));
y = ones(varargin{:});
o = quaternion(y,x,x,x);
end
