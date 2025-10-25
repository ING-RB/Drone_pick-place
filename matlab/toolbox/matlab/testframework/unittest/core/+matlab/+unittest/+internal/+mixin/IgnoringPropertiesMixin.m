% This class is undocumented.

% The IgnoringPropertiesMixin can be included as a part of class that supports
% specifying entities to ignore. See NameValueMixin.m for details on the
% process to utilize this mixin.

%  Copyright 2015-2017 The MathWorks, Inc.
classdef (Hidden,HandleCompatible) IgnoringPropertiesMixin < matlab.unittest.internal.mixin.NameValueMixin
    properties (SetAccess=private)
        % IgnoredProperties - Properties to ignore
        %
        %   When specified, the instance ignores these Properties.
        %
        %   The IgnoredProperties property is empty by default, but can be specified
        %   during construction of the instance by utilizing the (...,
        %   'IgnoringProperties', value) parameter value pair.
        IgnoredProperties = cell(1,0);
    end
    
    methods (Hidden, Access=protected)
        function mixin = IgnoringPropertiesMixin
            % Add Ignoring parameter and its set function
            mixin = mixin.addNameValue('IgnoringProperties', ...
                @setIgnoredProperties, ...
                @ignoringPropertiesPreSet,...
                @ignoringPropertiesPostSet);
        end
        
        function [mixin,value] = ignoringPropertiesPreSet(mixin, value)
            import matlab.unittest.internal.mustBeTextArray;
            import matlab.unittest.internal.mustContainCharacters;
            mustBeTextArray(value,'IgnoredProperties');
            mustContainCharacters(value,'IgnoredProperties');
            value = unique(reshape(cellstr(value),1,[]));
        end
        
        function mixin = ignoringPropertiesPostSet(mixin)
        end
    end
    
    methods (Hidden, Sealed)
        function mixin = ignoringProperties(mixin, value)
            [mixin,value] = mixin.ignoringPropertiesPreSet(value);
            mixin = mixin.setIgnoredProperties(value);
            mixin = mixin.ignoringPropertiesPostSet();
        end
    end
    
    methods (Access = private)
        function mixin = setIgnoredProperties(mixin, value)
            mixin.IgnoredProperties = value;
        end
    end
end