classdef SimpleActionServer < ros.internal.mixin.ROSInternalAccess & ...
        coder.ExternalDependency

%#codegen

%   Copyright 2022 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        %GoalMessage - goal message struct for safe access
        GoalMessage

        %FeedbackMessage - feedback message struct for safe access
        FeedbackMessage

        %ResultMessage - result message struct for safe access
        ResultMessage
    end

    properties (SetAccess = immutable)
        %ActionName - Name of action associated with this server
        ActionName

        %ActionType - Type of action associated with this server
        ActionType

        %DataFormat - Message format to be used
        DataFormat

        %GoalMessageType - Message type of goal message
        GoalMessageType

        %FeedbackMessageType - Message type of feedback message
        FeedbackMessageType

        %ResultMessageType - Message type of result message
        ResultMessageType
    end

    properties (Access = private)
        %ExecuteGoalFcnData - Callback-data provided by the user with
        %execute-goal callback function
        ExecuteGoalFcnData
        %GoalMsgStruct - private goal message struct
        GoalMsgStruct
        %FeedbackMsgStruct - private feedback message struct
        FeedbackMsgStruct
        %ResultMsgStruct - private result message struct
        ResultMsgStruct
        %IsInitialized - indicator of object initialization
        IsInitialized = false
    end

    properties
        %ActServerHelper - Helper properties to access predefined server
        ActServerHelper
        %ExecuteGoalFcn - Callback property for new goal execution
        ExecuteGoalFcn
    end

    methods
        function obj = SimpleActionServer(node, actionName, actionType, varargin)
            %SIMPLEACTIONSERVER Create a ROS action server object
            %   Please see the class documentation
            %   (help ros.SimpleActionServer) for more details.

            % Set defaults
                defaults = struct( ...
                    'DataFormat','object', ...
                    'ExecuteGoalFcn',[]);
                coder.inline('never');
                coder.extrinsic('ros.codertarget.internal.getCodegenInfo');
                coder.extrinsic('ros.codertarget.internal.ROSMATLABCgenInfo');
                coder.extrinsic('ros.codertarget.internal.ROSMATLABCgenInfo.getInstance');
                coder.extrinsic('ros.codertarget.internal.getEmptyCodegenMsg');
    
                % Ensure actionType is not empty
                coder.internal.assert(contains(actionType,'/'),'ros:mlroscpp:codegen:MissingMessageType',actionName,'SimpleActionServer');

                % A node cannot create another node in codegen
                if ~isempty(node)
                    coder.internal.assert(false,'ros:mlroscpp:codegen:NodeMustBeEmpty');
                end

                % Action name and type must be specified for codegen
                actname = convertStringsToChars(actionName);
                validateattributes(actname,{'char'},{'nonempty'},...
                    'SimpleActionServer','actionName');
                acttype = convertStringsToChars(actionType);
                validateattributes(acttype,{'char'},{'nonempty'},...
                    'SimpleActionServer','actionType');

                % Enables message struct type generation for all required
                % action message cpp definitions
                rosmessage([acttype 'Action'],'DataFormat','struct');

                % Parse NV pairs including all callback functions
                nvPairs = struct(...
                    'DataFormat', uint32(0), ...
                    'ExecuteGoalFcn',uint32(0));
                pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
                pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{1:end});
                executeGoalFcn = coder.internal.getParameterValue(pStruct.ExecuteGoalFcn, ...
                                                             defaults.ExecuteGoalFcn, varargin{1:end});
                dataFormat = coder.internal.getParameterValue(pStruct.DataFormat, ...
                                                          defaults.DataFormat, varargin{1:end});
                validateStringParameter(dataFormat,{'object','struct'},'SimpleActionServer','DataFormat');
                coder.internal.assert(strcmp(dataFormat,'struct'), ...
                                  'ros:mlroscpp:codegen:InvalidDataFormat','SimpleActionServer');

                if ~isempty(executeGoalFcn)
                    coder.internal.assert(isa(executeGoalFcn,'function_handle')||isa(executeGoalFcn,'cell'), ...
                                      'ros:mlroscpp:codegen:InvalidCallback','ExecuteGoalFcn','SimpleActionServer');
    
                    if isa(executeGoalFcn, 'function_handle')
                        obj.ExecuteGoalFcn = executeGoalFcn;
                    else
                        % cell with executeGoalFcn and ExecuteGoalFcnData
                        obj.ExecuteGoalFcn = executeGoalFcn{1};
                        obj.ExecuteGoalFcnData = executeGoalFcn{2};
                    end
                end

                % Store input arguments
                obj.ActionName = actname;
                obj.ActionType = acttype;
                obj.GoalMessageType = [acttype 'Goal'];
                obj.FeedbackMessageType = [acttype 'Feedback'];
                obj.ResultMessageType = [acttype 'Result'];
                obj.DataFormat = dataFormat;
                

                % Get and register code generation information
                cgActionInfo = coder.const(@ros.codertarget.internal.getCodegenInfo,actname,[acttype 'Action'],'actserver');

                cgGoalInfo = coder.const(@ros.codertarget.internal.getCodegenInfo,actname,[acttype 'Goal'],'actserver');
                goalMsgStructGenFcn = str2func(cgGoalInfo.MsgStructGen);
                obj.GoalMsgStruct = goalMsgStructGenFcn();
    
                cgFeedbackInfo = coder.const(@ros.codertarget.internal.getCodegenInfo,actname,[acttype 'Feedback'],'actserver');
                feedbackMsgStructGenFcn = str2func(cgFeedbackInfo.MsgStructGen);
                obj.FeedbackMsgStruct = feedbackMsgStructGenFcn();
    
                cgResultInfo = coder.const(@ros.codertarget.internal.getCodegenInfo,actname,[acttype 'Result'],'actserver');
                resultMsgStructGenFcn = str2func(cgResultInfo.MsgStructGen);
                obj.ResultMsgStruct = resultMsgStructGenFcn();

                % Create pointer to MATLABActServer object
                coder.ceval('auto goalStructPtr= ', coder.wref(obj.GoalMsgStruct));
                coder.ceval('auto feedbackStructPtr= ', coder.wref(obj.FeedbackMsgStruct));
                coder.ceval('auto resultStructPtr= ', coder.wref(obj.ResultMsgStruct));

                templateTypeStr = ['MATLABActServer<',cgActionInfo.MsgClass, ...
                               ',' cgGoalInfo.MsgClass ',' cgFeedbackInfo.MsgClass ',' cgResultInfo.MsgClass ...
                               ',' cgGoalInfo.MsgStructGen '_T,' cgFeedbackInfo.MsgStructGen '_T,' ...
                               cgResultInfo.MsgStructGen '_T>'];
                obj.ActServerHelper = coder.opaque(['std::unique_ptr<' templateTypeStr, '>'],'HeaderFile','mlroscpp_actserver.h');
                if ros.internal.codegen.isCppPreserveClasses
                    % Create ActionServer by passing in class method as
                    % callback
                    obj.ActServerHelper = coder.ceval(['std::unique_ptr<' templateTypeStr, ...
                                                       '>(new ', templateTypeStr, '([this](){this->executeGoalCallback();},', ...
                                                       'goalStructPtr,feedbackStructPtr,resultStructPtr));//']);
                else
                    % Create ActionServer by passing in static function as
                    % callback
                    obj.ActServerHelper = coder.ceval(['std::unique_ptr<' templateTypeStr, ...
                                                       '>(new ', templateTypeStr, '([obj](){ActionServer_executeGoalCallback(obj);},', ...
                                                       'goalStructPtr,feedbackStructPtr,resultStructPtr));//']);
                end
                coder.ceval('MATLABActServer_createActServer', obj.ActServerHelper, coder.rref(obj.ActionName), ...
                    size(obj.ActionName, 2));

                % Ensure callback is not optimized away by making an
                % explicit call here
                obj.executeGoalCallback;
                obj.IsInitialized = true;
        end

        function resultMsg = rosmessage(obj, varargin)
        % ROSMESSAGE Create a new action result message
            coder.inline('never');
            resultMsg = rosmessage(obj.ResultMessageType, 'DataFormat', 'struct');
        end % rosmessage

        function feedbackMsg = getFeedbackMessage(obj, varargin)
        % GETFEEDBACKMESSAGE Create a new action feedback message
            coder.inline('never');
            feedbackMsg = rosmessage(obj.FeedbackMessageType, 'DataFormat', 'struct');
        end % getFeedbackMessage

        function executeGoalCallback(obj)
            %EXECUTEGOALCALLBACK Callback function for goal execution
            coder.inline('never');
            ros.internal.codegen.doNotOptimize(obj.ActionType);

            if ~isempty(obj.ExecuteGoalFcn) && (obj.IsInitialized)
                % Call user defined callback function
                % function [result, success] = goalExecution(src,goal,defaultFeedback,defaultResult)
                lastGoalMsg = obj.GoalMessage;
                defaultFeedbackMsg = getFeedbackMessage(obj);
                defaultResultMsg = rosmessage(obj);

                % Run ExecuteGoalFcn and return result message
                resultMsg = defaultResultMsg; %#ok<NASGU>
                if isempty(obj.ExecuteGoalFcnData)
                    [resultMsg, success] = obj.ExecuteGoalFcn(obj, ...
                                                           lastGoalMsg, ...
                                                           defaultFeedbackMsg, ...
                                                           defaultResultMsg);
                else
                    [resultMsg, success] = obj.ExecuteGoalFcn(obj, ...
                                                           lastGoalMsg, ...
                                                           defaultFeedbackMsg, ...
                                                           defaultResultMsg, ...
                                                           obj.ExecuteGoalFcnData);
                end
                % Send the result back over the network
                if success
                    coder.ceval('MATLABActServer_mlSetSucceeded',obj.ActServerHelper,resultMsg);
                elseif isPreemptRequested(obj)
                    coder.ceval('MATLABActServer_mlSetPreempted',obj.ActServerHelper);
                else
                    coder.ceval('MATLABActServer_mlSetAborted',obj.ActServerHelper);
                end
            end
        end

        function sendFeedback(obj, feedbackMsg)
        % SENDFEEDBACK Send feedback to action client while goal is executing
            ros.internal.codegen.doNotOptimize(obj.ActionType);
            coder.ceval('MATLABActServer_mlPublishFeedback',obj.ActServerHelper,feedbackMsg);
        end

        function status = isPreemptRequested(obj)
        %ISPREEMPTREQUESTED Check if goal has been preempted
            ros.internal.codegen.doNotOptimize(obj.ActionType);
            status = false;
            status = coder.ceval('MATLABActServer_mlIsPreemptRequested',obj.ActServerHelper);
        end

        function msg = get.GoalMessage(obj)
            coder.ceval('MATLABActServer_lock',obj.ActServerHelper);
            msg = obj.GoalMsgStruct;
            coder.ceval('MATLABActServer_unlock',obj.ActServerHelper);
        end

        function msg = get.FeedbackMessage(obj)
            coder.ceval('MATLABActServer_lock',obj.ActServerHelper);
            msg = obj.FeedbackMsgStruct;
            coder.ceval('MATLABActServer_unlock',obj.ActServerHelper);
        end

        function msg = get.ResultMessage(obj)
            coder.ceval('MATLABActServer_lock',obj.ActServerHelper);
            msg = obj.ResultMsgStruct;
            coder.ceval('MATLABActServer_unlock',obj.ActServerHelper);
        end
    end

    methods (Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'FeedbackMessageType','ResultMessageType'};
        end

        function ret = getDescriptiveName(~)
            ret = 'ROS ActionServer';
        end

        function ret = isSupportedContext(bldCtx)
            ret = bldCtx.isCodeGenTarget('rtw');
        end

        function updateBuildInfo(buildInfo,bldCtx)
            if bldCtx.isCodeGenTarget('rtw')
                srcFolder = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
                addIncludeFiles(buildInfo,'mlroscpp_actserver.h',srcFolder);
            end
        end
    end

    methods (Static, Access = ?ros.internal.mixin.ROSInternalAccess)
        function props = getImmutableProps()
            props = {'ActionType','ActionName','DataFormat',...
                     'GoalMessageType','FeedbackMessageType','ResultMessageType'};
        end
    end
end

function validateStringParameter(value, options, funcName, varName)
% Separate function to suppress output and just validate
    validatestring(value, options, funcName, varName);
end
