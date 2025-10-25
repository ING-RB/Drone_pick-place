function objs = serialportfind(varargin)
%

%   Copyright 2023 The MathWorks, Inc.

try
    objs = matlabshared.testmeas.internal.objectcacher.ObjectCacher.find("serialport", varargin{:});
catch ex
    throwAsCaller(ex);
end
end