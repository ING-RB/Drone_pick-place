classdef DescriptorProperties
    %DESCRIPTORPROPERTIES contains properties for creating an instance of
    % DeviceParamsDescriptor in TcpclientDescriptor class.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Constant)
        % Name of product Map file.
        MATLABDocMap (1, 1) string = "matlab"
    end

    properties
        % The name of the descriptor
        Name (1, 1) string

        % The Topic ID in the doc that shows up as the help text when
        % selecting the descriptor
        TopicID (1, 1) string

        % Enable or disable the descriptor button
        Enabled (1, 1) logical = true

        % The tooltip text shown when the descriptor button is disabled.
        % This can be used to provide information to the user as to why the
        % button is disabled.
        TooltipText (1, 1) string
    end
end