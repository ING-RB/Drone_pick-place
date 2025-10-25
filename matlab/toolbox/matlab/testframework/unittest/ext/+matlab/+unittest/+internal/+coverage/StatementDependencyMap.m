classdef StatementDependencyMap
    % Class is undocumented and may change in a future release.

    %  Copyright 2023 The MathWorks, Inc.

    % TO DO: Try to make the structure as close as possible to Emmanuel's
    % requirements.

    properties
        TrueLines
        FalseLines
        StatementLine
        StatementType
        RawNode
    end

    methods
        function obj = StatementDependencyMap(rawNode, statementType, statementLineNumber,trueLines,falseLines)
            obj.RawNode = rawNode;
            obj.TrueLines = trueLines;
            obj.FalseLines = falseLines;
            obj.StatementLine = statementLineNumber;
            obj.StatementType = statementType;
        end

        function objArray = append(objArray1, objArray2)
            objArray = [objArray1, objArray2(:)'];
        end
    end
end