classdef CallBackTypeEnum < uint8
%

%   Copyright 2019-2020 The MathWorks, Inc.

    enumeration
        TYPE_UNDEF  (0)
        TYPE_EVAL   (1)
        TYPE_FEVAL  (2)
    end
    methods
        function obj = CallBackTypeEnum(val)
            mlock;
            obj@uint8(val);
        end
    end

end
