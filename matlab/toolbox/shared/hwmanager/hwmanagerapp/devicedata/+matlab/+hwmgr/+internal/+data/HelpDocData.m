classdef HelpDocData < matlab.hwmgr.internal.data.LaunchableData
    %HELPDOCDATA required by Hardware Manager app

    % Copyright 2024 The MathWorks, Inc.

    properties %(SetAccess = private)
        % HelpDocLink
        %   Link to the documentation page
        HelpDocLink

        % RelatedAddOnBaseCodes
        %   Base codes for add-ons that are relevant to the documentation that can be optionally installed.
        RelatedAddOnBaseCodes
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = HelpDocData(displayName, description, iconID, helpDocLink, identifier, nameValueArgs)
            arguments
                displayName (1, 1) string
                description (1, 1) string
                iconID (1, 1) string
                helpDocLink (1, 1)
                identifier (1, 1) string
                nameValueArgs.?matlab.hwmgr.internal.data.LaunchableData
                nameValueArgs.RelatedAddOnBaseCodes (1, :) string = string.empty()
            end

            validateattributes(helpDocLink, ["matlab.hwmgr.internal.data.LinkData", "matlab.hwmgr.internal.data.DocLinkData"], "scalar");

            % Remove the NV pair for "RelatedAddOnBaseCodes" as it only applicable within this class
            namedArgsCell  = namedargs2cell(rmfield(nameValueArgs,'RelatedAddOnBaseCodes'));

            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.LaunchableData(identifier, ...
                                                          matlab.hwmgr.internal.data.FeatureCategory.HelpDoc, ...
                                                          displayName, ...
                                                          description, ...
                                                          iconID, ...
                                                          [], ...
                                                          message('hwmanagerapp:hwmgrstartpage:ViewDocumentation').getString(), ...
                                                          namedArgsCell{:});

            % Initialize this class properties
            obj.HelpDocLink = helpDocLink;
            obj.RelatedAddOnBaseCodes = upper(nameValueArgs.RelatedAddOnBaseCodes);
        end
    end
end