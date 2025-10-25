% Util class for UITable to validate Selection property 
%
% Called from C++ when Selection property is set.



classdef TableSelectionValidator

    methods (Static)
        function validateSelection (storage, selection)
            
            import matlab.ui.internal.controller.uitable.utils.TableSelectionValidator;
            
            % validate selection against different selection type.
            switch storage.SelectionType
                case 'cell'
                    TableSelectionValidator.validateCellSelection(storage, selection);
                case 'row'
                    TableSelectionValidator.validateRowSelection(storage, selection);
                case 'column'
                    TableSelectionValidator.validateColumnSelection(storage, selection);
                otherwise
                    % Should not be here. Invalid selection type.
                    error('invalid selection type');
            end
            
            % validate selection against Multiselect.
            TableSelectionValidator.validateSingleSelection(storage, selection);
        end
        
        % validate selection against Multiselect
        function validateSingleSelection(storage, selection)
            % no validation for Multiselect 'on'
            if storage.Multiselect || isempty(selection)
                return;
            end
            
            switch storage.SelectionType
                case {'row', 'column'}
                    isValid = isscalar(selection);
                case'cell'
                    isValid = (size(selection, 1) == 1);
                otherwise
                    isValid = false;
                    % should not be here.
                    error('invalid selection type');
            end
            
            if (~isValid) 
                error(message('MATLAB:hg:gbtdatatypes:TableSelection:InvalidSingleSelection'));     
            end
        end
        
        % validate selection for rows
        function validateRowSelection(storage, selection)

            if isempty(selection) 
                return;
            end            
            
            % validate dimension N-by-1
            if ~isnumeric(selection) || size(selection, 1) > 1 
                error(message('MATLAB:hg:gbtdatatypes:TableSelection:InvalidRowSelection'));                
            end

            % validate data boundary
            invalidRows = selection > storage.DataDimension(1) | selection < 1;
            if any(invalidRows) 
                error(message('MATLAB:hg:gbtdatatypes:TableSelection:SelectionOutOfBoundary'));
            end
        end
        
        % validate selection for columns
        function validateColumnSelection(storage, selection)
            
            if isempty(selection) 
                return;
            end
            
            % validate dimension N-by-1
            if ~isnumeric(selection) || size(selection, 1) > 1
                error(message('MATLAB:hg:gbtdatatypes:TableSelection:InvalidColumnSelection'));                
            end    
            
            % validate data boundary
            invalidColumns = selection > storage.DataDimension(2) | selection < 1;
            if any(invalidColumns) 
                error(message('MATLAB:hg:gbtdatatypes:TableSelection:SelectionOutOfBoundary'));
            end            
        end  
        
        % validate selection input against cell selection type.
        function validateCellSelection(storage, selection)
            
            if isempty(selection) 
                return;
            end
            
            % validate dimension N-by-2
            if ~isnumeric(selection) || size(selection, 2) ~= 2
                error(message('MATLAB:hg:gbtdatatypes:TableSelection:InvalidCellSelection'));                
            end
            
            import matlab.ui.internal.controller.uitable.utils.*;
            
            % validate data boundary for row and column
            TableSelectionValidator.validateRowSelection(storage, selection(:,1)');
            TableSelectionValidator.validateColumnSelection(storage, selection(:,2)');
        end    
        
        % Calculate uitable data dimension
        function dim = calculateTableDataDimension(model)
            if ischar(model.Data) || isStringScalar(model.Data) 
                % single char
                dim = [1 1];
            else 
                dim = size(model.Data);
            end
        end

        % Clear selection which is out of bounds of Data
        function clearInvalidSelection(model)
            if isempty(model.Selection)
                return;
            end
            
            if isempty(model.Data)
                model.Selection = [];
            else
                dataSize = matlab.ui.internal.controller.uitable.utils.TableSelectionValidator.calculateTableDataDimension(model);
                selection = model.Selection;
                switch model.SelectionType
                    case 'cell'
                        selection = selection(selection(:,1) <= dataSize(1), :);
                        selection = selection(selection(:,2) <= dataSize(2), :);
                    case 'row'
                        selection = selection(selection <= dataSize(1));
                    case 'column'
                        selection = selection(selection <= dataSize(2));
                end
                if ~isequal(selection, model.Selection)
                    model.Selection = selection;
                end
            end
        end
        
    end
    
    
end