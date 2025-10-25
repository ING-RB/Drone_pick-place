function msg = nargoutchk_compat(low,high,n,varargin)
%MATLAB Code Generation Library Function

%   Limitations:  Struct output does not include stack information.

%   Copyright 1984-2019 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(low,high,n,varargin{:});
if (isempty(coder.target()))
    msg = nargoutchk(low, high, n, varargin{:}); %#ok will error when deprecated
else
    coder.internal.assert(nargin >= 3, ...
                  'MATLAB:minrhs');
    coder.internal.assert(eml_is_const(low) && eml_is_const(high) && eml_is_const(n) && ...
                  (nargin < 4 || eml_is_const(varargin{1})), ...
                  'Coder:toolbox:nargoutchk_2', ...
                  'IfNotConst','Fail');
    coder.internal.assert(nargin < 4 || (strcmp(varargin{1},'string') || strcmp(varargin{1},'struct')), ...
                  'Coder:toolbox:nargoutchk_3', ...
                  'IfNotConst','Fail');
    coder.internal.assert(isscalar(low) && isscalar(high) && isscalar(n), ...
                  'Coder:toolbox:nargoutchk_4', ...
                  'IfNotConst','Fail');
    coder.internal.assert(isa(low,'numeric') && isa(high,'numeric') && isa(n,'numeric'), ...
                  'Coder:toolbox:nargoutchk_5', ...
                  'IfNotConst','Fail');
    coder.internal.assert(low(1) == coder.internal.scalar.floor(low(1)) && ...
                  high(1) == coder.internal.scalar.floor(high(1)) && ...
                  n(1) == coder.internal.scalar.floor(n(1)), ...
                  'Coder:toolbox:nargoutchk_6', ...
                  'IfNotConst', 'Fail');
    
    if n < low
        if nargin < 4 || strcmp(varargin{1},'string')
            msg = 'Not enough output arguments.';
        else
            msg.message = 'Not enough output arguments.';
            msg.identifier = 'MATLAB:nargoutchk:notEnoughOutputs';
        end
    elseif n > high
        if nargin < 4 || strcmp(varargin{1},'string')
            msg = 'Too many output arguments.';
        else
            msg.message = 'Too many output arguments.';
            msg.identifier = 'MATLAB:nargoutchk:tooManyOutputs';
        end
    else
        if nargin < 4 || strcmp(varargin{1},'string')
            msg = [];
        else
            msg = struct('message',cell(0,1),'identifier',cell(0,1));
        end        
    end
end
