function outTime = timeKeeper(newTime)
%MATLAB Code Generation Private Function

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen
coder.inline('never');
persistent savedTime;
if isempty(savedTime)
    if nargout > 0 && nargin == 0
        coder.internal.error('MATLAB:toc:callTicFirstNoInputs');
    end
    savedTime = coder.internal.time.getTime();
end
if nargin > 0
    savedTime = newTime;
end
if nargout > 0
    outTime = savedTime;
end

%--------------------------------------------------------------------------
