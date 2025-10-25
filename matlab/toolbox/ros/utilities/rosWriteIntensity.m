function msg = rosWriteIntensity(msg, intensity, varargin)
%rosWriteIntensity Write points in intensity data to a ROS/ROS 2 pointcloud2 message struct.
%   MSG = rosWriteIntensity(MSG, INTENSITY) writes the intensity values from 
%   M-by-1 vector or M-by-N matrix to a ROS/ROS 2 sensor_msgs/PointCloud2
%   message MSG and stores the intensity values in the message MSG.
%
%   MSG = rosWriteIntensity(___,Name,Value) provides additional options
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
%       xyzPoints = single(10*rand(480,640,3));
%
%       % Create a sensor_msgs/PointCloud2 message
%       msg = rosmessage("sensor_msgs/PointCloud2","DataFormat","struct");
%       msg = rosWriteXYZ(msg,xyzPoints,"PointStep",32);
%
%       % Create a random M-by-N matrix with intensity Values
%       intensity = uint8(10*rand(480,640));
%
%       % Write the intensity data to the msg
%       msg = rosWriteIntensity(msg,intensity);
%
%   See also: ROSREADFIELD

%   Copyright 2022 The MathWorks, Inc.
%#codegen

    coder.inline('never');
    narginchk(2,6);

    validateattributes(msg, {'struct'},{'scalar'},'rosWriteIntensity', 'msg');
    coder.internal.assert(strcmp(msg.MessageType,'sensor_msgs/PointCloud2'),...
        'ros:mlroscpp:pointcloud:InvalidMessageWrite',...
        'rosWriteIntensity','sensor_msgs/PointCloud2');

    nvPairs = struct(...
        'PointStep', 0, ...
        'FieldOffset', 0);

    % Parse optional FieldOffset and PointStep parameters to the function
    pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
    pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{1:end});
    pointStepIn = coder.internal.getParameterValue(pStruct.PointStep,0,varargin{1:end});
    fieldOffsetIn = coder.internal.getParameterValue(pStruct.FieldOffset,0,varargin{1:end});
    
    validateattributes(pointStepIn, {'numeric'},{'nonempty','integer','nonnegative','nonnan','scalar'},'rosWriteIntensity', 'pointStepIn');
    validateattributes(fieldOffsetIn, {'numeric'},{'nonempty','integer','nonnegative','nonnan', 'scalar'},'rosWriteIntensity','fieldOffsetIn');

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

    % check (x,y,z) fields are available in the ROS/ROS 2 pointcloud2
    % message struct.
    allFieldNames = specialMsgUtil.getAllFieldNames(msg);
    hasXYZ = false;
    for i=1:length(allFieldNames)
        if strcmp(allFieldNames{i},'x')
            hasXYZ = true;
            break;
        end
    end
    coder.internal.errorIf(~hasXYZ,'ros:mlroscpp:pointcloud:InvalidXYZData');

    validateIntensity(intensity, height, width);

    msg = specialMsgUtil.writeIntensity(msg, intensity, fieldOffset, pointStep, allFieldNames);

    %------------------------------------------------------------------
    function validateIntensity(intensity, height, width)
        % Check Intensity input data type
        validTypes = {'uint8', 'uint16', 'int32','uint32', 'single', 'double'};
        validateattributes(intensity, validTypes, {'real', 'nonsparse'}, ...
            'rosWriteIntensity', 'Intensity');
        validateattributes(width,{'uint32'},{'scalar','nonempty'},'rosWriteIntensity');
        validateattributes(height,{'uint32'},{'scalar','nonempty'},'rosWriteIntensity');

        % Validate Intensity input data
        isMx1 = ismatrix(intensity) && size(intensity,2)==1;
        isMxN = ismatrix(intensity) && size(intensity,3)==1;

        coder.internal.errorIf(~(isMx1 || isMxN), 'ros:mlroscpp:pointcloud:invalidIntensityData');

        % Check size attributes.
        if isMx1
            coder.internal.errorIf( ...
                ~(iscolumn(intensity) && ...
                isequal(uint32(size(intensity,1)), width)), ...
                'ros:mlroscpp:pointcloud:unmatchedIntensityDimensions');
        else
            coder.internal.errorIf( ...  
                ~(ismatrix(intensity) && ...
                isequal(uint32(size(intensity,1)), height) && ...
                isequal(uint32(size(intensity,2)), width)), ...
                'ros:mlroscpp:pointcloud:unmatchedIntensityDimensions');
        end
    end

end
