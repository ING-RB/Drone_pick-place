function callbackStruct = ros2ActionSendGoalOptions(varargin)
%ROS2ACTIONSENDGOALOPTIONS Return a structure of action client callbacks
%   CB = ros2ActionSendGoalOptions returns a structure with  GoalRespFcn,
%   FeedbackFcn, and ResultFcn fields which specify callbacks for goals
%   sent from an action client. With no input specifying behavior, CB
%   specifies the GoalRespFcn to indicate that the goal has been accepted
%   by the server immediately.
%
%   CB = ros2ActionSendGoalOptions(Name=Value) provides options specified
%   by one or more Name=Value pair arguments.
%
%      "GoalRespFcn" - Callback function that is called after receiving goal
%                      response from server. The callback function should
%                      accept at least one input argument, GH, which is
%                      the associated ActionClientGoalHandle object.
%                      You can provide additional inputs with VARARGIN.
%                      The function signature is as follows:
%
%                          function goalRespFcn(GH, VARARGIN)
%
%      "FeedbackFcn" - Callback function that is called when receiving
%                      feedback response from server. The callback function
%                      should accept at least two input arguments. The first
%                      argument, GH, is the associated 
%                      ros.internal.ros.ActionClientGoalHandle object. The
%                      second argument, FBMSG, is the received feedback 
%                      message. You can provide additional inputs with 
%                      VARARGIN. The function signature is as
%                      follows:
%
%                          function feedbackFcn(GH, FBMSG, VARARGIN)
%
%      "ResultFcn"   - Callback function that is called when receiving
%                      result message from server. The callback function
%                      should accept at least two input arguments. The first
%                      argument, GH, is the associated 
%                      ros.internal.ros.ActionClientGoalHandle object. The
%                      second argument, RESULT, is a structure with 
%                      information about the goal result. You can provide
%                      additional inputs with VARARGIN.
%                      The RESULT structure contains the following fields:
%                      - result   - Received result message
%                      - code     - Received result code
%                      - goalUUID - Goal UUID associated with the result
%                      The function signature is as follows:
%
%                          function resultFcn(GH, RESULT, VARARGIN)
%
%   Note: You pass additional arguments to the callback function by
%   including both the callback function and the arguments as elements of a
%   cell array when setting the property.
%
%   Example:
%      % Create a ROS 2 node
%      node = ros2node("/node_1");
%
%      % Create an action client and wait to connect to the action server
%      % (blocking). This assumes there is an action server for this action
%      % name in existence.
%      client = ROS2ACTIONCLIENT(node,"fibonacci",...
%          "example_interfaces/Fibonacci", ...
%          CancelServiceQoS=struct(Depth=200,History="keeplast"), ...
%          FeedbackTopicQoS=struct(Depth=200,History="keepall"));
%      waitForServer(client);
%
%      % Create the goal message
%      goalMsg = ros2message(client);
%      goalMsg.order = int32(8);
%
%      % Create optional callback functions
%      callbackOpts = ros2ActionSendGoalOptions(...
%          FeedbackFcn={@printMessage,1}, ...
%          ResultFcn={@printMessage,2});
%
%      % Send a goal with customized callback functions to the server. This
%      call will return immediately.
%      goalHandle = sendGoal(client,goalMsg,callbackOpts);
%
%      function printMessage(~,resp,userData)
%          seq = resp.sequence;
%          fprintf("Stage %d: Numbers in received sequence: [", userData);
%          for i=1:numel(seq)
%              fprintf(" %d",seq(i));
%          end
%          fprintf(' ]\n');
%      end

%   Copyright 2022 The MathWorks, Inc.
%#codegen

% Set up default callback functions
    defaultGoalRespFcn = @(goalHandle,~) fprintf('Goal with GoalUUID %s accepted by server, waiting for result!\n',goalHandle.GoalUUID);
    defaultFeedbackFcn = @(goalHandle,feedbackMsg) [];
    defaultResultFcn = @(goalHandle,resultMsg) [];

    % Parse NV pairs
    nvPairs = struct(...
        'GoalRespFcn', uint32(0), ...
        'FeedbackFcn', uint32(0), ...
        'ResultFcn',uint32(0));
    pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
    pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
    GoalRespFcn = coder.internal.getParameterValue(pStruct.GoalRespFcn, ...
        defaultGoalRespFcn, varargin{:});
    FeedbackFcn = coder.internal.getParameterValue(pStruct.FeedbackFcn, ...
        defaultFeedbackFcn, varargin{:});
    ResultFcn = coder.internal.getParameterValue(pStruct.ResultFcn, ...
        defaultResultFcn, varargin{:});

    % Validate and extract actual callback functions and user data
    [callbackStruct.GoalRespFcn, callbackStruct.GoalRespUserData] = ...
        ros.internal.Parsing.validateFunctionHandle(...
            GoalRespFcn, 'ros2ActionSendGoalOptions', 'GoalRespFcn');

    [callbackStruct.FeedbackFcn, callbackStruct.FeedbackUserData] = ...
        ros.internal.Parsing.validateFunctionHandle(...
            FeedbackFcn, 'ros2ActionSendGoalOptions', 'FeedbackFcn');

    [callbackStruct.ResultFcn, callbackStruct.ResultUserData] = ...
        ros.internal.Parsing.validateFunctionHandle(...
            ResultFcn, 'ros2ActionSendGoalOptions', 'ResultFcn');

    if ~isempty(coder.target)
        % Generate unique id for send goal option set
        % This is only required for code generation workflow as an
        % identifier.
        strOpts = ['A':'Z' 'a':'z'];
        callbackStruct.OptionID = strOpts(randi([1,52],1,5));
    end
end