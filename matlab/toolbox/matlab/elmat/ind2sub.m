function [v1,v2,varargout] = ind2sub(siz,ndx)
%IND2SUB Multiple subscripts from linear index.
%   IND2SUB is used to determine the equivalent subscript values
%   corresponding to a given single index into an array.
%
%   [I,J] = IND2SUB(SIZ,IND) returns the arrays I and J containing the
%   equivalent row and column subscripts corresponding to the index
%   matrix IND for a matrix of size SIZ.
%   For matrices, [I,J] = IND2SUB(SIZE(A),FIND(A>5)) returns the same
%   values as [I,J] = FIND(A>5).
%
%   [I1,I2,I3,...,In] = IND2SUB(SIZ,IND) returns N subscript arrays
%   I1,I2,..,In containing the equivalent N-D array subscripts
%   equivalent to IND for an array of size SIZ.
%
%   Class support for input IND:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%
%   See also SUB2IND, FIND.

%   Copyright 1984-2024 The MathWorks, Inc.

siz = double(siz);
lensiz = numel(siz);
if ~isreal(siz) || ~isvector(siz) || lensiz < 2
    error(message('MATLAB:ind2sub:InvalidSize'));
end
if ~isreal(ndx)
    error(message('MATLAB:ind2sub:RealSubscript'));
end

nout = max(nargout,1);

if nout > 2
    % Since lensiz is at least 2, attempt to pad siz only when nout > 2.
    if lensiz+1 < nout
        % In addition, we only use the first nout-1 elements of siz.
        % Therefore, we pad siz only when (nout-lensiz) > 1.
        siz = [siz ones(1,nout-lensiz)];
    end
    k = cumprod(siz);
    for i = nout:-1:3
        vi = rem(ndx-1, k(i-1)) + 1;
        vj = (ndx - vi)/k(i-1) + 1;
        varargout{i-2} = double(vj);
        ndx = vi;
    end
end

if nout >= 2
    vi = rem(ndx-1, siz(1)) + 1;
    v2 = double((ndx - vi)/siz(1) + 1);
    v1 = double(vi);
else
    v1 = double(ndx);
end
