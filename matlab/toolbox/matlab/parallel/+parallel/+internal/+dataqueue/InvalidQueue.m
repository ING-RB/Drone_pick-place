classdef InvalidQueue < handle
    % Internal implementation of DataQueue used when deserialization fails.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        Size = 0
    end
    
    properties (SetAccess = immutable)
        Error
    end
    
    % Common methods implemented by all Queue implementation classes
    methods
        function obj = InvalidQueue(arg)
            % The zero-arg constructor stores a default exception.
            % Alternatively the exception can be passed on construction.
            if nargin == 0
                obj.Error = MException("MATLAB:parallel:dataqueue:NoPool","error");
            else
                obj.Error = arg;
            end
        end
        
        function add(obj, ~, ~)
            throw(obj.Error);
        end
        
        function out = poll(~, ~) %#ok<STOUT>
            throw(obj.Error);
        end
        
        function out = drain(~) %#ok<STOUT>
            throw(obj.Error);
        end
        
        function clear(~)
            throw(obj.Error);
        end
    end
end
