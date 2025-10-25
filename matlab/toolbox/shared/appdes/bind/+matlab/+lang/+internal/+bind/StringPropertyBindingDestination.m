classdef StringPropertyBindingDestination < matlab.lang.internal.bind.PropertyBindingDestination
    %STRINGPROPERTYBINDINGDESTINATION A BindingDestination that is used for
    %destination objects that have a public property that needs to take a
    %string value.

    % Copyright 2023 The MathWorks, Inc.

    methods        
        function setData(obj, varargin)
            % Override setData to first convert the value to a string

            data = string(varargin{1});

            setData@matlab.lang.internal.bind.PropertyBindingDestination(obj, data)
        end
    end
end

