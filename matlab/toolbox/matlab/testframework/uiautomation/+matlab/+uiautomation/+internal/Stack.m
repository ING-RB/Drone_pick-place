classdef(Hidden) Stack < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2024 The MathWorks, Inc.

    properties(Access=private)
        Values = {};
    end

    methods

        function push(stack,value)
            stack.Values(end+1) = {value};
        end

        function value = pop(stack)
            if isempty(stack.Values)
                value = [];
                return
            end
            value = stack.Values{end};
            stack.Values(end) = [];
        end

        function top = peek(stack)
            if isempty(stack.Values)
                top = stack.Values;
                return
            end
            top = stack.Values{end};
        end

    end   
end