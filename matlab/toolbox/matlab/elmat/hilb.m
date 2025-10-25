function H = hilb(n,classname)
%HILB   Hilbert matrix.
%   H = HILB(N) is the N-by-N matrix with elements 1/(i+j-1), which is a
%   famous example of a badly conditioned matrix. The INVHILB function
%   calculates the exact inverse.
%
%   H = HILB(N,CLASSNAME) returns a matrix of class CLASSNAME, which can be
%   either 'single' or 'double' (the default).
%
%   HILB is also a good example of efficient MATLAB programming
%   style, where conventional FOR or DO loops are replaced by
%   vectorized statements. 
%
%   Example:
%
%   HILB(3) is
%
%          1.0000    0.5000    0.3333
%          0.5000    0.3333    0.2500
%          0.3333    0.2500    0.2000
%
%   See also INVHILB.

%   Copyright 1984-2018 The MathWorks, Inc.

if nargin < 2
    classname = 'double';
end
if (isstring(classname) && ~isscalar(classname)) || (~strcmp(classname,'single') && ~strcmp(classname,'double'))
    error(message('MATLAB:hilb:notSupportedClass'));
end

J = 1:cast(n,classname);
H = 1./(J'+J-1);
