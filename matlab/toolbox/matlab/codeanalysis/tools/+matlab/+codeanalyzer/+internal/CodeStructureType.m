classdef CodeStructureType
%

%   Copyright 2024 The MathWorks, Inc.

    enumeration
        classDefinition
        functionDefinition
        methodDefinition

        ifStatement
        forStatement
        whileStatement
        switchStatement
        tryStatement
        parforStatement
        spmdStatement

        enumerationBlock
        eventsBlock
        methodsBlock
        propertiesBlock
        argumentsBlock

        elseifBlock
        elseBlock
        caseSelection
        otherwiseBlock
        catchBlock

        section
        comment
        blockComment
    end
end
