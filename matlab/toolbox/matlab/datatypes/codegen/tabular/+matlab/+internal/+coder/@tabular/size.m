function varargout = size(t,dim)  %#codegen
%SIZE Size of a table.

%   Copyright 2019-2022 The MathWorks, Inc.

rowlen = t.rowDimLength();
varlen = t.varDim.length;

if nargin == 1
    if nargout < 2
        varargout = {[rowlen varlen]};
    elseif nargout == 2
        varargout = {rowlen varlen};
    else
        nout = nargout;
        varargout{1} = rowlen;
        varargout{2} = varlen;
        for i = 3:nout
            varargout{i} = 1;
        end
    end
else % if nargin == 2
    coder.internal.prefer_const(dim);
    coder.internal.assert(nargout == numel(dim) || nargout < 2,'MATLAB:nargoutchk:tooManyOutputs');
    coder.internal.assert(...
        isnumeric(dim) && isreal(dim) ...
        && (isvector(dim) || isscalar(dim) || isempty(dim)) ...
        && (all(1 <= dim(:) & dim(:) <= 2^48) && all(round(dim(:)) == dim(:))), ...
        'MATLAB:table:size:InvalidDim');
    out = ones(1,numel(dim));
    out(dim == 1) = rowlen;
    out(dim == 2) = varlen;
    if nargout < 2
        varargout = {out};
    else
        for i = coder.unroll(1:nargout)
            varargout{i} = out(i);
        end
    end
end
