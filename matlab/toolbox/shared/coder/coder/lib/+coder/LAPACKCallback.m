%CODER.LAPACKCallback An abstract class for LAPACK callback

%   Copyright 2015-2020 The MathWorks, Inc.

classdef (Abstract) LAPACKCallback
    methods (Static, Abstract)
         headerName = getHeaderFilename()
         updateBuildInfo(aBuildInfo, context)
    end
end
