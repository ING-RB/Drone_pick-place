classdef (Sealed) CodeStructure
%matlab.codeanalyzer.internal.CodeStructure represent code structure in MATLAB

%   Copyright 2024 The MathWorks, Inc.

    properties (SetAccess=private)
        Name (1,1) string % Name of the block if exist, i.e. function name
        Type (1,1) matlab.codeanalyzer.internal.CodeStructureType
        StartLine (1,1) double
        EndLine (1,1) double
        StartColumn (1,1) double
        EndColumn (1,1) double
        NestedStructures (1,:) matlab.codeanalyzer.internal.CodeStructure
    end

    methods
        function obj = CodeStructure(structure)
            arguments
                structure struct
            end
            obj.Name = structure.name;
            obj.Type = computeType(structure.type);
            obj.StartLine = structure.startLine;
            obj.EndLine = structure.endLine;
            obj.StartColumn = structure.startColumn;
            obj.EndColumn = structure.endColumn;
            obj.NestedStructures = matlab.codeanalyzer.internal.CodeStructure.createCodeStructures(structure.blocks);
        end
    end

    methods(Static)
        function array = createCodeStructures(blocks)
            arguments
                blocks struct
            end
            array = matlab.codeanalyzer.internal.CodeStructure.empty();
            for i = 1:numel(blocks)
                array(i) = matlab.codeanalyzer.internal.CodeStructure(blocks(i));
            end
        end

    end
end

function type = computeType(str)
    if str == "else"
        type = matlab.codeanalyzer.internal.CodeStructureType.elseBlock;
    elseif str == "classdef"
        type = matlab.codeanalyzer.internal.CodeStructureType.classDefinition;
    elseif str == "method"
        type = matlab.codeanalyzer.internal.CodeStructureType.methodDefinition;
    else
        type = matlab.codeanalyzer.internal.CodeStructureType(str);
    end
end
