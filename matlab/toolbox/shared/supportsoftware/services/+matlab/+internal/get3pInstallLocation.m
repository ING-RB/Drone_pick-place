function installLocation = get3pInstallLocation(componentName)
% MATLAB.INTERNAL.GET3PINSTALLLOCATION - Return install location of a 3p component
% 
% LOC = MATLAB.INTERNAL.GET3PINSTALLLOCATION(3PCOMP) returns the
% installation location of a third-party tool installed as a 3p
% instruction-set component. 3PCOMP is a character array specifying the
% name of the instruction-set component, without the '3p/' prefix. LOC is
% the fully-specified installation folder for the third-party tool. If
% 3PCOMP is not an installed instruction-set component, LOC is '' (empty
% character array).
% 
% Example:
%    installLoc = matlab.internal.get3pInstallLocation('gradle.instrset');
% OR installLoc = matlab.internal.get3pInstallLocation("gradle.instrset");

% Copyright 2015-2018 The MathWorks, Inc.

% This API looks at appdata/3p/arch/componentName directory under
% support package root and looks for the file with a name of
% componentName_install_info.txt, open the file if it exists and reads
% its content which is the installation folder of the 3rd party tool
% It also does the proper input validation and reports error if applicable

componentName = convertStringsToChars(componentName);
fileName = matlab.internal.get3pInstallFileLocation(componentName);
fileId = fopen(fileName, 'r');
if (fileId ~= -1)
    textData = textscan(fileId, '%*q%q', 1, 'delimiter', '=');
    installLocation = char(strtrim(textData{1}));
    fclose(fileId);
else
    installLocation = '';
end
end