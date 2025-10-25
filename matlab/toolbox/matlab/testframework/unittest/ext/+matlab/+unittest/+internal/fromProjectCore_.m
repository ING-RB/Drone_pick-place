function suite = fromProjectCore_(project, modifier, externalParameters, includeReferencedProjects, varargin)
%

% Copyright 2021-2023 The MathWorks, Inc.

import matlab.unittest.Test;
import matlab.internal.project.api.makeProjectAvailable;
import matlab.unittest.internal.testSuiteFileExtensionServices;
import matlab.unittest.internal.DefaultProjectFileErrorHandler;

project = convertCharsToStrings(project);
validateattributes(project, {'matlab.project.Project', 'string', 'char'}, {'nonempty', 'scalar'}, '', 'project');

parser = matlab.unittest.internal.strictInputParser;
parser.addParameter("ProjectFileErrorHandler_", DefaultProjectFileErrorHandler); % undocumented
parser.parse(varargin{:});

if isstring(project)
    if isfile(project)
        [folder,~,ext] = fileparts(project);
        if strcmpi(ext, '.prj')
            project = folder;
        end
    end
    project = makeProjectAvailable(project);
    projectPath = project.ProjectPath;
    if includeReferencedProjects
        refProjects = getAllReferencedProjects(project);
        projectPath = [projectPath, refProjects.ProjectPath];
    end
    if ~isempty(projectPath)
        paths = [projectPath.File];
        oldPath = addpath(paths{:});
        resetPath = onCleanup(@()path(oldPath));
    end
else
    if ~project.isvalid
        error(message('MATLAB:unittest:TestSuite:InvalidProjectHandle'));
    end
    if ~project.isLoaded
        error(message('MATLAB:unittest:TestSuite:ProjectNotLoaded'));
    end
end

projectFiles = project.Files;
if includeReferencedProjects
    refProjects = getAllReferencedProjects(project);
    projectFiles = [projectFiles, refProjects.Files];
end

labels = [projectFiles.Labels, matlab.internal.project.api.Label.empty];
labels = labels(strcmp([labels.CategoryUUID],"FileClassCategory") & ...
    (strcmp([labels.LabelUUID],"test") | strcmp([labels.Name],getString(message("MATLAB:project:labels:Test")))));
if isempty(labels)
    suite = Test.empty;
    return;
end

suite = createSuiteForLabels(testSuiteFileExtensionServices, labels, modifier, externalParameters, parser.Results.ProjectFileErrorHandler_);

fixture = matlab.unittest.fixtures.ProjectFixture(project.RootFolder);
suite = suite.addExternalFixtures(fixture);
end


function suite = createSuiteForLabels(fileExtensionServices, labels, modifier, externalParameters, errorHandler)
import matlab.unittest.Test;
import matlab.unittest.internal.services.fileextension.FileExtensionLiaison;
import matlab.unittest.internal.selectors.AttributeSet;
import matlab.unittest.internal.selectors.BaseFolderAttribute;
import matlab.unittest.internal.selectors.FilenameAttribute;

fileIdx = isfile([labels(:).File]);
files = [labels(fileIdx).File string.empty];
nFiles = numel(files);
testSuites = cell(1, nFiles);

% See if we can use the rejector to filter out some files before creating a
% test suite. We only know about file level attributes at this point, so we
% can only reject if the rejector uses those attributes.
shouldRejectFile = false(1, nFiles);

rejector = modifier.getRejector;
rejectorUsesAttributes = rejector.uses(?matlab.unittest.internal.selectors.FilenameAttribute) || ...
    rejector.uses(?matlab.unittest.internal.selectors.BaseFolderAttribute);

if rejectorUsesAttributes
    attributeDataLength = nFiles;
    fileLevelAttributes = [BaseFolderAttribute(cellstr(fileparts(files))), FilenameAttribute(files)];
    fileLevelAttributeSet = AttributeSet(fileLevelAttributes, attributeDataLength);
    shouldRejectFile = rejector.reject(fileLevelAttributeSet);
end

files = files(~shouldRejectFile);

currentFolder = pwd;
restoreFolder = onCleanup(@()cd(currentFolder));

for idx = 1:numel(files)
    thisFile = files(idx);
    liaison = FileExtensionLiaison(thisFile, UseResolvedFile=true);
    validateNoPrivateFolderFromFile(leafFolderGenerator(liaison.ContainingFolder));

    newFolder = liaison.ContainingFolder;
    if newFolder ~= currentFolder
        cd(newFolder);
        currentFolder = newFolder;
    end
    supportingService = fileExtensionServices.findServiceThatSupports(liaison.Extension);
    if ~isempty(supportingService)
        try
            test = supportingService.createSuiteExplicitly(liaison, modifier, externalParameters, NonTestBehavior="ignore");
        catch e
            errorHandler.handle(e, liaison.ShortFile);
            test = Test.empty;
        end
        test = test.addInternalPathAndCurrentFolderFixtures(liaison.ContainingFolder);
        testSuites{idx} = test;
    end
end

delete(restoreFolder);
suite = [Test.empty, testSuites{:}];
end

function leafFolder = leafFolderGenerator(folder)
folders = regexp(folder, filesep, 'split');
leafFolder = folders{end};
end

function validateNoPrivateFolderFromFile(folder)
if identifyPrivateFolders(folder)
    error(message('MATLAB:unittest:TestSuite:FilesInPrivateFolderNotAllowed'));
end
end

function mask = identifyPrivateFolders(folders)
mask = strcmp(folders, 'private');
end

function p = getAllReferencedProjects(project)
refs = listAllProjectReferences(project);
p = [refs.Project, matlab.project.Project.empty];
end

% LocalWords:  prj isstring isfile fileextension rejector exc Teardownable
