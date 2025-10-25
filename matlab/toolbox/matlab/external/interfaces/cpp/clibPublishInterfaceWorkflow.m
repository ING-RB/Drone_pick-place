%clibPublishInterfaceWorkflow Creates and opens a new live script for the 
%C++ interface publisher workflow
%
%   clibPublishInterfaceWorkflow Creates and opens a new live script into
%   the MATLAB editor. The live script contains the steps for the C++
%   interface publisher workflow.
%
%   The generated live script name is of the form untitledX.mlx where X is
%   a number which can be renamed.

%   Copyright 2022 The MathWorks, Inc. 
function clibPublishInterfaceWorkflow
    narginchk(0,0);
    % Start with untitled filename.
    fullFilename = fullfile(cd, 'untitled.mlx');
    % Determine the ending number for the untitled file
    n = 0;
    while isfile(fullFilename)
        n = n + 1;
        % The "untitled" file exists, try another one
        fullFilename = fullfile(cd, ['untitled' sprintf('%d', n) '.mlx']);
    end
    % Popup dialog to accept or choose another filename, or quit script
    [userfilename,userpathname] = uiputfile(fullFilename,...
        getString(message('MATLAB:CPPUI:WorkflowScripNameSelectiontTitle')));
    if ~isequal(userfilename,0) && ~isequal(userpathname,0)
        newfullFilename = fullfile(userpathname,userfilename);
        if ~strcmp(newfullFilename, fullFilename)
            fullFilename = newfullFilename;
        end
    else
        % cancel
        return;
    end
    % Copy template script to new name and open in the editor
    templateFile = fullfile(matlabroot,'toolbox','matlab','external', ...
        'interfaces','cpp','internal','publishInterfaceWorkflowTemplate.mlx');
    copyfile(templateFile, fullFilename);
    fileattrib(fullFilename,'+w');
    matlab.desktop.editor.openDocument(fullFilename);
    while ~matlab.desktop.editor.isOpen(fullFilename)
        pause(0.05); % Allow editor some time to process events
    end
    % Set focus
    matlab.desktop.editor.openDocument(fullFilename);
end

% LocalWords:  mlx
