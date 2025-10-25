classdef AppMCodeBuilder < handle
    %APPMCODEBUILDER handle-class allowing pass-by-reference behavior when recursively
    % building the component M code. Pre-allocates the code lines, increasing in size when
    % necessary for performance

%   Copyright 2024 The MathWorks, Inc.

    properties (Access = private)
        CodeLines
        CurrentCount double = 1;
    end

    properties (Access = public)
        ObjectName string = "app";
    end

    methods
        function obj = AppMCodeBuilder(size)
            arguments
                size double
            end

            obj.CodeLines = strings(1, size);
        end

        function addCodeLine(obj, codeLine)
            arguments
                obj
                codeLine
            end

            % For now, this function would only be called less than 10 times,
            % it's OK to manipulate on class property directly
            obj.CodeLines(obj.CurrentCount) = codeLine;
            
            obj.CurrentCount = obj.CurrentCount + 1;
        end

        function addCodeLines(obj, codeLineList)
            count = length(codeLineList);

            newCurrentCount = obj.CurrentCount + count;

            obj.CodeLines(obj.CurrentCount:newCurrentCount-1) = codeLineList;
            obj.CurrentCount = newCurrentCount;
        end

        function codeContent = joinCodeLines(obj)
            codeContent = join(obj.CodeLines(1:obj.CurrentCount-1), newline);
        end
    end
end
