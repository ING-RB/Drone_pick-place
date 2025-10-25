classdef Category< handle
%Category  Label category
%    Provides information about the categories of labels in the current
%    project. It cannot be used to create new categories or modify
%    existing ones.
%
%    To create new categories use the createCategory method of the
%    currently loaded project.
%
%    See also currentProject

 
%   Copyright 2022-2023 The MathWorks, Inc.

    methods
        function out=createLabel(~) %#ok<STOUT>
            %createLabel  Define a new label within this category
            %
            %    Usage:
            %    labelDefinition = createLabel(category, labelName)
            %
            %    Example:
            %    project = currentProject;
            %    classificationCategory = findCategory(project, 'Classification');
            %    % Create a new classification label, 'Requirement'
            %    createLabel(classificationCategory, 'Requirement')
        end

        function out=findLabel(~) %#ok<STOUT>
            %findLabel  Get a label in this category
            %
            %    Usage:
            %    label = findLabel(category, labelName)
            %
            %    Example:
            %    project = currentProject;
            %    classificationCategory = findCategory(project, 'Classification');
            %    designLabel = findLabel(classificationCategory, 'Design')
        end

        function out=removeLabel(~) %#ok<STOUT>
            %removeLabel  Remove a label definition from this category
            %
            %    Usage:
            %    removeLabel(category, labelName)
            %
            %    Example:
            %    project = currentProject;
            %    classificationCategory = findCategory(project, 'Classification');
            %    % Create a new classification label, 'Requirement'
            %    createLabel(classificationCategory, 'Requirement')
            %    % Remove this new label definition:
            %    removeLabel(classificationCategory, 'Requirement')
        end

    end
    properties
        % The type of data that can be added to labels in this category
        DataType;

        Delegate;

        % An array of the label definitions within this category
        LabelDefinitions;

        % The name of this category
        Name;

        % Boolean value describing whether this category is single valued
        SingleValued;

    end
end
