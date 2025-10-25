% Copyright 2021 The MathWorks, Inc.

classdef IScheduledTask< handle

    methods (Abstract, Access = public)
        run();
        isValid();
    end
end
