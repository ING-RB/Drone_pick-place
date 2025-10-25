classdef ProjectFile< handle
%ProjectFile  File or folder within a project
%    The properties of files and folders in a project can be
%    queried to get the full path to the file, and for information
%    about any labels that have been attached to the file.
%
%    Example:
%
%    % Get the currently open project:
%    project = currentProject
%
%    % Get the files in this project:
%    allFiles = project.Files;
%
%    % Examine the third file (for example)
%    f3 = allFiles(3)
%
%    f3 =
%
%        ProjectFile with properties:
%
%                   Path: '/tmp/20121026T095355/airframe/custom_tasks/analyzeModelFiles.m'
%                 Labels: [1x1 matlab.project.Label]
%               Revision: '2'
%    SourceControlStatus: Unmodified
%
%    See also currentProject

 
%   Copyright 2022-2024 The MathWorks, Inc.

    methods
        function out=addLabel(~) %#ok<STOUT>
            %addLabel  Attach a label to this file
            %
            %    Usage:
            %    label = addLabel(file, labelDefinition);
            %    label = addLabel(file, labelDefinition, data);
            %
            %    label = addLabel(file, categoryName, labelName)
            %    label = addLabel(file, categoryName, labelName, data)
            %
            %    Example:
            %    project = currentProject;
            %    % Create and add a file to the project
            %    filepath = fullfile(project.RootFolder, 'data.mat');
            %    save(filepath);
            %    file = project.addFile(filepath);
            %    % Create a test result category within this project
            %    testCategory = createCategory(project, 'Test Result', 'char');
            %    % Create a 'Failed' label definition
            %    failedLabelDefinition = createLabel(testCategory, 'Failed');
            %    % Add this label to this file:
            %    addLabel(file, failedLabelDefinition)
            %    % Add this label to this file with some data:
            %    addLabel(file, failedLabelDefinition, 'Wrong answer');
            %    label = findLabel(file, 'Test Result', 'Failed')
        end

        function out=findLabel(~) %#ok<STOUT>
            %findLabel  Get a label attached to this file
            %
            %    Usage:
            %    label = findLabel(file, categoryName, labelName);
            %    label = findLabel(file, labelDefinition);
        end

        function out=removeLabel(~) %#ok<STOUT>
            %removeLabel  Detach a label from this file
            %
            %    Usage:
            %    removeLabel(file, label)
            %    removeLabel(file, categoryName, labelName)
        end

    end
    properties
        % An array of the labels attached to this file
        Labels;

        % The full path to this file
        Path;

        % A string from the source control tool that describes the revision
        % of the local file
        Revision;

        % An enumeration value describing the source control status
        % of the local file
        SourceControlStatus;

    end
end
