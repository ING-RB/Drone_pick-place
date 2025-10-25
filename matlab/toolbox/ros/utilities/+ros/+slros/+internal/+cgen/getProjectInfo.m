function rosProjectInfo = getProjectInfo(configData, modelName, isRefModel, refLibrary, modelParseFcn, buildDir)
%This function is for internal use only. It may be removed in the future.
%
% GETPROJECTINFO Generate a ROS project structure that contains the
% information about the model for use with the ROS project generation.
%
%  import ros.slros.internal.cgen.*
%  data = codertarget.data.getData(getActiveConfigSet(mdlName));
%  refLibrary = 'ros2lib';
%  modelParseFcn = @ros.slros2.internal.bus.Util.getROS2BlocksInModel;
%  getProjectInfo(data,mdlName,false,refLibrary, modelParseFcn);
%
%  ans =
%
%   struct with fields:
%
%     PackageInformation: [1x1 struct]
%                 Folder: 'L:\R2019b\ros'
%              Workspace: 'L:\R2019b\ros'
%             Publishers: [1x1 containers.Map]
%            Subscribers: [1x1 containers.Map]
%            ExtmodeInfo: [1x1 struct]

%   Copyright 2020-2025 The MathWorks, Inc.

%% Coder target and Code-generation info

% arguments
%     configData (1,1) struct
%     mdlName (1,1) char {mustBeNonempty, mustBeLoaded(mdlName)}
%     isRefModel (1,1) logical
%     refLibrary (1,1) char {mustBeNonempty}
%     modelParseFcn (1,1) function_handle {mustBeNonempty}
%     buildDir {mustBeAFolder}
% end

% Store Package information

    import ros.codertarget.internal.Util

    rosProjectInfo.ModelName = modelName;
    rosProjectInfo.PackageInformation = configData.Packaging;

    % Store ROS2 Install folder and workspace
    rosProjectInfo.Folder = configData.ROS2Install.Folder;
    rosProjectInfo.Workspace = configData.ROS2Install.Workspace;
    rosProjectInfo.needNodeInterface = true;
    rosProjectInfo.hasModelRefs = false;
    rosProjectInfo.IncludeMdlTermFcn = get_param(modelName,'IncludeMdlTerminateFcn');
    % Apply code interface packaging settings
    rosProjectInfo.StepMethodName = [];
    rosProjectInfo.ModelClassName = [];
    rosProjectInfo.ModelStepArguments = '';
    rosProjectInfo.ModelInitializeArguments = '';
    rosProjectInfo.ModelTerminateArguments = '';
    rosProjectInfo.ModelFcnArguments = '';
    rosProjectInfo.BlockDataInit = '';
    switch(get_param(modelName,'CodeInterfacePackaging'))
        case 'C++ class'
            rtwCPPClassObj = get_param(modelName,'RTWCPPFcnClass');
            rosProjectInfo.StepMethodName = rtwCPPClassObj.getStepMethodName;
            rosProjectInfo.ModelClassName = rtwCPPClassObj.ModelClassName;
        case 'Reusable function'
            [rosProjectInfo.ModelStepArguments, ...
                rosProjectInfo.ModelInitializeArguments, ...
                rosProjectInfo.ModelTerminateArguments,...
                rosProjectInfo.ModelFcnArguments,...
                rosProjectInfo.BlockDataInit] = ...
                ros.codertarget.internal.getFunctionPrototypeArguments(...
                modelName,buildDir);
        otherwise
    end
    rosProjectInfo.ModelRTMVarName = [modelName, '_M'];
    % Total length of 'RT_MODEL_<modelname>_T' needs to be less than
    % maxIdLength
    maxIdLen = get_param(modelName, 'MaxIdLength');
    maxMdlNameLen = maxIdLen-11;
    rosProjectInfo.ModelRTMVarType = ['RT_MODEL_' modelName(1:min(length(modelName),maxMdlNameLen)) '_T'];

    if isRefModel
        % Empty scheduling data for referenced models
        rosProjectInfo.isSingleTasking = [];
        rosProjectInfo.HasExplicitPartitions = [];
        rosProjectInfo.SampleTimes = [];
        rosProjectInfo.SampleTimeNsecs = '';
        rosProjectInfo.isRefModel = true;
    else
        % Base-rate step function name
        cInfo = load(fullfile(buildDir,"codeInfo.mat"));
        codeInfo = cInfo.codeInfo;
        rosProjectInfo.BaseStepFcn = codeInfo.OutputFunctions(1).Prototype.Name;
        [isSingleTasking, sampleTimes, hasExplicitPartitions, baseRateSampleTime] = Util.getSchedulerData(modelName, buildDir);
        rosProjectInfo.isSingleTasking = isSingleTasking;
        rosProjectInfo.HasExplicitPartitions = hasExplicitPartitions;
        rosProjectInfo.SampleTimes = sampleTimes;
        nanoSecs = baseRateSampleTime*1e9;
        % Convert SampleTime to nanoseconds
        rosProjectInfo.SampleTimeNsecs = sprintf('%d',int64(round(nanoSecs)));
        % Set the RTM Access type for scheduling
        rosProjectInfo.UseMemberMethodForRTM = Util.useMemberMethodForRTM(modelName);
        rosProjectInfo.isRefModel = false;
    end    
    % will be added later
    rosProjectInfo.ExtmodeInfo = [];
    rosProjectInfo.ROS = configData.ROS;    
    if isfield(configData.ROS, 'ROSTimeStepping')
        rosProjectInfo.ROS.ROSTimeStepping = loc_convertParameterToLogical(configData.ROS.ROSTimeStepping);
        rosProjectInfo.ROS.ROSTimeNotification = loc_convertParameterToLogical(configData.ROS.ROSTimeNotification);
        rosProjectInfo.ROS.StepNotify = configData.ROS.StepNotify;
    else
        rosProjectInfo.ROS.ROSTimeStepping = false;
        rosProjectInfo.ROS.ROSTimeNotification = false;
        rosProjectInfo.ROS.StepNotify = '/step_notify';
    end
    %% Pub/Sub/Svc info

    % get all the ROS2 blocks
    [~,~,~, pubSubMsgBlks,paramBlockList,getTfBlockList,applyTfBlockList,~,timeBlks,svcCallBlks, svcServerBlks, ...
        actSendGoalBlks, actMonitorGoalBlks, actCancelGoalBlks] = feval(modelParseFcn,modelName);
    % -------------------------------------------------------------------------
    % Create publisher/subscriber MAP with following format
    % --------------+----------------------------------------------------------
    %   Key (char)  |                          Value (structure)
    % --------------+----------------------------------------------------------
    %               | .BlockID = '<BlkName_id>', .BusName = '<SL_Bus_busname>',
    %  BlkName      | .msgInfo.msgCPPClassName = 'msg::type'
    %               |
    % --------------+----------------------------------------------------------

    Publishers = containers.Map();
    Subscribers = containers.Map();
    MessageTypes = cell(numel(pubSubMsgBlks)+2*numel(svcCallBlks),1);
    registry = ros.internal.CustomMessageRegistry.getInstance('ros2');
    % loop over all the blocks and populate the map
    for ii=1:numel(pubSubMsgBlks)
        thisBlk = pubSubMsgBlks{ii};
        % replace all newline characters to <space>
        thisKey = strrep(thisBlk, newline, ' ');
        % get the message type of the block
        msgType = get_param(thisBlk, 'messageType');
        MessageTypes{ii} = msgType;
        % convert message type to bus name
        busName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName(msgType);
        % get message info to derive C++ class name
        msgInfo = ros.internal.ros2.getMessageInfo(msgType, registry);
        switch(get_param(thisBlk,'ReferenceBlock'))
          case [refLibrary '/Publish']
            Publishers(thisKey) = struct('BlockID', get_param([thisBlk,'/SinkBlock'], 'BlockId'), ...
                                         'BusName', busName, ...
                                         'msgInfo', msgInfo);
          case [refLibrary '/Subscribe']
            Subscribers(thisKey) = struct('BlockID', get_param([thisBlk,'/SourceBlock'], 'BlockId'), ...
                                          'BusName', busName, ...
                                          'msgInfo', msgInfo);
        end
    end
                
    % -------------------------------------------------------------------------
    % Create ServiceCaller MAP with following format
    % --------------+----------------------------------------------------------
    %   Key (char)  |                          Value (structure)
    % --------------+----------------------------------------------------------
    %               | .BlockID = '<BlkName_id>', .InputBusName = '<SL_Bus_busname>',
    %  BlkName      | .OutputBusName = '<SL_Bus_busname>',
    %               | .msgInfo.msgBaseCppClassName = 'pkg::srv::type'
    % --------------+----------------------------------------------------------
    ServiceCallers = containers.Map();
    CallerServiceTypes = cell(numel(svcCallBlks),1);
    % loop over all the blocks and populate the map
    for ii=1:numel(svcCallBlks)
        thisBlk = svcCallBlks{ii};
        % replace all newline characters to <space>
        thisKey = strrep(thisBlk, newline, ' ');
        % get the service type of the block
        svcType = get_param(thisBlk, 'serviceType');
        % add service into service type list
        CallerServiceTypes{ii} = svcType;
        % add service request and response into message type list
        MessageTypes{numel(pubSubMsgBlks)+2*ii-1} = [svcType 'Request'];
        MessageTypes{numel(pubSubMsgBlks)+2*ii} = [svcType 'Response'];
        % convert input and output service type to bus name
        inputBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName([svcType 'Request']);
        outputBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName([svcType 'Response']);
        % get service info to derive C++ class name
        msgInfo = ros.internal.ros2.getServiceInfo([svcType 'Request'], svcType, 'Request');
        % this is required for ProjectTool information
        reqMsgInfo = ros.internal.ros2.getMessageInfo([svcType 'Request'], registry);
        reqMsgStruct = struct('msgInfo',reqMsgInfo);
        ServiceCallers(thisKey) = struct('BlockID', get_param([thisBlk,'/ServiceCaller'],'BlockId'), ...
                                         'InputBusName', inputBusName, 'OutputBusName', outputBusName, 'msgInfo', msgInfo, ...
                                         'Request',reqMsgStruct);
    end

    % -------------------------------------------------------------------------
    % Create ServiceServer MAP with following format
    % --------------+----------------------------------------------------------
    %   Key (char)  |                          Value (structure)
    % --------------+----------------------------------------------------------
    %               | .BlockID = '<BlkName_id>', .ReqBusName = '<SL_Bus_busname>',
    %  BlkName      | .RespBusName = '<SL_Bus_busname>',
    %               | .msgInfo.msgBaseCppClassName = 'pkg::srv::type'
    % --------------+----------------------------------------------------------
    ServiceServers = containers.Map();
    ServerServiceTypes = cell(numel(svcServerBlks),1);
    % loop over all the blocks and populate the map
    for ii=1:numel(svcServerBlks)
        thisBlk = svcServerBlks{ii};
        % replace all newline characters to <space>
        thisKey = strrep(thisBlk, newline, ' ');
        % get the service type of the block
        svcType = get_param(thisBlk, 'serviceType');
        % add service into service type list
        ServerServiceTypes{ii} = svcType;
        % add service request and response into message type list
        MessageTypes{end+1,1} = [svcType, 'Request']; %#ok<AGROW>
        MessageTypes{end+1,1} = [svcType, 'Response']; %#ok<AGROW>
        % convert request and response service type to bus name
        reqBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName([svcType 'Request']);
        respBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName([svcType 'Response']);
        % get service info to derive C++ class name
        msgInfo = ros.internal.ros2.getServiceInfo([svcType 'Request'], svcType, 'Request');
        % this is required for ProjectTool information
        reqMsgInfo = ros.internal.ros2.getMessageInfo([svcType 'Request'], registry);
        reqMsgStruct = struct('msgInfo',reqMsgInfo);
        ServiceServers(thisKey) = struct('BlockID', get_param(thisBlk,'BlockId'), ...
                                         'ReqBusName', reqBusName, 'RespBusName', respBusName, 'msgInfo', msgInfo, ...
                                         'Request',reqMsgStruct);
    end


    % -------------------------------------------------------------------------
    % Create ActionClient MAP with following format
    % --------------+----------------------------------------------------------
    %   Key (char)  |                          Value (structure)
    % --------------+----------------------------------------------------------
    %               | .BlockID = '<BlkName_id>', .GoalBusName = '<SL_Bus_busname>',
    %  BlkName      | .FeedbackBusName = '<SL_Bus_busname>', .ResultBusName = '<SL_Bus_busname>',
    %               | .msgInfo.msgBaseCppClassName = 'pkg::act::type'
    % --------------+----------------------------------------------------------
    ActionClients = containers.Map();
    ActionClientTypes = cell(numel(actSendGoalBlks),1);
    % loop over all the blocks and populate the map
    for ii=1:numel(actSendGoalBlks)
        thisBlk = actSendGoalBlks{ii};
        % replace all newline characters to <space>
        thisKey = strrep(thisBlk, newline, ' ');
        % get the action type of the block
        actType = get_param(thisBlk, 'actionType');
        % add action into action type list
        ActionClientTypes{ii} = actType;
        % add action goal, uuid, feedback, result and cancel messages into message type list
        MessageTypes{end+1,1} = [actType, 'Goal']; %#ok<AGROW>
        MessageTypes{end+1,1} = 'unique_identifier_msgs/UUID'; %#ok<AGROW>

        if ~isempty(actMonitorGoalBlks)
            MessageTypes{end+1,1} = [actType, 'Feedback']; %#ok<AGROW>
            MessageTypes{end+1,1} = [actType, 'Result']; %#ok<AGROW>
        end

        cancelGoalBlockId = '';
        if ~isempty(actCancelGoalBlks)
            cancelGoalBlk = actCancelGoalBlks{ii};
            cancelGoalBlockId = get_param(cancelGoalBlk, 'BlockId');
            MessageTypes{end+1,1} = 'action_msgs/CancelGoalResponse'; %#ok<AGROW>
        end
        
        % convert goal, feedback and result action type to bus name
        goalBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName([actType 'Goal']);
        feedbackBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName([actType 'Feedback']);
        resultBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName([actType 'Result']);
        cancelBusName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName('action_msgs/CancelGoalResponse');
        % get action info to derive C++ class name
        msgInfo = ros.internal.ros2.getActionInfo([actType 'Goal'], actType, 'Goal');
        % this is required for ProjectTool information
        goalMsgInfo = ros.internal.ros2.getMessageInfo([actType 'Goal'], registry);
        goalMsgStruct = struct('msgInfo',goalMsgInfo);
        ActionClients(thisKey) = struct('BlockID', get_param(thisBlk,'BlockId'), ...
                                        'CancelGoalBlockID', cancelGoalBlockId, ...
                                         'GoalBusName', goalBusName, ...
                                         'FeedbackBusName', feedbackBusName, 'ResultBusName', resultBusName, 'CancelBusName', cancelBusName, ...
                                         'msgInfo', msgInfo, 'Goal',goalMsgStruct);
    end

    if ~isempty(getTfBlockList)
        MessageTypes{end+1,1} = 'geometry_msgs/TransformStamped';
    end

    if ~isempty(applyTfBlockList)
        MessageTypes{end+1,1} = 'geometry_msgs/TransformStamped';
        % loop over all the blocks and add message types for entities
        for ii=1:numel(applyTfBlockList)
            thisBlk = applyTfBlockList{ii};
            msgType = get_param([thisBlk,'/ApplyTransform'],'EntityMsgType');
            MessageTypes{end+1,1} = msgType; %#ok<AGROW>
        end
    end

    if ~isempty(timeBlks)
        hasBusOutput = cellfun(@(block) strcmp(get_param(block, 'OutputFormat'), 'bus'), timeBlks);
        if any(hasBusOutput)
            MessageTypes{end+1,1} = 'builtin_interfaces/Time';
        end
    end

    rosProjectInfo.Publishers = Publishers;
    rosProjectInfo.Subscribers = Subscribers;
    rosProjectInfo.ParamGetters = createGetParamBlockInfo(paramBlockList);
    rosProjectInfo.TransformGetters = createGetTfBlockInfo(getTfBlockList);
    rosProjectInfo.ServiceCallers = ServiceCallers;
    rosProjectInfo.ServiceServers = ServiceServers;
    rosProjectInfo.ActionClients = ActionClients;
    rosProjectInfo.MessageTypes = unique(MessageTypes);
    rosProjectInfo.ServiceTypes = unique([CallerServiceTypes; ServerServiceTypes]);
    rosProjectInfo.ActionTypes = ActionClientTypes;

end

function ret = mustBeLoaded(mdlName)
    ret = bdIsLoaded(mdlName);
end

function getTfBlks = createGetTfBlockInfo(getTfBlockList)
    getTfBlks = containers.Map();
    % loop over all the blocks and populate the map
    for ii=1:numel(getTfBlockList)
        thisBlk = getTfBlockList{ii};
        % replace all newline characters to <space>
        thisKey = strrep(thisBlk, newline, ' ');
        % message type is always TransformStamped
        msgType = 'geometry_msgs/TransformStamped';
        % convert message type to bus name
        busName = ros.slros2.internal.bus.Util.rosMsgTypeToBusName(msgType);
        getTfBlks(thisKey) = struct('BlockID', get_param([thisBlk,'/SourceBlock'],'BlockId'), ...
                                    'BusName', busName);
    end
end

function getParamBlks = createGetParamBlockInfo(paramBlockList)
% CREATEGETPARAMBLOCKINFO Returns a containers.Map object with the
% ROS 2 Get Parameter block meta-data in the model for use with Simulink
% code-generation
    cppParamMap = containers.Map();
    cppParamMap('uint8[]') = 'uint8_T';
    cppParamMap('int64[]') = 'int64_T';
    cppParamMap('double[]') = 'real64_T';
    cppParamMap('boolean[]') = 'boolean_T';
    cppParamMap('string') = 'std::string';
    cppParamMap('uint8') = 'uint8_T';
    cppParamMap('int64') = 'int64_T';
    cppParamMap('double') = 'real64_T';
    cppParamMap('boolean') = 'boolean_T';

    rosCppParamMap = containers.Map();
    rosCppParamMap('uint8[]') = 'std::vector<uint8_t>';
    rosCppParamMap('int64[]') = 'std::vector<int64_t>';
    rosCppParamMap('double[]') = 'std::vector<double>';
    rosCppParamMap('boolean[]') = 'std::vector<bool>';
    rosCppParamMap('string') = 'std::string';
    rosCppParamMap('int64') = 'int64_t';
    rosCppParamMap('double') = 'double';
    rosCppParamMap('boolean') = 'bool';
    getParamBlks = containers.Map();

    for k = 1:numel(paramBlockList)
        block = paramBlockList{k};
        prmMapKey = strrep(block, newline, ' ');
        s = struct('ParamType','','IsArray',false,'CppParamType','',...
            'ROSCppParamType','','Label','','Comment','');
        parameterType = get_param(block,'ParameterType');
        s.ParamType = parameterType;
        s.Label = get_param(block,'BlockId');
        s.Comment = sprintf('For Block %s', block);
        % Convert from Simulink to C++ type
        s.CppParamType = cppParamMap(s.ParamType);
        % Convert from Simulink to ROS C++ type
        % Decide if this type corresponds to an array or a scalar
        % parameter.
        s.IsArray = contains(parameterType,'[]');
        s.ROSCppParamType = rosCppParamMap(s.ParamType);
        getParamBlks(prmMapKey) = s;
    end
end

function outVal= loc_convertParameterToLogical(val)
    if ischar(val)
        outVal = logical(str2double(val));
    else
        outVal = logical(val);
    end
end
% LocalWords:  Extmode RTWCPP chrono
