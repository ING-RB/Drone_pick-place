function create(projectFile)
% matlab.apputil.create Create a project for packaging an app into an MLTBX file.
%

% Copyright 2012-2024 The MathWorks, Inc.

warning(message('MATLAB:apps:errorcheck:CreateRemoval'))

narginchk(0,1);

if nargin == 0
    % Launch new toolbox workflow
    matlab.internal.deployment.launchToolboxFolderSelectionDialog
else

    % Open the PRJ
    validateattributes(projectFile,{'char','string'},{'scalartext'}, ...
    'matlab.apputil.create','PRJFILE',1)
    projectFile = char(projectFile);
    
    fullFileName = matlab.internal.apputil.AppUtil.locateFile(projectFile, ...
        matlab.internal.apputil.AppUtil.ProjectFileExtension);
    
    if isempty(fullFileName)
        error(message('MATLAB:apputil:create:filenotfound', projectFile));
    end
    
    validProject = matlab.internal.apputil.AppUtil.validateProjectFile(fullFileName);
    
    if ~validProject
        error(message('MATLAB:apputil:create:invalidproject'));
    end
    
    open(fullFileName);
end