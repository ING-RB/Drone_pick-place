classdef (Sealed) Analysis
%matlab.codeanalyzer.internal.Analysis stores the MATLAB code information.

%   Copyright 2020-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        % File type for the MATLAB code
        FileType (1,1) matlab.codeanalyzer.internal.FileType

        % Table of code section information
        % titles     - title of each section
        % startLines - start line number of each section
        % endLines   - end line number of each section
        % isExplicit - whether this section is explicit declared by user,
        %              or added based on code structure.
        CodeSections table
        % Code Structure information, contains all the Code block and
        % comment block.
        CodeStructures (1,:) matlab.codeanalyzer.internal.CodeStructure
        % Whether the code contains syntax errors.
        % This cannot be true if AllowSyntaxError is set to false.
        HasSyntaxError (1,1) logical
        % Whether the code contains syntax errors that affecting the
        % structure of the code.
        % Code Structure information might be incorrect if this is true.
        HasStructureError (1,1) logical
    end

    methods (Hidden)
        function obj = Analysis(builtinResult)
            obj.FileType = builtinResult.fileType;

            sections = struct2table(builtinResult.codeSections);
            sections = movevars(sections,{'isExplicit'}, "After", "endLines");
            sections.Properties.VariableNames(1) = {'titles'};
            obj.CodeSections = sections;

            obj.CodeStructures = matlab.codeanalyzer.internal.CodeStructure.createCodeStructures(builtinResult.blocks);

            obj.HasSyntaxError = builtinResult.hasTreeError;
            obj.HasStructureError = builtinResult.hasStructureError;
        end
    end
end
