classdef ExampleData < matlab.hwmgr.internal.data.LaunchableData
    %EXAMPLEDATA required by Hardware Manager app

    % Copyright 2024 The MathWorks, Inc.

    properties %(SetAccess = private)
        %ExampleName
        %   Example name to launch
        ExampleName

        %RelatedLinks
        %   Links related examples help pages
        RelatedLinks

        %CommandArgs
        %   Arguments to pass to the example launcher
        CommandArgs

    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = ExampleData(displayName, description, iconID, learnMoreLink, exampleName, relatedLinks, identifier, nameValueArgs)
            arguments
                displayName (1, 1) string
                description (1, 1) string
                iconID (1, 1) string
                learnMoreLink (1, 1)
                exampleName (1, 1) string
                relatedLinks (1, :)
                identifier (1, 1) string
                nameValueArgs.?matlab.hwmgr.internal.data.LaunchableData
                nameValueArgs.CommandArgs (1, :) string = string.empty()
            end

            if ~isempty(relatedLinks)
                validateattributes(relatedLinks, ["matlab.hwmgr.internal.data.LinkData", "matlab.hwmgr.internal.data.DocLinkData"], "row");
            end

            % Remove the NV pair for CommandArgs since it belongs to
            % this class only
            namedArgsCell  = namedargs2cell(rmfield(nameValueArgs,'CommandArgs'));
           
            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.LaunchableData(identifier, ...
                                                          matlab.hwmgr.internal.data.FeatureCategory.Example, ...
                                                          displayName, ...
                                                          description, ...
                                                          iconID, ...
                                                          learnMoreLink, ...
                                                          message('hwmanagerapp:hwmgrstartpage:OpenExample').getString(), ...
                                                          namedArgsCell{:});

            % Initialize this class properties
            obj.ExampleName = exampleName;
            obj.RelatedLinks = relatedLinks;
            obj.CommandArgs = nameValueArgs.CommandArgs;
        end
    end
end