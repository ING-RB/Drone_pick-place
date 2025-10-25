classdef ValueArray < matlab.mixin.SetGet & matlab.mixin.Copyable
%   This class is for internal use only and will be removed in a later
%   release.
properties (SetObservable) 
    GridFirst = true;
    SampleSize = [];
    MetaData = [];
    Variable = [];
end

    methods 
        function set.GridFirst(obj,value)
        validateattributes(value,{'numeric','logical'}, {'scalar','nonnan'},'','GridFirst')
        value = logical(value); %  convert to logical
        obj.GridFirst = value;
        end

        function set.MetaData(obj,value)
            % DataType = 'handle'
        validateattributes(value,{'handle'}, {'scalar'},'','MetaData')
        obj.MetaData = privateSetMetaData(obj,value);
        end

        function set.Variable(obj,value)
            % DataType = 'handle'
        validateattributes(value,{'handle'}, {'scalar'},'','Variable')
        obj.Variable = value;
        end
    end
end

