function out = sysobjupdate(target, varargin)
%SYSOBJUPDATE Updates System object code to the current API
%
%   SYSOBJUPDATE ITEM updates System object code to be compliant with the
%   newest authoring syntax. ITEM can be a System object name, package
%   name, or folder path and must be on the path. The file(s) will be
%   opened in the editor with the changes applied but not saved.
%
%   SYSOBJUPDATE ITEM -inplace will automatically save the changes to the
%   System object(s) specified by ITEM without opening the files in the
%   editor. Backup copies of the original files will be created with the
%   "_orig.m" suffix.
%
%   SYSOBJUPDATE ITEM -diff behaves like the -inplace option, but in
%   addition, the visdiff tool is opened to compare the original and
%   updated System object.
%
%   info = SYSOBJUPDATE(___) returns a structure array containing files
%   that were updated and any warnings about properties that were not
%   updated.
%
%   ADDITIONAL OPTIONS:
%
%   -nobackup       With -inplace, do not create a backup file.
%   -pre <command>  Run a command with SYSTEM before updating the file. The
%                   command will be run with the full path to the file
%                   appended.
%   -post <command> Run a command with SYSTEM after updating the file. The
%                   command will be run with the full path to the file
%                   appended.
%   -listactions    Display a list of possible actions to use with the
%                   -actions option.
%   -actions <name> Instead of performing all known updates, only apply the
%                   specified System object updates. name must be a string
%                   array or cell array of character vectors.

%   Copyright 2010-2023 The MathWorks, Inc.

    if nargin == 0
        error(message('MATLAB:system:Analyzer:MissingTargetInput'));
    end

    config = parseInputs(target, varargin);
    config = crossValidateConfig(config);

    if displayActionOptions(config)
        return
    end

    classes = getClassesToUpdate(config.Entity);

    crossValidateClassesWithConfig(config, classes);

    % numSysObj - number of system objects touched by sysobjupdate.
    [result,numSysObj] = applyUpdates(classes, config);

    if nargout > 0
        out = result;
    else
        % use numSysObj in summary when sysobjupdate is applied to package
        % or directory
        displayResultsInCommandWindow(result, numSysObj, ~config.InPlace)
    end
end

function config = parseInputs(entity, args)
    config = struct('Entity', [], ...
                    'InPlace', false, ...
                    'Backup', true, ...
                    'Pre', [], ...
                    'Post', [], ...
                    'Diff', false, ...
                    'Hierarchy', false, ...
                    'ListActions', false, ...
                    'Actions', []);

    validateScalarTextOption('target', entity);

    if entity == "-listactions"
        config.ListActions = true;
        return
    else
        config.Entity = string(entity);
    end

    [hasArgs, index, arg] = nextFlagArg(args);

    while hasArgs
        switch arg
          case '-inplace'
            config.InPlace = true;
          case '-nobackup'
            config.Backup = false;
          case '-pre'
            [config, index] = processArgValue(config, 'Pre', '-pre', @validateScalarTextOption, args, index);
          case '-post'
            [config, index] = processArgValue(config, 'Post', '-post', @validateScalarTextOption, args, index);
          case '-diff'
            config.Diff = true;
          case '-hierarchy'
            config.Hierarchy = true;
          case '-actions'
            [config, index] = processArgValue(config, 'Actions', '-actions', @validateNonScalarTextOption, args, index);
          case '-listactions'
            config.ListActions = true;
          otherwise
            error(message('MATLAB:system:Analyzer:UnrecognizedOption', arg));
        end

        [hasArgs, index, arg] = nextFlagArg(args, index);
    end
end

function [hasArgs, index, arg] = nextFlagArg(varargin)
    [hasArgs, index, arg] = nextArg(varargin{:});
    if hasArgs
        validateScalarTextOption(getString(message('MATLAB:system:Analyzer:Option')), arg);
    end
end

function [config, index] = processArgValue(config, fieldName, optionName, validation, args, index)
    [validArg, index, arg] = nextArg(args, index);
    if ~validArg
        error(message('MATLAB:system:Analyzer:ExpectedAnotherArgument', optionName));
    end

    validation(optionName, arg);

    config.(fieldName) = string(arg);
end

function validateScalarTextOption(name, value)
    validateattributes(value, {'string', 'char'}, {'scalartext'}, 'sysobjupdate', name)
end

function validateNonScalarTextOption(name, value)
    if ~(isstring(value) || iscellstr(value))
        error(message('MATLAB:system:Analyzer:NotTextArray', name));
    end
end

function [hasArgs, index, arg] = nextArg(args, index)
    if nargin == 1
        index = 0;
    end

    index = index + 1;
    hasArgs = index <= numel(args);

    if hasArgs
        arg = args{index};
    else
        arg = [];
    end
end

function config = crossValidateConfig(config)
    if config.Diff
        if ~config.Backup
            error(message('MATLAB:system:Analyzer:DiffRequiresBackup'));
        end

        if config.InPlace
            error(message('MATLAB:system:Analyzer:DiffInPlaceTogether'));
        end
    end

    if ~(config.InPlace || config.Diff)
        if ~isempty(config.Post)
            error(message('MATLAB:system:Analyzer:PostWithoutSave'));
        end

        config.Backup = false;
    end

    % Diff implies in place
    if config.Diff
        config.InPlace = true;
    end

    validateActions(config.Actions);
end

function validateActions(actions)
    if isempty(actions)
        return
    end

    invalid = setdiff(actions, getActionOptions());

    if ~isempty(invalid)
        error(message('MATLAB:system:Analyzer:InvalidActionOption', invalid(1)));
    end
end

function classes = getClassesToUpdate(entity)
    spec = getSpecType(entity);

    if ~spec.Found
        error(message('MATLAB:system:Analyzer:TargetNotFound', entity));
    end

    switch spec.Type
      case {"Class","File"}
        classes = entity;
      case "Package"
        classes = getClassesFromPackage(entity);
      otherwise
        % Updating the code below to change directory. This is required
        % before calling getClassesFromDirectory since
        % getClassesFromDirectory uses meta.class.fromName which leads to
        % a bug described in g2217609
        OldPath = cd(entity);
        cl1 = onCleanup(@()cd(OldPath));
        classes = getClassesFromDirectory(entity);
        clear cl1
    end
end

function spec = getSpecType(input)
    spec = struct('Found', false, 'Type', "Nothing");

    spec = checkMCOS(input, spec);

    if spec.Found 
        return
    else
        if isfolder(input)
            spec.Found = true;
            spec.Type = "Directory";

            [success, attributes] = fileattrib(input);
            if success
                fullPath = attributes.Name;
                success = isOnPath(fullPath);
            end
            if ~success
                error(message('MATLAB:system:Analyzer:DirectoryNotOnPath', input));
            end
            
        elseif isfile(input)
            [success, attributes] = fileattrib(input);
            [folderName,fileName] = getInfoForFile(attributes.Name);
            if success && ~isempty(folderName) &&...
                    isOnPath(folderName)
                spec = checkMCOS(fileName, spec);
                spec.Type = "File";
            end
        end
    end
end

function spec = checkMCOS(input, spec)
    nameResolver = matlab.lang.internal.introspective.resolveName(input, "FindBuiltins", false);
    if isempty(nameResolver.classInfo)
        return
    end

    if (nameResolver.elementKeyword == "constructor") && ...
            isSystemObjectMetaClass(meta.class.fromName(input))
        spec.Found = true;
        spec.Type = "Class";
    elseif nameResolver.classInfo.isPackage
        spec.Found = true;
        spec.Type = "Package";
    end
end

% From MATLAB Answers
function onPath = isOnPath(folder)
    pathCell = [pwd regexp(path, pathsep, 'split')];
    if ispc  % Windows is not case-sensitive
        onPath = any(strcmpi(folder, pathCell));
    else
        onPath = any(strcmp(folder, pathCell));
    end
end

function classes = getClassesFromDirectory(folder)
    contents = what(folder);

    candidates = string([contents.m; contents.p; contents.classes]);
    for n = 1:numel(candidates)
        [~, candidates(n)] = fileparts(candidates(n));
    end

    idx = false(numel(candidates), 1);
    for n = 1:numel(candidates)
        if isSystemObject(candidates(n))
            idx(n) = true;
        end
    end

    classes = candidates(idx);
end

function flag = isSystemObject(name)
    flag = false;
    try
        mc = meta.class.fromName(name);
    catch
        return
    end

    if isempty(mc)
        return
    end

    flag = isSystemObjectMetaClass(mc);
end

function flag = isSystemObjectMetaClass(mc)
    flag = false;
    if mc < ?matlab.system.SystemImpl
        flag = true;
    end
end

function classes = getClassesFromPackage(packageName)
    package = meta.package.fromName(packageName);
    classes = getClassesFromMetaPackage(package);
end

function classes = getClassesFromMetaPackage(package)
    classes = strings(0);

    for index = 1:numel(package.ClassList)
        class = package.ClassList(index);
        if isSystemObjectMetaClass(class)
            classes = [classes; class.Name]; %#ok<AGROW>
        end
    end
end

function flag = displayActionOptions(config)
    flag = config.ListActions;

    if flag
        fprintf('\n%s\n\n%s\n\n', getString(message('MATLAB:system:Analyzer:ActionListHeader')), ...
                strjoin(strcat("    ", getActionOptions()), '\n'));
    end
end

function options = getActionOptions
    options = ["ObsoleteMixinRemoval"; "CustomAttributeUpdate"; "ObsoleteImplUpdate"];
end

function crossValidateClassesWithConfig(config, classes)
    if config.Diff && numel(classes) > 1
        error(message('MATLAB:system:Analyzer:DiffMultipleClasses', config.Entity));
    end
end

function [result, numSysObj] = applyUpdates(classes, config)
   result = struct('Class', {}, 'Messages', {});

    % Checking to see if applyUpdates is called on directory.
    % This is required to ensure correct System objects are modified. For
    % more information please refer to g2217609
    spec = getSpecType(config.Entity);
    numSysObj = numel(classes);
    
    applyUpdateToDirectory = ~ismember(spec.Type,["Class" "Package"]);
    
    if(applyUpdateToDirectory)
        if strcmpi(spec.Type,"File")
            [folderName,classes] = getInfoForFile(classes);
        else
            folderName = config.Entity;
        end
        if(~strcmpi(folderName,""))
            OldPath = cd(folderName);
            cl1 = onCleanup(@()cd(OldPath));
        end
    end
    
    for classIndex = 1:numSysObj
        class = classes(classIndex);

        updateInfo = matlab.system.internal.updateClass(class, config.Actions, config.Hierarchy);

        % if not analyzing class hierarchy, info size is always 1.
        assert(config.Hierarchy || numel(updateInfo) == 1);

        updatedClassNames = strings(0);

        for updateInfoIndex = 1:numel(updateInfo)
            if ~updateInfo(updateInfoIndex).Changed
                continue
            end

            updatedClassNames = [updatedClassNames, updateInfo(updateInfoIndex).Class]; %#ok<AGROW>

            file = updateInfo(updateInfoIndex).File;

            doBackup(file, config);
            doPre(file, config);
            doUpdate(file, updateInfo(updateInfoIndex).Text, config);
            doPost(file, config);
            showVisDiff(file, config);

            result = [result; struct('Class', updateInfo(updateInfoIndex).Class,...
                                'Messages', updateInfo(updateInfoIndex).Messages)]; %#ok<AGROW>
        end

        refreshMetaClasses(updatedClassNames, config);
    end
    if(applyUpdateToDirectory)
        clear cl1
    end
end

function refreshMetaClasses(updatedClasses, config)
    if ~config.InPlace || isempty(updatedClasses)
        return
    end

    rehash();
    meta.internal.updateClasses();

    %    % MCOS does not support auto-update for only property validation changing.
    %    % Try forcing a refresh
    %    for n = 1:numel(updatedClasses)
    %        metaClass = meta.class.fromName(updatedClasses(n));
    %        delete(metaClass);
    %        if isvalid(metaClass)
    %            error(message('MATLAB:system:Analyzer:StaleMetaClass'));
    %        end
    %    end
end

function doBackup(file, config)
    if ~config.Backup
        return;
    end

    destination = getBackupFileName(file);
    if isfile(destination) || isfolder(destination)
        error(message('MATLAB:system:Analyzer:BackupFileExists', destination));
    end
    copyfile(file, destination);
end

function file = getBackupFileName(file)
    [filepath, name, ext] = fileparts(file);
    file = fullfile(filepath, name + "_orig" + ext);
end

function doPre(file, config)
    if ~isempty(config.Pre) && system(config.Pre + " " + file)
        deleteBackUpFile(file, config);
        error(message('MATLAB:system:Analyzer:CommandReturnedNonzero', '-pre', config.Pre, file));
    end
end

function doPost(file, config)
    if ~isempty(config.Post) && system(config.Post + " " + file)
        error(message('MATLAB:system:Analyzer:CommandReturnedNonzero', '-post', config.Post, file));
    end
end

function doUpdate(file, text, config)
    if config.InPlace
        doInPlaceUpdate(file, text, config);
    else
        doUpdateInEditor(file, text);
    end
end

function doInPlaceUpdate(file, text, config)
    fileID = fopen(file, 'w');
    if fileID == -1
        deleteBackUpFile(file, config);
        error(message('MATLAB:system:Analyzer:UnableToOpenFile', file));
    end
    closer = onCleanup(@()fclose(fileID));
    fwrite(fileID, text, 'char');
end

function doUpdateInEditor(file, text)
    document = matlab.desktop.editor.openDocument(file);
    document.Text = text;
end

function showVisDiff(file, config)
    if config.Diff
        visdiff(getBackupFileName(file), file);
    end
end

function displayResultsInCommandWindow(results,  numSysObj, isWarning)
    % Following code is modified as a part of fix for g2263509
    if isempty(results)
            disp(getString(message('MATLAB:system:Analyzer:NoUpdatedSystemObjects')));
            return
    end
    fprintf('%s\n\n', getString(message('MATLAB:system:Analyzer:ResultsHeader')));
    for resultIndex = 1:numel(results)
        fprintf('%s\n', results(resultIndex).Class);
        notes = results(resultIndex).Messages;
        for noteIndex = 1:numel(notes)
            if isWarning
                % display notes as warning
                warning(notes(noteIndex));
            else
                fprintf('  %s %s\n', getString(message('MATLAB:system:Analyzer:UpdateNotes')), notes(noteIndex));
            end
        end
        if(~isempty(notes) && resultIndex ~= numel(results))
            fprintf('\n\n');
        end
    end

    % If sysobjupdate is applied to package or directory provide the number
    % of System objects modified by sysobjupdate as a summary
    if length(results)>1
        fprintf('%s\n\n', getString(message('MATLAB:system:Analyzer:SummaryHeader')));
        fprintf('  %s \n',...
            getString(message('MATLAB:system:Analyzer:SummaryStatement',...
            numel(results),numSysObj)));
    end

    fprintf('\n');
end

function deleteBackUpFile(file, config)
    if config.Backup
       bkFile = getBackupFileName(file);
       delete(bkFile);
    end
end

function [folderName,className] = getInfoForFile(fileLocation)
% helper function to identify the folderName and className from file 
% location is provided for system object update
    nameResolver = matlab.lang.internal.introspective.resolveName(char(fileLocation));
    if isempty(nameResolver.classInfo)
        folderName = "";
        className = "";
    else
        classPath = char(nameResolver.classInfo.minimalPath);
        index = cell2mat(regexpi(classPath,{'\+','@'},'once'));
        if ~isempty(index)
            minIndex = min(index);
            classPath = classPath(minIndex:end);
        end
        folderName = string(erase(nameResolver.nameLocation,...
            strcat(filesep,classPath)));
        className = string(nameResolver.resolvedTopic);
    end
end
