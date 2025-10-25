classdef(Hidden) WithCountMixin < matlab.unittest.internal.mixin.NameValueMixin
    % This class is undocumented.
    
    %  Copyright 2018 The MathWorks, Inc.
    
    % The WithCountMixin can be included as a part of class that supports
    % specifying entities that need to find the number of ocurrence.
    % See NameValueMixin.m for details on the process to utilize this mixin.
    
    properties (Hidden, SetAccess=private)
        % Count - The numeric value for comparing the returned regexp count.
        %
        %   When specified, the instance compares the regexp count
        %   values with the user input.
        %
        %   The Count property is empty by default, but can be specified during
        %   construction of the instance by utilizing the (..., 'WithCount ', value)
        %   parameter value pair.
        Count(1,1) = 0;
        CountValueProvidedExplicitly(1,1) logical = false;
    end
    
    methods (Hidden, Access=protected)
        function mixin = WithCountMixin
            mixin = mixin.addNameValue('WithCount', ...
                @setWithCount,...
                @withCountPreSet);
        end
        
        function [mixin,value] = withCountPreSet(mixin,value)
            validateattributes(value,{'numeric'},{'scalar', 'finite', 'positive', 'integer','nonnan'},'','Count');
        end
    end    
        
    methods (Access=private)
        function mixin = setWithCount(mixin, value)
            mixin.Count = value;
            mixin.CountValueProvidedExplicitly = true;
        end
    end
end

