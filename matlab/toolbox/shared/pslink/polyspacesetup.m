function polyspacesetup(varargin)
%POLYSPACESETUP - manage installation of Polyspace Simulink plug-in in MATLAB
%
%   POLYSPACESETUP('install', 'polyspaceFolder', POLYSPACEFOLDER) installs 
%   Polyspace plug-in located in the folder POLYSPACEFOLDER on your current
%   version of MATLAB.
%
%   POLYSPACESETUP('install', 'polyspaceFolder', POLYSPACEFOLDER, 'silent', ISSILENT)
%   installs Polyspace without confirmation messages if ISSILENT is set to true.
%   When ISSILENT is false (default), the installation shows confirmation messages.
%
%   POLYSPACESETUP('uninstall') removes the current installation of
%   Polyspace plug-in from your current version of MATLAB.
%
%   POLYSPACESETUP('showpolyspacefolders') lists all Polyspace plug-in 
%   folders installed with your current version of MATLAB.

% Copyright 2020 The MathWorks, Inc.

parserObj = inputParser;
parserObj.addOptional('action', 'install', @(x) (isstring(x) && isscalar(x)) || ischar(x));
parserObj.addParameter('polyspaceFolder', '', @(x) (isstring(x) && isscalar(x)) || ischar(x));
parserObj.addParameter('silent', false, @islogical);
parserObj.parse(varargin{:});

action = char(parserObj.Results.action);
polyspaceFolder = parserObj.Results.polyspaceFolder;
% Detect if batch option is used then force isSilent to true
isSilent = parserObj.Results.silent || batchStartupOptionUsed;

if isempty(polyspaceFolder) && exist('polyspaceroot') ~= 0 %#ok<EXIST>
    polyspaceFolder = polyspaceroot;
elseif isempty(polyspaceFolder)
    % Try to use default installation folder of same release of Polyspace
    psVersion  = ver('MATLAB');
    release = psVersion.Release(2:end-1);
    rootFolder = fullfile(matlabroot, "..", "..");
    polyspaceFolder = fullfile(rootFolder, 'Polyspace', release);
    if ~isfolder(polyspaceFolder)
        if ispc
            polyspaceFolder = fullfile(rootFolder, 'Polyspace Server', release);
        else
            polyspaceFolder = fullfile(rootFolder, 'Polyspace_Server', release);
        end
    end

    if isfolder(polyspaceFolder)
        fprintf(1, '%s\n', message('polyspace:pscore:useDefaultInstallFolder', polyspaceFolder).getString());
    elseif isSilent
        error('pscore:invalidInstallPath', message('polyspace:pscore:invalidInstallPath').getString())
    else
        polyspaceFolder = input(message('polyspace:pscore:specifyInstallFolderPrompt').getString(), 's');
    end
end

if isfolder(polyspaceFolder)
    psSetupPath = fullfile(polyspaceFolder, 'toolbox', 'polyspace', 'pscore', 'pscore');
    if isfolder(psSetupPath)
        originalDir = pwd;
        try
            cd(psSetupPath);
            polyspacesetup(action, 'silent', isSilent);
            % Cannot use onCleanup due to clear classes done by called function
            cd(originalDir);
        catch ME
            cd(originalDir);
            rethrow(ME);
        end
    else
        error('polyspace:pscore:invalidInstallPath',...
            message('polyspace:pscore:invalidInstallPath').getString())
    end
else
    error('polyspace:pscore:nonExistentInstallPath',...
        message('polyspace:pscore:nonExistentInstallPath').getString())
end
end
