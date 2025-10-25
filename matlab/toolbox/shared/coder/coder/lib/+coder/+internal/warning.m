function warning(msgID, varargin) 
%MATLAB Code Generation Private Function

%   Copyright 2011-2019 The MathWorks, Inc.
%#codegen

if isempty(coder.target)
    warning(message(msgID, varargin{:}));
else
    eml_allow_mx_inputs;
    coder.internal.assert(nargin > 0,'MATLAB:minrhs');
    if coder.internal.runs_in_matlab
        coder.inline('never'); % For readability in generated code.
        feval('warning',feval('message',msgID,varargin{:}));
    end
end
