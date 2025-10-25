classdef (Hidden) StylesMetaData
    % StylesMetaData - This class is used to support serialization of the
    % StylesConfiguration.
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties
        % These properties are serialized in the context of Table and Tree
        Target = string.empty;
        TargetIndex = cell.empty;
        Style = matlab.ui.style.Style.empty;
        Dirty = logical.empty;
    end
    properties(Transient)
        % save removed style targets for StylesManager to clear view metadata.
        RemovedTarget = string.empty;
        RemovedTargetIndex = cell.empty;
    end
    
    methods (Static)
        function storage = initialStyleConfigurationStorage()
            storage = matlab.ui.style.internal.StylesMetaData;
        end
        
        function styleConfiguration = createStyleConfigurations(model, targetEnums) 

            if isempty(model.StyleConfigurationStorage)
                storage = matlab.ui.style.internal.StylesMetaData;
            else
                storage = model.StyleConfigurationStorage;
            end
            
            if nargin == 1
                % By default, assume that this is uitable so that existing
                % code does not break.
                targetEnums = {'table', 'column', 'row', 'cell'};
            end
            
            % create a categorical target list
            target = categorical(storage.Target, ...
                     targetEnums, ...
                     'Protected', true);
            % create table.
            styleConfiguration = table(target, ...
                                       storage.TargetIndex, ...
                                       storage.Style);
            % set row names.
            styleConfiguration.Properties.RowNames = string(1:height(styleConfiguration));
            
            % set column names
            styleConfiguration.Properties.VariableNames = {'Target', 'TargetIndex', 'Style'};
        end
        
        function addStyle(model, newTarget, newIndex, newStyle)
            
            if isempty(model.StyleConfigurationStorage)
                newValue = matlab.ui.style.internal.StylesMetaData;
            else
                newValue = model.StyleConfigurationStorage;
            end
            
            newValue.Target = [newValue.Target ; newTarget];
            newValue.TargetIndex = [newValue.TargetIndex ; newIndex];
            newValue.Style = [newValue.Style ; newStyle];
            newValue.Dirty = [newValue.Dirty ; true];
            
            % public set to trigger property update in controller.
            model.StyleConfigurationStorage = newValue;
        end
        
        % Remove styles from the storage meanwhile save removed styles to clear view metadata. 
        function removeStyle(model, indexType, indices)           

            switch indexType
                case 'all'
                    % create an empty storage.
                    newValue = matlab.ui.style.internal.StylesMetaData;
                    
                    % save removed styles.
                    newValue.RemovedTarget = [model.StyleConfigurationStorage.RemovedTarget; model.StyleConfigurationStorage.Target];
                    newValue.RemovedTargetIndex = [model.StyleConfigurationStorage.RemovedTargetIndex; model.StyleConfigurationStorage.TargetIndex];

                case 'numeric'
                    
                    originalValue = model.StyleConfigurationStorage;
                    
                    if any(indices > size(originalValue.Target, 1))
                        messageObject = message('MATLAB:ui:style:removalIndexOutOfBounds', ...
                                                'StyleConfigurations');
                        me = MException('MATLAB:ui:Table:removalIndexOutOfBounds', ...
                                        messageObject.getString());
                        throw(me);
                    end                   
                    
                    if numel(originalValue.Target) == numel(unique(indices))
                        % Initialize styles configuration as empty when all
                        % styles are  being removed without adjusting
                        % RemovedTarget
                        newValue = matlab.ui.style.internal.StylesMetaData;
                    else
                        newValue = originalValue;

                        % Then, remove from the storage.
                        newValue.Target(indices) = [];
                        newValue.TargetIndex(indices) = [];
                        newValue.Style(indices) = [];
                        newValue.Dirty(indices) = [];

                        % Finally, need to mark all remaining styles dirty.
                        rows = size(newValue.Dirty, 1);
                        newValue.Dirty = true(rows, 1);
                    end

                    % Capture removed targets to refresh view.
                    newValue.RemovedTarget = [originalValue.RemovedTarget ; originalValue.Target(indices)];
                    newValue.RemovedTargetIndex = [originalValue.RemovedTargetIndex ; originalValue.TargetIndex(indices)];
            end
            
            % public set to trigger property update in controller.
            model.StyleConfigurationStorage = newValue;
        end  
        
        function clearDirty(model)
            
            newValue = model.StyleConfigurationStorage;
            
            if isempty(newValue)
                return;
            end
            
            % clear dirty
            newValue.Dirty = false(size(newValue.Dirty, 1), 1);
            
            % clear removed styles if any.
            if ~isempty(newValue.RemovedTarget)
                newValue.RemovedTarget = string.empty;
                newValue.RemovedTargetIndex = cell.empty;
            end
            
            model.StyleConfigurationStorage = newValue;
        end        

        function markDirty(model, indices)
            % Mark all styles dirty unless indices are specified
            newValue = model.StyleConfigurationStorage;
            
            if isempty(newValue)
                return;
            end

            if nargin == 1
                % mark all dirty
                newValue.Dirty = true(size(newValue.Dirty));
            elseif nargin == 2
                % otherwise mark dirty at specific indices
                newValue.Dirty(indices) = true;
            end
            
            % Update StyleConfigurationStorage
            model.StyleConfigurationStorage = newValue;
        end        
          
    end
end
