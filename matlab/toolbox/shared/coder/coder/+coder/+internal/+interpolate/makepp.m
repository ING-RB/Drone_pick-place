function pp = makepp(breaks,coefs,ndEff)
%MATLAB Code Generation Private Function

%   Low-level function to construct a piecewise polynomial form. The input
%   COEFS should be N-D with the number of pieces and the number of terms
%   in the polynomial pieces being the lengths of the penultimate and
%   ultimate dimensions, respectively. The D input to MKPP corresponds to
%   the leading dimensions of COEFS. The optional NDEFF input is the
%   effective number of dimensions of COEFS. If NDEFF > coder.internal.ndims(COEFS),
%   then PP will be a piecwise constant polynomial (signified by PP.BREAKS
%   being a column vector rather than the usual row vector).
%
%   This function does no error checking. Get it right or use MKPP instead!

%   Copyright 1984-2013 The MathWorks, Inc.
%#codegen

coder.inline('always');
ndimsCoefs = coder.internal.ndims(coefs);
if nargin < 3
    ndEff = ndimsCoefs;
else
    coder.internal.prefer_const(ndEff);
end
if ndimsCoefs < ndEff
    % Piecewise constant polynomial. We flag this by making pp.breaks a
    % column vector instead of a row vector.
    pp = struct(...
        'breaks',breaks(:), ...
        'coefs',coefs);
else
    pp = struct(...
        'breaks',breaks(:).', ...
        'coefs',coefs);
end
