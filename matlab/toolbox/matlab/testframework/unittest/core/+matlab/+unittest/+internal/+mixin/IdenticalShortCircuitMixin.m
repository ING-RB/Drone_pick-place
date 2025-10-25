% This class is undocumented.

% Copyright 2018-2022 The MathWorks, Inc.

classdef (Hidden, HandleCompatible) IdenticalShortCircuitMixin < matlab.unittest.internal.mixin.NameValueMixin
    properties (Hidden, SetAccess=private, GetAccess=protected)
        IdenticalShortCircuit_ (1,1) logical = false;
    end
    
    methods (Hidden, Access=protected)
        function mixin = IdenticalShortCircuitMixin
            mixin = mixin.addNameValue('IdenticalShortCircuit_', ...
                @setIdenticalShortCircuit);
        end
    end
    
    methods (Access=private)
        function mixin = setIdenticalShortCircuit(mixin, value)
            mixin.IdenticalShortCircuit_ = value;
        end
    end
end

% LocalWords:  unittest
