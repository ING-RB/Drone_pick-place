classdef ROSUtil
    %This class is for internal use only. It may be removed in the future.

    %ROSUTIL - Utility functions for working with MATLAB ROS/ROS2 messages

    %   Copyright 2014-2024 The MathWorks, Inc.

    methods (Static)
        function out = isROSClass(classname)
            out = strncmp(classname, 'ros.', 13);
        end


        function out = isROSMsgObj(rosobj)
            out = isa(rosobj, 'ros.Message');
        end

        function out = isROSTimeEntityObj(rosobj)
            out = isa(rosobj, 'ros.msg.internal.TimeEntity');
        end

        function removeBlkPairingRegistration(block)
            %removeBlkPairingRegistration Removes block from registration list
            %   block is the current block full path name given by "gcb"

            if ~strcmp(bdroot(block),'ros2lib')
                pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
                currBlkH = getSimulinkBlockHandle(block);
                pairBlkMgr.removePairedBlock(currBlkH);
            end
        end

        function ret = getPairedBlockMaskType(block)
            %getPairedBlockMaskType Returns paired block mask type
            %   block is the current block full path name given by "gcb"

            currentBlkMask = get_param(block, 'MaskType');
            srcBlks = {ros.slros2.internal.block.ReceiveRequestBlockMask.MaskType; ...    % Receive Service Request
                ros.slros2.internal.block.SendResponseBlockMask.MaskType; ...      % Send Service Response
                ros.slros2.internal.block.SendActionGoalBlockMask.MaskType; ...    % Send Action Goal
                ros.slros2.internal.block.MonitorActionGoalBlockMask.MaskType ...  % Monitor Action Goal
                };
            targetBlks = {srcBlks{2}; srcBlks{1}; ...
                srcBlks{4}; srcBlks{3} ...
                };
            d = dictionary(srcBlks,targetBlks);
            retCell = d({currentBlkMask});
            ret = retCell{1};
        end

        function addNewPairingBlock(currentBlk, pairedBlk)
            %addNewPairingBlock Update block hyperlink and add to pairing manager
            %   currentBlk and pairedBlk is the full path name of two paring
            %   blocks

            currBlkH = getSimulinkBlockHandle(currentBlk);
            pairedBlkH = getSimulinkBlockHandle(pairedBlk);

            % Set hyperlink for currentBlk
            currBlkMaskObj = Simulink.Mask.get(currBlkH);
            currBlkLnk = currBlkMaskObj.getDialogControl('PairedBlkLink');
            currBlkLnk.Prompt = pairedBlk;

            % Set hyperlink for pairedBlk
            pairedBlkMaskObj = Simulink.Mask.get(pairedBlkH);
            pairedBlkLnk = pairedBlkMaskObj.getDialogControl('PairedBlkLink');
            pairedBlkLnk.Prompt = currentBlk;

            % Add blocks into pairBlkMgr
            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            pairBlkMgr.addPairedBlock(currBlkH, pairedBlkH);
        end

        function [foundPairedBlk, blkH] = getMatchingBlock(block, paramName)
            %getMatchingBlock Search for paired block

            foundPairedBlk = false; blkH = [];
            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            pairedBlk = pairBlkMgr.getPairedBlock(getSimulinkBlockHandle(block));
            if pairedBlk>0
                foundPairedBlk = true;
                blkH = pairedBlk;
                return;
            end

            % It is possible that PairedBlockManager got cleared. This
            % ensures blocks can still maintain linking by reconnecting
            % when PairedBlockManager is cleared.
            if ~pairBlkMgr.isBlockAdded(getSimulinkBlockHandle(block))
                % Find all matched paired blocks in model
                targetBlkMask = pairBlkMgr.getPairedBlockMaskType(block);
                listOfTargetBlks = find_system(bdroot(block),'LookUnderMasks','All', ...
                    'FindAll','on','Mask','on',...
                    'MaskType',targetBlkMask);
                for i=1:numel(listOfTargetBlks)
                    % Only add a link if target block matches the
                    % following condition:
                    %   1. property name has the same value as current
                    %   block
                    %   2. block haven't been paired
                    currBlkVal = get_param(block, paramName);
                    pairBlkVal = get_param(listOfTargetBlks(i),paramName);
                    if (~pairBlkMgr.isBlockAdded(listOfTargetBlks(i)) && ...
                            strcmp(currBlkVal, pairBlkVal))
                        ros.slros.internal.ROSUtil.addNewPairingBlock(...
                            block, ...
                            getfullname(listOfTargetBlks(i)));
                        foundPairedBlk = true;
                        blkH = listOfTargetBlks(i);
                    end
                end
            end
        end

        function copyBlkCallback(block, paramName, defaultPrompt)
            %copyBlkCallback Callback for copying block
            %   block is the copied block full path name given by "gcb"
            %   This function will be triggered after copying an existing
            %   block. The following actions will be taken step by step:
            %       1. Identify if it contains any hyperlink text
            %       2. If older block paired with other block, remove that on
            %          the new block
            %       3. Find from current model to pair with block of the same
            %          service name if there's any
            %       4. Update hyperlink for both, and add to PairedBlockManager
            %   Note that step 2,3,4 will not happen if there is no hyperlink
            %   in old block

            % Identify hyperlink on block
            maskObj = Simulink.Mask.get(block);
            pairedLink = maskObj.getDialogControl('PairedBlkLink');
            % Find all matched paired blocks in model
            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            targetBlkMask = pairBlkMgr.getPairedBlockMaskType(block);
            listOfTargetBlks = find_system(bdroot(block),'LookUnderMasks','All', ...
                'FindAll','on','Mask','on',...
                'MaskType',targetBlkMask);
            foundPairedBlock = false;
            for i=1:numel(listOfTargetBlks)
                % Only add a link if target block matches the following
                % condition:
                %   1. Haven't paired with other blocks
                %   2. property name has the same value as current
                %   block
                currBlkVal = get_param(block,paramName);
                pairBlkVal = get_param(listOfTargetBlks(i),paramName);
                if (~pairBlkMgr.isBlockAdded(listOfTargetBlks(i)) && ...
                        strcmp(currBlkVal,pairBlkVal))
                    % Update hyperlink and add new blocks to
                    % PairedBlockManager dictionary
                    ros.slros.internal.ROSUtil.addNewPairingBlock(...
                        block, ...
                        getfullname(listOfTargetBlks(i)));
                    foundPairedBlock = true;
                    break;
                end
            end
            if ~foundPairedBlock
                % Reset hyperlink to default
                pairedLink.Prompt = defaultPrompt;
            end
        end

        function addServerResponseBlockPair(~, newBlkName, currBlk)
            %addServerResponseBlockPair Bring paired blocks from library to model
            %   MODEL is the model name,
            %   NEWBLKNAME is the name of the block that we want to add to the model
            %   CURRBLK is the block name of current block

            maskObj = Simulink.Mask.get(currBlk);
            pairedBlkLnk = maskObj.getDialogControl('PairedBlkLink');

            currentBlkPath = currBlk(1:find(currBlk == '/', 1, 'last'));

            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            currBlkH = getSimulinkBlockHandle(currBlk);

            if ~pairBlkMgr.isBlockAdded(currBlkH)
                % Paired block not available, create new paired block!
                newBlkH = add_block(newBlkName,[currentBlkPath newBlkName(strfind(newBlkName,'/')+1:end)],'MakeNameUnique','on');
                % Add blocks into pairBlkMgr immediately after creation
                pairBlkMgr.addPairedBlock(currBlkH,newBlkH);

                % Set service name, type, blockid for the new block
                set_param(newBlkH, 'service', get_param(currBlk, 'service'));
                set_param(newBlkH, 'serviceType', get_param(currBlk, 'serviceType'));
                set_param(newBlkH, 'BlockId', get_param(currBlk, 'BlockId'));
                % Set new block hyperlink
                newBlkMaskObj = Simulink.Mask.get(newBlkH);
                newBlkLnk = newBlkMaskObj.getDialogControl('PairedBlkLink');
                newBlkLnk.Prompt = currBlk;

                % Update paired block name for current block
                pairedBlkLnk.Prompt = getfullname(newBlkH);

                % Since Sender block shares the same BlockId with Receiver
                % block, update BlockId for Sender block after creating a
                % paired block
                if strcmp(get_param(currBlk,'MaskType'),ros.slros2.internal.block.SendResponseBlockMask.MaskType)
                    set_param(currBlk, 'BlockId', get_param(newBlkH, 'BlockId'));
                end
            else
                % Paired block exists, highlight the paired block
                hilite_system(pairedBlkLnk.Prompt);
            end

        end

        function [foundPairedBlk, blkH, targetBlkName] = getMatchingServerBlkByService(block, paramName)
            %getMatchingServerBlkByService Search for paired service server block
            %   foundPairedBlk is a Boolean indicate whether a paired block is
            %   available.
            %   blkH is the block handle of the paired block. This will be
            %   empty if no paired block is available.
            %   targetBlkName is the name of the target block in library. This
            %   can be used to create new block.

            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            targetBlkMask = pairBlkMgr.getPairedBlockMaskType(block);
            targetBlkName = extractAfter(targetBlkMask, 'ROS2 ');

            [foundPairedBlk, blkH] = ros.slros.internal.ROSUtil.getMatchingBlock(block, paramName);
        end

        function checkSvcServerBlkAvailability(block)
            %checkSvcServerBlkAvailability Check if a pair of service server block is available
            %   BLOCK is the block which calls this function

            [foundPairedBlk, ~, targetBlkName] = ros.slros.internal.ROSUtil.getMatchingServerBlkByService(block, 'service');
            % If no paired block can be found, throw error message in
            % diagnostic viewer
            if ~foundPairedBlk
                % Paired block might've been removed, set paired prompt
                maskObj = Simulink.Mask.get(block);
                pairedBlkLnk = maskObj.getDialogControl('PairedBlkLink');
                pairedBlkLnk.Prompt = 'ros:slros2:blockmask:NoSvcPairedBlkPrompt';
                % Provide "Fixit" in diagnostic viewer
                mdlHandle = get_param(bdroot(block),'Handle');
                diag = MSLException(mdlHandle, message('ros:slros2:blockmask:NoSvcPairedBlkError', targetBlkName, ['ros2lib/' targetBlkName], block));
                throw(diag);
            end
        end

        function addMonitorAndSendActionGoalBlockPair(~, newBlkName, currBlk)
            %addMonitorAndSendActionGoalBlockPair Bring paired blocks from library to model
            %   MODEL is the model name,
            %   NEWBLKNAME is the name of the block that we want to add to the model
            %   CURRBLK is the block name of current block

            maskObj = Simulink.Mask.get(currBlk);
            pairedBlkLnk = maskObj.getDialogControl('PairedBlkLink');

            currentBlkPath = currBlk(1:find(currBlk == '/', 1, 'last'));

            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            currBlkH = getSimulinkBlockHandle(currBlk);

            if ~pairBlkMgr.isBlockAdded(currBlkH)
                % Paired block not available, create new paired block!
                newBlkH = add_block(newBlkName,[currentBlkPath newBlkName(strfind(newBlkName,'/')+1:end)],'MakeNameUnique','on');
                % Add blocks into pairBlkMgr immediately after creation
                pairBlkMgr.addPairedBlock(currBlkH,newBlkH);

                % Set action name, type, blockid for the new block
                set_param(newBlkH, 'action', get_param(currBlk, 'action'));
                set_param(newBlkH, 'actionType', get_param(currBlk, 'actionType'));
                set_param(newBlkH, 'BlockId', get_param(currBlk, 'BlockId'));
                % Set new block hyperlink
                newBlkMaskObj = Simulink.Mask.get(newBlkH);
                newBlkLnk = newBlkMaskObj.getDialogControl('PairedBlkLink');
                newBlkLnk.Prompt = currBlk;

                % Update paired block name
                pairedBlkLnk.Prompt = getfullname(newBlkH);

                % Since Monitor block shares the same BlockId with Sender
                % block, update BlockId for Monitor block after creating a
                % paired block
                if strcmp(get_param(currBlk,'MaskType'),ros.slros2.internal.block.MonitorActionGoalBlockMask.MaskType)
                    set_param(currBlk, 'BlockId', get_param(newBlkH, 'BlockId'));
                end
            else
                % Paired block exists, highlight the paired block
                hilite_system(pairedBlkLnk.Prompt);
            end
        end

        function [foundPairedBlk, blkH, targetBlkName] = getMatchingClientBlkByAction(block, paramName)
            %getMatchingClientBlkByAction Search for paired send goal or monitor goal block
            %   foundPairBlk is a boolean indicate whether a paired block is
            %   available.
            %   pairedBlkHandles is the block handle of the paired block. This will be
            %   empty if no paired block is available.
            %   targetBlkName is the name of the target block in library. This
            %   can be used to create new block.

            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            targetBlkMask = pairBlkMgr.getPairedBlockMaskType(block);
            targetBlkName = extractAfter(targetBlkMask, 'ROS 2 ');

            [foundPairedBlk, blkH] = ros.slros.internal.ROSUtil.getMatchingBlock(block, paramName);
        end

        function checkSendGoalBlkPairAvailability(block)
            %checkSendGoalBlkPairAvailability Check if a pair of send action goal
            % and monitor action block is available
            %   BLOCK is the block which calls this function

            [foundPairedBlk, ~, targetBlkName] = ros.slros.internal.ROSUtil.getMatchingClientBlkByAction(block,'action');
            % If no paired block can be found, throw error message in
            % diagnostic viewer
            if ~foundPairedBlk
                % Paired block might've been removed, set paired prompt
                maskObj = Simulink.Mask.get(block);
                pairedBlkLnk = maskObj.getDialogControl('PairedBlkLink');
                pairedBlkLnk.Prompt = 'ros:slros2:blockmask:NoSendGoalPairedBlkPrompt';
                % Provide "Fixit" in diagnostic viewer
                mdlHandle = get_param(bdroot(block),'Handle');
                diag = MSLException(mdlHandle, message('ros:slros2:blockmask:NoSendGoalPairedBlkError', ['ros2lib/' targetBlkName], block));
                throw(diag);
            end
        end

        function checkSendGoalBlkAvailability(block)
            %checkSendGoalBlkAvailability Check if atleast one send action goal
            % block is available. This is required to cancel a goal
            % irrespective of action name or action type
            %   BLOCK is the block which calls this function

            listOfTargetBlks = find_system(bdroot(block),'LookUnderMasks','All', ...
                'FindAll','on','Mask','on','MaskType', ...
                ros.slros2.internal.block.SendActionGoalBlockMask.MaskType);

            % If no send action goal block can be found, throw error message in
            % diagnostic viewer
            if isempty(listOfTargetBlks)
                % Provide "Fixit" in diagnostic viewer
                mdlHandle = get_param(bdroot(block),'Handle');
                diag = MSLException(mdlHandle, message('ros:slros2:blockmask:NoSendGoalBlkError'));
                throw(diag);
            end
        end

        function bringSendActionGoalBlockIntoModel(model)
            newBlkName = 'ros2lib/Send Action Goal';
            slashIndex = strfind(newBlkName,'/');
            add_block(newBlkName,[model newBlkName(slashIndex:end)],'MakeNameUnique','on');
        end

        function isFixed = isFixedSizeArray(msgType, rosPropName, rosver)
            %isFixedSizeArray Determine if a property in a message is a fixed-size array
            %   MSGTYPE is the ROS message type, for example
            %   'std_msgs/String'
            %   ROSPROPNAME is the property name as returned by rosmsg show

            % Use persistent variable for parsed message definitions, since
            % the process is expensive.
            persistent parsedArrayMap
            if isempty(parsedArrayMap)
                parsedArrayMap = containers.Map;
            end

            isFixed = false;

            if strcmp(msgType, ros.slros.internal.bus.Util.TimeMessageType) || ...
                    strcmp(msgType, ros.slros.internal.bus.Util.DurationMessageType) || ...
                    strcmp(msgType, 'ros/Time') || ...
                    strcmp(msgType, 'ros/Duration')
                return;
            end

            if isKey(parsedArrayMap, msgType)
                % This is fast. Simply use the already parsed list of
                % arrays.
                parsedArrays = parsedArrayMap(msgType);
            else
                % This is more expensive. Have to parse the message
                % definition.

                % Get message definition
                getMsgDefnMap = containers.Map({'ros','ros2'},...
                    {@(a)rosmsg('show',a),@(a)ros2('msg','show',a)});
                if exist('rosver','var')
                    % use custom function
                    verStr = validatestring(rosver, {'ros','ros2'});
                else
                    verStr = 'ros';
                end
                getMsgDefnFcn = getMsgDefnMap(verStr);
                msgDef = split(string(getMsgDefnFcn(msgType)),newline);
                parsedArrays = msgDef(~ismissing(regexp(msgDef,'^[\w /]+\[\d+\]\s+.*','match','once')));
                parsedArrayMap([verStr,':',msgType]) = parsedArrays;
            end

            if isempty(parsedArrays)
                % This message type doesn't have any arrays, so return.
                return;
            end

            % Determine if property is a fixed-size array
            propIdx = strcmp(strip(parsedArrays.extractAfter(']')),rosPropName);
            if any(propIdx)
                % Property name found. Extract the associated array size
                % If size is -1 it's variable-sized. If size is another
                % number, it's fixed-size.
                prop = parsedArrays(propIdx);
                arraySize = str2double(extractBetween(prop,'[',']'));
                % Found a fixed-size array property if arraySize is a
                % positive scalar.
                isFixed = ~isnan(arraySize);
            end
        end

        function obj = getStdStringObj()
            obj = ros.msggen.std_msgs.String;
        end

        function out = isStdEmptyMsgType(msgType)
            isEmptyMsg = strcmpi(msgType, 'std_msgs/Empty');
            isEmptySrvMsg = any( strcmpi(msgType, {['std_srvs/Empty', 'Request'], ['std_srvs/Empty', 'Response']}) );
            out = any([isEmptyMsg, isEmptySrvMsg]);
        end


        % Note that following won't work (messages
        % are derived from ros.Message so ISA works
        % but classname comparison will not)
        %
        % function out = isROSMsgClass(classname)
        %      out = strcmp(classname, 'ros.Message');
        %  end
        %
        % function out = isROSTimeEntityClass(classname)
        %    out = strcmp(classname, 'ros.msg.TimeEntity');
        % end

        function out = isROSObj(rosobj)
            out = isa(rosobj, 'ros.Message') || isa(rosobj, 'ros.msg.internal.TimeEntity');
        end


        function entity = getTimeEntityType(classname)
            switch classname
                case 'ros.msg.Time'
                    entity = 'Time';
                case 'ros.msg.Duration'
                    entity = 'Duration';
                otherwise
                    entity = '';
            end % switch
        end % function


        function [propList, rosPropList] = getPropertyLists(rosmsg)
            mc = metaclass(rosmsg);
            % these lists do not include constants
            idx1 = strcmp({mc.PropertyList.Name}, 'PropertyList');
            idx2 = strcmp({mc.PropertyList.Name}, 'ROSPropertyList');
            propList = mc.PropertyList(idx1).DefaultValue;
            rosPropList = mc.PropertyList(idx2).DefaultValue;
        end


        function nonServiceTypes = getMessageTypesWithoutServices()
            % getMessageTypesWithoutServices returns the list of available
            % ROS message types, excluding service-related types.

            % Rationale:
            % rostype.getMessageList includes types like the following,
            % which are only used by services.
            %   1. gazebo_msgs/JointRequest
            %   2. gazebo_msgs/JointRequestRequest
            %   3. gazebo_msgs/JointRequestResponse
            %
            % (1) is actually an alias for (2), i.e.,
            % rosmessage('gazebo_msgs/JointRequest') returns a message of
            % type gazebo_msgs/JointRequestRequest. In addition, some of
            % the service response messages are empty. Both of these
            % characteristics cause issues in Simulink ROS, so it is
            % preferable to filter out the service types.

            basicServiceTypes = rostype.getServiceList;
            allServiceTypes = [...
                basicServiceTypes;
                strcat(basicServiceTypes, 'Request');
                strcat(basicServiceTypes, 'Response')];

            % Note: SETDIFF output is automatically sorted
            nonServiceTypes = setdiff(rostype.getMessageList, allServiceTypes);
        end

        % creates class object based on version
        % If ROS the obj will be of ros.slroscpp.internal.ROSLoggerHelper
        % If ROS2 the obj will be of ros.slros2.internal.ROSLoggerHelper
        function rosUtilLogger = getROSUtilLogger(modelName)
            rosUtilLogger = ros.slros.internal.ROSLogger(modelName);
        end

        % ROS Logging Settings - ROSLoggingTable, ROSLoggingInfo,
        % ROSLoggingReload
        function ret = getROSLoggingSettings(modelName)
            import ros.slros.internal.dlg.ROSLoggingSpecifier
            w = get_param(modelName, 'ModelWorkspace');
            ret.ROSLoggingTable = getDataFromWorkspace(w, ROSLoggingSpecifier.MessageTableVarName);
            ret.ROSLoggingInfo = getDataFromWorkspace(w, ROSLoggingSpecifier.LoggingInfoVarName);
            ret.ROSLoggingReload = getDataFromWorkspace(w, ROSLoggingSpecifier.ReloadInfoVarName);
            function outval = getDataFromWorkspace(wkspc, varName)
                if hasVariable(wkspc, varName)
                    outval = getVariable(wkspc, varName);
                else
                    outval = [];
                end
            end
        end

        function [t, blkFullNames] = generateTableFromTop(modelName, refBlkPrefix)
            %generateTableFromTop Generate signal info table from top level model
            % This function is used to generate table for top level model given
            % model name as input. The input model is allowed to contain
            % referenced models and nested referenced models.
            %
            % Example:
            %   [t, blkFullNames] =
            %   ros.slros.internal.ROSUtil.generateTableFromTop('mymodel');

            if nargin<2
                refBlkPrefix = '';
            end

            if isempty(Simulink.findBlocks(modelName))
                % Return empty immediately when there is no block in model
                % (g2901417)
                t = []; blkFullNames = [];
                return;
            end

            % Update model to collect ROS/ROS 2 bus signal information
            set_param(modelName, 'SimulationCommand', 'Update');

            % Add values into cell array
            % Top level model, i.e. current level model
            [t, blkFullNames] = ros.slros.internal.ROSUtil.generateTableForSingleModel(modelName, refBlkPrefix);

            % Get a full list of referenced model blocks
            [~, refblks] = find_mdlrefs(modelName, ...
                'KeepModelsLoaded',true, ...
                'AllLevels',false, ...
                'MatchFilter', @Simulink.match.allVariants);

            % Previous prefix to be attached
            if strcmp(refBlkPrefix, '')
                previousPrefix = '';
            else
                previousPrefix = [refBlkPrefix '/'];
            end

            % Referenced models
            if ~isempty(refblks)
                for i=1:numel(refblks)
                    refMdlName = get_param(refblks{i,1},'ModelName');
                    refBlkNameCell = split(refblks{i,1},'/');
                    refBlkName = refBlkNameCell{numel(refBlkNameCell),1};
                    [tTemp, blkFullNamesTemp] = ros.slros.internal.ROSUtil.generateTableFromTop(refMdlName, [previousPrefix refBlkName]);
                    t = [t; tTemp]; %#ok<AGROW>
                    blkFullNames = [blkFullNames; blkFullNamesTemp]; %#ok<AGROW>
                end
            end
        end

        function [t, blkFullNames] = generateTableForSingleModel(modelName, refBlkName)
            %generateTableForSingleModel Generate signal info table for single model
            % This function is used to generate table for one single model
            % given model name as input. This function will exclude signals
            % contained in referenced models inside the input model. Use
            % ros.slros.internal.ROSUtil.generateTableFromTop if there are
            % referenced models.


            if strcmp(refBlkName, '')
                addNamePrefix = false;
            else
                addNamePrefix = true;
            end

            % Get all signals in the model
            % One bus is also considered as one signal.
            mdlSignals = find_system(modelName,'FindAll','on', ...
                'FollowLinks','off','type','line', ...
                'SegmentType','trunk');

            % Get all source block names to narrow down interested signals to only
            % ROS signals.
            numOfSignals = numel(mdlSignals);
            srcBlkHandles = zeros(numOfSignals,1);
            isROSMsg = zeros(numOfSignals,1,'logical');
            portNums = zeros(numOfSignals,1);

            rosUtilLogger = ros.slros.internal.ROSUtil.getROSUtilLogger(modelName);
            for i = 1:numOfSignals
                [isROSMsg(i,1),portNums(i,1),srcBlkHandles(i,1)] = evaluateSignal(mdlSignals(i,1), rosUtilLogger.getAllSrcBlk);
            end
            % allROSSignals contains signal handles for all ROS or ROS2 buses
            allROSSrcBlkHandles = srcBlkHandles(isROSMsg);
            allROSSignals = mdlSignals(isROSMsg);
            allROSPortNums = portNums(isROSMsg);

            % Generate data logging information, source name, topic name, and
            % message type for all valid ROS/ROS2 signals
            numOfROSSignals = numel(allROSSignals);
            isLoggingEnabled = cell(numOfROSSignals,1);
            sourceNames = cell(numOfROSSignals,1);
            topicNames = cell(numOfROSSignals,1);
            msgTypes = cell(numOfROSSignals,1);
            blkFullNames = cell(numOfROSSignals,1);
            for i = 1:numOfROSSignals
                % Collect data logging information for all ROS signals
                portHandle = get_param(allROSSrcBlkHandles(i),'PortHandles');
                isLoggingEnabled{i,1} = strcmp(get_param(portHandle.Outport(allROSPortNums(i)),'DataLogging'),'on');
                % Get the name of source block and attach the port number
                blkFullName = getfullname(allROSSrcBlkHandles(i));
                blkFullPath = blkFullName(numel(modelName)+2:end);
                sourceNames{i,1} = [blkFullPath sprintf(':%d',allROSPortNums(i))];
                blkFullNames{i,1} = blkFullName;

                % Generate topic names
                % There are two generation rules:
                %   1. If such signals is connected to a "ROS Subscribe","ROS2 Subscribe", a "ROS
                %   Publish", "ROS2 Publish or a "Read Data" block, the topic name will be the
                %   topic from block with lowercase block path. For example:
                %   my_topic_blank_message
                %   2. Otherwise, the topic name will be only the lowercase block
                %   path.
                if any(contains(get_param(allROSSrcBlkHandles(i),'MaskType'),{rosUtilLogger.getAllSrcBlk{1:3}})) %#ok<CCAT1>
                    % For ROS Subscribe, ROS Publish, ROS 2 Publish, ROS 2 Subscribe and Read Data blocks, grab topic directly
                    % from block
                    blkTopicName = get_param(allROSSrcBlkHandles(i),'topic');
                    topicNames{i,1} = [blkTopicName '_' blkFullPath];
                else
                    % Rule #2
                    topicNames{i,1} = blkFullPath;
                end

                topicNames{i,1} = formalizeTopicName(topicNames{i,1});
                ros.internal.Namespace.canonicalizeName(topicNames{i,1});
                % Generate message type
                msgTypes{i,1} = getMessageTypeFromSignalHandle(allROSSignals(i));
            end

            t = [isLoggingEnabled sourceNames topicNames msgTypes];

            % Special block handling
            for i = 1:numOfSignals
                [msgLogged,msgSrcName,msgTopic,msgType,fullPathToBlk] = directReturnFromSpecialBlk(mdlSignals(i,1), rosUtilLogger.getAllSrcBlk, modelName);
                if ~isempty(msgLogged)
                    t(end+1,:) = {msgLogged, msgSrcName, msgTopic, msgType}; %#ok<AGROW>
                    blkFullNames{end+1,:} = fullPathToBlk; %#ok<AGROW>
                    allROSSignals(end+1) = mdlSignals(i,1); %#ok<AGROW>
                end
            end
            % Find all ROS/ROS2 Publish block and check whether we need to add
            % any prefix to existed signals
            allPubBlks = rosUtilLogger.getPublishBlocks(modelName);
            if ~isempty(allPubBlks)
                for i=1:numel(allPubBlks)
                    portH = get_param(allPubBlks(i),'PortHandles');
                    targetLine = get_param(portH.Inport,'line');
                    for signalIndex = 1:numel(allROSSignals)
                        if isIdenticalSignal(targetLine, allROSSignals(signalIndex))
                            % Check and determine whether we need to add
                            % prefix
                            currentTopicName = t{signalIndex,3};
                            pubBlkTopic = regexprep(get_param(allPubBlks(i),'topic'),'^/','');
                            
                            % g3411425 Handle edge case where
                            % numel(pubBlkTopic) > numel(currentTopicName).
                            % Will concatenate the final topic name if the edge case is hit.
                            if ~(numel(pubBlkTopic) <= numel(currentTopicName) && strcmp(pubBlkTopic, currentTopicName(1:numel(pubBlkTopic))))
                                t{signalIndex,3} = [pubBlkTopic '_' currentTopicName];
                            end
                        end
                    end
                end
            end

            % Add prefix to block path name and postfix to topic name if it
            % is under a referenced model
            if addNamePrefix
                for i=1:size(t,1)
                    t{i,2} = [refBlkName '/' t{i,2}];
                    % Replace "/" by "_" in refBlkName
                    topicPostfix = lower(strrep(refBlkName,'/','_'));
                    t{i,3} = [t{i,3} '_' topicPostfix];
                end
            end

            function processedTopicName = formalizeTopicName(rawTopicName)
                %formalizeTopicName Return a topic name without '/',
                %whitespace, and newline (g2897706)

                % Replace '/', whitespace, dash, and newline in topic name
                % by underscore '_'.
                processedTopicName = lower(replace(rawTopicName, {'/',' ','-',newline}, {'_','_','_','_'}));
                % Replace potential double underscore by one underscore,
                % replace front underscores.
                processedTopicName = regexprep(replace(processedTopicName,{'__'},{'_'}),'^_+','');

                ros.internal.Namespace.canonicalizeName(processedTopicName);
            end

            %% helper functions
            function isSame = isIdenticalSignal(targetLine, existedLine)
                %isIdenticalSignal Return whether two line handles represent the same signal
                % Return true if the value are the same. Otherwise, need to
                % check whether the source block handle are the same since any
                % triage is possible to create different line handle for the
                % same signal in Simulink.

                isSame = false;
                if isequal(targetLine, existedLine)
                    isSame = true;
                    return;
                end
                targetSrcBlkH = get_param(targetLine, 'SrcBlockHandle');
                existedSrcBlkH = get_param(existedLine, 'SrcBlockHandle');
                if isequal(targetSrcBlkH,existedSrcBlkH)
                    isSame = true;
                end
            end

            function [msgLogged,msgSrcName,msgTopic,msgType,fullPathToBlk] = directReturnFromSpecialBlk(currentSignal, allROSSrcBlk, modelName)
                srcBlkH = get_param(currentSignal,'SrcBlockHandle');
                srcBlkMaskType = get_param(srcBlkH,'MaskType');
                msgLogged = [];
                msgSrcName = [];
                msgTopic = [];
                msgType = [];
                fullPathToBlk = [];

                % Special block handling
                % If the signal is not coming out from a ROS block, it can only
                % come out from "Bus Assignment", "Inport", or "MATLAB Function"
                % block.
                if isempty(srcBlkMaskType)
                    if strcmp(get_param(srcBlkH,'BlockType'), 'BusAssignment')
                        % Bus Assignment block
                        srcBlkPortHandle = get_param(srcBlkH,'PortHandles');
                        % Message port is the first input port for BusAssignment
                        inputToSrc = srcBlkPortHandle.Inport(1);
                        inputSignal = get_param(inputToSrc,'Line');
                        secSrcBlkH = get_param(inputSignal,'SrcBlockHandle');
                        if any(contains(get_param(secSrcBlkH,'MaskType'), allROSSrcBlk))
                            msgLogged = strcmp(get_param(srcBlkPortHandle.Outport(1),'DataLogging'),'on');
                            fullPathToBlk = getfullname(srcBlkH);
                            blkPath = strrep(fullPathToBlk(numel(modelName)+2:end),newline,' ');
                            msgSrcName = [blkPath ':1'];
                            msgTopic = formalizeTopicName(blkPath);
                            msgType = getMessageTypeFromSignalHandle(currentSignal);
                        end
                    elseif strcmp(get_param(srcBlkH,'BlockType'), 'Inport')
                        % Inport block
                        srcBlkPortHandle = get_param(srcBlkH,'PortHandles');
                        fullPathToBlk = getfullname(srcBlkH);
                        blkName = get_param(srcBlkH,'Name');
                        try
                            % Inport block in subsystem
                            subSystemBlk = fullPathToBlk(1:end-numel(blkName)-1);
                            subSysPortHandle = get_param(subSystemBlk, 'PortHandles');
                            subSysInport = subSysPortHandle.Inport;
                            inputSigToSubSys = get_param(subSysInport,'Line');
                            upperLevelBlkH = get_param(inputSigToSubSys,'SrcBlockHandle');
                            upperLevelBlkMaskType = get_param(upperLevelBlkH,'MaskType');
                            if any(contains(upperLevelBlkMaskType,allROSSrcBlk))
                                msgLogged = strcmp(get_param(srcBlkPortHandle.Outport(1),'DataLogging'),'on');
                                blkPath = fullPathToBlk(numel(modelName)+2:end);
                                msgSrcName = [blkPath ':1'];
                                msgTopic = formalizeTopicName(blkPath);
                                msgType = getMessageTypeFromSignalHandle(inputSigToSubSys);
                            end
                        catch
                            % Inport block in top level, OutDataTypeStr has
                            % to start with 'Bus: SL_Bus_<modelName>' or 'BUS: SL_Bus_<msgType>,
                            % otherwise, we cannot guarantee such output is
                            % a ROS/ROS2 signal.
                            outDataTypeStr = get_param(srcBlkH,'OutDataTypeStr');
                            if contains(outDataTypeStr,'Bus: SL_Bus_*')
                                msgLogged = strcmp(get_param(srcBlkPortHandle.Outport(1),'DataLogging'),'on');
                                blkPath = fullPathToBlk(numel(modelName)+2:end);
                                msgSrcName = [blkPath ':1'];
                                msgTopic = formalizeTopicName(blkPath);

                                % Get message type from presaved data
                                % dictionary - robotlib.sldd
                                robotlibDD = Simulink.data.dictionary.open('robotlib.sldd');
                                dDataSectObj = getSection(robotlibDD,'Design Data');
                                replacedBusName = strrep(outDataTypeStr,modelName,'robotlib');
                                presavedBusName = replacedBusName(6:end);
                                presavedEntry = getEntry(dDataSectObj,presavedBusName);
                                presavedBusObj = getValue(presavedEntry);
                                busDescription = presavedBusObj.Description;
                                msgType = busDescription(9:end);
                                close(robotlibDD);
                            end
                        end
                    else
                        try
                            sfBlkType = get_param(srcBlkH,'SFBlockType');
                        catch
                            sfBlkType = '';
                        end
                        if strcmp(sfBlkType, 'MATLAB Function')
                            % MATLAB Function block
                            srcBlkPortHandle = get_param(srcBlkH,'PortHandles');
                            % find the outport associated with current signal
                            targetPortHandle = 0;
                            targetPortIndex = 0;
                            for outportIndex = 1:numel(srcBlkPortHandle.Outport)
                                if isequal(get_param(srcBlkPortHandle.Outport(outportIndex),'Line'),currentSignal)
                                    targetPortHandle = srcBlkPortHandle.Outport(outportIndex);
                                    targetPortIndex = outportIndex;
                                    break;
                                end
                            end
                            if targetPortHandle > 0
                                targetSignalHierarchy = get_param(targetPortHandle, 'SignalHierarchy');
                                if isfield(targetSignalHierarchy,'BusObject') && contains(targetSignalHierarchy.BusObject,'SL_Bus')
                                    msgLogged = strcmp(get_param(targetPortHandle,'DataLogging'),'on');
                                    fullPathToBlk = getfullname(srcBlkH);
                                    blkPath = fullPathToBlk(numel(modelName)+2:end);
                                    msgSrcName = [blkPath ':' num2str(outportIndex)];
                                    msgTopic = formalizeTopicName(blkPath);
                                    % Message type name can be interpreted directly from
                                    % data type of output port of MATLAB Function blocks
                                    blockEMChart = find(get_param(modelName,"Object"),"-isa","Stateflow.EMChart","Name",get_param(srcBlkH,'Name'));
                                    rawBusType = blockEMChart.Outputs(targetPortIndex).CompiledType;
                                    % Get ROS/ROS2 message type from info map
                                    rosMsgTypes = ros.slroscpp.internal.bus.Util.getAllMessageInfoMapForModel(modelName);
                                    rosValues = rosMsgTypes.values;
                                    ros2MsgTypes = ros.slros2.internal.bus.Util.getAllMessageInfoMapForModel(modelName);
                                    ros2Values = ros2MsgTypes.values;
                                    for keyVal = 1:rosMsgTypes.length
                                        if strcmp(rosValues{1,keyVal}.BusName,rawBusType)
                                            msgType = rosValues{1,keyVal}.ROSMessageType;
                                            break;
                                        end
                                    end
                                    for keyVal = 1:ros2MsgTypes.length
                                        if strcmp(ros2Values{1,keyVal}.BusName,rawBusType)
                                            msgType = ros2Values{1,keyVal}.ROSMessageType;
                                            break;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            function msgTypeName = getMessageTypeFromSignalHandle(currentSignal)
                srcBlkH = get_param(currentSignal,'SrcBlockHandle');
                srcBlkMaskType = get_param(srcBlkH,'MaskType');

                if strcmp(srcBlkMaskType,"") && strcmp(get_param(srcBlkH,'BlockType'),'SubSystem')
                    % Subsystem
                    % Find outport block inside the subsystem that connects
                    % to the inport line - currentSignal
                    subSysPath = getfullname(srcBlkH);

                    portNumH = get_param(currentSignal,'SrcPortHandle');
                    portNum = get_param(portNumH, 'PortNumber');

                    % Find the specific outport block in the subsystem
                    outportBlk = find_system(subSysPath, 'SearchDepth',1,...
                        'BlockType','Outport','Port',num2str(portNum));

                    outportH = get_param(outportBlk{1},'Handle');
                    internalSignal = find_system(subSysPath,'FindAll','on',...
                        'Type','line','DstBlockHandle',outportH);
                    msgTypeName = getMessageTypeFromSignalHandle(internalSignal);

                    return;
                end

                if any(contains(srcBlkMaskType, {rosUtilLogger.getAllSrcBlk{[1,4]}})) %#ok<CCAT1>
                    msgTypeName = get_param(srcBlkH, 'messageType');
                elseif any(contains(srcBlkMaskType,{'ros.slros.internal.block.CurrentTime','ros.slros2.internal.block.CurrentTime'}))
                    msgTypeName = 'std_msgs/Time';
                elseif any(contains(srcBlkMaskType, rosUtilLogger.getAllSrcBlk{2}))
                    msgTypeName = get_param(srcBlkH, 'msgType');
                elseif any(contains(srcBlkMaskType, rosUtilLogger.getAllSrcBlk{7}))
                    msgTypeName = [get_param(srcBlkH, 'serviceType') 'Response'];
                elseif any(contains(srcBlkMaskType, rosUtilLogger.getAllSrcBlk{10}))
                    msgTypeName = 'geometry_msgs/TransformStamped';
                elseif any(contains(srcBlkMaskType, rosUtilLogger.getAllSrcBlk{11}))
                    msgTypeName = get_param(srcBlkH, 'EntityMsgType');
                elseif any(contains(srcBlkMaskType, rosUtilLogger.getAllSrcBlk{8}))
                    msgTypeName = 'sensor_msgs/PointCloud2';
                elseif any(contains(srcBlkMaskType, rosUtilLogger.getAllSrcBlk{9}))
                    msgTypeName = 'sensor_msgs/Image';
                else
                    % Header block cannot determine the message type, need to
                    % look into upper stream signals
                    srcBlkPortHandle = get_param(srcBlkH,'PortHandles');
                    % There's only one input port for Header block
                    inputToSrc = srcBlkPortHandle.Inport(1);
                    inputSignal = get_param(inputToSrc,'Line');
                    msgTypeName = getMessageTypeFromSignalHandle(inputSignal);
                end
            end

            function [isAROSMsg, portNum, srcBlkH] = evaluateSignal(currentSignal, allROSSrcBlk)
                %   evaluateSignal - Evaluate whether the input signal is either a ROS or ROS2 message
                %   This function will also return the port number and source
                %   block handle for later use.
                srcBlkH = get_param(currentSignal,'SrcBlockHandle');
                srcBlkMaskType = get_param(srcBlkH,'MaskType');
                srcPortH = get_param(currentSignal,"SrcPortHandle");
                portNum = get_param(srcPortH,'PortNumber');

                isAROSMsg = false;
                if any(contains(srcBlkMaskType,allROSSrcBlk))
                    % This is a signal coming out from valid ROS or ROS2 block
                    if any(contains(srcBlkMaskType,{allROSSrcBlk{[1,2]}})) %#ok<CCAT1>
                        % Subscriber or Read Data block, only second output port is honored
                        if portNum == 2
                            isAROSMsg = true;
                        end
                    elseif any(contains(srcBlkMaskType,allROSSrcBlk{6})) && (strcmp(get_param(srcBlkH,'OutputFormat'),'bus'))
                        % Current Time block, only valid when the output is a bus
                        isAROSMsg = true;
                    elseif any(contains(srcBlkMaskType,allROSSrcBlk{10})) && (strcmp(get_param(srcBlkH,'OutputFormat'),'bus'))
                        % Get Transform block, only valid when the output
                        % is a bus
                        if portNum==2
                            isAROSMsg = true;
                        end
                    elseif (portNum == 1) && ~any(contains(srcBlkMaskType,allROSSrcBlk{6}))
                        % All other blocks only contains one output port and
                        % they always return bus
                        isAROSMsg = true;
                    end
                end
            end
        end

        function logROSMessageToBagFile(modelName)
            %logROSMessageToBagFile Create a bagfile and store the data
            %messages logged during the latest run. The settings are
            %retrieved from model workspace
            arguments
                modelName
            end

            % Retrieve ROS Logger app settings from the model workspace.
            logInfo = ros.slros.internal.ROSUtil.getROSLoggingSettings(modelName);

            % Guard to check if logging is enabled.
            if ~logInfo.ROSLoggingInfo.GenBagFile || isempty(logInfo.ROSLoggingTable)
                return
            end

            % Abstract class to provide a unified interface for ROS and ROS2.
            rosUtilLogger = ros.slros.internal.ROSUtil.getROSUtilLogger(modelName);

            rosUtilLogger.reportStatus('Start');
            try

                % Get the handle to latest simulation from SDI.
                runIDs = Simulink.sdi.getAllRunIDs;
                
                % Return early if no simulation log data is present
                if isequal(numel(runIDs), 0)
                    return;
                end
                
                runID = runIDs(end);
                lastRun = Simulink.sdi.getRun(runID);

                % Export all the logged data to a temporary mat file. Setup a
                % onCleanup function to delete the temp mat file on exit.
                fileName =  [tempname '.mat'];
                export(lastRun, "to","file", "filename",fileName);
                deleteMat = onCleanup( @() delete(fileName)  );


                % Creates the Simulink.SimulationData.Dataset object.
                logsout = Simulink.SimulationData.DatasetRef(fileName, 'data');

                % Get the Simulation StartTime stored using a Singleton
                startTimeInSec = rosUtilLogger.getStartTime();

                % Create a bagfile based on stored settings. Sets up a cleanup
                % function to delete the object on function exit.
                [bagWriter, bagFolderName] = rosUtilLogger.getWriterObject( logInfo );
                bagWriterCleanup = onCleanup(@() delete(bagWriter));

                % Retrieve the list of signals to be logged in bagfile.
                blockList = logInfo.ROSLoggingTable(:,2);

                % Iterate over all the signals logged during simulation.
                numSignals = logsout.numElements;
                for idx=1:numSignals

                    % Gets the signal at index idx in
                    % matlab.io.datastore.SimulationDatastore representation.
                    % This representation makes sure to not load all the
                    % timeseries data in memory.
                    signal = getAsDatastore(logsout, idx);

                    % Get the signal Name.
                    signalName = ros.slros.internal.ROSUtil.getSignalName( signal );

                    if any(contains( signalName, blockList ))

                        % Retrieve the auxillary information regarding the
                        % signal stored by ROS Logger App
                        loggingTableRow = find(strcmp(blockList, signalName));
                        topicName = logInfo.ROSLoggingTable{loggingTableRow,3};
                        msgType = logInfo.ROSLoggingTable{loggingTableRow,4};

                        signalDatastore = getAsDatastore(logsout, idx).Values;


                        % Setup the field length info tables and create a
                        % DsManager object to store all the datastore variables
                        [fieldLenInfo, dVarField, dsMap] = ros.slros.internal.ROSUtil.setupTables( signalDatastore );

                        % Create a skeleton message based on fieldLenInfo
                        blankMessage = rosUtilLogger.getBlankMessage(msgType);
                        filledMessage = rosUtilLogger.fillUpMsgFields(blankMessage, fieldLenInfo);


                        % Generate the runtime function to copy data from MAT
                        % file to the skeleton message
                        [copyFunc, cleanupFile] = ros.slros.internal.ROSUtil.generateCopyFunction( signalDatastore, filledMessage(1), fieldLenInfo, dVarField );

                        % Set all caches to size 100.
                        dsMap.setBatchSize( 100 );
                        numMsgs = dsMap.numMsgs;

                        for tIdx = 1:numMsgs
                            currentMsg = filledMessage;
                            currentMsg = copyFunc( dsMap, currentMsg );
                            tsp = rosUtilLogger.convertToROSTime(startTimeInSec + dsMap.getTime);
                            try
                                write( bagWriter, topicName, tsp, currentMsg );
                            catch
                                rosUtilLogger.reportStatus('Error', bagFolderName);
                            end
                        end

                        % Explicitly clear the variable to trigger the onCleanup
                        % function to delete the generated function.
                        clear('cleanupFile');
                    end
                end
                rosUtilLogger.reportStatus('Completed', bagFolderName);
            catch ME
                sldiagviewer.reportError(ME);
            end
           
        end

        function [copyFunc, cleanup]  = generateCopyFunction(signals, sampleMsg, fieldInfoMap, dVarInfoMap)
            % generateCopyFunction top level function to generate the
            % runtime assignment function
            s = StringWriter;
            s.addcr('function currentMsg = assignFieldValue_ROSLogging(ds,currentMsg)');
            s.addcr();
            s = ros.slros.internal.ROSUtil.dfsGenFunc( signals , sampleMsg , '' ,fieldInfoMap, dVarInfoMap, s);
            s.addcr();
            s.addcr('end');

            outFileName = 'assignFieldValue_ROSLogging.m';
            outFile = fullfile(pwd, outFileName);
            s.write(outFile);
            % Sets up onCleanup function to delete the function and returns
            % so the caller can handle it's lifetime.
            cleanup = onCleanup( @() delete(outFileName) );
            copyFunc = @assignFieldValue_ROSLogging;
        end

        function [fieldInfoMap, dVarInfoMap, dsManager] = setupTables(baseVar, basePrefix, fieldInfoMap, dVarInfoMap, dsManager)
            % setupTables Top level function to generate field len info
            % table and the DsManager obj. The function call itself
            % recursively in case of nested messages.
            
            % Default values to be setup when called for the top level
            % message
            arguments
                baseVar
                basePrefix = '';
                fieldInfoMap = dictionary(string([]),[]);
                dVarInfoMap = dictionary(string([]),[]);
                dsManager = ros.slros.internal.DsManager();
            end
            
            fields = fieldnames(baseVar);
            
            contArr = contains(fields, 'SL_Info');
            
            % Get fields containing data and Length information
            msgFields = fields(~contArr);
            infoFields = fields(contArr);
            
            % Extract length information from fieldname.CurrentLength. This
            % assumes that the CurrentLength info remains same during the
            % simulation.
            for field = infoFields'
                fieldname = field{1};
                % Sets ReadSize to 1 to make sure only single variable is
                % loaded in memory
                baseVar.(fieldname).CurrentLength.ReadSize = 1;

                fieldKey = strcat(basePrefix,  field, '.CurrentLength');
                dVarKey = extractBefore(fieldKey, '_SL_Info');

                varSize = read(baseVar.(fieldname).CurrentLength).Data;
                fieldInfoMap(fieldKey) = varSize;
                dVarInfoMap(dVarKey) = varSize;
            end

            for field = msgFields'
                fieldname = field{1};
                
                % Get the full flattened fieldname by concatenating the
                % current fieldname and the basePrefix (Used in case of
                % nested message).
                fullFieldName = strcat( basePrefix, fieldname );
                if iscell(fullFieldName)
                    fullFieldName = fullFieldName{1};
                end

                
                % If field is struct then we have nested message.
                if isa(baseVar.(fieldname), 'struct')
                    
                    % Handle Nested message arrays. Check if current length
                    % is set and loop based on it.
                    r = 1;
                    if isKey( dVarInfoMap, fullFieldName )
                        r = dVarInfoMap( fullFieldName );
                    end
                    if r == 0
                        continue
                    end

                    if r > 1
                        for idx=1:r
                            % Set the basePrefix with idx. eg ,
                            % basePrefix = field.msgArray(3)
                            pref = strcat(basePrefix, field, '(', int2str(idx), ')', '.');
                            [fieldInfoMap, dVarInfoMap, dsManager] = ...
                                ros.slros.internal.ROSUtil.setupTables( ...
                                baseVar.(fieldname)(idx) , pref, fieldInfoMap, dVarInfoMap,dsManager);
                        end
                    else
                        %Need to account for cases when current length is 1
                        %but the base array size for the field is
                        %greater than > 1. The function expects a single variable
                        % but the field will be an array of size > 1 (g3289920).
                        pref = strcat(basePrefix,  field, '.');
                        [fieldInfoMap, dVarInfoMap, dsManager] = ...
                            ros.slros.internal.ROSUtil.setupTables( ...
                            baseVar.(fieldname)(1), pref, fieldInfoMap, dVarInfoMap, dsManager);
                    end
                else
                    % If you find a datastore variable, then store in the
                    % DsManager.
                    dsVar = baseVar.(fieldname);
                    dsManager.addToMap(fullFieldName, dsVar);

                end
            end

        end

        function s = dfsGenFunc(baseVar, baseMsg ,basePrefix, fieldInfoMap, dVarInfoMap, s)
            % dfsGenFunc Generates the runtime function. Stores it inside a
            % string writer. Calls itself recursively in case of nested
            % messages.
            fields = fieldnames(baseVar);

            contArr = contains(fields, 'SL_Info');
            msgFields = fields(~contArr);

            for field = msgFields'
                fieldname = field{1};

                fullFieldName = strcat( basePrefix, fieldname );
                if iscell(fullFieldName)
                    fullFieldName = fullFieldName{1};
                end

                if isa(baseVar.(fieldname), 'struct')

                    if isKey(dVarInfoMap, fullFieldName)
                        r = dVarInfoMap(fullFieldName);
                    else
                        [r, ~] = size(baseMsg.(fieldname));
                    end

                    if r == 0
                        continue;
                    end
                    if r > 1
                        for idx=1:r
                            pref = strcat(basePrefix, field, '(', int2str(idx), ')', '.');
                            s = ros.slros.internal.ROSUtil.dfsGenFunc( ...
                                baseVar.(fieldname)(idx), baseMsg.(fieldname)(idx) , ...
                                pref, fieldInfoMap, dVarInfoMap, s);
                        end
                    else
                        %Need to account for cases when current length is 1
                        %but the base array size for the field is
                        %greater than > 1. The function expects a single variable
                        % but the field will be an array of size > 1 (g3289920).
                        pref = strcat(basePrefix, field, '.');
                        s = ros.slros.internal.ROSUtil.dfsGenFunc( ...
                            baseVar.(fieldname)(1), baseMsg.(fieldname) , pref, ...
                            fieldInfoMap, dVarInfoMap, s);
                    end

                end

                if isa(baseVar.(fieldname), 'matlab.io.datastore.SimulationDatastore')
                    fieldType = class( baseMsg.(fieldname) );


                    if isKey(dVarInfoMap, fullFieldName)
                        maxLenForField = dVarInfoMap(fullFieldName);

                        if isequal(maxLenForField, 0)
                            continue
                        end

                        s.addcr("   currentMsg.%1$s =  cast(ds.read('%1$s', %2$d), '%3$s');", ...
                            fullFieldName ,maxLenForField , fieldType);
                        continue;
                    end

                    s.addcr("   currentMsg.%1$s =  cast(ds.read('%1$s'), '%2$s');", ...
                        fullFieldName ,fieldType);
                end

            end
        end

        function finalSignalName = getSignalName(signal)
            fullBlkPath = signal.BlockPath.convertToCell;
            blkPaths = cellfun( @(path) ros.slros.internal.ROSUtil.removeMdlName(path), ...
                fullBlkPath, 'UniformOutput',true );
            finalSignalName = sprintf('%s:%d', strjoin( blkPaths, '/' ), signal.PortIndex);

        end


        function blkName = removeMdlName(blkPath)
            % regex pattern to capture everything after the first slash.
            afterFirstSlashCap = '^.*?\/(.*)';

            tok = regexp( blkPath, afterFirstSlashCap, "tokens" );
            blkName = tok{1};
        end

        function loggerStartFcn(modelName)
            logInfo = ros.slros.internal.ROSUtil.getROSLoggingSettings(modelName);

            if ~logInfo.ROSLoggingInfo.GenBagFile || isempty(logInfo.ROSLoggingTable)
                return
            end


            loggerUtil = ros.slros.internal.ROSLogger(modelName);
            loggerUtil.setStartTime(modelName);

        end
        
        function isMoreThanOneROS2Pacer(currentSystem)
        %isMoreThanOneROS2Pacer - this function throws error if there are more
        %than one ROS 2 pacer blocks in a model.
            ros2pacerBlocks = ros.slros.internal.bus.Util.listBlocks(currentSystem, ...
                ros.slros2.internal.block.ROS2PacerBlockMask.getMaskType);

            if numel(ros2pacerBlocks) > 1
                % error out if more than 1 ros 2 pacer block is present
                % in the simulink model
                error(message('ros:slros2:ros2pacer:MultipleROS2PacerBlocks'));
            end
        end
    end

end

% LocalWords:  NEWBLKNAME CURRBLK blockid atleast mymodel presaved bagfile auxillary eg dfs Func
