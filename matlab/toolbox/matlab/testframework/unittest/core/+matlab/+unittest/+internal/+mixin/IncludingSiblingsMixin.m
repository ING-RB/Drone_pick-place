% This class is undocumented.

% Copyright 2016-2022 The MathWorks, Inc.

classdef (Hidden) IncludingSiblingsMixin < matlab.unittest.internal.mixin.NameValueMixin
    properties (Hidden, SetAccess=private)
        IncludeSiblings (1,1) logical = false;
    end
    
    methods (Hidden, Access=protected)
        function mixin = IncludingSiblingsMixin
            mixin = mixin.addNameValue('IncludingSiblings',...
                @setIncludeSiblings);
        end
    end
    
    methods (Hidden, Sealed)
        function mixin = includingSiblings(mixin)
            mixin.IncludeSiblings = true;
        end
    end
end

function mixin = setIncludeSiblings(mixin, value)
mixin.IncludeSiblings = value;
end
