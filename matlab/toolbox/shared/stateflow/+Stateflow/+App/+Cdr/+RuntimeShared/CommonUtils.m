classdef CommonUtils < handle
%

%   Copyright 2020 The MathWorks, Inc.

    properties
        nestedObjects = [];
        currentInstance = []
        currentInstanceId = [];
        counter = 0;

    end
    methods(Access=private)
        function obj = CommonUtils
        end
    end
    methods(Static)
        function retval = instance
            persistent obj
            if isempty(obj)
                obj = Stateflow.App.Cdr.RuntimeShared.CommonUtils;
                obj.nestedObjects = containers.Map('KeyType', 'double', 'ValueType', 'any');
                obj.currentInstance = [];
                obj.currentInstanceId = [];
                obj.counter = 0;
            end
            retval = obj;
        end
    end
end
