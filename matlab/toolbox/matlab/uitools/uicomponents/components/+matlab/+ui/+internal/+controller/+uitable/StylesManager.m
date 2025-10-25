classdef StylesManager < handle
    % STYLESMANAGER 
    
    %   Copyright 2021-2023 The MathWorks, Inc.
    
    properties(Constant, Access = 'private')
        HexString0to255 = string(dec2hex(0:255, 2));
    end
    
    properties (Access = 'private')
        Model   
        StyleStorage = matlab.ui.style.Style.empty;
        PreviousStylesTarget = string.empty;
    end
    
    methods        
        function obj = StylesManager(model)
            obj.Model = model;
        end
        
        function handleStylesConfigurationChanged(obj, controller)
            
            % update the local copy
            obj.StyleStorage = obj.Model.StyleConfigurationStorage;
            
            storage = obj.StyleStorage;
            
            if isempty(storage)
                return;
            end
            
            if ~any(storage.Dirty) && isempty(storage.RemovedTarget)
                return; 
            end
            
            % performance improvement for the last added Style 
            if any(find(storage.Dirty, 1, 'first') == size(storage.Dirty, 1)) && isempty(storage.RemovedTarget)
                % only the last style is added recently (dirty).
                obj.updateLastStyle(storage.Target(end), storage.TargetIndex{end}, controller);
            else
                % Otherwise, update metadata for all rows/columns
                rows = 1:size(obj.Model.Data,1);
                columns = 1:size(obj.Model.Data,2);

                % Get types to clear
                typesToClear = obj.getMetadataTypesToClear(storage.Target, obj.PreviousStylesTarget);            

                for type = typesToClear
                    switch type
                        case "cell"
                            obj.clearCellMetaData(controller, rows, columns);
                        case "row"
                            obj.clearRowMetaData(controller, rows);
                        case "column"
                            obj.clearColumnMetaData(controller, columns);
                        case "table"
                            obj.clearTableMetaData(controller);
                    end
                end
            end
            
            obj.PreviousStylesTarget = storage.Target;
            
            % Finally, clear dirty information for last style.
            matlab.ui.style.internal.StylesMetaData.clearDirty(obj.Model);
        end 

        function updateLastStyle(obj, target, index, controller)
            
            switch target
                case "cell"
                    obj.clearCellMetaData(controller, index(:, 1), index(:, 2));
                case "row"
                    obj.clearRowMetaData(controller, index);
                case "column"
                    if istable(obj.Model.Data) && (iscell(index) || ischar(index))
                        % convert char index (varialbe names in table data) 
                        % to number index.                    
                        columnNames = obj.Model.Data.Properties.VariableNames;
                        index = find(ismember(columnNames, index));
                    end
                    obj.clearColumnMetaData(controller, index);                
                case "table"
                    obj.clearTableMetaData(controller);
            end   
        end

        function ruleExists = hasStylesTable(obj)
            
            ruleExists = ~isempty(obj.StyleStorage);
        end
        
        function style = getStyleMetaData(obj, metadataType, varargin)
            % GETSTYLE - Compute all applicable rules for given cell and
            % return a struct of all style attributes based on all of the
            % satisfied rules
            computedStyle = struct();
            
            if strcmp(metadataType, 'cell')
                row = varargin{1};
                column = varargin{2};
            elseif strcmp(metadataType, 'row')
                row = varargin{1};
                column = 0;
            elseif strcmp(metadataType, 'column')
                row = 0;
                column = varargin{1};
            else % metadataType == 'table'
                row = 0;
                column = 0;
            end
            
            applicableIndices = obj.filterApplicableRules(metadataType, row, column);
            if ~isempty(applicableIndices)
                % TODO: Optimize this by iterating backwards through the table
                % & only applying style properties that have yet to be applied
                for ruleIndex = reshape(applicableIndices, 1, [])
                    computedStyle = obj.buildRuleStyle(computedStyle, ruleIndex);
                end
            end
            if isempty(fields(computedStyle))
                style = computedStyle;
            else
                % The computedStyle is a 1x2 struct with all style
                % properties
                % These need to be broken apart and captured as two
                % separate meta data properties, 'style', 'StyleRank'.
                style = struct();
                style.style = computedStyle(1);
                style.StyleRank = computedStyle(2);
            end
        end

        function markStylesDirty(obj)
            % Mark all styles as dirty
            matlab.ui.style.internal.StylesMetaData.markDirty(obj.Model);
        end
    end
    methods(Access = private)
        %% Clear Metadata
        
        function clearCellMetaData(obj, controller, sourceRow, column)
            % CLEARCELLMETADATA - Notify that the cell metadata has changed
            % Filter rows and columns not within the range of data
            if isnumeric(sourceRow) && isnumeric(column)
                % Remove rows and columns that are higher than the size of
                % the data
                dataSize = size(obj.Model.Data);
                sourceRow(sourceRow > dataSize(1)) = [];
                column(column > dataSize(2)) = [];
                controller.clearCellMetaData(sourceRow, column);
            end
        end
        
        function clearRowMetaData(obj, controller, sourceRow)
            % CLEARROWMETADATA - Notify that the row metadata has changed
            % Filter rows not within the range of data
            if isnumeric(sourceRow)
                % Remove rows and columns that are higher than the size of
                % the data
                dataSize = size(obj.Model.Data);
                sourceRow(sourceRow > dataSize(1)) = [];
                controller.clearRowMetaData(sourceRow);
            end
        end
        
        function clearColumnMetaData(obj, controller, column)
            % CLEARCOLUMNMETADATA - Notify that the column metadata has changed
            % Filter columns not within the range of data
            if isnumeric(column)
                % Remove rows and columns that are higher than the size of
                % the data
                dataSize = size(obj.Model.Data);
                column(column > dataSize(2)) = [];
                controller.clearColumnMetaData(column);
            end
        end
        
        function clearTableMetaData(obj, controller)
            % CLEARTABLEMETADATA - Notify that the table metadata has changed
            controller.clearTableMetaData();
        end
    end
    
    methods(Static)
        function hexColor = rgb2hex(rgbColor)
            % Convert from [0-1] RGB values to [0-255] RGB values
            
            % The HexString0to255 stores the hex verison of each color.
            % add 1 to this color array in order to shift from 
            % 0-255 (value) to 1-256 (array indices)
            colorValue = round(255 * rgbColor);
            colorIndices = colorValue + 1;
            hexColor = "#" + ...
                matlab.ui.internal.controller.uitable.StylesManager.HexString0to255(colorIndices(1)) + ...
                matlab.ui.internal.controller.uitable.StylesManager.HexString0to255(colorIndices(2)) + ...
                matlab.ui.internal.controller.uitable.StylesManager.HexString0to255(colorIndices(3));
        end
    end
    
    methods(Access = private)       
        function applicableIndices = filterApplicableRules(obj, metadataType, row, column)
            % FILTERAPPLICABLERULES - Return indices of obj.Model.StyleConfigurationStorage 
            % that only includes the rules for which styles should be applied
                    
            % Filter by metadata type
            matchesTarget = obj.StyleStorage.Target == metadataType;
            matchedTargetIndices = find(matchesTarget);
            
            % If no rule exists for this type of metadata, return
            if isempty(matchedTargetIndices)
                applicableIndices = [];
                return;
            end
            
            if any(strcmp(metadataType, {'row', 'column'}))

                % Filter by index
                if strcmp(metadataType, 'row')
                    rowOrColumnNumber = row;
                else
                    rowOrColumnNumber = column;
                end
                
                matchesIndex = obj.filterByRowOrColumnIndex(matchedTargetIndices, metadataType, rowOrColumnNumber);
                applicableIndices = matchedTargetIndices(matchesIndex);
                
            elseif strcmp(metadataType, 'cell')  % metadataType is cell
             
                % Filter by index
                matchesIndex = obj.filterByCellIndex(matchedTargetIndices, row, column);
                applicableIndices = matchedTargetIndices(matchesIndex);
                
            else % table metadata, no need to filter               
                applicableIndices = matchedTargetIndices;
            end
            
            % Filter by rule condition == true
            % 
            % computeRuleFcn = @(styleObj) obj.computeRule(styleObj, row, column);
            % ruleCriteriaMet = cellfun(computeRuleFcn, filteredStylesTable.Style);
            % filteredStylesTable = filteredStylesTable(ruleCriteriaMet, :);
        end
        
        function applicableIndices = filterByRowOrColumnIndex(obj, matchedTargetIndices, metadataType, rowOrColumnNumber)
            % FILTERBYINDEX - Filter the given styles table to only the
            % rules in which TargetIndex matches this row and/or column
            matchRowOrColumnFcn = @(index) obj.matchRowOrColumn(index, metadataType, rowOrColumnNumber);
            indexData = obj.StyleStorage.TargetIndex(matchedTargetIndices, :);
            matchesRowOrColumn = cellfun(matchRowOrColumnFcn, indexData);
            applicableIndices = find(matchesRowOrColumn);
        end
        
        function matchesRowOrColumn = matchRowOrColumn(obj, index, metadataType, rowOrColumnNumber)
            % MATCHROWORCOLUMN - Returns true or false depending if the
            % index contains the given row or column
            if isnumeric(index)
                matchesRowOrColumn = any(index == rowOrColumnNumber);
            elseif ((iscellstr(index) || ischar(index)) && ...
                    strcmp(metadataType, 'column') && ...
                    istable(obj.Model.Data))
                % Table column variable case
                tableVariableNames = obj.Model.Data.Properties.VariableNames;
                columnVariableName = tableVariableNames(rowOrColumnNumber);
                
                matchesRowOrColumn = any(strcmp(columnVariableName, index));
            else
                matchesRowOrColumn = false;
            end
        end
        
        function applicableIndices = filterByCellIndex(obj, matchedTargetIndices, row, column)
            % FILTERBYCELLINDEX - Filter the given styles table to only the
            % rules in which TargetIndex contains the given cell
            numMatchedStyles = size(matchedTargetIndices, 1);
            applicableIndices = zeros(numMatchedStyles, 1);
            matchedIndexData = obj.StyleStorage.TargetIndex(matchedTargetIndices, :);
            
            for i=1:numMatchedStyles
                index = matchedIndexData{i};
                % Check if an index matches the specified cell
                applicableIndices(i) = any(index(:, 1) == row & index(:,2) == column);
            end
            
            applicableIndices = find(applicableIndices);
        end
        
        % Method to be used for conditional styling.
        function ruleCriteriaMet = computeRule(obj, styleObj, row, column)
            % COMPUTERULE - Assesses if the rule is satisfied for the input
            % cell
            if obj.isStatic(styleObj)
                ruleCriteriaMet = true;
            else % Conditional rule
                data = obj.Model.Data{row, column};

                % Assume numeric comparison
                % TODO: All other use cases
                % TODO: Consider using sprintf if faster
                expression = [ num2str(data), styleObj.Condition{1}, num2str(styleObj.Condition{2})];
                
                % TODO: Consider using a lookup table for method names like
                % eq, ge, gt, etc. for performance reasons
                ruleCriteriaMet = eval(expression);
            end
        end
        
        function isStatic = isStatic(obj, styleObj)
            isStatic = isa(styleObj, 'matlab.ui.style.Style');
        end
       
        function computedStyle = buildRuleStyle(obj, computedStyle, ruleIndex)
            % BUILDRULESTYLE - Merge the given rule's style with the
            % existing computedStyle. All style attributes as part of this
            % this rule will overwrite its associated attributes in
            % computedStyle.
            % 
            % The computed Style will be a 1x2 struct array.  
            % computedStyle(1) is the attributes
            % computedStyle(2) is the rule index (relative to the entire
            % styles table)
            ruleStyle = obj.StyleStorage.Style(ruleIndex);


            if isa(ruleStyle, 'matlab.ui.style.Style')
                if ~isempty(ruleStyle.BackgroundColor)
                    computedStyle(1).backgroundColor = obj.rgb2hex(ruleStyle.BackgroundColor);
                    computedStyle(2).backgroundColor = ruleIndex;
                end
                if ~isempty(ruleStyle.FontColor)
                    computedStyle(1).color = obj.rgb2hex(ruleStyle.FontColor);
                    computedStyle(2).color = ruleIndex;
                end
    
                % These values do not require conversion.
                styleName = ["FontWeight", "FontAngle", "FontName", "HorizontalAlignment", "HorizontalClipping", "IconUri", "IconAlignment", "Interpreter"];
                metadataName = ["fontWeight", "fontStyle", "fontFamily", "textAlign", "textClip", "iconUri", "iconAlignment", "interpreter"];
    
                for idx = 1:numel(styleName)
                    value = ruleStyle.(styleName(idx));
                    if ~isempty(value)
                        computedStyle(1).(metadataName(idx)) = value;
                        computedStyle(2).(metadataName(idx)) = ruleIndex;
                    end
                end
            elseif isa(ruleStyle, 'matlab.ui.style.internal.SemanticStyle')
                if ~isempty(ruleStyle.BackgroundColor)
                    computedStyle(1).backgroundColor = "var(" + ruleStyle.BackgroundColor + ")";
                    computedStyle(2).backgroundColor = ruleIndex;
                end
                if ~isempty(ruleStyle.FontColor)
                    computedStyle(1).color = "var(" + ruleStyle.FontColor + ")";
                    computedStyle(2).color = ruleIndex;
                end
            elseif isa(ruleStyle, 'matlab.ui.style.internal.IconIDStyle')
                if ~isempty(ruleStyle.IconID)
                    computedStyle(1).iconID = ruleStyle.IconID;
                    computedStyle(2).iconID = ruleIndex;
                end
                if ~isempty(ruleStyle.Width)
                    computedStyle(1).iconWidth = ruleStyle.Width;
                    computedStyle(2).iconWidth = ruleIndex;
                end
                if ~isempty(ruleStyle.Height)
                    computedStyle(1).iconHeight = ruleStyle.Height;
                    computedStyle(2).iconHeight = ruleIndex;
                end
            elseif isa(ruleStyle, 'matlab.ui.style.Behavior')
                if ~isempty(ruleStyle.Editable)
                    computedStyle(1).editable = logical(ruleStyle.Editable);
                    computedStyle(2).editable = ruleIndex;
                end
            
            end
        end
    end
    
    methods (Static, Access = private)
        
               
        function typesToClear = getMetadataTypesToClear(target, previousTarget)
            % GETMETADATATYPESTOCLEAR - Use target and previous target
            % information to determine which metadata types require
            % clearing.  If type is a member of either group, the metadata
            % must be cleared.
            
            allTypes = ["table", "column", "row", "cell"];
            
            typesToClear = string.empty;
            
            for type = allTypes        
                if any(target == type) || any(previousTarget == type)
                    typesToClear = [typesToClear, type];
                end
            end
        end
    end    
end

