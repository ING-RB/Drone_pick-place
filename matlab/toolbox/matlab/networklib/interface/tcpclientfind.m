function objs = tcpclientfind(varargin)
%

%   Copyright 2023 The MathWorks, Inc.

try
    objs = matlabshared.testmeas.internal.objectcacher.ObjectCacher.find("tcpclient", varargin{:});
catch ex
    throwAsCaller(ex);
end
end