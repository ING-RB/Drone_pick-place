classdef AppDesignerSimulinkBindModeHandler < handle
    % AppDesignerSimulinkBindModeHandler App Designer handler to enabling bind mode
    % and perform Bindings between Simulink Model elements & UI Components

    % Copyright 2022-2024 The MathWorks, Inc.

    properties
        BindModeSourceObj;
        BindData;
        AppModelId;
        SimulinkModelController;
    end

    methods
        % Constructor
        function obj = AppDesignerSimulinkBindModeHandler(bindData, appModelId, simulinkModelController)
            obj.BindModeSourceObj = appdesigner.internal.simulinkapps.AppDesignerSourceData(bindData.ModelName, obj);
            obj.BindData = bindData;
            obj.AppModelId = appModelId;
            obj.SimulinkModelController = simulinkModelController;
        end

        function openModel (obj)
            open_system(obj.BindModeSourceObj.modelName);
        end

        function closeModel (obj)
            close_system(obj.BindModeSourceObj.modelName);
        end

        function activate (obj)
            BindMode.BindMode.enableBindMode(obj.BindModeSourceObj);
        end

        function deactivate (obj)
            modelObj = get_param(obj.BindModeSourceObj.modelName, "Object");
            BindMode.BindMode.disableBindMode(modelObj);
        end

        function bindableData = getBindableData (obj, selectionHandles, ~)
            activeEditor = BindMode.utils.getLastActiveEditor();

            selectionFullPath = convertToCell(Simulink.BlockPath.fromHierarchyIdAndHandle(activeEditor.getHierarchyId, ...
                obj.getValidSelectionHandle(selectionHandles)));

            if ~(BindMode.utils.isSameModelInstance({obj.BindModeSourceObj.modelName}, selectionFullPath))
                bindableData.bindableRows = [];
                bindableData.emptyMessage = message('MATLAB:appdesigner:appdesigner:SimulinkModelRefNotSupportedForBind').string();
                bindableData.emptyMessageIsWarning = true;
                return;
            end

            % TO-DO: Replace the below condition with isModelUptoDate from
            % simulation object when it is ready
            updateDiagramNeeded = obj.isUpdatedDiagramNeeded(selectionHandles, selectionFullPath);

            if (updateDiagramNeeded)
                bindableData.bindableRows = [];
                bindableData.emptyMessage =  message('MATLAB:appdesigner:appdesigner:SimulinkModelUpdateDiagram').string();
                bindableData.emptyMessageIsWarning = true;
                bindableData.updateDiagramButtonRequired = true;
                return;
            end

            signalLogging = get_param(obj.BindModeSourceObj.modelName, 'SignalLogging');

            if (isequal(signalLogging, 'off') && isequal(BindMode.BindableTypeEnum.SLSIGNAL, obj.BindData.BindType))
                bindableData.bindableRows = [];
                bindableData.emptyMessage = message('MATLAB:appdesigner:appdesigner:SimulinkModelEnableSignalLogging').string();
                bindableData.emptyMessageIsWarning = true;
                return;
            end

            signalRows = [];
            parameterRows = [];
            bindablePropertyName = '';
            emptyMessage = '';
            emptyMessageIsWarning = false;

            if isequal(BindMode.BindableTypeEnum.SLSIGNAL, obj.BindData.BindType)
                signalRows = BindMode.utils.getSignalRowsInSelection(selectionHandles, true); % 2nd argument ensures that only logged signals are returned
                bindablePropertyName = 'SourceParameter';
            elseif isequal(BindMode.BindableTypeEnum.VARIABLE, obj.BindData.BindType)
                [parameterRows, updateDiagramNeeded] = BindMode.utils.getParameterRowsInSelection(selectionHandles, true); % 2nd argument ensures that only variables are returned
                % Output of getParameterRowsInSelection may include mask
                % workspace variables. So remove them from the list.
                for i = 1: length(parameterRows)
                    % Mask workspace variables have type as SLPARAMETER
                    if ~isequal(parameterRows{i}.bindableTypeChar, BindMode.BindableTypeEnum.VARIABLE)
                        parameterRows{i} = [];
                    end
                end

                parameterRows = parameterRows(~cellfun('isempty', parameterRows));

                % create rows for struct fields 
                if matlab.internal.feature("StructFieldBinding") == 1
                    parameterRows = obj.createParameterRowsForStructureFields(parameterRows, selectionHandles);                    
                end

                bindablePropertyName = 'DestinationParameter';
            end

            selectionRows = obj.filterUnsupportedBindableRows([parameterRows signalRows]);

            if ~isempty(obj.BindData.ExistingBindings)
                obj.updateRowConnectionStatus(selectionRows, bindablePropertyName, obj.BindData.BindType);
            end

            bindableRows = BindMode.utils.combineSelectedAndConnectedRows(selectionRows, []);

            if isempty(bindableRows)
                if isequal(BindMode.BindableTypeEnum.SLSIGNAL, obj.BindData.BindType)
                    emptyMessage = message('MATLAB:appdesigner:appdesigner:SimulinkModelNoSignalsFoundForBinding').string();
                else
                    emptyMessage = message('MATLAB:appdesigner:appdesigner:SimulinkModelNoVariablesFoundForBinding').string();
                end
                emptyMessageIsWarning = true;
            end

            bindableData.bindableRows = BindMode.utils.combineSelectedAndConnectedRows(selectionRows, []);
            bindableData.emptyMessage = emptyMessage;
            bindableData.emptyMessageIsWarning = emptyMessageIsWarning;
            bindableData.updateDiagramButtonRequired = updateDiagramNeeded;

        end

        function success = onRadioSelectionChange (obj, ~, bindableType, bindableName, bindableMetaData, isChecked)
            if isChecked
                componentData = struct();
                componentData.codeName = obj.BindData.ComponentCodeName;
                componentData.bindableProperty = obj.BindData.ComponentBindableProperty;
                bindableParameter = obj.getBindableParameterFromMetaData(bindableType, bindableMetaData);

                simulinkElementData = struct('bindableType', bindableType, 'bindableParameter', ...
                    bindableParameter, 'bindableMetaData', bindableMetaData, 'name', regexprep(bindableName,'[\n\r]',' '));

                if isequal(BindMode.BindableTypeEnum.VARIABLE, obj.BindData.BindType)
                    simulinkElementData.value = obj.SimulinkModelController.getSimulinkSimulation().TunableVariables.getVariableValue(bindableParameter);
                end

                obj.SimulinkModelController.ClientEventSender.sendEventToClient('bindingCompleted', {'simulinkElementData', simulinkElementData, 'componentData', componentData});
                success = true;
                obj.deactivate();
            else
                success = false;
            end
        end
    end

    methods(Access = private)
        function updateNeeded = isUpdatedDiagramNeeded (obj, selectionHandles, selectionFullPath) 
            updateNeeded = false;
            if isequal(BindMode.BindableTypeEnum.SLSIGNAL, obj.BindData.BindType)
                signalRows = BindMode.utils.getSignalRowsInSelection(selectionHandles, true);
                if ~isempty(signalRows)
                    blockPathStr = regexprep(signalRows{1}.bindableMetaData.blockPathStr,'[\n\r]',' ');
                    signalProperties = obj.SimulinkModelController.getSimulinkSimulation().LoggedSignals.getSignalProperties(blockPathStr, signalRows{1}.bindableMetaData.outputPortNumber);

                    % getSignalProperties uses the same condition as below
                    % to determine if the model is compiled. So, make sure
                    % to use the same condition here to avoid inconsistency.
                    if isempty(signalProperties.dimensions) || signalProperties.dimensions < 1
                        updateNeeded = true;
                    end
                end
            elseif isequal(BindMode.BindableTypeEnum.VARIABLE, obj.BindData.BindType)
                [~, updateNeeded] = BindMode.utils.getParametersUsedByBlk(selectionFullPath);
            end
        end


        function updateRowConnectionStatus (obj, bindableRows, bindablePropertyName, bindType)
            for i = 1 : numel(bindableRows)
                for j = 1 : numel(obj.BindData.ExistingBindings)
                    if isequal(obj.getBindableParameterFromMetaData(bindType, bindableRows{i}.bindableMetaData), obj.BindData.ExistingBindings(j).(bindablePropertyName))
                        bindableRows{i}.isConnected = true;
                        break;
                    end
                end
            end
        end

        function validSelectionHandle = getValidSelectionHandle (~, selectionHandles)
            validSelectionHandle = -1;
            for idx = 1 : numel(selectionHandles)
                if (selectionHandles(idx) ~= 0)
                    validSelectionHandle = selectionHandles(idx);
                    if (strcmp(get_param(validSelectionHandle, 'Type'), 'port'))
                        validSelectionHandle = get_param(get_param(validSelectionHandle, 'Parent'), 'Handle');
                    end
                    break;
                end
            end
        end

        function parameterName = getBindableParameterFromMetaData (obj, bindableType, bindableMetaData)
            if isequal(BindMode.BindableTypeEnum.SLSIGNAL, bindableType)
                blockPathStr = regexprep(bindableMetaData.blockPathStr,'[\n\r]',' ');
                parameterName = strcat(blockPathStr, ':', num2str(bindableMetaData.outputPortNumber));
            else
                if ((isfield(bindableMetaData, 'workspaceTypeStr') || isprop(bindableMetaData, 'workspaceTypeStr')) && ...
                        strcmp(bindableMetaData.workspaceTypeStr, 'model'))
                    parameterName = strcat(bindableMetaData.name, ':', obj.BindModeSourceObj.modelName);
                else
                    parameterName = bindableMetaData.name;
                end
            end
        end

        function bindableRows = filterUnsupportedBindableRows(obj, bindableRows)
            import appdesigner.internal.simulinkapps.AppDesignerSimulinkBindModeHandler;

            bindableDataTypes = AppDesignerSimulinkBindModeHandler.getBindableDataTypes();

            for i = 1: length(bindableRows)
                if isequal(BindMode.BindableTypeEnum.SLSIGNAL, obj.BindData.BindType)
                    blockPathStr = regexprep(bindableRows{i}.bindableMetaData.blockPathStr,'[\n\r]',' ');

                    signalProperties = obj.SimulinkModelController.getSimulinkSimulation().LoggedSignals.getSignalProperties(blockPathStr, bindableRows{i}.bindableMetaData.outputPortNumber);

                    if ~(signalProperties.isSignalTypeSupported && ...
                            any(strcmp(signalProperties.dataType, bindableDataTypes)))
                        bindableRows{i} = [];
                    end

                elseif isequal(BindMode.BindableTypeEnum.VARIABLE, obj.BindData.BindType)
                    bindableParameterName = obj.getBindableParameterFromMetaData(obj.BindData.BindType, bindableRows{i}.bindableMetaData);

                    variableValue = obj.SimulinkModelController.getSimulinkSimulation().TunableVariables.getVariableValue(bindableParameterName);

                    if ~(any(strcmp(class(variableValue), bindableDataTypes)) && isscalar(variableValue))
                        bindableRows{i} = [];
                    end
                end
            end

            bindableRows = bindableRows(~cellfun('isempty', bindableRows));
        end

        % given an array of BindMode.VariableMetaDatas, extract those whose corresponding
        % variables are structs
        function structVarMetadata = getStructVariableMetadataFromMetadataSet(obj, variableMetadata)
            arguments
                obj
                variableMetadata (1,:) BindMode.VariableMetaData
            end

            varNames = arrayfun(@(x) x.name, variableMetadata, 'UniformOutput', false);
            varEvaluator = @(x) obj.SimulinkModelController.getSimulinkSimulation().TunableVariables.getVariableValue(x);
            varValues = cellfun(@(x) varEvaluator(x), varNames, 'UniformOutput', false);
            structVarLocations = cellfun(@(x) isstruct(x), varValues);
            structVarMetadata = variableMetadata(structVarLocations);
        end

        function parameterRows = createParameterRowsForStructureFields(obj, parameterRows, selectionHandles) 
            if isempty(parameterRows)
                return
            end
            
            variableMetadata = cellfun(@(x) x.bindableMetaData, parameterRows);
            assert(isequal(class(variableMetadata), 'BindMode.VariableMetaData'));

            structVarMetadata = obj.getStructVariableMetadataFromMetadataSet(variableMetadata);
            fieldReferences = BindMode.utils.getPureStructReferencesInBlockDialogParameters(selectionHandles, structVarMetadata);
            structFieldRows = BindMode.utils.createBindableRowsFromFieldReferences(fieldReferences, structVarMetadata);

            parameterRows(end+1:end+numel(structFieldRows)) = structFieldRows;
        end
    end

    methods(Static=true)
        function bindableDataTypes = getBindableDataTypes()
            % GETBINDABLEDATATYPES - This method returns the list of
            % data types for which App Designer supports binding
            bindableDataTypes = {
                'double', ...
                'single', ...
                'int8', ...
                'int16', ...
                'int32', ...
                'int64', ...
                'uint8', ...
                'uint16', ...
                'uint32', ...
                'uint64', ...
                'logical', ...
                'boolean', ...
                };
        end
    end
end
