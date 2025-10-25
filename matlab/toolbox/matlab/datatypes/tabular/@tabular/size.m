function varargout = size(t,dim,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isIntegerVals
import matlab.internal.datatypes.isScalarInt

if nargin == 1
    if nargout < 2
        varargout = {[t.rowDim.length t.varDim.length]};
    elseif nargout == 2
        varargout = {t.rowDim.length t.varDim.length};
    else
        varargout(1:2) = {t.rowDim.length t.varDim.length};
        varargout(3:nargout) = {1};
    end
elseif nargin == 2
    if isScalarInt(dim,1,2^48)
        nargoutchk(0,1);
        if dim == 1
            varargout = {t.rowDim.length};
        elseif dim == 2
            varargout = {t.varDim.length};
        else
            varargout = {1};
        end
    elseif  isnumeric(dim) && isempty(dim)
        varargout = {zeros(1,0)};
    elseif isvector(dim) && isIntegerVals(dim,1,2^48)
        out = ones(1,numel(dim));
        out(dim==1) = t.rowDim.length;
        out(dim==2) = t.varDim.length;
        if nargout < 2
            varargout = {out};
        else
            varargout(1:nargout) = num2cell(out);
        end
    else
        error(message('MATLAB:table:size:InvalidDim'));
    end
else % varargin
    dim = [dim, varargin{:}];
    isDimsArg = ~isempty(dim) && isIntegerVals(dim,1,2^48) ...
        && (numel(dim) == nargin-1);
    if ~isDimsArg
        error(message('MATLAB:table:size:InvalidDim'));
    end
    out = ones(1,numel(dim));
    out(dim==1) = t.rowDim.length;
    out(dim==2) = t.varDim.length;
    nargoutchk(0,numel(dim));
    if nargout < 2
        varargout = {out};
    else
        varargout(1:nargout) = num2cell(out);
    end
    
end
end
