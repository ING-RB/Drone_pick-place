% Class responsible for configuring the PF block. This class implements
% tasks specific for EKF/UKF (and not needed for other state estimator
% blocks). The superclass takes care of the rest.

%   Copyright 2016-2017 The MathWorks, Inc.

classdef configureBlockPF < matlabshared.tracking.internal.blocks.configureBlockStateEstimator
    properties(Access=protected)
        % boolean. Should the block calculate state estimates and output
        % them in the outport 'xhat'?
        OutputStateEstimate;
        
        % boolean. Should the block output all particles?
        OutputParticles;
        
        % boolean. Should the block output the weights of the particles?
        OutputWeights;
    end    
    
    properties(Constant,Access=protected)
        % Scalar integer. Indicates which inport of the Correct blocks are
        % utilized for sorting the order of operations underneath the main
        % block
        SignalOrderingInportOnCorrectBlock = 3;
    end
    
    methods
        function this = configureBlockPF(blockHandle,filterType,dialogParameters)
            this = this@matlabshared.tracking.internal.blocks.configureBlockStateEstimator(blockHandle,filterType,dialogParameters);
        end
    end
    
    methods(Access=protected)
        function [blocksToAdd,blockPositions,blockOptions,signalConnections] = getCorrectBlockConfig(this,desiredPosition,measNo)
            % Construct a set of variables that describe the setup of the a
            % Corrector block, all associated helper blocks and associated
            % signal connections. This is utilized when we are adding a new
            % measurement model.
            
            % Each correct operation involves 8 blocks:
            % 1) Correct block (algorithm)
            % 2-4) Data Type Conversion blocks
            % 5-7) Inport or Constant blocks
            % 8) Signal check block
            numBlocksToAdd = 8;
            numConnections  = 9;
            
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
            blocksToAdd{1,1} = 'sharedTrackingLibrary/Extras/PFCorrect';
            blocksToAdd{1,2} = sprintf('%s/Correct%d',this.BlockPath,measNo);
            blockPositions{1} = desiredPosition;
            % No options to set for this blk
            % Outgoing connections from this blk is handled outside this routine (block
            % sorting related tasks are done in the caller of this routine)
            
            % 2-4) Data Type Conversion blocks
            positionOffset = [0 30 0 30];
            % Source of all data type conversion blocks is the same. Also they output
            % the same data type, except for the Enable
            blocksToAdd(2:4,1) = {'simulink/Signal Attributes/Data Type Conversion'};
            blockOptions(3:4) = {{'OutDataTypeStr','p.DataType'}};
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
            
            blocksToAdd{4,2} = sprintf('%s/DataTypeConversion_uMeas%d',this.BlockPath,measNo);
            blockPositions{4} = blockPositions{3} + positionOffset;
            signalConnections(idxConnections,:) = {4,'/1',1,'/2'};
            idxConnections = idxConnections+1;
            
            % 5-7) Inport or Constant blocks
            positionOffset = [0 30 0 30];
            % Enable
            [blocksToAdd{5,1},blockOptions{5}] = this.getEnableInportConfig(measNo);
            blocksToAdd{5,2} = sprintf('%s/Enable%d',this.BlockPath,measNo);
            blockPositions{5} = desiredPosition-[240 25 340 125];
            signalConnections(idxConnections,:) = {5,'/1',2,'/1'};
            idxConnections = idxConnections+1;
            % y
            blocksToAdd(6,[1 2]) = {'built-in/Inport', sprintf('%s/y%d',this.BlockPath,measNo)};
            blockPositions{6} = blockPositions{5} + positionOffset;
            signalConnections(idxConnections,:) = {6,'/1',3,'/1'};
            idxConnections = idxConnections+1;
            % u
            sampleTimeStr = sprintf('p.SampleTimes.MeasurementFcn(%d)',measNo);
            blocksToAdd(7,[1 2]) = {'built-in/Constant', sprintf('%s/MeasurementFcn%dInputs',this.BlockPath,measNo)};
            blockPositions{7} = blockPositions{6} + positionOffset;
            blockOptions{7} = {'SampleTime',sampleTimeStr,'OutDataTypeStr','p.DataType'};
            signalConnections(idxConnections,:) = {7,'/1',4,'/1'};
            idxConnections = idxConnections+1;
            
            % Signal check block
            % * Copy this from the checkMeasurementFcn1Signals. It's always there and
            % is already configured to have the correct # of inports (4). Even though
            % we take this from user's model, we are OK if we change our library:
            % checkMeasurementFcn1Signals always comes from the sharedTrackingLibrary.
            % * Set its parameters from checkMeasurementFcn1Signals, just by changing
            % the indexing into the cell that hold the necessary params
            blocksToAdd{8,1} = [this.BlockPath '/checkMeasurementFcn1Signals'];
            blocksToAdd{8,2} = sprintf('%s/checkMeasurementFcn%dSignals',this.BlockPath,measNo);
            blockPositions{8} = desiredPosition-[135 67 180 158];
            checkSignalParam = get_param(blocksToAdd{8,1},'Parameters');
            checkSignalParam = strrep(checkSignalParam,'{1}',sprintf('{%d}',measNo));
            blockOptions{8} = {'Parameters',checkSignalParam};
            % Connections to the signal check block
            signalConnections(idxConnections,:) = {5,'/1',8,'/1'};
            idxConnections = idxConnections+1;
            signalConnections(idxConnections,:) = {6,'/1',8,'/2'};
            idxConnections = idxConnections+1;
            signalConnections(idxConnections,:) = {7,'/1',8,'/3'};
        end
        
        function setBlockSpecificProperties(this, dialogParameters)
            % Assign the state variables (configuration parameters) that
            % are specific to PF (and not utilized by other state estimator
            % blocks).
            
            % Should the block have xhat outport?
            if strcmp(dialogParameters.StateEstimationMethod,...
                slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodNone'))
                this.OutputStateEstimate = false();
            else
                this.OutputStateEstimate = true();
            end
           
            this.OutputParticles = logical(dialogParameters.OutputParticles);
            this.OutputWeights = logical(dialogParameters.OutputWeights);
        end
        
        function performBlockSpecificConfiguration(this)
            % Perform configuration tasks specific to the PF block
            
            % Configure the state estimate outport
            this.configureStateEstimateOutport();
            
            % Configure the Particles outport
            this.configureParticlesOutport();
            
            % Configure the Weights outport
            this.configureWeightsOutport();
        end
        
        function [inportBlockNames, outportBlockNames] = getPortNames(this)
            % List of all possible IO ports for the PF block, in the order
            % they should appear on the block (when they are active)
            
            inportBlockNames = cell(1+3*this.NumberOfMeasurements,1);
            inportBlockNames{1} = 'StateTransitionFcnInputs';
            inportIdx = 2;
            for kk=1:this.NumberOfMeasurements
                inportBlockNames{inportIdx} = sprintf('Enable%d',kk);
                inportIdx = inportIdx + 1;
                inportBlockNames{inportIdx} = sprintf('y%d',kk);
                inportIdx = inportIdx + 1;
                inportBlockNames{inportIdx} = sprintf('MeasurementFcn%dInputs',kk);
                inportIdx = inportIdx + 1;
            end
            
            outportBlockNames = {'xhat','P','Particles','Weights'};
        end
        
        function configureStateEstimateOutport(this)
            % Configure the xhat outport of the PF block
            %
            % Outport is shown if the StateEstimationMethod isn't 'none'
            if this.OutputStateEstimate
                desiredBlockType = 'Outport';
                desiredBlock = 'built-in/Outport';
            else
                desiredBlockType = 'Terminator';
                desiredBlock = 'built-in/Terminator';
            end
            
            outportPath = [this.BlockPath '/xhat'];
            if ~strcmp(get_param(outportPath,'BlockType'),desiredBlockType)
                matlabshared.tracking.internal.blocks.replaceBlock(outportPath,desiredBlock);
            end
        end
        
        function configureParticlesOutport(this)
            % Configure the Particles outport of the PF block
            if this.OutputParticles
                desiredBlockType = 'Outport';
                desiredBlock = 'built-in/Outport';
            else
                desiredBlockType = 'Terminator';
                desiredBlock = 'built-in/Terminator';
            end
            
            outportPath = [this.BlockPath '/Particles'];
            if ~strcmp(get_param(outportPath,'BlockType'),desiredBlockType)
                matlabshared.tracking.internal.blocks.replaceBlock(outportPath,desiredBlock);
            end
        end
        
        function configureWeightsOutport(this)
            % Configure the Weights outport of the PF block
            if this.OutputWeights
                desiredBlockType = 'Outport';
                desiredBlock = 'built-in/Outport';
            else
                desiredBlockType = 'Terminator';
                desiredBlock = 'built-in/Terminator';
            end
            
            outportPath = [this.BlockPath '/Weights'];
            if ~strcmp(get_param(outportPath,'BlockType'),desiredBlockType)
                matlabshared.tracking.internal.blocks.replaceBlock(outportPath,desiredBlock);
            end
        end  
    end % methods(Access=protected)
    
end % classdef

