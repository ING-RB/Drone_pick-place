function procedureName = getSelectedTestProcedureNames(fileName, selectionStartPosition, selectionEndPosition)
% This function is undocumented and may change in a future release.

% Copyright 2017-2024 The MathWorks, Inc.

import matlab.unittest.internal.fileResolver;
import matlab.internal.getCode;

fileName = fileResolver(fileName);

% Because matlab.desktop.editor.Document's ExtendedSelection value counts
% sprintf("\r\n") as one character but mtree's leftposition and
% rightposition values count this as two, we need to collapse these two
% newline characters into one before passing to mtree.
code = getCode(fileName);
code = regexprep(code, "\r\n", "\n");
parseTree = mtree(code,'-comments');

if parseTree.isnull
    procedureName = cell(1,0);
    return;
end

if parseTree.root.iskind('ERR')
    parseTreeError = MException("MATLAB:unittest:TestSuite:ParseTreeError", "%s", string(parseTree));
    parseError = MException(message("MATLAB:unittest:TestSuite:ParseError", fileName));
    parseError = parseError.addCause(parseTreeError);
    throwAsCaller(parseError);
end

root = parseTree.root;
if root.FileType == mtree.Type.ClassDefinitionFile
    subTree = getFunctionsFromTestMethodBlocksSubTree(parseTree);
    allFunctionNames = subTree.Fname;
    procedureName = getSelectedProcedureNames(subTree, allFunctionNames, selectionStartPosition, selectionEndPosition);
    
elseif root.FileType == mtree.Type.FunctionFile
    subTree = getTestSubFunctionsSubTree(parseTree);
    allFunctionNames = subTree.root.Next.List.Fname;
    procedureName = getSelectedProcedureNames(subTree, allFunctionNames, selectionStartPosition, selectionEndPosition);
    if (~isempty(procedureName))
        procedureName = functionSelectedTestProcedures(fileName, procedureName);
    end
else
    % To address edge case where file is updated to script and button is
    % clicked before save occurs, we force empty procedureName.
    procedureName = cell(1,0);
    return;
end

end

function functionsFromTestMethodBlocks = getFunctionsFromTestMethodBlocksSubTree(parseTree)
testMethodsTree = parseTree.mtfind('Kind', 'METHODS', 'Attr.Arg.List.Any.Left.String', 'Test' );
functionsFromTestMethodBlocks = testMethodsTree.Body.List.mtfind('Kind','FUNCTION');
end

function subTree = getTestSubFunctionsSubTree(parseTree)
subTree = parseTree.root.Next.List.mtfind('Kind','FUNCTION');
end


function selectedProcedureNames = functionSelectedTestProcedures(fileName, procedureName)
import matlab.unittest.TestSuite;
try
    suite = TestSuite.fromFile(fileName, "ProcedureName",procedureName);    
    selectedProcedureNames = {suite.ProcedureName};
catch
    selectedProcedureNames = cell(1,0);  
end
end

function procedureName = getSelectedProcedureNames(subTree, allFunctionNames, selectionStartPosition, selectionEndPosition)
allfunctionStartIndices = subTree.lefttreepos.';
allfunctionEndIndices = subTree.righttreepos.'+1;

procedureName = allFunctionNames.strings;
procedureNameAtStart = selectionStartPosition <= allfunctionEndIndices;
procedureNameAtEnd = selectionEndPosition >= allfunctionStartIndices;
procedureName = procedureName(any((procedureNameAtStart & procedureNameAtEnd), 1));
end

% LocalWords:  unittest mcheck mde mtree's leftposition rightposition isnull
% LocalWords:  testsuite mtfind Fname iskind namingconvention
