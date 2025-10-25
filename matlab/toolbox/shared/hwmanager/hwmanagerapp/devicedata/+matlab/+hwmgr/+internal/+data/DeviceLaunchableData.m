classdef DeviceLaunchableData < matlab.mixin.Heterogeneous
    %DEVICELAUNCHABLEDATA This class defines common properties and constructor for
    % Data specific to a Hardware Manager device associated with launchable
    % feature

    % Copyright 2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = private)
        % IdentifierReference - Used to refer to a specific LaunchableData instance in the corresponding Data Plugin
        IdentifierReference

        % SupportingAddOnBaseCodes - Base codes for upstream toolbox and support package dependencies
        % required for the feature to be launched.
        SupportingAddOnBaseCodes

        %SkipSupportingAddonInstallation
        %   A dictionary using SupportingAddOnBaseCodes as keys and true/false as values (indicating if the installation of toolbox/support package is needed
        %   for the client app to work with this device)  
        SkipSupportingAddonInstallation

    end

    methods

        function obj = DeviceLaunchableData(identifierReference, supportingAddOnBaseCodes, skipSupportingAddonInstallation)
            arguments
                identifierReference (1, 1) string
                supportingAddOnBaseCodes (1, :) string = string.empty()
                skipSupportingAddonInstallation = dictionary(string.empty, logical.empty) 
            end

            obj.IdentifierReference = identifierReference;
            obj.SupportingAddOnBaseCodes = upper(supportingAddOnBaseCodes);
            obj.SkipSupportingAddonInstallation =  skipSupportingAddonInstallation;
        end
    end
end