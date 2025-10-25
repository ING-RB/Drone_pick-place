classdef ExecutionModeEnum < uint8
%

%   Copyright 2019-2020 The MathWorks, Inc.

    enumeration
        singleShot (0)
        fixedSpacing (1)
        fixedDelay (2)
        fixedRate (3)
    end

    methods
        function obj = ExecutionModeEnum(val)
            mlock;
            obj@uint8(val);
        end
    end

end
