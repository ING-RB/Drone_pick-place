classdef PairedBlockManager < handle
%This class is for internal use only. It may be removed in the future.

%   PairedBlockManager is a utility class that manages paired blocks in
%   Simulink model.
%

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = private)
        % PairedBlkDict - Dictionary for saving Paired block handles
        PairedBlkDict
        % PairedBlkPathDict - Dictionary for saving Paired block path
        PairedBlkPathDict
    end

    properties (SetAccess = private, Hidden)
        %DefaultNameDict - Dictionary for name property
        DefaultNameDict

        %DefaultNameValDict - Dictionary for value associated with name
        DefaultNameValDict

        %DefaultTypeDict - Dictionary for type property
        DefaultTypeDict

        %DefaultTypeValDict - Dictionary for value associated with type
        DefaultTypeValDict

        %DefaultLnkDict - Dictionary for default hyperlink text
        DefaultLnkDict

        %PairedBlkMaskType - Dicitonary for paired block mask type
        PairedBlkMaskType
    end

    properties (Constant, Hidden)
        SrcBlks = {ros.slros2.internal.block.ReceiveRequestBlockMask.MaskType; ...    % Receive Service Request
                   ros.slros2.internal.block.SendResponseBlockMask.MaskType; ...      % Send Service Response
                   ros.slros2.internal.block.SendActionGoalBlockMask.MaskType; ...    % Send Action Goal
                   ros.slros2.internal.block.MonitorActionGoalBlockMask.MaskType ...  % Monitor Action Goal
                   };
        TargetBlks = {ros.slros2.internal.block.SendResponseBlockMask.MaskType; ...      % Send Service Response
                      ros.slros2.internal.block.ReceiveRequestBlockMask.MaskType; ...    % Receive Service Request
                      ros.slros2.internal.block.MonitorActionGoalBlockMask.MaskType; ...  % Monitor Action Goal
                      ros.slros2.internal.block.SendActionGoalBlockMask.MaskType ...    % Send Action Goal
                      };
        DefaultNames = {"service";"service";"action";"action"};
        DefaultTypes = {"serviceType";"serviceType";"actionType";"actionType"};
        DefaultNameVals = {"/my_service";"/my_service";"/fibonacci";"/fibonacci"};
        DefaultTypeVals = {"std_srvs/Empty";"std_srvs/Empty";"example_interfaces/Fibonacci";"example_interfaces/Fibonacci"};
        DefaultLnkVals = {ros.slros2.internal.block.ReceiveRequestBlockMask.DefaultPrompt; ...
                          ros.slros2.internal.block.SendResponseBlockMask.DefaultPrompt; ...
                          ros.slros2.internal.block.SendActionGoalBlockMask.DefaultPrompt; ...
                          ros.slros2.internal.block.MonitorActionGoalBlockMask.DefaultPrompt ...
                          };
    end

    methods (Access = private)
        % Private constructor to prevent explicit object construction
        function obj = PairedBlockManager
        end
    end

    %% Singleton class access method
    methods (Static)
        function obj = getInstance
            persistent instance__
            mlock;
            if isempty(instance__)
                instance__ = ros.internal.block.PairedBlockManager();
                instance__.PairedBlkDict = dictionary(0,0);
                instance__.PairedBlkPathDict = dictionary('','');
                instance__.PairedBlkMaskType = dictionary(instance__.SrcBlks, instance__.TargetBlks);
                instance__.DefaultNameDict = dictionary(instance__.SrcBlks,instance__.DefaultNames);
                instance__.DefaultNameValDict = dictionary(instance__.SrcBlks,instance__.DefaultNameVals);
                instance__.DefaultTypeDict = dictionary(instance__.SrcBlks,instance__.DefaultTypes);
                instance__.DefaultTypeValDict = dictionary(instance__.SrcBlks,instance__.DefaultTypeVals);
                instance__.DefaultLnkDict = dictionary(instance__.SrcBlks,instance__.DefaultLnkVals);
            end
            obj = instance__;
        end
    end

    methods
        function addPairedBlock(obj, thisBlk, pairedBlk)
        %addPairedBlock add a pair of block into PairedBlkDict
        %   thisBlk and pairedBlk are expected to be block handles.

            obj.PairedBlkDict(thisBlk) = pairedBlk;
            obj.PairedBlkDict(pairedBlk) = thisBlk;
            if ~isKey(obj.PairedBlkPathDict, getfullname(thisBlk))
                obj.addPairedBlockPath(getfullname(thisBlk),getfullname(pairedBlk));
            end
        end

        function addPairedBlockPath(obj, thisBlkPath, pairedBlkPath)
        %addPairedBlockPath add a pair of block into PairedBlkPathDict
            obj.PairedBlkPathDict(thisBlkPath) = pairedBlkPath;
            obj.PairedBlkPathDict(pairedBlkPath) = thisBlkPath;
        end

        function pairedBlk = getPairedBlock(obj, thisBlk)
        %getPairedBlock returns the paired block handle for given block
        %   If no paired block, this will return 0.
        %   thisBlk is expected to be a block handle

            try
                pairedBlk = obj.PairedBlkDict(thisBlk);
                % Sanity check to ensure pairedBlk is valid since block
                % handle may change during model loading time
                getfullname(pairedBlk);
            catch
                try
                    pairedBlk = getSimulinkBlockHandle(obj.PairedBlkPathDict(getfullname(thisBlk)));
                    if pairedBlk<0
                        % Paired block no longer exist. Update
                        % pairedBlkPathDict to clear the pair
                        obj.PairedBlkPathDict(obj.PairedBlkPathDict(getfullname(thisBlk))) = [];
                        obj.PairedBlkPathDict(getfullname(thisBlk)) = [];
                    end
                catch
                    pairedBlk = 0;
                end
            end
        end

        function removePairedBlock(obj, thisBlk)
        %removePairedBlock remove current block and its paired block from
        %PairedBlkDict
        %   thisBlk is expected to be a block handle

            try
                pairedBlk = obj.PairedBlkDict(thisBlk);
                %obj.resetDefaultNameType(pairedBlk);
                % Reset paired block hyperlink
                obj.resetHyperlink(pairedBlk);
                % Remove both from PairedBlockManager
                obj.PairedBlkDict(thisBlk) = [];
                obj.PairedBlkDict(pairedBlk) = [];
                obj.PairedBlkPathDict(getfullname(thisBlk)) = [];
                obj.PairedBlkPathDict(getfullname(pairedBlk)) = [];
                % Reset paired block mask fields
                %obj.resetDefaultNameType(pairedBlk);
            catch
                % No such key, do nothing
            end
        end

        function updatePairedBlkHyperlink(obj, thisBlk, defaultHyperLink)
        %updatePairedBlkHyperlink updates the hyperlink of current block
        %   thisBlk is expected to be a block handle

            currBlkMaskObj = Simulink.Mask.get(thisBlk);
            currBlkLnk = currBlkMaskObj.getDialogControl('PairedBlkLink');

            pairedBlkH = obj.getPairedBlock(thisBlk);
            if pairedBlkH
                pairedBlk = getfullname(pairedBlkH);
                currBlkLnk.Prompt = pairedBlk;
            else
                currBlkLnk.Prompt = defaultHyperLink;
            end
        end

        function ret = isBlockAdded(obj, thisBlk)
        %isBlockAdded return whether block has been added to PairedBlkDict
        %or PairedBlkPathDict
            ret = obj.PairedBlkDict.isKey(thisBlk) || ...
                  obj.PairedBlkPathDict.isKey(getfullname(thisBlk));
        end

        function clearAll(obj)
            obj.PairedBlkDict(obj.PairedBlkDict.keys) = [];
            obj.PairedBlkPathDict(obj.PairedBlkPathDict.keys) = [];
        end

        function ret = isDictionaryEmpty(obj)
            obj.PairedBlkDict(0) = [];
            obj.PairedBlkPathDict('') = [];
            ret = numel(obj.PairedBlkDict.keys)<=0 && ...
                  numel(obj.PairedBlkPathDict.keys)<=0;
        end

        function resetDefaultNameType(obj, block)
        %resetDefaultNameType reset block name and type
            
            thisBlkMask = get_param(block, 'MaskType');

            if strcmp(thisBlkMask,ros.slros2.internal.block.SendResponseBlockMask.MaskType) || ...
                strcmp(thisBlkMask,ros.slros2.internal.block.MonitorActionGoalBlockMask.MaskType)
                % Get all information for dictionary as cell
                nameField = obj.DefaultNameDict({thisBlkMask});
                nameDefault = obj.DefaultNameValDict({thisBlkMask});
                typeField = obj.DefaultTypeDict({thisBlkMask});
                typeDefault = obj.DefaultTypeValDict({thisBlkMask});
    
                % Set block name, type
                set_param(block,nameField{1},nameDefault{1});
                set_param(block,typeField{1},typeDefault{1});
            end
        end

        function resetHyperlink(obj, block)
        %resetHyperlink reset block hyperlink
            
            thisBlkMask = get_param(block, 'MaskType');
            defaultLnkTxt = obj.DefaultLnkDict({thisBlkMask});
            maskObj = Simulink.Mask.get(block);
            pairedBlkLnk = maskObj.getDialogControl('PairedBlkLink');
            pairedBlkLnk.Prompt = defaultLnkTxt{1};
        end

        function ret = getPairedBlockMaskType(obj, block)
        %getPairedBlockMaskType Returns the paired block mask type
        %   block is the current block full path name given by "gcb"

            currentBlkMask = get_param(block, 'MaskType');
            retCell = obj.PairedBlkMaskType({currentBlkMask});
            ret = retCell{1};
        end
    end
end