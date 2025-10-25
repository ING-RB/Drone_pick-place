classdef LabelDefinition
%LabelDefinition
%    A LabelDefinition is a definition of a label that can be attached
%    to a file in the currently loaded project.
%
%    Example:
%
%    % Open the Airframe example project:
%    openExample("simulink/AirframeProjectExample")
%
%    % Get the project:
%    project = currentProject;
%
%    % Get the categories for this project:
%    categories = project.Categories
%
%    categories =
%        Category with properties:
%
%                    Name: 'Classification'
%                DataType: 'none'
%        LabelDefinitions: [1x8 slproject.LabelDefinition]
%
%    % Create a new LabelDefinition in the first category, Classification:
%    newLabel = createLabel(categories, 'Data');
%
%    % Create a new label in the Classification category with name Test:
%    newLabel = slproject.LabelDefinition('Classification','Test');
%
%    % Attach it to a file in the project:
%    file = findFile(project, ...
%                   fullfile('custom_tasks', 'saveModelFiles.m'));
%    addLabel(file, newLabel);
%
%    The category for the new label must already exist in the current
%    project. To create new categories, use the createCategory method
%    of currentProject. The label name does not need to
%    already exist, and will be created automatically if it does not.
%
%    See also currentProject, openProject

 
%   Copyright 2011-2023 The MathWorks, Inc.

    methods
        function out=LabelDefinition
            % Label  - Constructor
            %
            % Usage obj = LabelDefinition(categoryName, labelName);
            %
            %
            % where:
            %
            %     categoryName - char - the name of the parent category.
            %
            %     labelName - char - the name of the label.
        end

    end
    properties
        % The name of the label's parent category.
        CategoryName;

        % The label's name
        Name;

    end
end
