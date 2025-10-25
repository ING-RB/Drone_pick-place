classdef BusyModeEnum < uint8
%

%   Copyright 2019-2020 The MathWorks, Inc.

    enumeration
        drop (0)
        queue (1)
        error (2)
    end
    methods
        function obj = BusyModeEnum(val)
            mlock;
            obj@uint8(val);
        end
    end

end
