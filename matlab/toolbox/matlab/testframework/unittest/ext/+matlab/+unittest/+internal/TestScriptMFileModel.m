classdef(Hidden) TestScriptMFileModel < matlab.unittest.internal.TestScriptFileModel
    % The TestScriptMFileModel utilizes static analysis in order to retrieve
    % the test content contained inside test code sections.
    
    %  Copyright 2016-2023 The MathWorks, Inc.
    
    properties(SetAccess = immutable)
        FileCode
        TestSectionNameList
        TestSectionCodeExtentList
        SharedVariableSectionCodeExtent
    end
    
    properties(Dependent, SetAccess=immutable)
        ScriptValidationFcn
    end
    
    methods(Static)
        function model = fromFile(fileName, parseTree)
            if nargin < 2
                parseTree = mtree(fileName,'-file','-cell');
            end
            info = getScriptInformation(fileName, parseTree);
            model = matlab.unittest.internal.TestScriptMFileModel(info);
        end
    end
    
    methods
        function model = TestScriptMFileModel(info)
            model = model@matlab.unittest.internal.TestScriptFileModel(info.Filename);
            model.FileCode = matlab.internal.getCode(info.Filename);
            model.TestSectionNameList = info.TestSectionNameList;
            model.SharedVariableSectionCodeExtent = info.SharedVariableSectionCodeExtent;
            model.TestSectionCodeExtentList = info.TestSectionCodeExtentList;
        end
        
        function value = get.ScriptValidationFcn(model)
            import matlab.unittest.internal.ScriptFileValidator;
            value = ScriptFileValidator.createScriptFileValidationFcn(model.Filename,...
                'WithExtension',true, 'WithCode',true);
        end
    end
end


function info = getScriptInformation(fileName, parseTree)
info.Filename = fileName;
info.TestSectionNameList = cell(0,1);
info.TestSectionCodeExtentList = cell(0,1);
info.SharedVariableSectionCodeExtent = [1,0];
info.LastLine = 0;

if isInvalidTree(parseTree)
    info = finalizeScriptInformation(info);
    return;
end

rootNode = root(parseTree);
info.LastLine = getlastexecutableline(rootNode);

info = addSectionInformation(info,parseTree);
info = finalizeScriptInformation(info);
end


function bool = isInvalidTree(parseTree)
bool = parseTree.isnull || (parseTree.count == 1 && parseTree.iskind('ERR'));
end


function info = addSectionInformation(info,parseTree)
info.SharedVariableSectionCodeExtent = [1,info.LastLine];
thisNode = parseTree.select(1);
while ~isempty(thisNode)
    kind = thisNode.kind;
    if strcmp(kind,'CELLMARK')
        info = addTestSection(info,thisNode);
    end
    thisNode = thisNode.Next;
end
end


function info = addTestSection(info,thisNode)
lineNum = getLineSections(info, thisNode);
info = shortenPreviousSection(info,lineNum(1));

info.TestSectionCodeExtentList{end+1} = lineNum;
info.TestSectionNameList(end+1) = regexp(thisNode.string,...
    '^\s*%%\s*(.*?)\s*$','tokens','once');
end

function sectionLineExtent = getLineSections(info, thisNode)
sectionStartLineNum = lineno(thisNode);
sectionLineExtent = [sectionStartLineNum, info.LastLine];
end


function info = shortenPreviousSection(info,currentSectionStartLineNum)
if isempty(info.TestSectionCodeExtentList)
    info.SharedVariableSectionCodeExtent(2) = ...
        currentSectionStartLineNum - 1;
else
    info.TestSectionCodeExtentList{end}(2) = ...
        currentSectionStartLineNum - 1;
end
end

function info = finalizeScriptInformation(info)
import matlab.lang.makeValidName;
import matlab.lang.makeUniqueStrings;
if isempty(info.TestSectionNameList)
    % If no test sections (identified by %%) then use everything
    % as a single test section.
    [~,shortName,~] = fileparts(info.Filename);
    info.TestSectionNameList = {shortName};
    info.TestSectionCodeExtentList = {info.SharedVariableSectionCodeExtent};
    info.SharedVariableSectionCodeExtent = [1,0];
else
    [validNames, invalidIdx] = makeValidName(info.TestSectionNameList,'Prefix','test');
    validNames(~invalidIdx) = makeUniqueStrings(validNames(~invalidIdx), {}, namelengthmax);
    info.TestSectionNameList = makeUniqueStrings(validNames, invalidIdx, namelengthmax);
end
end

% LocalWords:  isnull lang iskind CELLMARK