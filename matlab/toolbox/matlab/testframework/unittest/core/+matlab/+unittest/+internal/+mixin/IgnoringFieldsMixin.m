% This class is undocumented.

% The IgnoringFieldsMixin can be included as a part of class that supports
% specifying entities to ignore. See NameValueMixin.m for details on the
% process to utilize this mixin.

%  Copyright 2015-2017 The MathWorks, Inc.
classdef (Hidden) IgnoringFieldsMixin < matlab.unittest.internal.mixin.NameValueMixin
    properties (SetAccess=private)
        % IgnoredFields - Fields to ignore
        %
        %   When specified, the instance ignores these fields.
        %
        %   The IgnoredFields property is empty by default, but can be specified
        %   during construction of the instance by utilizing the (...,
        %   'IgnoringFields', value) parameter value pair.
        IgnoredFields = cell(1,0);
    end
    
    methods (Hidden, Access=protected)
        function mixin = IgnoringFieldsMixin
            % Add Ignoring parameter and its set function
            mixin = mixin.addNameValue('IgnoringFields', ...
                @setIgnoredFields, ...
                @ignoringFieldsPreSet,...
                @ignoringFieldsPostSet);
        end
        
        function [mixin,value] = ignoringFieldsPreSet(mixin, value)
            import matlab.unittest.internal.mustBeTextArray;
            import matlab.unittest.internal.mustContainCharacters;
            mustBeTextArray(value,'IgnoredFields');
            mustContainCharacters(value,'IgnoredFields');
            value = unique(reshape(cellstr(value),1,[]));
        end
        
        function mixin = ignoringFieldsPostSet(mixin)
        end
    end
    
    methods (Hidden, Sealed)
        function mixin = ignoringFields(mixin, value)
            [mixin,value] = mixin.ignoringFieldsPreSet(value);
            mixin = mixin.setIgnoredFields(value);
            mixin = mixin.ignoringFieldsPostSet();
        end
    end
    
    methods (Access = private)       
        function mixin = setIgnoredFields(mixin, value)
            mixin.IgnoredFields = value;
        end
    end
end