classdef (Sealed) AliasFileManager < handle
    %AliasFileManager Create and edit alias definition files
    % Use an AliasFileManager object to create and manage a set of alias 
    % definitions for classes in a given folder.  Aliases allow you to rename 
    % classes without introducing incompatibilities.  MATLAB will recognize 
    % the new (current) name of the class and all of the old names (aliases).  
    % In addition, you can load an old MAT-file containing instances of the 
    % class that were created before the class was renamed.  MATLAB will   
    % load the MAT-file using the new class name.  You can also load new
    % MAT-files in older versions of MATLAB before the class was renamed as
    % long as you include all of the old names in your alias definition for
    % the class.
    %
    % Use a single AliasFileManager object to manage all of the alias
    % definitions for a given folder.  
    %
    % fileMgr = matlab.alias.AliasFileManager creates an AliasFileManager
    % object with no alias definitions.
    %
    % fileMgr = matlab.alias.AliasFileManager(location) creates an
    % AliasFileManager object containing the alias definitions for classes
    % in the specified location.  The location must be specified as a string 
    % scalar.  It must be a full or relative path to the parent folder of  
    % the resources folder containing the alias definition file.  This is a  
    % convenient way to view the aliases defined for classes in the specified
    % location.
    %
    % Aliases should be defined and managed using a function (preferred) or
    % script.  Once you have written your function or script to capture your 
    % alias definitions, run the code.  This allows the alias definitions to  
    % take effect.  When updating alias definitions, re-run the code so that  
    % your changes take effect.  
    % 
    % When sharing code with others that includes classes that have been
    % renamed using aliasing, include the alias definition file alongside 
    % the code you share so that others can continue to use the old name.  
    % You can also share your function or script and have it run as part of
    % an installation or setup step in order to create a new alias
    % definition file.
    %
    % %Example 1: - Create a function to rename two classes and save the 
    % %alias definition file in the resources folder of the current folder,
    % %then run the function:
    %
    % function myAliasFunction
    %     fileMgr = matlab.alias.AliasFileManager;
    %     addAlias(fileMgr, NewName = "NewCls", OldNames = "OldCls");
    %     addAlias(fileMgr, NewName = "OtherNewCls", OldNames = "OtherOldCls");
    %     writeAliasFile(fileMgr);
    % end
    %
    % %Example 2: - Update the function to rename NewCls to NewerCls, then
    % %run the function for the updates to take effect:
    %
    % function myAliasFunction
    %     fileMgr = matlab.alias.AliasFileManager;
    %     addAlias(fileMgr, NewName = "NewerCls", OldNames = ["NewCls", "OldCls"]);
    %     addAlias(fileMgr, NewName = "OtherNewCls", OldNames = "OtherOldCls");
    %     writeAliasFile(fileMgr);
    % end
    %
    % AliasFileManager methods:
    %     addAlias -       Add an alias defining one or more old names for a class
    %     writeAliasFile - Save alias definitions to an alias definition file
    %
    % AliasFileManager properties:
    %     Aliases - List of AliasDefinition objects for this file manager
    %
    % See also matlab.alias.AliasDefinition, class, classdef
    
    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Transient)
        %Aliases Alias definitions for renamed classes in a given folder
        % The Aliases property contains a list of the alias definitions for 
        % the classes in a given folder that have been renamed.  Each alias 
        % definition maps one or more old names to the new name of a class.  
        % The new  name must correspond to the actual name of a class in 
        % that folder.  None of the old names can be in use as a class or 
        % function in the folder.
        Aliases (1,:) matlab.alias.AliasDefinition
    end

    methods
        function obj = AliasFileManager(location)
            arguments
                location string {mustBeScalarOrEmpty, mustBeFolder} = string.empty
            end

            if ~isempty(location) 
                [~, values] = fileattrib(location);
                % error if no read permissions to the location.
                if ~values.UserRead
                    error(message('MATLAB:aliasFileManager:NoFolderPermission', location));
                end
                aliasFile = fullfile(location, 'resources','alias.json');
                aliasFolder = dir(location).folder;
                if ~isfile(aliasFile)
                    error(message('MATLAB:aliasFileManager:NoExistingAliasFile', aliasFolder));
                end

                [~, fileValues] = fileattrib(aliasFile);
                if ~fileValues.UserRead
                    error(message('MATLAB:aliasFileManager:NoFilePermission', aliasFolder));
                end
                
                aliasesStruct = jsondecode(fileread(aliasFile));
                obj = addAliasFromStruct(obj, aliasesStruct, location);
            end
        end
        
        function addAlias(obj, options)
            %addAlias Add an alias defining one or more old names for a class
            % addAlias(fileMgr, NewName = newname, OldNames = oldnames) adds 
            % one or more aliases for the class specified by NewName.  
            % NewName must be a string scalar.  OldNames must be a string 
            % array of one or more old names. 
            % 
            % Use a function or script to create your alias definitions using 
            % addAlias.  Create one function to rename all of the classes in 
            % a given folder.  The new class name must match a class definition 
            % in that folder. None of the old names can be in use as classes 
            % or functions in the folder.
            %
            % When renaming a class multiple times, update the existing call 
            % to addAlias in your function or script.  The most recent
            % alias name must be first in the list of old names.  It is
            % expected that aliases are introduced over times as classes
            % are renamed.  MATLAB will issue a warning if more than one
            % old name is added for a class at the same time, but will
            % save the definition when writing the alias definition file.
            %
            % See also AliasFileManager, writeAliasFile, matlab.alias.AliasDefinition
       
            arguments
                obj (1,1)
                options.NewName (1,1) string {mustBeNonmissing}
                options.OldNames (1,:) string {mustBeNonempty, mustBeNonmissing}
            end
            
            if ~isfield(options, "NewName")
                me = MException(message("MATLAB:aliasFileManager:MissingName", "NewName"));
                throw(me);
            end
            if ~isfield(options, "OldNames")
                me = MException(message("MATLAB:aliasFileManager:MissingName", "OldNames"));
                throw(me);
            end          
            
            validateNewName(options.NewName, options.OldNames);  
            validateOldNames(options.OldNames, options.NewName);
            newDefinition = matlab.alias.AliasDefinition(options.NewName, options.OldNames, false);

            % definitionToOverwrite is the index position of an existing  
            % alias definition that will be overwritten or updated by the new 
            % definition being added.  We overwrite an existing definition
            % if the new names are the same.
            definitionToOverwrite = 0;
            for ii = 1 : numel(obj.Aliases)
                existingDefinition = obj.Aliases(ii);
                
                % The input new name cannot be in use as an old name in an
                % existing alias definition
                if any(existingDefinition.OldNames == newDefinition.NewName)
                    error(message('MATLAB:aliasFileManager:NewNameIsExistingAlias', newDefinition.NewName, existingDefinition.NewName));
                end
                
                % This new alias definition matches an existing one if
                % both the new and old names are the same.  For example, if
                % an existing alias definition is updated to set the
                % WarnOnOldName flag, then both the old and new names will
                % be the same.  Issue a warning if the new name is the same 
                % but the old names differ.  In both cases, the new
                % definition will overwrite the existing one so we break
                % out of the for-loop.
                if newDefinition.NewName == existingDefinition.NewName
                     definitionToOverwrite = ii;
                     if ~isequal(newDefinition.OldNames, existingDefinition.OldNames)
                        warning(message('MATLAB:aliasFileManager:NewNameDefinedMultipleTimes', existingDefinition.NewName));
                     end
                    break;
                end
                
                allNamesInExistingDefinition = [existingDefinition.NewName, ...
                    existingDefinition.OldNames];
                
                % Next, check to see if this new alias definition is for a
                % class that is being renamed more than once.   An example
                % of renaming a class more than once is if there is an 
                % existing definition renaming "Foo" to "Bar", then later a
                % new call to addAlias is made to rename the class from
                % "Foo" to "NewFoo", as in:
                %  addAlias(NewName = "NewFoo", OldNames = ["Foo", "Bar"]);
                %
                % We detect that this is a multiple-renaming scenario if
                % any one of the old names specified in the new defintion 
                % appears in the set of all names for the existing definition 

                if any(ismember(allNamesInExistingDefinition, newDefinition.OldNames))
                    % Enforce the rules for a multiple-renaming scenario. 
                    % If no errors, we will overwrite the existing
                    % definition and break out of the for loop.
                    validateMultipleRenaming(allNamesInExistingDefinition, newDefinition);
                    definitionToOverwrite = ii;
                    break;
                end
            end  %[for]
            
            % Update existing alias or add a new alias 
            addToAliases(obj, definitionToOverwrite, newDefinition);
        end  %[function]
        

        function writeAliasFile(obj, location)
            %writeAliasFile Save alias definitions to an alias definition file
            % writeAliasFile(fileMgr) creates an alias definition file
            % containing the alias definitions in the fileMgr object.  The 
            % alias definition file is written to the resources folder of 
            % the current folder.  fileMgr must be a matlab.alias.AliasFileManager 
            % object.  A resources folder is created if it does not already
            % exist.
            %
            % writeAliasFile(fileMgr, location) creates an alias definition
            % file in the resources folder of the specified location.  The
            % location must be a string scalar.  It can be specified as a
            % full or relative path to the parent folder of the resources
            % folder where the alias definitions will be stored.  If an
            % alias definition file already exists at the specified location, 
            % it will be overwritten by a new file.
            %
            % When writing out an alias definition file, MATLAB will
            % validate that each new name matches the name of a class
            % definition in the folder where the alias definition file is
            % being written.  It also confirms than none of the specified
            % old names are used as class or function names in the folder.
            %
            % See also matlab.alias.AliasFileManager, addAlias

            arguments
                obj (1, 1) matlab.alias.AliasFileManager
                location string {mustBeScalarOrEmpty, mustBeFolder} = pwd
            end

            if exist(location, 'dir') && ~isempty(dir(location))
                location = dir(location).folder;
            end
            resourcesDir = fullfile(location, 'resources');
            
            % Check alias restrictions on all aliases and new names
            for ii = 1 : numel(obj.Aliases)
                newName = obj.Aliases(ii).NewName;
                oldNames = obj.Aliases(ii).OldNames;
                
                % Error if the old name file is in the folder
                for jj = 1: numel(oldNames)
                    [fileExists, ~] = doesFileExist(location, oldNames(jj));
                    if fileExists
                        error(message('MATLAB:alias:OldNameExists', oldNames(jj), newName, location));
                    end
                end             

                % Error if the new name file is not in folder or the new
                % name file is not a class definition file.
                [fileExists, fullFileName] = doesFileExist(location, newName);
                if ~fileExists
                    error(message('MATLAB:aliasFileManager:MissingNewClassInAliasFolder', location, newName));
                else
                    %Note that we know the file is present because of the
                    %previous check, so we don't need to catch the error
                    %issued by mtree if the file is not found.
                    mt = mtree(fullFileName,'-file');
                    if mt.FileType ~= mtree.Type.ClassDefinitionFile
                        error(message('MATLAB:aliasFileManager:NewFileNotClass', location, newName));
                    end
                end
                
            end
            
            if ~isfolder(resourcesDir)
                try
                    mkdir(resourcesDir);
                catch
                    error(message('MATLAB:aliasFileManager:CreateAliasFileFailed', location));
                end
            end

            fileID = fopen(fullfile(resourcesDir,'alias.json'),'w+');
            
            % Error if cannot create alias file successfully
            if fileID == -1
                error(message('MATLAB:aliasFileManager:CreateAliasFileFailed', location));
            end

            c = onCleanup(@()fclose(fileID));
            fprintf(fileID, jsonencode(obj, 'PrettyPrint', true));

            % close the file
            clear c;
            % The following two lines are necessary to ensure that the path
            % manager will pick up a newly created alias.json file 
            fname = fullfile(resourcesDir,'alias.json');
            c = exist(fname,"file");
            % notify mcos of the alias file creation/update
            matlab.alias.internal.updateClassAlias(location);
        end
    end


    methods (Access = private)
   
        function obj = addAliasFromStruct(obj, aliasesStruct, location)
         %Helper method to process the aliases from an alias definition file
         %The jsondecode function returns a struct.  Issue a warning if the
         %new class does not exist in the current folder
            aliasesFromFile = aliasesStruct.Aliases;
            numAliases = numel(aliasesFromFile);
            for i = 1:numAliases
                aliasDef = aliasesFromFile(i);
                newName = string(aliasDef.NewName);
                oldNames = string(aliasDef.OldNames)';
                warnOnOldName = aliasDef.WarnOnOldName;

                if validNamesFromFile(newName, oldNames, location)
                    %warn and skip if entry from file is not valid
                    obj.Aliases = [obj.Aliases, matlab.alias.AliasDefinition(newName, oldNames, warnOnOldName)];
                end
            end
        end
        
        %-------------------------
        function addToAliases(obj, existingIndex, newDefinition)
        %Add the new definition to the list of aliases for this
        %AliasFileManager.  If existingIndex > 0, we are overwriting an
        %existing alias definition.  Otherwise we are adding a new one.

            if existingIndex > 0
                obj.Aliases(existingIndex) = newDefinition;
            else 
                if numel(newDefinition.OldNames) > 1
                     % Warn if multiple aliases are defined for the new name
                     % the first time this class is being renamed.
                    warning(message('MATLAB:aliasFileManager:MultipleAliasesFirstTimeRenaming', newDefinition.NewName));
                end
                
                if isempty(obj.Aliases)
                    obj.Aliases = newDefinition;
                else
                    obj.Aliases = [obj.Aliases, newDefinition];
                end
            end
        end
    end
end  %[classdef]


%% Helper functions

function names = buildClassNameListForMessage(nameArray)
%Construct list of old names for use in error and warning messages
    names = char(39) + nameArray + char(39);
    names = strjoin(names, ", ");
end

%-----------------------
function isbuiltin = isBuiltinClass(name)
% Check if a name is a built-in class.
    isbuiltin = (exist(name, "class") == 8 && any(strfind(which(name), "built-in"), 'all'));
end

%-----------------------
function isValid = isValidClassName(name)
% Error if name is not a valid class name
    isValid = true;
    pieces = split(name,'.');
    for ii = 1 : numel(pieces)
        if ~isvarname(pieces(ii))
            isValid = false;
            break;
        end
    end
end
        
%-------------------------
function valid = validNamesFromFile(newName, oldNames, location)
%Check if the names read in from the alias.json file are valid.  If the
%alias file manager is used to create the alias.json file, the names should
%already be valid. This additional checking is here in case someone
%hand-edited the alias definition file.
   
    if validateNewName(newName, oldNames, IssueError = false)
        [fileExists, ~] = doesFileExist(location, newName);
        if ~fileExists
            valid = false;
            warning(message("MATLAB:alias:MissingNewClass", newName, location));
        else
            valid = validateOldNames(oldNames, newName, IssueError = false);
        end
    else
        valid = false;
    end
end

 %-------------------------------
function valid = validateNewName(newName, oldNames, pairs)
% Validate that the new class name does not violate any of the
% restrictions.  It must be a valid MATLAB identifier and cannot be
% the name of a built-in class.  The new name cannot be the same as
% the old name specified in an alias definition (i.e., A -> A).

    arguments
        newName
        oldNames
        pairs.IssueError (1,1) logical = true;
    end

    valid = true;

    % Error or warn if newName is not a valid identifier
    if  ~isValidClassName(newName)
        valid = false;
        issueErrorOrWarning(message('MATLAB:aliasFileManager:NameNotValid', newName), pairs.IssueError);
        return;
    end

    % Error or warn if new name is builtin class name
    if isBuiltinClass(newName)
        valid = false;
        issueErrorOrWarning(message('MATLAB:alias:NewNameIsBuiltinClass', newName), pairs.IssueError);
        return;
    end

    % Error or warn if renaming to the same name
    if any(find(oldNames == newName))
        valid = false;
        issueErrorOrWarning(message('MATLAB:aliasFileManager:AliasingSameName', newName), pairs.IssueError);
        return;
    end
end


%----------------------------------
function valid = validateOldNames(oldNames, newName, pairs)
% Validate old name(s) according to the various aliasing rules.
% All old names must be valid MATLAB class names.  None of the old
% names can match the name of an existing built-in class.

    arguments
        oldNames
        newName
        pairs.IssueError (1,1) logical = true;
    end
    
    valid = true;
    
    for ii = 1 : numel(oldNames)     
        if ~isValidClassName(oldNames(ii))
            valid = false;
            issueErrorOrWarning(message('MATLAB:aliasFileManager:NameNotValid', oldNames(ii)), pairs.IssueError);
            return
        end 
        
        % Error or warn if any old name is a builtin class name
        if isBuiltinClass(oldNames(ii))
            valid = false;
            issueErrorOrWarning(message('MATLAB:alias:AliasIsBuiltinClass', oldNames(ii), newName), pairs.IssueError);
            return
        end
    end
end

%-----------------------
function issueErrorOrWarning(m, issueError)
%Helper for issuing an error or warning
    if issueError
        throwAsCaller(MException(m));
    else
        warning(m)
    end
end

%----------------------
function [fileExists,fullFileName] = doesFileExist(location, name)
% Check if a class is defined in the location.  The location is the parent
% folder of the resources folder containing the alias definition file.  The
% class name could be package qualified, and the class may be in an
% @-folder.

   % If the name is a package name, such as "a.b", return true if
   % "location/+a/b.m" exists
    nameList = split(name,".");
    fileLocation = location;

    for i = 1 : numel(nameList)-1
        fileLocation = fullfile(fileLocation, strcat('+', nameList(i)));
    end
    
    [fileExists, fullFileName] = fileExistsInLocation(fileLocation, nameList(end));

    if ~fileExists
        % Check if a file exist in @-folder
        fileLocation = fullfile(fileLocation, strcat('@', nameList(end)));
        [fileExists, fullFileName] = fileExistsInLocation(fileLocation, nameList(end));
    end            
end

%-----------------------
function [fileIsInLocation, fullFileName] = fileExistsInLocation (location, classname)
%fileExistsInLocation Is class with the given name in location

    % Only check file extensions ".m", ".p" and ".mlx" because only
    % those are possible for class definitions.
    extensions = [".m", ".p", ".mlx"];
    fileIsInLocation = false;

    for ii = 1:numel(extensions)
        anExtension = extensions(ii);
        fullFileName = fullfile(location, strcat(classname, anExtension));
        
        % On Mac and Windows, isfile performs a case-insensitive
        % check, where-as on Linux the check is case-sensitive.
        % Therefore, an additional check is required on Mac and
        % Windows platforms to ensure that the input name is an
        % exact, case-sensitive match for a name on the file
        % system.
        if isfile(fullFileName)
            if ispc || ismac
                % Get a list of the file names with the extension 
                % and check each for an exact, case-sensitive match
                % with the desired name.
                fileList = dir(fullfile(location, strcat("*", anExtension)));
                for jj = 1 : numel(fileList)
                    [~, fileNameFromLocation, extension] = fileparts(fileList(jj).name);
                    if strcmp(fileNameFromLocation, classname)
                        fileIsInLocation = true;
                        fullFileName = fullfile(location, [fileNameFromLocation, extension]);
                        %Exact match found - stop looking and return
                        return;
                    end
                end
            else
                %Must be Linux, in which case isfile is case sensitive
                fileIsInLocation = true;
                return;
            end
        end
    end
end

%-----------------------
function validateMultipleRenaming(existingNames, newDefinition)

    % existingNames contains the names from an existing alias
    % definition as follows:  [existingNewName, existingOldNames]
    % newDefinition is a new alias definition being processed by a 
    % call to addAlias. It is made up of a NewName plus a set of 
    % OldNames.  
    % This function has been called because we have determined that
    % an OldName appearing in the new definition is also in use in
    % an existing alias definition, and that therefore a class that 
    % has previously been renamed is being renamed again.  This 
    % function validates that the rules for renaming a class again
    % are followed.

    % When renaming a class once, we have NewName = "foo" and
    % OldNames = "bar".  If foo is renamed again, the new
    % definition is expected to be NewName = "newfoo" and OldNames
    % = ["foo", "bar"].  Therefore, the names in the existing
    % definition (["foo", "bar"]) should match the set of OldNames
    % specified in the new definition.
    if ~isequal(existingNames, newDefinition.OldNames)

        % When renaming a class multiple times, the most recent name
        % should be the first in the list of old names.
        if newDefinition.OldNames(1) ~= existingNames(1)
            error(message('MATLAB:aliasFileManager:RecentNameFirst'));
        end

        % Check if the set of oldNames is consistent with expectations.
        % There are four scenarios tested here:
        % 1. The set of oldNames contains the same names as
        % existingNames, but in the wrong order.
        % 2. The set of oldNames contains the expected number of names, 
        % but the actual names are different names than in
        % existingNames.

        if numel(existingNames) == numel(newDefinition.OldNames)
            difference = setdiff(existingNames, newDefinition.OldNames);
            if isempty(difference)
                warning(message('MATLAB:aliasFileManager:OldNamesReordered',newDefinition.NewName));
            else
                warning(message('MATLAB:aliasFileManager:OldNamesChanged',newDefinition.NewName));
            end
        elseif numel(existingNames) > numel(newDefinition.OldNames)
            droppedNames = setdiff(existingNames, newDefinition.OldNames);
            nameString = buildClassNameListForMessage(droppedNames);
            warning(message('MATLAB:aliasFileManager:OldNamesDropped', nameString, newDefinition.NewName));
        
        else %number of old names in the new definition is greater
            addedNames = setdiff(newDefinition.OldNames, existingNames);
            if isempty(addedNames)
                warning(message('MATLAB:aliasFileManager:SameOldName', newDefinition.NewName));
            else
                nameString = buildClassNameListForMessage(addedNames);
                warning(message('MATLAB:aliasFileManager:OldNamesAdded', nameString, newDefinition.NewName));
            end
        end
    end  %~isequal(existingNames, oldNames)
end      %function validateMultipleRenaming
