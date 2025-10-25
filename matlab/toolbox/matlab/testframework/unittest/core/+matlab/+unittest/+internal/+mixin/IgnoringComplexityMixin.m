% This class is undocumented.

% The IgnoringComplexityMixin can be included as a part of any class that can
% ignore complexity differences. See NameValueMixin.m for details on the process
% to utilize this mixin.

% Copyright 2019-2022 The MathWorks, Inc.

classdef (Hidden) IgnoringComplexityMixin < matlab.unittest.internal.mixin.NameValueMixin
    properties (Hidden, SetAccess=private)
        % IgnoreComplexity - Boolean indicating whether this instance is insensitive to complexity
        %
        %   When this value is true, the instance is insensitive to complexity
        %   differences. When it is false, the instance is sensitive to complexity.
        %
        %   The IgnoreComplexity property is false by default, but can be
        %   specified to be true during construction of the instance by
        %   utilizing the (..., 'IgnoringComplexity', true) parameter value pair.
        IgnoreComplexity (1,1) logical = false;
    end
    
    methods (Hidden, Access = protected)
        function mixin = IgnoringComplexityMixin
            mixin = mixin.addNameValue('IgnoringComplexity', ...
                @setIgnoreComplexity,...
                @ignoringComplexityPreSet,...
                @ignoringComplexityPostSet);
        end
        
        function [mixin, value] = ignoringComplexityPreSet(mixin, value)
        end
        
        function mixin = ignoringComplexityPostSet(mixin)
        end
    end
    
    methods (Hidden, Sealed)
        function mixin = ignoringComplexity(mixin)
            mixin = mixin.setIgnoreComplexity(true);
            mixin = mixin.ignoringComplexityPostSet();
        end
    end
    
    methods (Access=private)
        function mixin = setIgnoreComplexity(mixin, value)
            mixin.IgnoreComplexity = value;
        end
    end
end