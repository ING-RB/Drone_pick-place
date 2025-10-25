classdef RegularTimetableType < matlab.coder.type.TabularType
    % Custom coder type for regular timetables
    
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
        StartTime;
        SampleRate;
        TimeStep;
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
            m.StartTime = {'rowDim.Properties.startTime',@(obj, val, access) ...
                obj.setTypeProperty('StartTime', 'Properties.rowDim.Properties.startTime', ...
                obj.validateStartTime(val,access), access)};
            m.SampleRate = {'rowDim.Properties.sampleRate',@(obj, val, access) ...
                obj.setTypeProperty('SampleRate', 'Properties.rowDim.Properties.sampleRate', ...
                obj.validateSampleRate(val,access), access)};
            m.TimeStep = {'rowDim.Properties.timeStep',@(obj, val, access) ...
                obj.setTypeProperty('TimeStep', 'Properties.rowDim.Properties.timeStep', ...
                obj.validateTimeStep(val,access), access)};
        end
        
        function x = validateStartTime(x,access)
            % do not validate when access is nonempty: type.StartTime.xxx = yyy
            if matlab.internal.coder.type.util.isFullAssignment(access)
                if isa(x, 'coder.Constant')
                    val = x.Value;
                elseif isa(x, 'coder.type.Base') % custom coder type
                    val = getCoderType(x);
                else
                    val = x;
                end
                
                if isa(val, 'coder.Type')
                    if strcmp(val.ClassName, 'datetime')
                        valid = isequal(val.Properties.data.SizeVector, [1 1]) && ...
                            ~any(val.Properties.data.VariableDims);
                    elseif strcmp(val.ClassName, 'duration')
                        valid = isequal(val.Properties.millis.SizeVector, [1 1]) && ...
                            ~any(val.Properties.millis.VariableDims);
                    else
                        valid = false;
                    end
                else
                    valid = isscalar(val) && (isdatetime(val) || isduration(val));
                end
                if ~valid
                    error(message('MATLAB:timetable:InvalidStartTimeType'));
                end
            end
        end
        
        function x = validateSampleRate(x,access)
            % do not validate when access is nonempty: type.SampleRate.xxx = yyy
            if matlab.internal.coder.type.util.isFullAssignment(access)
                if isa(x, 'coder.Constant')
                    val = x.Value;
                else
                    val = x;
                end
                
                if isa(val, 'coder.Type')
                    valid = isequal(val.SizeVector, [1 1]) && ~any(val.VariableDims) && ...
                        strcmp(val.ClassName, 'double');
                else
                    valid = isscalar(val) && isa(val,'double');
                end
                if ~valid
                    error(message('MATLAB:timetable:InvalidSampleRateType'));
                end
            end
        end
        
        function x = validateTimeStep(x,access)
            % do not validate when access is nonempty: type.TimeStep.xxx = yyy
            if matlab.internal.coder.type.util.isFullAssignment(access)
                if isa(x, 'coder.Constant')
                    val = x.Value;
                elseif isa(x, 'coder.type.Base') % custom coder type
                    val = getCoderType(x);
                else
                    val = x;
                end
                
                if isa(val, 'coder.Type')
                    valid = strcmp(val.ClassName, 'duration') && isequal(...
                        val.Properties.millis.SizeVector, [1 1]) && ~any(val.Properties.millis.VariableDims);
                else
                    valid = isscalar(val) && isduration(val);
                end
                if ~valid
                    error(message('MATLAB:timetable:InvalidTimeStepType'));
                end
            end
        end
    end
end