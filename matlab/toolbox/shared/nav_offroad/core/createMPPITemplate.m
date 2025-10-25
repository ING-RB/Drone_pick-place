function createMPPITemplate
%

% Copyright 2024 The MathWorks, Inc.


% Read in template code
fileName = 'customCostExample';
exampleFile = fullfile(toolboxdir("shared"), "nav_offroad", "core", "+nav",...
    "+algs", "+mppi", "+internal", fileName + ".m");
fid = fopen(exampleFile);
contents = fread(fid, "*char");
fclose(fid);


% Open template code in an Untitled file in the editor
editorDoc = matlab.desktop.editor.newDocument(contents(:)');


% Change the function name to a custom name. Replace all instances of the
% class name with the new custom name.
contents = regexprep(editorDoc.Text,...
    fileName, "customCost");

% Remove the MathWorks Copyright line
% contents = regexprep(contents,...
    % "^%   Copyright.*$", "", "lineanchors", "dotexceptnewline", "once");

% Reload the modified file contents in the editor window
editorDoc.Text = contents;
editorDoc.smartIndentContents;
editorDoc.goToLine(1);
