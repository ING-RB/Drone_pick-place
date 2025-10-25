function showManager(entryPointIdentifier, varargin)
% showManager Open Add-on Manager
%
%   1.  matlab.internal.addons.launchers.showManager(ENTRYPOINTIDENTIFIER)
%       opens Add-on Manager. Brings window to front if already open
%       
%       ENTRYPOINTIDENTIFIER is a unique id used to track the entry point
%       for Add-On Explorer for usage data analytics
%
%       Example: Open Add-on Manager to installed add-ons list view
%
%       matlab.internal.addons.launchers.showManager("unique-id-for-udc")
%
%   2.  matlab.internal.addons.launchers.showManager(ENTRYPOINTIDENTIFIER,"identifier", IDENTIFIER)
%       opens Add-on Manager detail page for an add-on in Add-on Manager
%
%       Example: Show details for Simulink in Add-on Manager
%
%       matlab.internal.addons.launchers.showManager("unique-id-for-udc", "identifier", "SL")
%
%   3.  matlab.internal.addons.launchers.showManager(ENTRYPOINTIDENTIFIER, "identifier", IDENTIFIER, "version", VERSION)
%       opens Add-on Manager detail page for an add-on with specific version in Add-on Manager
%
%       Example: Show details for Simulink v19.0.0 in Add-on Manager
%
%       matlab.internal.addons.launchers.showManager("unique-id-for-udc", "identifier", "SL", "version", "19.0.0")
%
%   4.  matlab.internal.addons.launchers.showManager(ENTRYPOINTIDENTIFIER, "identifier", IDENTIFIER, "version", VERSION, "name", ADDONNAME, "showDialog", DIALOGTYPE)
%       Show enable confirmation dialog in Add-on Manager
%
%       Example: Show enable confirmation dialog in Add-on Manager for GUI
%       Layout Toolbox v 2.1.2
%
%       matlab.internal.addons.launchers.showManager("unique-id-for-udc", "identifier", "e5af5a78-4a80-11e4-9553-005056977bd0", "name", "GUI Layout Toolbox", "version", "2.1.2", "showDialog", "confirmEnable")
%       
%   5.  matlab.internal.addons.launchers.showManager(ENTRYPOINTIDENTIFIER, "openUrl", APPLICATIONURL)
%       Opens URL in a dialog within Add-on Manager
%
%   6.  matlab.internal.addons.launchers.showManager(ENTRYPOINTIDENTIFIER, "showTab", TABNAME)
%       Show a specific tab in Add-on Manager
%       TABNAME - One of "Installed" or "Updates"
%
%       Example: Show Updates tab
%       matlab.internal.addons.launchers.showManager("unique-id-for-udc", "showTab", "updates")
%
%   See also: matlab.internal.addons.launchers.showExplorer

%   Copyright 2019-2022 The MathWorks, Inc.

    narginchk(1,9);
    
    connector.ensureServiceOn;

    managementUIInstance = matlab.internal.addons.Manager.getInstance;

    parser = inputParser;
    parser.FunctionName = "showManager";
    parser.CaseSensitive = false;
    parser.PartialMatching = false;
    
    addRequired(parser, "entryPointIdentifier", @(x)validateStringScalarInput("matlab.internal.addons.launchers.showManager", "entryPointIdentifier", x)); 
    addParameter(parser, "identifier", string.empty, @(x)validateStringScalarInput("matlab.internal.addons.launchers.showManager", "identifier", x));
    addParameter(parser, "version", string.empty, @(x)validateStringScalarInput("matlab.internal.addons.launchers.showManager", "version", x));
    addParameter(parser, "name", string.empty, @(x)validateStringScalarInput("matlab.internal.addons.launchers.showManager", "name", x));
    addParameter(parser, "openUrl", string.empty, @(x)validateStringScalarInput("matlab.internal.addons.launchers.showManager", "openUrl", x));
    addParameter(parser, "showTab", string.empty, @(x) validateShowTab(x));
    addParameter(parser, "showDialog", string.empty, @(x) validateShowDialog(x));
    
    parser.parse(entryPointIdentifier, varargin{:});
    results = parser.Results;

    navigationData = matlab.internal.addons.NavigationData;
    navigationData.entryPoint(results.entryPointIdentifier);

    % ToDo: Check to see if there is a better way to implement the code
    % with less number of if conditions
    if (nargin == 0) 
        error(message('matlab_addons:errors:provideEntryPointIdentifier'));
    end
    
    if (nargin == 1)
        navigationData.showTab("installed");
        managementUIInstance.show(navigationData);
        return;
    end
   
    if ~(isStringEmpty(results.openUrl))
        navigationData.loadApplicationUrl(results.openUrl);
        managementUIInstance.show(navigationData);
        return;    
    end
    
    if ~(isStringEmpty(results.showTab))
        if (strcmpi(results.showTab, "updates") == 1)
            navigationData.showTab("updates");
        else
            navigationData.showTab("installed");
        end
        managementUIInstance.show(navigationData);
        return; 
    end
    
    if ~(isStringEmpty(results.identifier))
        navigationData.identifier(results.identifier);
        if ~(isStringEmpty(results.version))
            navigationData.version(results.version);
        else
            % In the scenario where add-on version is not provided as a parameter, Add-on Manager must display the detail page for
            %  1. Most recently enabled version of add-on
            %  2. In case there are no enabled versions, most recently
            %  installed version must be considered.
            %  Today, there is no way to query for (2) from MATLAB. Use
            %  java code to fetch the same
            try
                addOnVersion = matlab.internal.addons.util.getEnabledOrMostRecentlyInstalledVersionUsingJavaApi(results.identifier);
                navigationData.version(addOnVersion);
            catch ex
                if isprop(ex, 'ExceptionObject') && ...
                    ~isempty(strfind(ex.ExceptionObject.getClass, 'IdentifierNotFoundException'))
                    % Do not add version to navigationdata in case of an
                    % exception
                end 
            end
        end
    end
        
    
    % Show enable confirmation
    if ~ isStringEmpty(results.showDialog) && ~isStringEmpty(results.name)
        navigationData.name(results.name); 
        navigationData.showDialog(results.showDialog);
    end
    
    managementUIInstance.show(navigationData);
       
    function validateShowTab(value)
        validateStringScalarInput('matlab.internal.addons.launchers.showManager', 'SHOWTAB', value);
        if ~any(strcmpi(["installed", "updates"], value))
            error(message('matlab_addons:errors:invalidTabName', '{"installed", "updates"}'));
        end
    end

    function validateShowDialog(value)
        validateStringScalarInput('matlab.internal.addons.launchers.showManager', 'SHOWDIALOG', value)
        if ~any(strcmpi("confirmEnable", value))
            error(message('matlab_addons:errors:invalidTabName', 'confirmEnable'));
        end
    end
end