classdef AppletData < matlab.hwmgr.internal.data.LaunchableData
    %APPLETDATA Applet data required by Hardware Manager app

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (SetAccess = private)

        %AppletClass
        %   Client app applet class inheriting from matlab.hwmgr.internal.AppletBase
        AppletClass

        %PluginClass
        %   Client app plugin class inheriting from matlab.hwmgr.internal.plugins.PluginBase
        PluginClass

        %TroubleshootingLinks
        %   Troubleshooting links related to client app or hardware used
        %   with client app
        TroubleshootingLinks

    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})

        function obj = AppletData(appletDisplayName, appletClass, pluginClass, ...
                description, iconID, learnMoreLink, troubleshootingLinks, ...
                identifier, nameValueArgs)
            arguments
                appletDisplayName (1, 1) string
                appletClass (1, 1) string
                pluginClass (1, 1) string
                description (1, 1) string  
                iconID (1, 1) string
                learnMoreLink (1, 1)
                troubleshootingLinks (1, :) {mustBeNonempty}
                identifier (1, 1) string = ""
                nameValueArgs.?matlab.hwmgr.internal.data.LaunchableData
            end

            validateattributes(troubleshootingLinks, ["matlab.hwmgr.internal.data.LinkData", "matlab.hwmgr.internal.data.DocLinkData"], "nonempty");

            namedArgsCell  = namedargs2cell(nameValueArgs);

            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.LaunchableData(identifier, ...
                                                          matlab.hwmgr.internal.data.FeatureCategory.Applet, ...
                                                          appletDisplayName, ...
                                                          description, ...
                                                          iconID, ...
                                                          learnMoreLink, ...
                                                          message('hwmanagerapp:hwmgrstartpage:OpenApp').getString(), ...
                                                          namedArgsCell{:});

            % Initialize AppletData properties
            obj.AppletClass = appletClass;
            obj.PluginClass = pluginClass;
            obj.TroubleshootingLinks = troubleshootingLinks;

        end
    end
end
