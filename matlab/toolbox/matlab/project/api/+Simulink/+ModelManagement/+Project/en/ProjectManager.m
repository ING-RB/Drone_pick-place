classdef ProjectManager< handle
%ProjectManager  Enables a project to be managed programmatically.
%
% This function will be removed in a future release. Use currentProject
% and related functions instead.

 
%   Copyright 2010-2022 The MathWorks, Inc.

    methods
        function out=ProjectManager
        end

        function out=addFileToProject(~) %#ok<STOUT>
            % addFileToProject - Adds a file to the project. This file must be
            % contained within the project root folder.
            %
            % Usage:
            %
            % obj.addFileToProject(file)
            %
            % Where:
            %
            % file - string - The full qualified path name of a file within the
            % project's root folder.
        end

        function out=attachLabelToFile(~) %#ok<STOUT>
            % attachLabelToFile - Attach a label to a file in the project.
            %
            % Usage:
            %
            % obj.attachLabelToFile(file,label);
            %
            % Where:
            %
            % file - string - the fully qualified path name of a file in
            % the project.
            %
            % label - Simulink.ModelManagement.Project.Label - The label to
            % be attached to the specified file.
        end

        function out=createCategory(~) %#ok<STOUT>
            % createCategory - Create a label category in the project.
            %
            % Usage:
            %
            % obj.createCategory(categoryName)
            %
            % Where:
            %
            % categoryName - string - The name of the category to be
            % created.
        end

        function out=createLabel(~) %#ok<STOUT>
            % createLabel - Create a label in the project.
            %
            % Usage:
            %
            % obj.createLabel(label)
            %
            % Where:
            %
            % label - Simulink.ModelManagement.Project.Label - Describes
            % the label to be created. An instance of Label can be
            % constructed by specifying a category and label name.
        end

        function out=detachLabelFromFile(~) %#ok<STOUT>
            % detachLabelFromFile - Detach a label from a file in the
            % project.
            %
            % Usage:
            %
            % obj.detachLabelFromFile(file,label)
            %
            % Where:
            %
            % file - string - the fully qualified path name of a file in
            % the project.
            %
            % label - Simulink.ModelManagement.Project.Label - A label
            % which is currently attached to the specified file.
        end

        function out=export(~) %#ok<STOUT>
            % export - Export the project to a zip file.
            %
            % Usage:
            %
            % obj.export(file, definitionType)
            %
            % Where:
            %
            % file - string - the full qualified path name of the zip file
            % to write.
            %
            % definitionType - DefinitionFiles - the type of project
            % definition file to use (MultiFile or SingleFile).
        end

        function out=getAttachedLabels(~) %#ok<STOUT>
            % getAttachedLabels - Return all of the labels attached to the
            % specified file.
            %
            % Usage:
            %
            % labels = obj.getAttachedLabels(file);
            %
            % Where:
            %
            % labels - object array of type Label - The Labels attached to
            % the specified file.
            %
            % file - char - The fully qualified filename of a file in the
            % project.
        end

        function out=getCategories(~) %#ok<STOUT>
            % getCategories - Gets a list of all the categories defined in
            % the project.
            %
            % Usage:
            %
            % categories = obj.getCategories();
            %
            % Where:
            %
            % categories - cell array of strings - one entry for each label
            % in the project.
        end

        function out=getFilesInProject(~) %#ok<STOUT>
            % getFilesInProject - Get the files which are currently within the
            % project.
            %
            % Usage:
            %
            % files = obj.getFilesInProject();
            % files = obj.getFilesInProject(includeFolders);
            %
            % Where:
            %
            % files - cell array of strings - each entry gives the fully
            % qualified filename of a file in the project.
            %
            % includeFolders - (optional) logical, true if folders should
            % be included in the list of project files. If this input is
            % not specified a default value of true is used.
        end

        function out=getLabels(~) %#ok<STOUT>
            % getLabels - Get all of the labels which exist in the project
            % and are members of the specified label category.
            %
            % Usage:
            %
            % labels = obj.getLabels(categoryName);
            %
            % Where:
            %
            % categoryName - The name of the category whose labels will be
            % returned.
            %
            % labels - array of Simulink.ModelManagement.Project.Label -
            % the labels which are members of the specified category.
        end

        function out=getProjectName(~) %#ok<STOUT>
            % getProjectName - This method returns the project's name.
            %
            % Usage:
            %
            % name = obj.getName();
            %
            % Where:
            %
            % name - string - the name of the project.
        end

        function out=getRootFolder(~) %#ok<STOUT>
            % getRootFolder - Get the project's root level folder
            %
            % Usage:
            %
            % folder = obj.getRootFolder();
            %
            % Where:
            %
            % folder - string - the path of the project's root level
            %             folder.
        end

        function out=removeCategory(~) %#ok<STOUT>
            % removeCategory - Remove a label category from the project.
            %
            % Usage:
            %
            % obj.removeCategory(categoryName)
            %
            % Where:
            %
            % categoryName - string - the name of a label category which
            % exists in the project.
        end

        function out=removeFileFromProject(~) %#ok<STOUT>
            % removeFileFromProject - Remove a file from the project.
            %
            % Usage:
            %
            % obj.removeFileFromProject(file)
            %
            % Where:
            %
            % file - string - the full qualified path name of a file within the
            % project.
        end

        function out=removeLabel(~) %#ok<STOUT>
            % removeLabel - Removes the specified label from the project.
            %
            % Usage:
            %
            % obj.removeLabel(label)
            %
            % Where:
            %
            % label - Simulink.ModelManagement.Project.Label - The label to be
            % removed from the project.
        end

        function out=setProjectName(~) %#ok<STOUT>
            % setProjectName - This method sets the project's name.
            %
            % Usage:
            %
            % obj.setProjectName(name)
            %
            % Where:
            %
            % name - string - The name to be given to the project.
        end

    end
end
