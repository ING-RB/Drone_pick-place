function validatedFullFileName = getValidatedCustomComponentFile(inputFile)
%GETVALIDATEDCUSTOMCOMPONENTFILE Checks and returns a full file path to a
%custom UI component class.
%   inputFile can be a full or partial path to a file

% Copyright 2020-2023 The MathWorks, Inc.

supportedFileExtensions = {'.m', '.mlapp'};
success = false;

if ~ischar(inputFile) && ~(isstring(inputFile) && isscalar(inputFile))
    error(message('MATLAB:appdesigner:appdesigner:InvalidInput'));
end

inputFile = char(inputFile);
[~, ~, ext] = fileparts(inputFile);

if ~isempty(ext) && ~any(strcmp(supportedFileExtensions, ext))
    error(message('MATLAB:appdesigner:appdesigner:InvalidGeneralFileExtension', inputFile, ext));
end

if ~isempty(ext)
    fileExtensions = {ext};
else
    fileExtensions = supportedFileExtensions;
end


for i = 1:numel(fileExtensions)
    % Validate file
    validatedFileName = appdesigner.internal.application.getValidatedFile(inputFile, fileExtensions{i});

    % Get the full file path of the file and verify existance.
    [success, fileInfo, ~] = fileattrib(validatedFileName);

    if success
        validatedFullFileName = appdesigner.internal.application.normalizeFullFileName(fileInfo.Name, fileExtensions{i});
        break;
    end
end

if ~success
    error(message('MATLAB:appdesigner:appdesigner:InvalidFileName', validatedFileName));
end

% Validate the file is a custom component
try
    isCustomComponent = isCustomComponentFile(validatedFullFileName);
catch exception
    newException = MException(message('MATLAB:appdesigner:usercomponentmetadata:NotValidCustomComponentClass',...
        validatedFullFileName));
    newException = addCause(newException, exception);
    throw(newException);
end

if ~isCustomComponent
    error(message('MATLAB:appdesigner:usercomponentmetadata:NotCustomComponentClass',...
        validatedFullFileName, 'matlab.ui.componentcontainer.ComponentContainer'));
end

end

function isCustomComponent = isCustomComponentFile(fullFilePath)
% Returns if file is a user custom UI Component

[canidateFilePath, candidateClassName] = packageFileParts(fullFilePath);

% Need to cd to the location of the file so that it is on the path to
% check its metaclass information.
currentDir = pwd;
cd(canidateFilePath);
c = onCleanup(@()cd(currentDir));

% Perform metaclass check (include P-coded superclass)
isCustomComponent = isCustomComponentFromMetaClass(candidateClassName);
end

function [packageRoot, packageName] = packageFileParts(file)
% Returns the root of a packaged file name or class folder name and the
% fully qualified package name

[filePath, name] = fileparts(file);

if contains(filePath, '+')
    packageRoot = strip(strtok(filePath, '+'), 'right', filesep);
    packageName = strsplit(filePath,'+');
    packageName = strtok(packageName(2:end), filesep);
    packageName = [packageName, name];
    packageName = strjoin(packageName, '.');
elseif contains(filePath, '@')
    packageRoot = strip(strtok(filePath, '@'), 'right', filesep);
    packageName = name;
else
    packageRoot = filePath;
    packageName = name;
end

end

function  isCustomComponent = isCustomComponentFromMetaClass(className, parentSuperClasses)
% Return if class is a user component by checking metaclass

isCustomComponent = false;

% Keep track of all parent superclasses searched through to prevent
% infinite recursion on circular inheritance
if nargin < 2
    parentSuperClasses = {};
end

% Check that candidate is UI Component class
mc = meta.class.fromName(className);
superClasses = mc.SuperclassList;
usercomponentBaseClasses = {'matlab.ui.componentcontainer.ComponentContainer'};

for k = 1:numel(superClasses)
    if ismember(superClasses(k).Name, usercomponentBaseClasses)
        isCustomComponent = true;
        return;
    end
end

for k = 1:numel(superClasses)
    superClassName = superClasses(k).Name;

    % Skip classes already searched and buildin classes
    if ismember(superClassName, parentSuperClasses) || exist(superClassName, 'builtin')
        continue;
    end

    % recursively check if superclass is UI Component with all already searched supperclasses
    isSuperUICompnent = isCustomComponentFromMetaClass(superClasses(k).Name, [parentSuperClasses superClasses.Name]);
    if(isSuperUICompnent)
        isCustomComponent = true;
        return;
    end
end

end