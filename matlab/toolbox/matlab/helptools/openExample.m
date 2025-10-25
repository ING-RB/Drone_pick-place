function openExample(file, NameValueArgs)
%openExample Open an example for modification and execution.
%   openExample(E) opens an example, identified by E, in a new folder. If
%   the folder already exists, it opens the existing version.
%   openExample(E,'supportingFile', SF) opens an example, identified by E, and launches a supporting file,
%   identified by SF.
%   openExample(E,'workDir', WD) opens an example, identified by E, in a folder,
%   identified by WD.


%   Copyright 2015-2024 The MathWorks, Inc.

arguments
    file                         { mustBeNonzeroLengthText, mustBeTextScalar }
    NameValueArgs.supportingFile { mustBeNonzeroLengthText, mustBeTextScalar }
    NameValueArgs.workDir        { mustBeNonzeroLengthText, mustBeTextScalar }
    NameValueArgs.validateHost   { mustBeNumericOrLogical } = false
end

if ~matlab.ui.internal.hasDisplay
    error(message('MATLAB:examples:InvalidConfiguration'));
end

if NameValueArgs.validateHost
    domain = matlab.internal.doc.getDocCenterDomain;
    mathworksDomainPattern = textBoundary + "https://" + optionalPattern(regexpPattern("[a-zA-Z0-9-]+") + ".") + "mathworks.com" + optionalPattern(digitsPattern(1,5)) + textBoundary;

    if ~matches(domain, mathworksDomainPattern)
        error(message('MATLAB:examples:InvalidHostName', domain));
    end
end

[exampleId, isMainFile] = matlab.internal.examples.identifyExample(file);
if ~isMainFile
    NameValueArgs.supportingFile = file;
else
    if isfield(NameValueArgs, 'supportingFile')
        NameValueArgs.supportingFile = convertCharsToStrings(NameValueArgs.supportingFile);
    end
end

metadata = findExample(exampleId);
if numel(metadata.project) > 0
    % Check if a project is open. If so, ask the user if they want to close
    % it before opening the example project.
    choice = matlab.internal.project.example.closeCurrentProjectRequest;
    if ~choice
        % User clicked cancel, so do not carry on
        return
    end
end

setupExampleInputs = {metadata};
if isfield(NameValueArgs, "workDir")
    setupExampleInputs = {metadata,NameValueArgs.workDir};
end
[workDir,metadata] = setupExample(setupExampleInputs{:});

override = false;
if isfield(NameValueArgs, 'supportingFile') 
    override = true;
    overrideFile = NameValueArgs.supportingFile;
end


% Change folder for runnability and such.
cd(workDir)

% Reset workDir to account for symbolic links in user's $HOME path
workDir = pwd;

% Open.
openCompleted = false;
if override
    openCompleted = matlab.internal.examples.openSupportingFile(workDir, metadata, overrideFile);
end

if ~openCompleted
    for iFiles = 1:numel(metadata.files)
        f = metadata.files{iFiles};
        if f.open
            open(fullfile(workDir,f.filename))
            openCompleted = true;
            break;
        end
    end
end

if ~openCompleted
    for i = 1:numel(metadata.project)
        p = metadata.project(i);
        if p.open
            if p.supported
                openProject(p.root);
            else
                [~, ~, topLevelProjectRoot] = matlab.internal.project.example.projectDemoSetUp(metadata.project.path, ...
                                          workDir, metadata.project.cmSystem);
                openProject(topLevelProjectRoot);
            end
            openCompleted = true;
            break;
        end
    end
end

if ~openCompleted
    if isfield(metadata,'callback')
        eval(metadata.callback)
        openCompleted = true;
    end
end

if ~openCompleted
    mainFile = matlab.internal.examples.getMainFile(metadata);
    edit(fullfile(workDir, mainFile))
end

end
