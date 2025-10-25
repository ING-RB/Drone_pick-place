function msg = rosWriteXYZ(msg, xyzPoints, varargin)
%rosWriteXYZ Write points in (x,y,z) coordinates to a ROS/ROS 2 pointcloud2 message struct.
%   MSG = rosWriteXYZ(MSG, XYZ) writes the (x,y,z) coordinates from 
%   Mx3 or MxNx3 matrix of 3D point to a ROS/ROS 2 sensor_msgs/PointCloud2
%   message MSG and stores the coordinates in the message MSG.
%
%   MSG = rosWriteXYZ(___,Name,Value) provides additional options
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
%       xyz = uint8(10*rand(128,128,3));
%
%       % Create a sensor_msgs/PointCloud2 message
%       msg = rosmessage("sensor_msgs/PointCloud2","DataFormat","struct");
%
%       % Write the x,y,z co-ordinates to the msg
%       msg = rosWriteXYZ(msg,xyz);
%
%   See also: ROSREADXYZ.

%   Copyright 2022 The MathWorks, Inc.
%#codegen
    
    % Validate Input argument and create local fields for ROS or ROS 2
    % sensor_msgs/PointCloud2
    coder.inline('never');
    narginchk(2,6);

    validateattributes(msg, {'struct'},{'scalar'},'rosWriteXYZ', 'msg');
    coder.internal.assert(strcmp(msg.MessageType,'sensor_msgs/PointCloud2'),...
        'ros:mlroscpp:pointcloud:InvalidMessageWrite',...
        'rosWriteXYZ','sensor_msgs/PointCloud2');
    
    validateXYZPoints(xyzPoints);

    nvPairs = struct(...
        'PointStep', 0, ...
        'FieldOffset', 0);

    % Parse optional FieldOffset and PointStep parameters to the function
    pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
    pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{1:end});
    pointStepIn = coder.internal.getParameterValue(pStruct.PointStep,0,varargin{1:end});
    fieldOffsetIn = coder.internal.getParameterValue(pStruct.FieldOffset,0,varargin{1:end});
    
    validateattributes(pointStepIn, {'numeric'},{'nonempty','integer','nonnegative','nonnan','scalar'},'rosWriteXYZ', 'pointStepIn');
    validateattributes(fieldOffsetIn, {'numeric'},{'nonempty','integer','nonnegative','nonnan', 'scalar'},'rosWriteXYZ','fieldOffsetIn');

    pointStep = uint32(pointStepIn);
    fieldOffset = uint32(fieldOffsetIn);

    if isfield(msg, 'Data')
        % ROS message struct
        specialMsgUtil = ros.internal.SpecialMsgUtil;
    else
        % ROS 2 message struct
        specialMsgUtil = ros.internal.ros2.SpecialMsgUtil;
    end

    msg = specialMsgUtil.writeXYZ(msg, xyzPoints, fieldOffset, pointStep);

    %------------------------------------------------------------------
    function validateXYZPoints(xyzPoints)
        % Validate XYZ input data type
        validateattributes(xyzPoints, {'numeric'}, {'nonempty', 'real', 'nonsparse' }, 'rosWriteXYZ', 'xyzPoints');

        % Validate XYZ input data
        isMx3   = ismatrix(xyzPoints) && size(xyzPoints,2)==3;
        isMxNx3 = ndims(xyzPoints)==3 && size(xyzPoints,3)==3;

        coder.internal.errorIf(~(isMx3 || isMxNx3), 'ros:mlroscpp:pointcloud:invalidXYZPoints');
    end

end
