classdef InputFormatInput < matlab.io.internal.FunctionInterface
    %InputFormatInput 

%   Copyright 2018 The MathWorks, Inc.

    properties (Parameter)
        InputFormat = ''
    end
    
    methods
        function obj = set.InputFormat(obj,fmt)
        fmt = convertCharsToStrings(fmt);
        obj.setInputFormat(fmt);
        obj.InputFormat = char(fmt);
        end
    end
    
    methods (Abstract, Access = protected)
        fmt = setInputFormat(obj,fmt)
    end
end

