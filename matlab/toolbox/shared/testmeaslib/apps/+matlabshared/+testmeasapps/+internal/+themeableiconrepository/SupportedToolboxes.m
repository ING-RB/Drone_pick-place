classdef SupportedToolboxes
    %SUPPORTEDTOOLBOXES provides list of supported toolboxes for the
    %Themeable Icon Repository class - IconRepository.m.
    % It also contains the name of the icon repository class for the
    % toolbox specific implementation, e.g.
    % "matlabshared.transportapp.internal.ICTIconRepository" for "ict".
    %
    %% NOTE TO CLIENTS
    % If adding a new toolbox to the icon repository, do the following -
    %
    % 1. Add your toolbox to the enumeration below (if not already added).
    %
    % 2. Create an icon repository class (See
    % matlabshared.transportapp.internal.ICTIconRepository for reference)
    %
    % 3. Add the name of your IconRepository class to the
    % ToolboxRegistration property below. E.g. "ict",
    % "matlabshared.transportapp.internal.ICTIconRepository" shows the Icon
    % repository class name for the ICT toolbox.

    % Copyright 2023 The MathWorks, Inc.

    %% LIST OF SUPPORTED TOOLBOXES
    enumeration
        daq
        hwmgr
        hwmgrclient
        icomm
        ict
        imaq
        mlhw
        mock
        vnt
    end

    %% TOOLBOX ICON REPOSITORY PATH
    properties (Constant)
        ToolboxIconRepositoryDictionary = dictionary( ...
            "daq", "", ... % TO BE IMPLEMENTED
            "hwmgr", "", ... % TO BE IMPLEMENTED
            "hwmgrclient", "matlabshared.testmeasapps.internal.themeableiconrepository.HwMgrClientIconRepository", ...
            "icomm", "", ... % TO BE IMPLEMENTED
            "ict", "matlabshared.transportapp.internal.ICTIconRepository", ...
            "imaq", "imaqapplet.applet.IMAQIconRepository", ...
            "mlhw", "", ... % TO BE IMPLEMENTED
            "mock", "themeableiconrepo.MockIconRepository", ...
            "vnt", "" ... % TO BE IMPLEMENTED
            )
    end

    methods (Static)
        function val = getSupportedToolboxes()
            val = string(enumeration("matlabshared.testmeasapps.internal.themeableiconrepository.SupportedToolboxes"))';
        end
    end
end