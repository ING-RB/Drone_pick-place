function [varargout] = constExtrinsic(func, varargin)
%#codegen
%   Copyright 2021 The MathWorks, Inc.
coder.internal.prefer_const(func, varargin);

coder.unroll()
for i=coder.internal.indexInt(1):nargin-1
    coder.internal.assert(coder.internal.isConst(varargin{i}), 'Coder:toolbox:AllConstInputs');
end

[varargout{1:nargout}] = coder.const(@feval, func, varargin{:});

end