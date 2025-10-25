function executeScriptLines(scriptName,sectionStartLineNum,sectionEndLineNum)
% This function is undocumented and may change in a future release.

% Note: Calls to this function are set by the TestScriptFileModel and
% placed on to the ScriptTestCaseProvider starting in R2024a. Since
% ScriptTestCaseProvider is serialized, this function is required to allow
% script based test suites from R2024a and after to be loaded from a MAT
% file.

%  Copyright 2023 The MathWorks, Inc.
if(sectionStartLineNum<=sectionEndLineNum)
    matlab.lang.internal.executeCodeBlock('caller',scriptName,double.empty(0,2),sectionStartLineNum,sectionEndLineNum);
end
end