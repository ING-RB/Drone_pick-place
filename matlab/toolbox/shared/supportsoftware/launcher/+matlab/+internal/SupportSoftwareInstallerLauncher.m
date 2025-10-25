classdef SupportSoftwareInstallerLauncher < handle

    %SupportSoftwareInstallerLauncher:
    %SupportSoftwareInstallerLauncher is the MATLAB API for launching Support Software Installer webwindow.
    %The API is used for 'INSTALLFROMFOLDER' and 'MLPKGINSTALL' workflows.
    %The API can also simulate AddOn workflows.
    %Following methods can be called on a SupportSoftwareInstallerLauncher
    %object :
    %launchWindow(<workflow type>,<download folder>,<install folder>,<basecodes>)
    % launchWindow takes in four input fields:
    %   <workflow type> -> This is a mandatory field and takes in String or Char
    %                   There are four kinds of workflows that SSI supports
    %                   'ADDONSINSTALL' -> For installing the support package
    %                                       through AddOns Explorer.
    %                   'ADDONSDOWNLOAD' -> For downloading the support package
    %                                       through AddOn Explorer.
    %                   'MLPKGINSTALL' -> For installing the support package
    %                                       by doubleclicking the mlpkg file.
    %                   'INSTALLFROMFOLDER' -> For installing from the folder
    %                                       which already have archives downloaded.
    %                   'SUPPORTPACKAGEUPDATE' -> For updating installed
    %                                       support packages.
    %   <download folder> -> Takes in String or Char.
    %                      For 'INSTALLFROMFOLDER' workflow it means where the
    %                       archives(downloaded previously) are present.
    %                      A valid download folder is mandatory for 'INSTALLFROMFOLDER' workflow.
    %                      For rest of the workflows, it means where the
    %                       archives will be downloaded. To proceed with the
    %                       default SSI downloads folder, pass empty ("" or '' or [])
    %                       for this field.
    %   <install folder> -> Takes in String or Char.
    %                     Location where you want to install support package.
    %                     To proceed with the default SSI install folder,
    %                     pass empty ("" or '' or [])for this field.
    %   <basecodes> -> For 'INSTALLFROMFOLDER' workflow, skip this field as its not required.
    %                For rest of the flows pass:
    %                    A string for single basecode -> Eg. 'basecode' or "basecode"
    %                    A cell array for multiple basecodes -> Eg.
    %                    {'basecode1', 'basecode2'} or {"basecode1", "basecode2"}
    %
    %closeWindow()
    % closeWindow() closes the Support Software Installer webwindow.
    %
    %isWindowInstantiated()
    % This returns true if the API was successfully able to create a webwindow.
    % Else returns false.

    %Copyright 2015-2024 The MathWorks, Inc.

    properties (Access = private)
        instWin = [];
    end

    methods

        function value = isWindowInstantiated(obj)
            if (~isempty(obj.instWin))
                value = obj.instWin.isWindowValid ;
            else
                value = false;
            end
        end

        function launchWindowHelper(obj, workflowType, spkgLoc, installLoc, jbasecodes)

            if(~obj.isWindowInstantiated())
                try
                    % Wait for connector to start before continuing
                    connector.ensureServiceOn;

                    % Initialize the SSI services
                    % The first initialization will be removed when the install service handler is updated
                    % to take configuration files.  The init on the second line would take that config.

                    % create page URL
                    if strcmp(workflowType, 'DPKG')
                        pageUrl = matlab.internal.getAddOnsUrl(jbasecodes, 'WorkflowName', workflowType, 'IsJAVAUI', false);
                    elseif strcmp(workflowType, 'INSTALLFROMFOLDER')
                        if ~exist(spkgLoc ,"dir")
                            error(message('shared_supportsoftware:launcher:supportsoftwareinstallerlauncher:BadPath'));
                        end
                        pageUrl = matlab.internal.getAddOnsUrl(jbasecodes, 'WorkflowName', workflowType, 'IsJAVAUI', false, 'SpkgLoc', spkgLoc);
                    else
                        pageUrl = matlab.internal.getAddOnsUrl(jbasecodes, 'WorkflowName', workflowType, 'IsJAVAUI', false);
                    end
                    pageUrl = [pageUrl '&isStandalone=true'];
                    pageUrl = connector.getUrl(pageUrl);

                    % create a web window
                    debugPort = 0; %matlab.internal.getDebugPort;
                    cefWidth = 550;
                    cefHeight = 470;

                    set(0,'units','pixels');
                    screensize = get(0,'screensize');

                    width = screensize(3);
                    height = screensize(4);

                    center_x = width / 2;
                    center_y = height / 2;

                    cefXpos = center_x - (cefWidth / 2);
                    cefYpos = center_y - (cefHeight / 2);

                    cefPosition = [cefXpos, cefYpos, cefWidth, cefHeight];
                    obj.instWin = matlab.internal.webwindow(pageUrl,debugPort,cefPosition);
                    obj.instWin.Title = '';
                    obj.instWin.setResizable(false);
                    arch = computer('arch');
                    icon = fullfile(matlabroot, 'resources', 'supportsoftwareclient', 'icons');
                    switch arch
                        case {'win64'}
                            obj.instWin.Icon = fullfile(icon, 'ssi.ico');
                        case {'glnxa64'}
                            obj.instWin.Icon = fullfile(icon, 'ssi.png');
                        case {'maci64'}
                            % Not supported
                    end

                catch ME
                    error(message('shared_supportsoftware:launcher:supportsoftwareinstallerlauncher:SSILauncherError',getReport(ME, 'basic', 'hyperlinks','off')));
                end
            end
        end

        function launchWindow(obj, workflowType, spkgLoc, installLoc, baseCode)
            spkgLoc = convertStringsToChars(spkgLoc);

            installLoc = convertStringsToChars(installLoc);
            if isempty(installLoc)
                installLoc = matlabshared.supportpkg.getSupportPackageRoot;
            end

            if(nargin < 5)
                jbasecodes = {''};
            else
                baseCode = convertStringsToChars(baseCode);
                if(iscell(baseCode))
                    %supports multiple basecodes, passed as cell array
                    jbasecodes = repmat({''},1,(size(baseCode,2)));
                    for idx=1:size(baseCode,2)
                        bc = convertStringsToChars(baseCode{idx});
                        jbasecodes(idx) = {bc};
                    end
                else
                    %supports single basecode string
                    jbasecodes = {baseCode};
                end
            end

            workflowType = convertStringsToChars(workflowType);
            validateattributes(workflowType, {'char'}, {'nonempty'});

            if(~obj.isWindowInstantiated())
                obj.launchWindowHelper(workflowType, spkgLoc, installLoc, jbasecodes);
            end
            if(obj.isWindowInstantiated())
                obj.instWin.show();
                obj.instWin.bringToFront();
            end
        end

        function closeWindow(obj)
            if (obj.isWindowInstantiated())
                obj.instWin.close;
                close(obj.instWin);
            end
        end
    end
end
