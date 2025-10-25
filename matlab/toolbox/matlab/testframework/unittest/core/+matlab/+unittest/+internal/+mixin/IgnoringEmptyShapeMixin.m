% This class is undocumented.

% The IgnoringEmptyShapeMixin can be included as a part of any class that can
% ignore different sized empties (i.e., 0x0, 1x0, 0x1). See NameValueMixin.m for 
% details on the process to utilize this mixin.

% Copyright 2021-2022 The MathWorks, Inc.

classdef (Hidden) IgnoringEmptyShapeMixin < matlab.unittest.internal.mixin.NameValueMixin
    properties (Hidden, SetAccess=private)
        % IgnoreEmptyShape - Boolean indicating whether this instance is
        % insensitive to empty size dimensions
        %
        %   When this value is true, the instance is insensitive to empty
        %   size dimensions. When it is false, the instance is sensitive to empty size
        %   dimensions.
        %
        %   The IgnoreEmptyShape property is false by default, but can be
        %   specified to be true during construction of the instance by
        %   utilizing the (..., 'IgnoringEmptyShape', true) parameter value pair.
        IgnoreEmptyShape (1,1) logical = false;
    end
    
    methods (Hidden, Access = protected)
        function mixin = IgnoringEmptyShapeMixin
            mixin = mixin.addNameValue('IgnoringEmptyShape', ...
                @setIgnoreEmptyShape,...
                @ignoringEmptyShapePreSet,...
                @ignoringEmptyShapePostSet);
        end
        
        function [mixin, value] = ignoringEmptyShapePreSet(mixin, value)
        end
        
        function mixin = ignoringEmptyShapePostSet(mixin)
        end
    end
    
    methods (Hidden, Sealed)
        function mixin = ignoringEmptyShape(mixin)
            mixin = mixin.setIgnoreEmptyShape(true);
            mixin = mixin.ignoringEmptyShapePostSet();
        end
    end
    
    methods (Access=private)
        function mixin = setIgnoreEmptyShape(mixin, value)
            mixin.IgnoreEmptyShape = value;
        end
    end
end