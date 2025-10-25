classdef ProjectFile
%ProjectFile  A file or folder within a project
%    The properties of files and folders in a project can be queried to
%    get the full path to the file, and for information about any
%    labels that have been attached to the file.
%
%    Example:
%
%    % Open the Airframe example project:
%    openExample("simulink/AirframeProjectExample")
%
%    % Get the project:
%    project = currentProject;
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
%                   Path: 'C:\Users\Username\MATLAB\airframe\custom_tasks\analyzeModelFiles.m'
%                 Labels: [1x1 slproject.Label]
%               Revision: '2'
%    SourceControlStatus: Unmodified
%
%    See also currentProject

 
%   Copyright 2010-2023 The MathWorks, Inc.

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
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    % Select a file within this project
            %    file = findFile(project, ...
            %                fullfile('custom_tasks', 'analyzeModelFiles.m'));
            %    % Create a test result category within this project
            %    testCategory = createCategory(project, 'Test Result', 'char');
            %    % Create a 'Failed' label definition
            %    failedLabelDefinition = createLabel(testCategory, 'Failed');
            %    % Add this label to this file:
            %    addLabel(file, failedLabelDefinition)
            %    % Add this label to this file with some data:
            %    addLabel(file, failedLabelDefinition, 'Wrong answer')
            %    label = findLabel(file, 'Test Result', 'Failed')
        end

        function out=findLabel(~) %#ok<STOUT>
            %findLabel  Get a label attached to this file
            %
            %    Usage:
            %    label = findLabel(file, categoryName, labelName);
            %    label = findLabel(file, labelDefinition);
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    file = findFile(project, ...
            %                fullfile('custom_tasks', 'analyzeModelFiles.m'));
            %    label = findLabel(file, 'Classification', 'Utility')
            %    % This file has this label attached.
            %
            %    classificationCategory = project.Categories(1);
            %    artifactLabelDefinition = ...
            %                     classificationCategory.LabelDefinitions(1);
            %    label = findLabel(file, artifactLa[transformed{:}]belDefinition)
            %    % This file does not have this label attached.
        end

        function out=removeLabel(~) %#ok<STOUT>
            %removeLabel  Detach a label from this file
            %
            %    Usage:
            %    removeLabel(file,label)
            %    removeLabel(file, categoryName, labelName)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    % Select a file within this project
            %    file = findFile(project, ...
            %                fullfile('custom_tasks', 'analyzeModelFiles.m'));
            %    % Select the classification category within this project
            %    classificationCategory = findCategory(project, 'Classification');
            %    % Select the 'Utility' label definition
            %    utilityLabelDefinition = findLabel(classificationCategory, ...
            %                                'Utility');
            %    % Add this label to this file:
            %    addLabel(file, utilityLabelDefinition)
            %    % Now remove it:
            %    label=findLabel(file,'Classification','Utility')
            %    removeLabel(file, label)
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
