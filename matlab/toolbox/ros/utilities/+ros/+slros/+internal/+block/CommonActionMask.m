classdef (Abstract) CommonActionMask < ros.slros.internal.block.CommonMask
%This class is for internal use only. It may be removed in the future.

%CommonActionMask Common base class for ROS Action block masks

%   Copyright 2023 The MathWorks, Inc.

    %%
    methods
        %% Callbacks
        % Callbacks for individual params are invoked when the user:
        % * Opens a mask dialog
        % * Modifies a param value and changes focus
        % * Modifies a param value and selects OK or Apply
        % * Updates the model (presses Ctrl+D or simulates the model)
        %
        % Note - these are **not** invoked when user does a SET_PARAM
        function actionSelect(obj, block, getDlgFcn)
        %actionSelect Callback for "Action" button on action name

            try
                actDlg = feval(getDlgFcn);
                actDlg.openDialog(@dialogCloseCallback);
            catch ME
                % Send error to Simulink diagnostic viewer rather than a
                % DDG dialog.
                % NOTE: This does NOT stop execution.
                reportAsError(MSLDiagnostic(ME));
            end

            function dialogCloseCallback(isAcceptedSelection, selectedAct, selectedActType)
                if isAcceptedSelection
                    set_param(block, 'action', selectedAct);
                    set_param(block, 'actionType', selectedActType);
                    obj.updatePairedBlkMaskParam(block, 'action', selectedAct);
                    obj.updatePairedBlkMaskParam(block, 'actionType', selectedActType);
                end
            end
        end

        function actionTypeSelect(obj, block, getDlgFcn)
        %actionTypeSelect Callback for "Select" button on action type

            currentActionType = get_param(block, 'actionType');

            actDlg = feval(getDlgFcn);
            actDlg.openDialog(currentActionType, @dialogCloseCallback);

            function dialogCloseCallback(isAcceptedSelection, selectedAct)
                if isAcceptedSelection
                    set_param(block, 'actionType', selectedAct);
                    obj.updatePairedBlkMaskParam(block, 'actionType', selectedAct);
                end
            end
        end

        function updatePairedBlkMaskParam(~, block, maskParam, paramValue)
        %updatePairedBlkMaskParam Updates paired block mask parameters

            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            currBlkH = getSimulinkBlockHandle(block);
            pairedBlkH = pairBlkMgr.getPairedBlock(currBlkH);
            if pairedBlkH
                set_param(pairedBlkH,maskParam,paramValue);
                defaultPrompt = 'ros:slros2:blockmask:NoMonitorGoalPairedBlkPrompt';
                pairBlkMgr.updatePairedBlkHyperlink(currBlkH, defaultPrompt);
            end
        end
    end
end
