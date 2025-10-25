classdef TimetableType < matlab.coder.type.TabularType
    % Custom coder type for timetables
    
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
        RowTimes;
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
            m.RowTimes = {'rowDim.Properties.labels',@(obj, val, access) ...
                obj.setTypeProperty('RowTimes', 'Properties.rowDim.Properties.labels',...
                obj.validateRowTimes(val,access), access)};
        end
    end
       
    methods (Hidden)
        function x = validateRowTimes(obj,x,access)
            % do not validate when access is nonempty: type.RowTimes.xxx = yyy
            if matlab.internal.coder.type.util.isFullAssignment(access)
                if isa(x, 'coder.Constant')
                    val = x.Value;
                elseif isa(x, 'coder.type.Base')
                    val = x.getCoderType();
                else
                    val = x;
                end
                nrows = obj.Size(1);
                varnrows = obj.VarDims(1);
                if isa(val, 'coder.Type')
                    if strcmp(val.ClassName, 'datetime')
                        valid = val.Properties.data.SizeVector(2) == 1 && ...
                            ~val.Properties.data.VariableDims(2);
                        isCorrectLength = (val.Properties.data.SizeVector(1) == nrows) && ...
                            (val.Properties.data.VariableDims(1) == varnrows);
                    elseif strcmp(val.ClassName, 'duration')
                        valid = val.Properties.millis.SizeVector(2) == 1 && ...
                            ~val.Properties.millis.VariableDims(2);
                        isCorrectLength = (val.Properties.millis.SizeVector(1) == nrows) && ...
                            (val.Properties.millis.VariableDims(1) == varnrows);
                    else
                        valid = false;
                    end
                else
                    valid = iscolumn(val) && (isdatetime(val) || isduration(val));
                    isCorrectLength = length(val) == nrows;
                end
                if ~valid
                    error(message('MATLAB:timetable:InvalidRowTimesType'));
                end
                if ~isCorrectLength
                    error(message('MATLAB:timetable:IncorrectRowTimesTypeLength'));
                end
            end
        end
    end
end