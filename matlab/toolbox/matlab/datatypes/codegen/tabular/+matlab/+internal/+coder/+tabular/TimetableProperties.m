classdef (Sealed) TimetableProperties < matlab.internal.coder.tabular.TabularProperties  %#codegen
% TIMETABLEPROPERTIES Container for timetable metadata properties.

%   Copyright 2019-2020 The MathWorks, Inc.

properties
    Description = ''
    UserData = []
    DimensionNames = {'Time', 'Variables'};
    VariableNames = cell(1,0)
    VariableDescriptions = {}
    VariableUnits = {}
    VariableContinuity = []    
    SampleRate = NaN    
end

properties (Dependent)
    RowTimes
    StartTime
    TimeStep
end
    
properties (Access = ?matlab.internal.coder.timetable)
    RowTimes_I
    StartTime_I = seconds(NaN)
    TimeStep_I = seconds(NaN)
end

methods
    function props = set.VariableDescriptions(props, newDescrs)
        % reshape to a row
        if iscell(newDescrs) && isempty(newDescrs)
            props.VariableDescriptions = cell(1,0);
        else
            props.VariableDescriptions = reshape(newDescrs,1,[]);
        end
    end
    
    function props = set.VariableUnits(props, newUnits)
        % reshape to a row
        if iscell(newUnits) && isempty(newUnits)
            props.VariableUnits = cell(1,0);
        else
            props.VariableUnits = reshape(newUnits,1,[]);
        end
    end
    
    function props = set.VariableContinuity(props, newContinuity)
        % reshape to a row
        if isnumeric(newContinuity) && isempty(newContinuity)
            props.VariableContinuity = [];
        elseif ~isa(newContinuity, 'matlab.internal.coder.tabular.Continuity') && ...
                (iscellstr(newContinuity) || isstring(newContinuity))
            if isstring(newContinuity)
                newContinuityC = cellstr(newContinuity);  % convert strings to cellstr
            else
                newContinuityC = newContinuity;
            end
            v = repmat(matlab.internal.coder.tabular.Continuity.unset,1,numel(newContinuityC));
            for i = 1:numel(newContinuityC)
                [v(i),isValidName] = coder.internal.enumNameToValue(newContinuityC{i},...
                    'matlab.internal.coder.tabular.Continuity',false);
                coder.internal.assert(isValidName, 'MATLAB:table:InvalidContinuityValue');
            end
            props.VariableContinuity = v;
        else
            props.VariableContinuity = reshape(newContinuity,1,[]);
        end
    end
    
    function rowtimes = get.RowTimes(props)
        rowtimes = props.RowTimes_I;
    end
    
    function props = set.RowTimes(props, rowtimes)
        % reshape to a column
        rowtimescol = reshape(rowtimes,[],1);
        if isa(rowtimescol, 'duration')
            % match the duration format
            props.RowTimes_I = duration.fromMillis(milliseconds(rowtimescol), ...
                props.RowTimes_I.Format);
        else
            props.RowTimes_I = rowtimescol;
        end
    end
    
    function starttime = get.StartTime(props)
        starttime = props.StartTime_I;
    end
    
    function props = set.StartTime(props, starttime)
        if isa(starttime, 'duration')
            % match the duration format               
            props.StartTime_I = duration.fromMillis(milliseconds(starttime), ...
                props.StartTime_I.Format);
        else
            props.StartTime_I = starttime;
        end
    end
    
    function timestep = get.TimeStep(props)
        timestep = props.TimeStep_I;
    end
    
    function props = set.TimeStep(props, timestep)
        if isa(timestep, 'duration')
            % match the duration format
            props.TimeStep_I = duration.fromMillis(milliseconds(timestep), ...
                props.TimeStep_I.Format);
        else
            props.TimeStep_I = timestep;
        end
    end
end

methods (Static)
    function out = matlabCodegenFromRedirected(t)
        out = matlab.tabular.TimetableProperties;
        % use strtrim to convert all empties into 0x0
        out.Description = strtrim(t.Description);
        out.UserData = t.UserData;
        out.DimensionNames = t.DimensionNames;
        out.VariableNames = t.VariableNames;
        if ~all(cellfun('isempty', t.VariableDescriptions))            
            out.VariableDescriptions = strtrim(t.VariableDescriptions);
        end
        if ~all(cellfun('isempty', t.VariableUnits))
            out.VariableUnits = strtrim(t.VariableUnits);
        end
        if ~isempty(t.VariableContinuity) && ~all(t.VariableContinuity == 'unset')
            % manual conversion from matlab.internal.coder.tabular.Continuity
            % to matlab.tabular.Continuity
            out.VariableContinuity = matlab.tabular.Continuity(cellstr(t.VariableContinuity));
        end
        out.RowTimes = t.RowTimes;
        out.StartTime = t.StartTime;
        out.SampleRate = t.SampleRate;
        out.TimeStep = t.TimeStep;
    end
    
    function out = matlabCodegenToRedirected(t)
        out = matlab.internal.coder.tabular.TimetableProperties;
        out.Description = t.Description;
        out.UserData = t.UserData;
        out.DimensionNames = t.DimensionNames;
        out.VariableNames = t.VariableNames;
        timetablewidth = numel(t.VariableNames);
        if isempty(t.VariableDescriptions)
            out.VariableDescriptions = repmat({''},1,timetablewidth);
        else
            out.VariableDescriptions = t.VariableDescriptions;
        end
        if isempty(t.VariableUnits)
            out.VariableUnits = repmat({''},1,timetablewidth);
        else
            out.VariableUnits = t.VariableUnits;
        end
        % manual conversion from matlab.tabular.Continuity
        % to matlab.internal.coder.tabular.Continuity
        if isempty(t.VariableContinuity)
            if timetablewidth > 0
                out.VariableContinuity = repmat(matlab.internal.coder.tabular.Continuity.unset,1,timetablewidth);
            else
                out.VariableContinuity = [];
            end
        else            
            out.VariableContinuity = matlab.internal.coder.tabular.Continuity(cellstr(t.VariableContinuity));
        end
        out.RowTimes = t.RowTimes;
        out.StartTime = t.StartTime;
        out.SampleRate = t.SampleRate;
        out.TimeStep = t.TimeStep;
    end
    
    function result = matlabCodegenNontunableProperties(~)
        result = {'VariableNames', 'DimensionNames'};
    end
end

methods (Static, Hidden)
    function name = matlabCodegenUserReadableName
        % Make this look like a TimetableProperties (not the redirected 
        % TimetableProperties) in the codegen report
        name = 'TimetableProperties';
    end
end
end