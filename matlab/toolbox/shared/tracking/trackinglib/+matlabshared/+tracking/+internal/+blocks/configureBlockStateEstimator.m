% Class responsible for configuring EKF, UKF and PF blocks. Each block has
% a subclass that performs block specific tasks.

%   Copyright 2016-2017 The MathWorks, Inc.

classdef configureBlockStateEstimator < handle
    properties(Access=protected)
        % Handle and path to the state estimator block
        BlockHandle
        BlockPath
        
        % How many measurement models are utilized?
        NumberOfMeasurements;
        
        % Is there direct feedthrough?
        IsUsingCurrentEstimator;
        
        % Structure that holds various information about the state
        % transition and measurement (likelihood) functions
        FcnInfo;
        
        % Boolean vector to indicate if we need to provide an inport for
        % enabling/disabling corrections for each measurement model
        HasInportEnable;
        
        % Boolean variable that indicated if we provide a state covariance
        % outport
        HasOutportStateCovariance;
        
        % 'EKF', 'UKF' or 'PF'
        FilterType;
    end
    
    properties(Abstract,Constant,Access=protected)
        % Scalar integer. Indicates which inport of the Correct blocks are
        % utilized for sorting the order of operations underneath the main
        % block
        SignalOrderingInportOnCorrectBlock
    end
    
    methods
        function this = configureBlockStateEstimator(blkH,filterType,dialogParameters)
            % Set filter type
            this.FilterType = filterType;
            
            %%%
            % Gather block state (configuration parameters)
            %%%
            this.BlockHandle = blkH;
            this.BlockPath = getfullname(blkH);
            % Common block options among state estimators
            this.NumberOfMeasurements = dialogParameters.NumberOfMeasurements;
            this.IsUsingCurrentEstimator = dialogParameters.UseCurrentEstimator;
            % Common I/O ports
            this.HasInportEnable = dialogParameters.HasMeasurementEnablePort(1:this.NumberOfMeasurements);
            this.HasOutportStateCovariance = dialogParameters.OutputStateCovariance;
            % Info on fcns
            this.FcnInfo = dialogParameters.FcnInfo;
            % Gather EKF, UKF or PF specific configuration parameters
            setBlockSpecificProperties(this, dialogParameters);
            
            %%%
            % Start block configuration
            %%%
            configureBlock(this);
        end
        
        function set.FilterType(this,val)
            this.FilterType = validatestring(val,{'EKF','UKF','PF'});
        end
    end
    
    methods(Abstract, Access=protected)
        [blocksToAdd,blockPositions,blockOptions,signalConnections] = getCorrectBlockConfig(this,desiredPosition,measNo);
        setBlockSpecificProperties(this, dialogParameters);
        [inportBlockNames, outportBlockNames] = getPortNames(this);
        performBlockSpecificConfiguration(this);
    end
    
    methods(Access=protected)
        function configureBlock(this)
            % Perform block configuration
            
            % Configure all Correct blocks
            configureCorrectBlocks(this);
            % Configure the order of operations underneath the block to
            % output state estimates x[k|k] or x[k-1|k]. The former
            % involves direct feedthrough from measurement inports to block
            % outputs.
            configureFeedthrough(this);

            % Configure EKF-, UKF- or PF-specific tasks
            performBlockSpecificConfiguration(this);
            
            % Configure EnableX inports
            configureInportsEnable(this);
            % Configure StateTransitionFcnInputs and MeasurementFcnXInputs
            % inports
            configureOptionalArgumentInports(this);
            % Configure the StateCovariance outport
            configureOutportStateCovariance(this);
            
            % Set the ordering of the inports and outports. This ensures
            % that the ordering of the user's choices on the block dialog
            % do not impact the order of inports and outports on the block
            setPortOrdering(this);
        end
        
        function configureOutportStateCovariance(this)
            % Show/hide the state covariance outport P
            
            % Get the full path to the terminator/outport for P
            outportBlock = [this.BlockPath '/P'];
            if this.HasOutportStateCovariance
                desiredType = 'Outport';
                desiredBlock = 'built-in/Outport';
            else
                desiredType = 'Terminator';
                desiredBlock = 'built-in/Terminator';
            end
            if ~strcmp(get_param(outportBlock,'BlockType'),desiredType)
                matlabshared.tracking.internal.blocks.replaceBlock(outportBlock,desiredBlock);
            end
        end
        
        function configureCorrectBlocks(this)
            % Configure the corrector blocks. Ensure
            %   * # of correct blocks match the number of measurement models
            %   * If adding or removing correct blocks, also remove the
            %   associated constant/inport and data type conversion blocks
            
            numMeasurements = this.NumberOfMeasurements;
            % Find all the correct blocks underneath
            correctBlockPaths = find_system(this.BlockPath,...
                'SearchDepth',1,...
                'LookUnderMasks','on',...
                'FollowLinks','on',...
                'Regexp','on','Name','^Correct');
            numCorrectBlocks = numel(correctBlockPaths);
            % Add/remove new measurements as necessary
            if numCorrectBlocks>numMeasurements
                % Remove the excess correct blocks, and anything connected
                % to it.
                correctBlockPaths = sort(correctBlockPaths);
                % Delete the signal line between the very last correct block and GotoAfterCorrect
                delete_line(this.BlockPath,sprintf('Correct%d/1',numCorrectBlocks),'GotoAfterCorrect/1');
                % Delete the signal line between the last necessary correct block and
                % the extras
                delete_line(this.BlockPath,sprintf('Correct%d/1',numMeasurements),sprintf('Correct%d/%d',numMeasurements+1,this.SignalOrderingInportOnCorrectBlock));
                % Start recursive removal from the final Correct block
                matlabshared.tracking.internal.blocks.configureBlockStateEstimator.removeBlocksDeep(correctBlockPaths(end));
                
                % Add a signal line between the last existing correct block and GotoAfterCorrect
                add_line(this.BlockPath,sprintf('Correct%d/1',numMeasurements),'GotoAfterCorrect/1','autorouting','on');
            elseif numCorrectBlocks<numMeasurements
                % Delete the signal line between the last existing correct block and GotoAfterCorrect
                delete_line(this.BlockPath,sprintf('Correct%d/1',numCorrectBlocks),'GotoAfterCorrect/1');
                
                % Need to add new correct blocks
                for kk=1:numMeasurements-numCorrectBlocks
                    measNo = numCorrectBlocks+kk;
                    desiredPosition = [-80 -277+170*measNo 60 -163+170*measNo];
                    
                    % Perform the construction
                    [blocksToAdd,blockPositions,blockOptions,signalConnections] = this.getCorrectBlockConfig(desiredPosition,measNo);
                    matlabshared.tracking.internal.blocks.configureBlockStateEstimator.addBlocks(this.BlockPath,blocksToAdd,blockPositions,blockOptions,signalConnections);
                    
                    % Add a signal line between the new and the last port of the existing Correct block
                    add_line(this.BlockPath,sprintf('Correct%d/1',measNo-1),sprintf('Correct%d/%d',measNo,this.SignalOrderingInportOnCorrectBlock),'autorouting','on');
                end
                
                % Add a signal line between the last existing correct block and GotoAfterCorrect
                add_line(this.BlockPath,sprintf('Correct%d/1',numMeasurements),'GotoAfterCorrect/1','autorouting','on');
            end
        end
                
        function configureFeedthrough(this)
            % Configure the order of operations underneath the block to
            % output state estimates x[k|k] or x[k-1|k], along with other
            % relevant variables.
            %
            % The former choice involves direct feedthrough from
            % measurement inports to block outputs.
            
            % We have a simple scalar signal we pass around underneath our
            % block, which Simulink utilizes for ordering the operations
            if this.IsUsingCurrentEstimator
                desiredOutputExecutionToken = 'AfterCorrect';
                desiredCorrectExecutionToken = 'FirstOperation';
                desiredPredictExecutionToken = 'AfterOutput';
            else
                desiredOutputExecutionToken = 'FirstOperation';
                desiredCorrectExecutionToken = 'AfterOutput';
                desiredPredictExecutionToken = 'AfterCorrect';
            end
            % Set the order of operations
            gotoBlockPath = [this.BlockPath '/BlockOrderOutput'];
            if ~strcmp(get_param(gotoBlockPath,'GotoTag'),desiredOutputExecutionToken)
                set_param(gotoBlockPath,'GotoTag',desiredOutputExecutionToken);
            end
            gotoBlockPath = [this.BlockPath '/BlockOrderCorrect'];
            if ~strcmp(get_param(gotoBlockPath,'GotoTag'),desiredCorrectExecutionToken)
                set_param(gotoBlockPath,'GotoTag',desiredCorrectExecutionToken);
            end
            gotoBlockPath = [this.BlockPath '/BlockOrderPredict'];
            if ~strcmp(get_param(gotoBlockPath,'GotoTag'),desiredPredictExecutionToken)
                set_param(gotoBlockPath,'GotoTag',desiredPredictExecutionToken);
            end
        end
        
        function configureInportsEnable(this)
            % Switch Inport<->Constant blocks based on user choice of having an Enable inport
            
            % Loop over all measurement models
            for measNo=1:this.NumberOfMeasurements
                enableBlockPath = sprintf('%s%s%d',this.BlockPath,'/Enable',measNo);
                [desiredBlock,blockOptions,desiredEnableBlockType] = this.getEnableInportConfig(measNo);
                if ~strcmp(get_param(enableBlockPath,'BlockType'),desiredEnableBlockType)
                    matlabshared.tracking.internal.blocks.replaceBlock(enableBlockPath,desiredBlock,blockOptions{:});
                end
            end
        end
        
        function configureOptionalArgumentInports(this)
            % If user has provided MATLAB Functions for state transition or
            % measurement (likelihood) functions, we allow a maximum of 1
            % additional inports. Configure these inports.
            
            % For state transition fcn
            this.configureOptionalArgumentInportHelper(...
                this.FcnInfo.Predict.BlockConfig.NumberOfInports, ...
                '/StateTransitionFcnInputs', ...
                'HasStateTransitionFcnExtraArgument');
            % For measurement fcns
            for kk=1:this.NumberOfMeasurements
                this.configureOptionalArgumentInportHelper(...
                    this.FcnInfo.Correct.BlockConfig.NumberOfInports(kk), ...
                    sprintf('/MeasurementFcn%dInputs',kk),...
                    sprintf('HasMeasurementFcnExtraArgument%d',kk));
            end
        end
        
        function configureOptionalArgumentInportHelper(this, needInport, portName, widgetName)
            % We show or hide an extra argument inport for state transition
            % or measurement (likelihood) functions, when they are
            % specified as MATLAB Functions and they contain an extra
            % argument.
            %
            % We handle the following edge case:
            % * User first loads the model, provides a function with an
            % extra argument and we create an inport.
            % * User closes the model. Next time the model is loaded, the
            % MATLAB Function may not be on the path (yet). In this case we
            % should not remove the inport we created earlier.
            %
            % We store if we had an inport last time we located the
            % specified function (either MATLAB or Simulink Fcns). When the
            % function is not found, we do not add or remove the additional
            % inport.
            
            % Get the stored data from the block if we aren't currently
            % able to determine if we need an extra argument inport or not
            if needInport==-1
                needInport = str2double(get_param(this.BlockHandle,widgetName));
            end
            
            % Config the potential StateTransitionFcnInputs/MeasurementFcnXInputs
            % inport or constant
            if needInport
                desiredBlockType = 'Inport';
                desiredBlock = 'built-in/Inport';
                blockOptions = {};
            else
                desiredBlockType = 'Constant';
                % * Constant block with Value=0, OutDataTypeStr=p.DataType
                % * Use this instead of the built-in/Constant. Setting the
                % properties of the inserted block triggers evaluation of
                % mask variables (here 0 and p.DataType). However
                % p.DataType is nor available yet, which causes an error.
                desiredBlock = 'sharedTrackingLibrary/Extras/ConstantWithDataType';
                blockOptions = {};
            end
            blockName = [this.BlockPath portName];
            if ~strcmp(get_param(blockName,'BlockType'),desiredBlockType)
                matlabshared.tracking.internal.blocks.replaceBlock(blockName, ...
                    desiredBlock, blockOptions{:});
            end
            % Store the needInport result in the block widget
            currentData = str2double(get_param(this.BlockHandle,widgetName));
            if currentData~=needInport
                set_param(this.BlockHandle,widgetName,sprintf('%d',needInport));
            end
        end        
        
        function setPortOrdering(this)
            % localSetIOPortIndices Set the indices of the IO ports
            %
            % This ensures that the ordering of the user's choices on the
            % block dialog do not impact the order of inports and outports
            % on the block.
            %
            %   Inputs:
            %     parentName - getfullname(blockHandle)
            %     portData   - Structure containing the names of the IO ports, as well
            %                  as information about if they are being utilized
            [inportBlockNames, outportBlockNames] = this.getPortNames();
            
            numInports = numel(inportBlockNames);
            numOutports = numel(outportBlockNames);
            
            isUsingInport = false(numInports,1);
            isUsingOutport = false(numOutports,1);
            for kk=1:numInports
                isUsingInport(kk) = ...
                    strcmp(get_param([this.BlockPath '/' inportBlockNames{kk}],'BlockType'),'Inport');
            end
            for kk=1:numOutports
                isUsingOutport(kk) = ...
                    strcmp(get_param([this.BlockPath '/' outportBlockNames{kk}],'BlockType'),'Outport');
            end
            
            % Order the IO ports
            matlabshared.tracking.internal.blocks.configureBlockStateEstimator.orderPorts(this.BlockPath, inportBlockNames(isUsingInport));
            matlabshared.tracking.internal.blocks.configureBlockStateEstimator.orderPorts(this.BlockPath, outportBlockNames(isUsingOutport));
        end
        
        function [desiredBlock,blockOptions,desiredBlockType] = getEnableInportConfig(this,measNo)
            % Show/hide EnableX inports for controlling if correction
            % operations should be performed or not
            
            if this.HasInportEnable(measNo)
                desiredBlockType = 'Inport';
                desiredBlock = 'built-in/Inport';
                blockOptions = {};
            else
                desiredBlockType = 'Constant';
                desiredBlock = 'built-in/Constant';
                blockOptions = {'Value','true()',...
                    'SampleTime',sprintf('p.SampleTimes.MeasurementFcn(%d)',measNo)};
            end
        end
    end % methods(Access=protected)
    
    methods(Static)
        function addBlocks(parentBlockPath,blocksToAdd,blockPositions,blockOptions,signalConnections)
        % addBlocks Helper function for adding a set of blocks and signal
        %           connections underneath parentBlockPath
        %
        % Inputs:
        %   parentBlockPath - Full path to the parent, container of all new blocks
        %   blocksToAdd     - [n 2] cell, where n is the # of new blocks
        %                     Element (jj,1) is the library path (source)
        %                     Element (jj,2) is the destination
        %   blockPositions  - [n 1] cell, each element is [1 4] array. Positions of
        %                     the new blocks
        %   blockOptions    - [n 1] cell, each element is a [1 2*m] cell where m is
        %                     the # of properties we are setting in the new block.
        %   signalConnections - [k 4] cell, where k is the # of new signal
        %                       connections.
        %                       Element (jj,1) is the index of the source block
        %                       (path) in blocksToAdd
        %                       Element (jj,2) is the port on the source block
        %                       Element (jj,3)  is the index of the destination
        %                       block (path) in blocksToAdd
        %                       Element (jj,4) is the port on the destination block

        %   Copyright 2017 The MathWorks, Inc.

        % Add all blocks first
        numNewBlocks = size(blocksToAdd,1);
        for kk=1:numNewBlocks
            add_block(blocksToAdd{kk,1},blocksToAdd{kk,2},'Position',blockPositions{kk},blockOptions{kk}{:});
        end

        % Get block names from full paths
        parentPathLen = strlength(parentBlockPath) + 2; % +2 for including and skipping the / character
        newBlkNames = cell(numNewBlocks,1);
        for kk=1:numNewBlocks
            newBlkNames{kk} = blocksToAdd{kk,2}(parentPathLen:end);
        end

        % Add the signals
        for kk=1:size(signalConnections,1)
            sourcePort = [newBlkNames{signalConnections{kk,1}} signalConnections{kk,2}];
            destinationPort = [newBlkNames{signalConnections{kk,3}} signalConnections{kk,4}];
            add_line(parentBlockPath,sourcePort,destinationPort);
        end
        end
        
        function removeBlocksDeep(blockList)
            % Remove blocks along with everything connected to them
            
            for kk=1:numel(blockList)
                % Get LineHandles to delete the line and the other connected blocks
                % before deleting it
                allLineH = get_param(blockList{kk},'LineHandles');
                delete_block(blockList{kk});
                % Get&delete blocks connected to the Outport lines
                allLineH.Outport(~ishandle(allLineH.Outport)) = -1;
                for kkLine=1:numel(allLineH.Outport)
                    if allLineH.Outport(kkLine)==-1 || ... % unconnected port
                            ~ishandle(allLineH.Outport(kkLine)) % item might have been deleted since we obtained handles
                        % no op in these cases
                        continue;
                    end
                    % Connected: delete the connected line and the destination block
                    blkH = get_param(allLineH.Outport(kkLine),'DstBlockHandle');
                    delete_line(allLineH.Outport(kkLine));
                    for kkBlk=1:numel(blkH)
                        if ishandle(blkH(kkBlk))
                            matlabshared.tracking.internal.blocks.configureBlockStateEstimator.removeBlocksDeep({blkH(kkBlk)});
                        end
                    end
                end
                % Get&delete blocks connected to the Input lines
                for kkLine=1:numel(allLineH.Inport)
                    if allLineH.Inport(kkLine)==-1 || ... % unconnected port
                            ~ishandle(allLineH.Inport(kkLine)) % item might have been deleted since we obtained handles
                        % no op in these cases
                        continue;
                    end
                    blkH = get_param(allLineH.Inport(kkLine),'SrcBlockHandle');
                    delete_line(allLineH.Inport(kkLine));
                    if ishandle(blkH)
                        matlabshared.tracking.internal.blocks.configureBlockStateEstimator.removeBlocksDeep({blkH});
                    end
                end
                % Get&delete blocks connected to the Enable lines
                for kkLine=1:numel(allLineH.Enable)
                    if allLineH.Enable(kkLine)==-1 || ... % unconnected port
                            ~ishandle(allLineH.Enable(kkLine)) % item might have been deleted since we obtained handles
                        % no op in these cases
                        continue;
                    end
                    blkH = get_param(allLineH.Enable(kkLine),'SrcBlockHandle');
                    delete_line(allLineH.Enable(kkLine));
                    if ishandle(blkH)
                        matlabshared.tracking.internal.blocks.configureBlockStateEstimator.removeBlocksDeep({blkH});
                    end
                end
            end
        end
        
        function orderPorts(parentPath,ioPortNames)
            % Order inports of parentPath, per the ordering of their names
            % in ioPortNames
            
            portIndex = 1;
            for kkPorts=1:numel(ioPortNames)
                portPath = [parentPath '/' ioPortNames{kkPorts}];
                portOrderStr = sprintf('%d',portIndex);
                if ~strcmp(get_param(portPath,'Port'),portOrderStr)
                    set_param(portPath,'Port',portOrderStr);
                end
                portIndex = portIndex+1;
            end
        end
    end
end
