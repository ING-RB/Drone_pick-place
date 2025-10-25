function msg = rosWriteRGB(msg, rgb, varargin)
%rosWriteRGB Write RGB Color information to a ROS/ROS 2 pointcloud2 message struct.
%   MSG = rosWriteRGB(MSG, RGB) writes the RGB values from 
%   Mx3 or MxNx3 matrix of 3D point to a ROS/ROS 2 sensor_msgs/PointCloud2
%   message MSG and stores the coordinates in the message MSG.
%
%   MSG = rosWriteRGB(___,Name,Value) provides additional options
%   specified by one or more Name,Value pair arguments. You can specify
%   several name-value pair arguments in any order as Name1, Value1, ...,
%   NameN,valueN:
%
%      "PointStep" -   Optional parameter for setting up the point step of the
%                      input sensor_msgs/PointCloud2 message. point step is 
%                      number of bytes or data entries for one point. 
%                      If the PointStep field is not set in the input 
%                      sensor_msgs/PointCloud2 message, you can use this
%                      parameter to manually set the PointStep information.
%                      Default: uint32(0)
%
%      "FieldOffset" - Optional parameter for setting up the offset of a PointField
%                      of the input sensor_msgs/PointCloud2 message. Field Offset is 
%                      number of bytes from the start of the point to the byte,
%                      in which the field begins to be stored. 
%                      If the Offset field is not set for a PointField in the input 
%                      sensor_msgs/PointCloud2 message, you can use this
%                      parameter to manually set the Offset information.
%                      Default: uint32(0)
%
%   Example:
%       % Create a random M-by-N-by-3 matrix with xyzPoints
%       xyzPoints = single(10*rand(128,128,3));
%
%       % Create a sensor_msgs/PointCloud2 message
%       msg = rosmessage("sensor_msgs/PointCloud2","DataFormat","struct");
%       msg = rosWriteXYZ(msg,xyzPoints,"PointStep",32);
%
%       % Create a random M-by-N-by-3 matrix with rgb Values
%       rgb = single(10*rand(128,128,3));

%       % Write the rgb information to the msg
%       msg = rosWriteRGB(msg,rgb);
%
%   See also: ROSREADRGB.

%   Copyright 2022 The MathWorks, Inc.
%#codegen

    coder.inline('never');
    narginchk(2,6);

    validateattributes(msg, {'struct'},{'scalar'},'rosWriteRGB', 'msg');
    coder.internal.assert(strcmp(msg.MessageType,'sensor_msgs/PointCloud2'),...
        'ros:mlroscpp:pointcloud:InvalidMessageWrite',...
        'rosWriteRGB','sensor_msgs/PointCloud2');

    nvPairs = struct(...
        'PointStep', 0, ...
        'FieldOffset', 0);

    % Parse optional FieldOffset and PointStep parameters to the function
    pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
    pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{1:end});
    pointStepIn = coder.internal.getParameterValue(pStruct.PointStep,0,varargin{1:end});
    fieldOffsetIn = coder.internal.getParameterValue(pStruct.FieldOffset,0,varargin{1:end});
    
    validateattributes(pointStepIn, {'numeric'},{'nonempty','integer','nonnegative','nonnan','scalar'},'rosWriteRGB', 'pointStepIn');
    validateattributes(fieldOffsetIn, {'numeric'},{'nonempty','integer','nonnegative','nonnan', 'scalar'},'rosWriteRGB','fieldOffsetIn');

    pointStep = uint32(pointStepIn);
    fieldOffset = uint32(fieldOffsetIn);

    if isfield(msg, 'Data')
        % ROS message struct
        specialMsgUtil = ros.internal.SpecialMsgUtil;
        width = msg.Width;
        height = msg.Height;
    else
        % ROS 2 message struct
        specialMsgUtil = ros.internal.ros2.SpecialMsgUtil;
        width = msg.width;
        height = msg.height;
    end

    allFieldNames = specialMsgUtil.getAllFieldNames(msg);
    hasXYZ = false;
    for i=1:length(allFieldNames)
        if strcmp(allFieldNames{i},'x')
            hasXYZ = true;
            break;
        end
    end
    coder.internal.errorIf(~hasXYZ,'ros:mlroscpp:pointcloud:InvalidXYZData');

    validateColor(rgb, height, width);

    msg = specialMsgUtil.writeRGB(msg, rgb, fieldOffset, pointStep, allFieldNames);

    %------------------------------------------------------------------
    function validateColor(rgb, height, width)
        % Validate RGB input data type
        validTypes = {'uint8', 'uint16', 'int32', 'uint32','single', 'double'};
        validateattributes(rgb, validTypes, {'nonempty', 'real', 'nonsparse'},'rosWriteRGB', 'rgb');
        validateattributes(width,{'uint32'},{'scalar','nonempty'},'rosWriteRGB');
        validateattributes(height,{'uint32'},{'scalar','nonempty'},'rosWriteRGB');

        % Validate RGB input data
        isMx3   = ismatrix(rgb) && size(rgb,2)==3;
        isMxNx3 = ndims(rgb)==3 && size(rgb,3)==3;

        coder.internal.errorIf(~(isMx3 || isMxNx3), 'ros:mlroscpp:pointcloud:invalidRGBData');

        % Check size attributes.
        if isMx3
            coder.internal.errorIf( ...
                ~isempty(rgb) && ...
                ~isequal(uint32(size(rgb,1)), width), ...
                'ros:mlroscpp:pointcloud:unmatchedRGBDimensions');
        else
            coder.internal.errorIf( ...
                ~isempty(rgb) && ...
                ~isequal(uint32(size(rgb,1)), height) && ...
                ~isequal(uint32(size(rgb,2)), width), ...
                'ros:mlroscpp:pointcloud:unmatchedRGBDimensions');
        end
    end

end
