classdef TableType < matlab.coder.type.TabularType
    % Custom coder type for tables
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
        Data;
        Description;
        UserData;
        DimensionNames;
        VariableNames;
        VariableDescriptions;
        VariableUnits;
        VariableContinuity;
        RowNames;
    end
    
    methods (Static, Hidden)
        function m = map()
            m.Data = {'data',@(obj, val, access) ...
                obj.setTypeProperty('Data', 'Properties.data',...
                obj.validateData(val,access), access)};
            m.Description = {'arrayProps.Fields.Description',@(obj, val, access) ...
                obj.setTypeProperty('Description', 'Properties.arrayProps.Fields.Description', ...
                obj.validateDescription(val,access), access)};
            m.UserData = 'arrayProps.Fields.UserData';
            m.DimensionNames = {'metaDim.Properties.labels',@(obj, val, access) ...
                obj.setTypeProperty('DimensionNames', 'Properties.metaDim.Properties.labels', ...
                obj.validateDimensionNames(val,access), access)};
            m.VariableNames = {'varDim.Properties.labels',@(obj, val, access) ...
                obj.setTypeProperty('VariableNames', 'Properties.varDim.Properties.labels', ...
                obj.validateVariableNames(val,access), access)};
            m.VariableDescriptions = {'varDim.Properties.descrs',@(obj, val, access) ...
                obj.setTypeProperty('VariableDescriptions', 'Properties.varDim.Properties.descrs',...
                obj.validateVariableDescriptions(val,access), access)};
            m.VariableUnits = {'varDim.Properties.units',@(obj, val, access) ...
                obj.setTypeProperty('VariableUnits', 'Properties.varDim.Properties.units',...
                obj.validateVariableUnits(val,access), access)};  
            m.VariableContinuity = {'varDim.Properties.continuity',@(obj,val,access) ...
                obj.setTypeProperty('VariableContinuity', 'Properties.varDim.Properties.continuity',...
                obj.validateVariableContinuity(val,access), access)};
            m.RowNames = {'rowDim.Properties.labels',@(obj, val, access) ...
                obj.setTypeProperty('RowNames', 'Properties.rowDim.Properties.labels',...
                obj.validateRowNames(val,access), access)};
        end
    end
       
    methods (Hidden)
        function x = validateRowNames(obj,x,access)
            if isa(x, 'coder.Constant')
                val = x.Value;
            else
                val = x;
            end
            nrows = obj.Size(1);
            if ~matlab.internal.coder.type.util.isFullAssignment(access) 
                if numel(access) == 2 && isequal({access.type}, {'.', '{}'}) && ...
                        strcmp(access(1).subs, 'Cells')
                    % assigning individual cell
                    valid = matlab.internal.coder.type.util.isCharRowType(val, false); % don't allow empty char
                else
                    % for all other assignments type.RowNames.xxx = yyy,
                    % do not validate
                    valid = true;
                end
                isCorrectLength = true;
            else
                if isa(val, 'coder.Type')
                    % allow variable size
                    isEmptyType = isequal(val.SizeVector,[0 0]);
                    isColumnOrEmptyType = val.SizeVector(2) == 1 || isEmptyType;
                    isCorrectLength = (val.SizeVector(1) == nrows) || isEmptyType;
                else
                    isEmptyType = isequal(size(val),[0 0]);
                    isColumnOrEmptyType = iscolumn(val) || isEmptyType;
                    isCorrectLength = (length(val) == nrows) || isEmptyType;
                end
                valid = isColumnOrEmptyType && matlab.internal.coder.type.util.isCellstrType(val,false); % don't allow empty char
            end
            if ~valid
                error(message('MATLAB:table:InvalidRowNamesType'));
            end
            if ~isCorrectLength
                error(message('MATLAB:table:IncorrectRowNamesTypeLength'));
            end
        end
    end

end