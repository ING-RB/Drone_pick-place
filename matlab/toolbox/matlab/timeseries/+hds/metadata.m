classdef metadata < matlab.mixin.SetGet & matlab.mixin.Copyable
%   This class is for internal use only and will be removed in a later
%   release.
    properties (SetObservable)
        Units = '';
    end


    methods
        function set.Units(obj,value)
            % DataType = 'string'
            validateattributes(value,{'char'}, {'row'},'','Units')
            obj.Units = value;
        end
    end
end

