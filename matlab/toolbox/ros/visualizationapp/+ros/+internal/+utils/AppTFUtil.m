classdef AppTFUtil < handle
    %APPTFUTIL Utility class for handling transformations in ROS
    %   This class provides methods for transforming messages using a
    %   transformation tree (TFTree) and a ROS version helper.
    %
    %   Properties:
    %       TFTree - A transformation tree object for handling frame transformations.
    %       ROSVersionHelper - An object to assist with ROS version-specific operations.

    % Copyright 2024 The MathWorks, Inc.
    
    properties
        TFTree  % Transformation tree object
        ROSVersionHelper  % Helper object for ROS version-specific operations
    end

    methods
        function obj = AppTFUtil(tfTreeInput, helperInput)
            %APPTFUTIL Construct an instance of AppTFUtil
            %   Initializes the AppTFUtil object with a given transformation
            %   tree and a ROS version helper.
            %
            %   Inputs:
            %       tfTreeInput - Input transformation tree object.
            %       helperInput - Input ROS version helper object.
            obj.TFTree = tfTreeInput;
            obj.ROSVersionHelper = helperInput;
        end

        function transformedMsg = transform(obj, data, dataType, to_frame)
            %TRANSFORM Transform a message to a specified frame
            %   This method uses the ROSVersionHelper to transform a message
            %   from its current frame to the specified target frame.
            %
            %   Inputs:
            %       data - The message data to be transformed.
            %       dataType - The type of the message data.
            %       to_frame - The target frame to transform the message to.
            %
            %   Output:
            %       transformedMsg - The transformed message in the target frame.
            transformedMsg = obj.ROSVersionHelper.transformMessage(data, dataType, obj.TFTree, to_frame);
        end
    end
end