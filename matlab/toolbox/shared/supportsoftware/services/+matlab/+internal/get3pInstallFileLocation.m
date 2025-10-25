function installFileLocation = get3pInstallFileLocation(componentName)
% FILENAME = MATLAB.INTERNAL.GET3PINSTALLFILELOCATION - Return/display
% the path of the file name which contains 3p tools installation location
% based on the component name. This API can only read one component name at a time.

% This API looks at appdata/3p/arch/componentName directory under
% support package root first and looks for the file with a name of
% componentName_install_info.txt. If that file does not exist, it will
% try to look for that file in appdata/3p/common/componentName directory,
% then it returns the path of this file.
% It also does the proper input validation and reports error if applicable
%
%     Example:
%     installFileLocation = matlab.internal.get3pInstallFileLocation('usbwebcam')
%  OR installFileLocation = matlab.internal.get3pInstallFileLocation("usbwebcam")
%
%  Copyright 2015-2018 The MathWorks, Inc.

    narginchk(1,1);
    componentName = convertStringsToChars(componentName);
    [m, ~]=size(componentName);

    if ~ischar(componentName) || m~=1
        error(message('shared_supportsoftware:services:installationlocation:InvalidComponentName'));
    end

    spkgRoot = matlabshared.supportpkg.internal.getSupportPackageRootNoCreate();
    arch = computer('arch');

    index = strfind(componentName, '/');
    if ~isempty(index)
        name = componentName(index(end)+1:end);
    else
       name = componentName;
    end

    installFileLocation= fullfile(spkgRoot, 'appdata', '3p', arch, name, ...
                       [name, '_install_info.txt']);

    if exist(installFileLocation, 'file') ~= 2
        installFileLocation= fullfile(spkgRoot, 'appdata', '3p', 'common', name, ...
                       [name, '_install_info.txt']);
    end

end