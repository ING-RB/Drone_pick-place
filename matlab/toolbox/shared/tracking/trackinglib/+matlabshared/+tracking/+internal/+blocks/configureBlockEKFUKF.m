% Class responsible for configuring EKF and UKF blocks. This class
% implements tasks specific for EKF/UKF (and not needed for other state
% estimator blocks). The superclass takes care of the rest.

%   Copyright 2016-2017 The MathWorks, Inc.

classdef configureBlockEKFUKF < matlabshared.tracking.internal.blocks.configureBlockStateEstimator
    properties(Access=protected)
        % Boolean, indicates if process noise covariance is time varying
        % (and hence an inport is needed)
        HasTimeVaryingProcessNoise
        
        % Boolean vector, indicates measurement noise covariance is time
        % varying for each measurement model. An inport is shown for each
        % model that has time-varying covariance
        HasTimeVaryingMeasurementNoise        
    end
    
    properties(Constant,Access=protected)
        % Scalar integer. Indicates which inport of the Correct blocks are
        % utilized for sorting the order of operations underneath the main
        % block        
        SignalOrderingInportOnCorrectBlock = 4;
    end
    
    methods
        function this = configureBlockEKFUKF(blockHandle,filterType,dialogParameters)            
            this = this@matlabshared.tracking.internal.blocks.configureBlockStateEstimator(blockHandle,filterType,dialogParameters);
        end
    end
    
    methods(Access=protected)
        function [blocksToAdd,blockPositions,blockOptions,signalConnections] = getCorrectBlockConfig(this,desiredPosition,measNo)
            % Construct a set of variables that describe the setup of the a
            % Corrector block, all associated helper blocks and associated
            % signal connections. This is utilized when we are adding a new
            % measurement model.
            
            % Each correct operation involves 11 blocks for EKF and UKF:
            % 1) Correct block (algorithm)
            % 2-5) Data Type Conversion blocks
            % 6-10) Inport or Constant blocks
            % 11) Signal check block
            numBlocksToAdd = 10;
            numConnections  = 12;

            % Pre-allocate the necessary variables
            %
            % See help of addBlocks method in configureBlockStateEstimator
            % for a description of these variables
            blocksToAdd = cell(numBlocksToAdd,2);
            blockPositions = cell(numBlocksToAdd,1);
            blockOptions = cell(numBlocksToAdd,1);
            for kk=1:numBlocksToAdd
                blockOptions{kk} = {};
            end
            signalConnections = cell(numConnections,4);
            idxConnections = 1;            
            
            % 1) Correct block (algorithm)
            % Make a copy of the first correction block
            blocksToAdd{1,1} = ['sharedTrackingLibrary/Extras/' this.FilterType 'Correct'];
            blocksToAdd{1,2} = sprintf('%s/Correct%d',this.BlockPath,measNo);
            blockPositions{1} = desiredPosition;
            % No options to set for this blk
            % Outgoing connections from this blk is handled outside this routine (block
            % sorting related tasks are done in the caller of this routine)
            
            % 2-5) Data Type Conversion blocks
            positionOffset = [0 30 0 30];
            % Source of all data type conversion blocks is the same. Also they output
            % the same data type, except for the Enable
            blocksToAdd(2:5,1) = {'simulink/Signal Attributes/Data Type Conversion'};
            blockOptions(3:5) = {{'OutDataTypeStr','p.DataType'}};
            % Destinations of the added blocks
            %
            % Enable
            blocksToAdd{2,2} = sprintf('%s/DataTypeConversion_Enable%d',this.BlockPath,measNo);
            blockPositions{2} = desiredPosition-[120 23 195 127];
            blockOptions{2} = {'OutDataTypeStr','boolean'};
            signalConnections(idxConnections,:) = {2,'/1',1,'/Enable'};
            idxConnections = idxConnections+1;
            
            blocksToAdd{3,2} = sprintf('%s/DataTypeConversion_y%d',this.BlockPath,measNo);
            blockPositions{3} = blockPositions{2} + positionOffset;
            signalConnections(idxConnections,:) = {3,'/1',1,'/1'};
            idxConnections = idxConnections+1;
            
            blocksToAdd{4,2} = sprintf('%s/DataTypeConversion_R%d',this.BlockPath,measNo);
            blockPositions{4} = blockPositions{3} + positionOffset;
            signalConnections(idxConnections,:) = {4,'/1',1,'/2'};
            idxConnections = idxConnections+1;
            
            blocksToAdd{5,2} = sprintf('%s/DataTypeConversion_uMeas%d',this.BlockPath,measNo);
            blockPositions{5} = blockPositions{4} + positionOffset;
            signalConnections(idxConnections,:) = {5,'/1',1,'/3'};
            idxConnections = idxConnections+1;
            
            % 6-10) Inport or Constant blocks
            positionOffset = [0 30 0 30];
            % Enable
            [blocksToAdd{6,1},blockOptions{6}] = this.getEnableInportConfig(measNo);
            blocksToAdd{6,2} = sprintf('%s/Enable%d',this.BlockPath,measNo);
            blockPositions{6} = desiredPosition-[240 25 340 125];
            signalConnections(idxConnections,:) = {6,'/1',2,'/1'};
            idxConnections = idxConnections+1;
            % y
            blocksToAdd(7,[1 2]) = {'built-in/Inport', sprintf('%s/y%d',this.BlockPath,measNo)};
            blockPositions{7} = blockPositions{6} + positionOffset;
            signalConnections(idxConnections,:) = {7,'/1',3,'/1'};
            idxConnections = idxConnections+1;
            % R
            sampleTimeStr = sprintf('p.SampleTimes.MeasurementFcn(%d)',measNo);
            [blocksToAdd{8,1},blockOptions{8}] = ...
                matlabshared.tracking.internal.blocks.configureBlockEKFUKF.getCovarianceInportConfig(...
                this.HasTimeVaryingMeasurementNoise(measNo),...
                sprintf('p.R{%d}',measNo),...
                sampleTimeStr);
            blocksToAdd{8,2} = sprintf('%s/R%d',this.BlockPath,measNo);
            blockPositions{8} = blockPositions{7} + positionOffset;
            signalConnections(idxConnections,:) = {8,'/1',4,'/1'};
            idxConnections = idxConnections+1;
            % u
            blocksToAdd(9,[1 2]) = {'built-in/Constant', sprintf('%s/MeasurementFcn%dInputs',this.BlockPath,measNo)};
            blockPositions{9} = blockPositions{8} + positionOffset;
            blockOptions{9} = {'SampleTime',sampleTimeStr,'OutDataTypeStr','p.DataType'};
            signalConnections(idxConnections,:) = {9,'/1',5,'/1'};
            idxConnections = idxConnections+1;
            
            % Signal check block
            % * Copy this from the checkMeasurementFcn1Signals. It's always there and
            % is already configured to have the correct # of inports (4). Even though
            % we take this from user's model, we are OK if we change our library:
            % checkMeasurementFcn1Signals always comes from the sharedTrackingLibrary.
            % * Set its parameters from checkMeasurementFcn1Signals, just by changing
            % the indexing into the cell that hold the necessary params
            blocksToAdd{10,1} = [this.BlockPath '/checkMeasurementFcn1Signals'];
            blocksToAdd{10,2} = sprintf('%s/checkMeasurementFcn%dSignals',this.BlockPath,measNo);
            blockPositions{10} = desiredPosition-[135 67 180 158];
            checkSignalParam = get_param(blocksToAdd{10,1},'Parameters');
            checkSignalParam = strrep(checkSignalParam,'{1}',sprintf('{%d}',measNo));
            blockOptions{10} = {'Parameters',checkSignalParam};
            % Connections to the signal check block
            signalConnections(idxConnections,:) = {6,'/1',10,'/1'};
            idxConnections = idxConnections+1;
            signalConnections(idxConnections,:) = {7,'/1',10,'/2'};
            idxConnections = idxConnections+1;
            signalConnections(idxConnections,:) = {8,'/1',10,'/3'};
            idxConnections = idxConnections+1;
            signalConnections(idxConnections,:) = {9,'/1',10,'/4'};
        end
  
        function setBlockSpecificProperties(this, dialogParameters)
            % Assign the state variables (configuration parameters) that
            % are specific to EKF/UKF (and not utilized by other state
            % estimator blocks).
            this.HasTimeVaryingProcessNoise = dialogParameters.HasTimeVaryingProcessNoise;
            this.HasTimeVaryingMeasurementNoise = dialogParameters.HasTimeVaryingMeasurementNoise(1:this.NumberOfMeasurements);
        end
        
        function performBlockSpecificConfiguration(this)
            % Perform EKF/UKF specific block configuration tasks
            configureInportsProcessAndMeasurementNoiseCovariance(this);
        end
        
        function configureInportsProcessAndMeasurementNoiseCovariance(this)
            % Switch Inport<->Constant blocks based on user choice of
            % time-varying or constant process or measurement noise
            % covariance
            
            % State transition
            matlabshared.tracking.internal.blocks.configureBlockEKFUKF.configureCovarianceInportHelper(...
                this.HasTimeVaryingProcessNoise,...
                [this.BlockPath '/Q'],...
                'p.Q', ...
                'p.SampleTimes.StateTransitionFcn');
            % Measurements
            for measNo=1:this.NumberOfMeasurements
                matlabshared.tracking.internal.blocks.configureBlockEKFUKF.configureCovarianceInportHelper(...
                    this.HasTimeVaryingMeasurementNoise(measNo),...
                    sprintf('%s%s%d',this.BlockPath,'/R',measNo),...
                    sprintf('p.R{%d}',measNo),...
                    sprintf('p.SampleTimes.MeasurementFcn(%d)',measNo));
            end
        end
        
        function [inportBlockNames, outportBlockNames] = getPortNames(this)
            % List of all possible IO ports for EKF/UKF blocks, in the
            % order they should appear on the block (when they are active)
            
            inportBlockNames = cell(2+4*this.NumberOfMeasurements,1);
            inportBlockNames{1} = 'Q';
            inportBlockNames{2} = 'StateTransitionFcnInputs';
            inportIdx = 3;
            for kk=1:this.NumberOfMeasurements
                inportBlockNames{inportIdx} = sprintf('Enable%d',kk);
                inportIdx = inportIdx + 1;
                inportBlockNames{inportIdx} = sprintf('y%d',kk);
                inportIdx = inportIdx + 1;
                inportBlockNames{inportIdx} = sprintf('R%d',kk);
                inportIdx = inportIdx + 1;
                inportBlockNames{inportIdx} = sprintf('MeasurementFcn%dInputs',kk);
                inportIdx = inportIdx + 1;
            end
            
            outportBlockNames = {'xhat','P'};
        end
    end % methods(Access=protected)
    
    methods(Static)
        function configureCovarianceInportHelper(useInport,blockName,value,sampleTime)
            % Helper for configuring block for time-invariant or -varying
            % process and measurement noise covariance options            
            
            [desiredBlock,blockOptions,desiredBlockType] = ...
                matlabshared.tracking.internal.blocks.configureBlockEKFUKF.getCovarianceInportConfig(...
                useInport,value,sampleTime);
            
            if ~strcmp(get_param(blockName,'BlockType'),desiredBlockType)
                matlabshared.tracking.internal.blocks.replaceBlock(blockName,desiredBlock,blockOptions{:});
            end
        end          
        
        function [desiredBlock,blockOptions,desiredBlockType] = getCovarianceInportConfig(useInport,valueStr,sampleTime)
            % Helper for configuring block for time-invariant or -varying
            % process and measurement noise covariance options
            
            if useInport
                desiredBlockType = 'Inport';
                desiredBlock = 'built-in/Inport';
                blockOptions = {};
            else
                desiredBlockType = 'Constant';
                desiredBlock = 'built-in/Constant';
                blockOptions = {'Value',valueStr,'SampleTime',sampleTime};
            end
        end
    end % methods(Static)
    
end % classdef