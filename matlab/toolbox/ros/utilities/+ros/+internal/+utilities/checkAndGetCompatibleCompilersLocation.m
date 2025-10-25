function [gccLocation, gppLocation,matlabLIBSTDCXXVersionNum,mGLIBCXXMaxVerDefinitionsForSymbols] = checkAndGetCompatibleCompilersLocation
%This function is for internal use only. It may be removed in the future.

% checkAndGetCompatibleGPPLocation This utility returns the gcc and g++ locations to
% be used by validating the compatibility with MATLAB shipped libstdc++ version.

%   Copyright 2024 The MathWorks, Inc.

% The keys and values in the dictionary needs to be updated whenever a new linux
% distribution with a newer gcc/g++ version is to be supported.
% 
% This dictionary is created based on the symbol versioning on the libstdc++.so 
% binary present in mapfile: libstdc++-v3/config/abi/pre/gnu.ver.
% For more information, visit gcc.gnu.org/onlinedocs/libstdc++/manual/abi.html

mGLIBCXXMaxVerDefinitionsForSymbols = [30422, ... % Introduced in GCC 6.1.0
                                       30423, ... % Introduced in GCC 7.1.0
                                       30424, ... % Introduced in GCC 7.2.0
                                       30425, ... % Introduced in GCC 8.1.0
                                       30426, ... % Introduced in GCC 9.1.0
                                       30427, ... % Introduced in GCC 9.2.0
                                       30428, ... % Introduced in GCC 9.3.0
                                       30429, ... % Introduced in GCC 11.1.0
                                       30430, ... % Introduced in GCC 12.1.0
                                       30431, ... % Introduced in GCC 13.1.0
                                       30432];    % Introduced in GCC 13.2.0

mGPPMinVersions = ["6.1.0", "7.1.0", "7.2.0", ...
                   "8.1.0", "9.1.0", "9.2.0", ...
                   "9.3.0", "11.1.0", "12.1.0", ...
                   "13.1.0", "13.2.0"];

supportedCompilerVersions = dictionary(mGLIBCXXMaxVerDefinitionsForSymbols, mGPPMinVersions);

% Default gcc location is the mex configured gcc location
mexCInfo = mex.getCompilerConfigurations('C');
gccLocation = mexCInfo.Location;

% Default g++ location is the mex configured g++ location
mexCPPInfo = mex.getCompilerConfigurations('C++');
gppLocation = mexCPPInfo.Location;

% Get the full version number of system default gcc, as mexInfo does not
% have full version information
[gccVersionStatus, systemGCCVersion] = system([gccLocation ' --version | grep -oP ','''(\d+\.\d+\.\d+)''',' | head -n 1']);
if gccVersionStatus
   error(message('ros:utilities:util:ErrorFetchingGCCVersionInfo', fileparts(gccLocation)));
end
systemGCCVersionString = strtrim(systemGCCVersion);

% Get the full version number of system default g++, as mexInfo does not
% have full version information
[gppVersionStatus, systemGPPVersion] = system([gppLocation ' --version | grep -oP ','''(\d+\.\d+\.\d+)''',' | head -n 1']);
if gppVersionStatus
   error(message('ros:utilities:util:ErrorFetchingGCCVersionInfo', fileparts(gppLocation)));
end
systemGPPVersionString = strtrim(systemGPPVersion);

matlabLIBSTDCXXVersionNum = 0;

% Extract maximum version of GLIBCXX_ symbols supported by matlab shipped libstdc++.so.6 library 
matlabLIBSTDCXX = fullfile(matlabroot,'sys','os','glnxa64','libstdc++.so.6');
stringsCmd = ['strings ', matlabLIBSTDCXX, ' | grep LIBCXX_3 | sort -V | tail -1'];
[stringsCmdStatus, matlabLIBSTDCXXVersion] = system(stringsCmd);
if stringsCmdStatus
   warning(message('ros:utilities:util:UnableToExecuteStringsCommand', stringsCmd, matlabLIBSTDCXXVersion));
   return
end

matlabLIBSTDCXXVersionNum = ros.internal.utilities.getVersionVal(extractAfter(strtrim(matlabLIBSTDCXXVersion), 'GLIBCXX_'));

% Get the minimum gcc/g++ version number that is incompatible with MATLAB
matlabInCompatibleCompilerVer = supportedCompilerVersions(matlabLIBSTDCXXVersionNum+1);
matlabInCompatibleCompilerVerNum = ros.internal.utilities.getVersionVal(matlabInCompatibleCompilerVer);

% Get the version number of mex configured gcc/g++
systemGCCVersionNum = ros.internal.utilities.getVersionVal(systemGCCVersionString);
systemGPPVersionNum = ros.internal.utilities.getVersionVal(systemGPPVersionString);

% If system gcc/g++ version is >= matlab incompatible gcc version, search for
% other gcc/g++ installations based on the PATH environment variable and see if
% they are compatible
isIncompatible = (systemGCCVersionNum >= matlabInCompatibleCompilerVerNum) ...
                 || (systemGPPVersionNum >= matlabInCompatibleCompilerVerNum);

dirsInPathEnv = ''; %#ok<NASGU>
if isIncompatible
    % Check all paths available in PATH environment variable are valid folders
    pathEnvironment = getenv('PATH');
    pathValues = unique(strsplit(pathEnvironment,pathsep)');
    isFolderExists = cellfun(@isfolder,pathValues);
    % Handle Paths containing spaces
    pathValues = strcat('"',pathValues(isFolderExists),'"');
    dirsInPathEnv = strjoin(pathValues, ' ');
else
    % If both are compatible, then no need to fetch PATH environment
    % variable
    return
end

% Initialize map that contain gcc version numbers as keys and their
% locations as values
gccVerPathMap = containers.Map('KeyType','double','ValueType','any');
if systemGCCVersionNum >= matlabInCompatibleCompilerVerNum
    % Find all the gcc locations available based on Path Environment variable
    % Below are the commands used as part of "find" utility on linux
    % -max depth 1 ==> Limits the search to only immediate contents not
    %                  into subdirectories
    % -regextype posix-extended ==> Tells find to use extended regular expressions.
    % -type f ==> Limits the search to files
    % -type l ==> Limits the search to symbolic links
    % -regex ==> Specifies the regex pattern to match
    % -perm /a=x ==>  Looks for files that have the execute permission set for user, group, or others.
    [searchStatus,gccLocations] = system(['find ' dirsInPathEnv ' -maxdepth 1 -regextype posix-extended \( -type f -or -type l \) -regex ', '''.*/gcc(-[0-9]*)?$'' -perm /a=x']);
    if searchStatus
        % Throw a warning and use default mex configured gcc
       warning(message('ros:utilities:util:UnableToFetchGCCInstallations',gccLocations));
       return
    end
    gccLocations = strsplit(strtrim(gccLocations),newline)';
    % Handle location full path containing spaces
    gccLocations = strcat('"',gccLocations,'"');
    % Find the gcc versions based on the found paths and store all the
    % compatible versions with MATLAB in a map
    for idx = 1:numel(gccLocations)
        [versionStatus, gccVer] = system([gccLocations{idx} ' --version | grep -oP ','''(\d+\.\d+\.\d+)''',' | head -n 1']);
        if versionStatus
            error(message('ros:utilities:util:ErrorFetchingGCCVersionInfo', fileparts(gccLocations{idx})));
        end
        gccVerNum = ros.internal.utilities.getVersionVal(strtrim(gccVer));
        if gccVerNum < matlabInCompatibleCompilerVerNum
            gccVerPathMap(gccVerNum) = gccLocations{idx};
        end
    end
end

if isempty(gccVerPathMap)
    % As it is incompatible with MATLAB, throw an
    % error to downgrade the gcc version
    error(message('ros:utilities:util:NeedCompatibleCCompiler', systemGCCVersionString, matlabInCompatibleCompilerVer));
else
    % After the user has installed a compatible version and there is no error,
    % fetch the maximum compatible gcc location, which will be later
    % passed to CMAKE_C_COMPILER flag during compilation of ROS code.
    gccCompatibleVersions = gccVerPathMap.keys;
    gccCompatibleVersions = cell2mat(gccCompatibleVersions);
    gccLocation = gccVerPathMap(max(gccCompatibleVersions));
end

% Initialize map that contain g++ version numbers as keys and their
% locations as values
gppVerPathMap = containers.Map('KeyType','double','ValueType','any');
if systemGPPVersionNum >= matlabInCompatibleCompilerVerNum
    % Find all the g++ locations available based on Path Environment variable
    [searchStatus,gppLocations] = system(['find ' dirsInPathEnv ' -maxdepth 1 -regextype posix-extended \( -type f -or -type l \) -regex ', '''.*/g\+\+(-[0-9]*)?$'' -perm /a=x']);
    if searchStatus
       % Throw a warning and use default mex configured g++
       warning(message('ros:utilities:util:UnableToFetchGPPInstallations',gppLocations));
       return
    end
    gppLocations = strsplit(strtrim(gppLocations),newline)';
    % Handle location full path containing spaces
    gppLocations = strcat('"',gppLocations,'"');
    % Find the g++ versions based on the found paths and store all the
    % compatible versions with MATLAB in a map
    for idx = 1:numel(gppLocations)
        [versionStatus, gppVer] = system([gppLocations{idx} ' --version | grep -oP ','''(\d+\.\d+\.\d+)''',' | head -n 1']);
        if versionStatus
            error(message('ros:utilities:util:ErrorFetchingGPPVersionInfo', fileparts(gppLocations{idx})));
        end
        gppVerNum = ros.internal.utilities.getVersionVal(strtrim(gppVer));
        if gppVerNum < matlabInCompatibleCompilerVerNum
            gppVerPathMap(gppVerNum) = gppLocations{idx};
        end
    end
else
    return
end

if isempty(gppVerPathMap)
    % As it is incompatible with MATLAB, throw an
    % error to downgrade the g++ version
    error(message('ros:utilities:util:NeedCompatibleCPPCompiler', systemGPPVersionString, matlabInCompatibleCompilerVer));
else
    % After the user has installed a compatible version and there is no error,
    % fetch the maximum compatible g++ location, which will be later
    % passed to CMAKE_CXX_COMPILER flag during compilation of ROS code.
    gppCompatibleVersions = gppVerPathMap.keys;
    gppCompatibleVersions = cell2mat(gppCompatibleVersions);
    gppLocation = gppVerPathMap(max(gppCompatibleVersions));
end
end
