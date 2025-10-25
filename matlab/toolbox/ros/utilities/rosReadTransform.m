function varargout = rosReadTransform(tfmsg, varargin)
%

%   Copyright 2023 The MathWorks, Inc.
%#codegen

    coder.inline('never');

    % Validate message argument type
    validateattributes(tfmsg, {'struct'}, {'scalar'}, 'rosReadTransform');
    coder.internal.assert(strcmp(tfmsg.MessageType, 'geometry_msgs/TransformStamped'), ...
                              'ros:mlroscpp:codegen:InvalidMsgForSpMsgFun', ...
                              'rosReadTransform', 'geometry_msgs/TransformStamped');

    % Parse optional argument for output option
    defaultOutOption = 'se3';

    if nargin>1
        nvPairs = struct('OutputOption', uint32(0));
        pOpts = struct('PartialMatching', true, 'CaseSensitivity', false);
        pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
        option = coder.internal.getParameterValue(pStruct.OutputOption, ...
            defaultOutOption, varargin{:});
        option = convertStringsToChars(option);
        validatestring(option, {'se3','single','pair'},'rosReadTransform');
    else
        option = defaultOutOption;
    end

    % Determine if message is of type ROS or ROS 2
    if isfield(tfmsg, 'Transform')
        coder.internal.assert(~isempty(tfmsg.Transform), 'ros:mlroscpp:codegen:EmptyInputMsg','rosReadTransform');
        specialMsgUtil = ros.internal.SpecialMsgUtil;
    else
        coder.internal.assert(~isempty(tfmsg.transform), 'ros:mlroscpp:codegen:EmptyInputMsg','rosReadTransform');
        specialMsgUtil = ros.internal.ros2.SpecialMsgUtil;
    end

    [T, hMat, tVec, rMat] = specialMsgUtil.readTransform(tfmsg,option);

    % Return transformation
    if strcmp(option, 'se3')
        varargout{1} = T;
    elseif strcmp(option, 'single')
        varargout{1} = hMat;
    else
        varargout{1} = tVec';
        varargout{2} = rMat;
    end
end