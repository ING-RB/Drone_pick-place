classdef(Hidden) TestScriptMLXFileModel < matlab.unittest.internal.TestScriptFileModel
    % This class is undocumented and may change in a future release.
    
    % The TestScriptMLXFileModel utilizes static analysis (via
    % matlab.internal.livecode.* interfaces) in order to retrieve the test
    % content contained inside test sections.

    %  Copyright 2017-2023 The MathWorks, Inc.

    properties(SetAccess = immutable)
        FileCode
        TestSectionNameList
        TestSectionCodeExtentList
        SharedVariableSectionCodeExtent
        FileRelease
    end
    
    properties(Dependent, SetAccess=immutable)
        ScriptValidationFcn
    end
    
    methods(Static)
        function model = fromFile(fileName)
            import matlab.internal.livecode.FileModel;
            fileModel = FileModel.fromFile(fileName); % assumes fileName is a valid mlx file
            info = getScriptInformation(fileName, fileModel);
            model = matlab.unittest.internal.TestScriptMLXFileModel(info);
        end
    end
    
    methods
        function model = TestScriptMLXFileModel(info)
            model = model@matlab.unittest.internal.TestScriptFileModel(info.Filename);
            model.FileCode = info.FileCode;
            model.TestSectionNameList = info.TestSectionNameList;
            model.SharedVariableSectionCodeExtent = info.SharedVariableSectionCodeExtent;
            model.TestSectionCodeExtentList = info.TestSectionCodeExtentList;
            model.FileRelease = info.FileRelease;
        end
        
        function value = get.ScriptValidationFcn(model)
            import matlab.unittest.internal.ScriptFileValidator;
            value = ScriptFileValidator.createScriptFileValidationFcn(model.Filename,...
                'WithExtension',true, 'WithLastModifiedMetaData',true);
        end
    end
end

function info = getScriptInformation(fileName, fileModel)

numSections = numel(fileModel.Sections);
info.FileRelease = string(fileModel.Release);
info.Filename = fileName;
info.FileCode = fileModel.Code;
testNames = repmat({''}, 1, numSections);
info.TestSectionCodeExtentList = cell(1,numSections);

info.SharedVariableSectionCodeExtent = [1,0]; % Currently we do not support a shared variable section

prevLine = 1;
for k=1:numSections
    sectionModel = fileModel.Sections(k);
    hasCodeBlocks = ~isempty(sectionModel.getParagraphsOfType("Code"));
    lines=0;
    if(hasCodeBlocks)
        codeLines = splitlines(sectionModel.Code);
        lines = numel(codeLines);
    end

    startLine = prevLine;    
    headingParagraphModels = sectionModel.getParagraphsOfType("Heading");
    if ~isempty(headingParagraphModels)
        testNames{k} = headingParagraphModels(1).Content;
    end
    
    info.TestSectionCodeExtentList{k} = [startLine,startLine + lines - 1];
    prevLine = startLine + lines;
end

% Setting the function section names as empty to detect only code sections
% as test sections
functionSections = false(1,numSections);
for k=1:numSections
    sectionModel = fileModel.Sections(k);
    functionSections(k) = isFunctionSection(sectionModel);
end

testNames(functionSections)=[];
info.TestSectionCodeExtentList(functionSections)=[];
info.TestSectionNameList = fixTestNames(testNames);
end

function bool = isFunctionSection(sectionModel)
sectionTree = mtree(sectionModel.Code);
functionNode = sectionTree.FileType;
bool = functionNode == mtree.Type.FunctionFile;
end

function testNames = fixTestNames(testNames)
import matlab.lang.makeValidName;
import matlab.lang.makeUniqueStrings;

% Set preferred name for empty cases and cases which will only produce underscores
for k=1:numel(testNames)
    if isempty(regexp(testNames{k},'[a-zA-Z0-9]','once'))
        testNames{k} = sprintf('test_%u',k);
    end
end

[validNames, invalidIdx] = makeValidName(testNames,'Prefix','test');
validNames(~invalidIdx) = makeUniqueStrings(validNames(~invalidIdx), {}, namelengthmax);
testNames = makeUniqueStrings(validNames, invalidIdx, namelengthmax);
end