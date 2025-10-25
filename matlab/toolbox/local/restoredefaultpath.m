%RESTOREDEFAULTPATH Restores the MATLAB search path to installed products.
%   RESTOREDEFAULTPATH restores the MATLAB search path to its factory-
%   installed state. RESTOREDEFAULTPATH is only intended for situations
%   when the search path is corrupted and MATLAB is experiencing problems
%   during startup.
%
%   RESTOREDEFAULTPATH; MATLABRC sets the search path to include only
%   folders for installed products from MathWorks and corrects search path
%   problems encountered during startup.
%
%   MATLAB does not support issuing RESTOREDEFAULTPATH from a UNC path
%   name. Doing so might result in MATLAB being unable to find files on the
%   search path. If you do issue RESTOREDEFAULTPATH from a UNC path name,
%   restore the expected behavior by changing the current folder to an
%   absolute path, and then reissuing RESTOREDEFAULTPATH.
%
%   See also ADDPATH, GENPATH, MATLABRC, RMPATH, SAVEPATH.

%   Copyright 2003-2024 The MathWorks, Inc.

% RESTOREDEFAULTPATH is not supported for "remote client" like MATLAB Online
if ~any(matlab.internal.capability.getValue('LocalClient') == uint64(matlab.internal.capability.current))
    nse = connector.internal.notSupportedError;
    nse.throwAsCaller;
end

% Path is not mutable in deployed mode
if isdeployed
    error(message('MATLAB:mpath:PathAlterationNotSupported'));
end

% Get system path to Perl (MATLAB installs Perl on Windows)
if startsWith(computer,'PC')
    RESTOREDEFAULTPATH_perlPath = [matlabroot '\sys\perl\win32\bin\perl.exe'];
    RESTOREDEFAULTPATH_perlPathExists = exist(RESTOREDEFAULTPATH_perlPath,'file')==2;
else
    [RESTOREDEFAULTPATH_status, RESTOREDEFAULTPATH_perlPath] = matlab.system.internal.executeCommand('which perl');
    RESTOREDEFAULTPATH_perlPathExists = RESTOREDEFAULTPATH_status==0;
    RESTOREDEFAULTPATH_perlPath = (regexprep(RESTOREDEFAULTPATH_perlPath,{'^\s*','\s*$'},'')); % deblank lead and trail
end

% If Perl exists, execute "getphlpaths.pl"
if RESTOREDEFAULTPATH_perlPathExists
    RESTOREDEFAULTPATH_cmdString = sprintf('"%s" "%s" "%s"', ...
                                           RESTOREDEFAULTPATH_perlPath, which('getphlpaths.pl'), matlabroot);

    RESTOREDEFAULTPATH_localeInfo = feature('locale');
    if ispc && ~strcmp(RESTOREDEFAULTPATH_localeInfo.terminalEncoding, 'UTF-8')
        % Perl emits warning for some multi-byte locales on Windows
        % If not using UTF-8, then suppress the Perl warning by setting a compatible locale
        [RESTOREDEFAULTPATH_perlStat, RESTOREDEFAULTPATH_result] = matlab.system.internal.executeCommand(RESTOREDEFAULTPATH_cmdString, LC_ALL='C');
    else
        [RESTOREDEFAULTPATH_perlStat, RESTOREDEFAULTPATH_result] = matlab.system.internal.executeCommand(RESTOREDEFAULTPATH_cmdString);
    end
else
    error(message('MATLAB:restoredefaultpath:PerlNotFound'));
end

% Check for errors in shell command
if (RESTOREDEFAULTPATH_perlStat ~= 0)
    error(message('MATLAB:restoredefaultpath:PerlError',RESTOREDEFAULTPATH_result,RESTOREDEFAULTPATH_cmdString));
end

% Check that we aren't about to set the MATLAB path to an empty string
if isempty(RESTOREDEFAULTPATH_result)
    error(message('MATLAB:restoredefaultpath:EmptyPath'))
end

% Add userpath if possible
if exist( 'userpath.m', 'file' ) == 2
    RESTOREDEFAULTPATH_result = [userpath ';' RESTOREDEFAULTPATH_result];
end

% Add packages if any
if matlab.internal.feature('mpm')
    [RESTOREDEFAULTPATH_bp, RESTOREDEFAULTPATH_ep] = matlab.internal.packages.getPathForPackagesInstalledAfter(0x0000000000000u64);
    RESTOREDEFAULTPATH_result = [RESTOREDEFAULTPATH_bp ';' RESTOREDEFAULTPATH_result ';' RESTOREDEFAULTPATH_ep];
end

% Set the path
matlabpath(RESTOREDEFAULTPATH_result);

clear('RESTOREDEFAULTPATH_*');

% Create this variable so that if MATLABRC is run again, it won't try to
% use pathdef.m
RESTOREDEFAULTPATH_EXECUTED = true;
