classdef (AllowedSubclasses = ?matlab.tabular.EventtableProperties) TimetableProperties < matlab.tabular.TabularProperties
% TIMETABLEPROPERTIES Container for timetable metadata properties.
%   Access TIMETABLEPROPERTIES using T.Properties, where T is a timetable.
%   TIMETABLEPROPERTIES contains the following metadata:
%
%       Description           - A character vector describing the timetable
%       UserData              - A variable containing any additional information associated
%                               with the timetable.  You can assign any value to this property.
%       DimensionNames        - A two-element cell array of character vectors containing names
%                               of the dimensions of the timetable
%       VariableNames         - A cell array containing names of the variables in the timetable
%       VariableDescriptions  - A cell array of character vectors containing descriptions of
%                               the variables in the timetable
%       VariableUnits         - A cell array of character vectors containing units for the
%                               variables in timetable
%       VariableTypes         - A string array containing class names of
%                               each variable
%       RowTimes              - A datetime or durations vector containing times associated
%                               with each row in the timetable
%       StartTime             - First time value in the timetable
%       SampleRate            - For a timetable with a regularly-spaced time
%                               vector, the frequency of the samples
%       TimeStep              - For a timetable with a regularly-spaced time
%                               vector, the time interval between samples
%       CustomProperties      - A container for user-defined per-timetabletable or per-variable 
%                               custom metadata fields. Add custom properties using ADDPROP.
%       Events                - eventtable for event-based subscripting of the timetable.

%   See also: TIMETABLE.

%   Copyright 2018-2022 The MathWorks, Inc.

properties
    Description = ''
    UserData = []
    DimensionNames = {'Time', 'Variables'};
    VariableNames = cell(1,0)
    VariableTypes = string.empty(1,0)
    VariableDescriptions = {}
    VariableUnits = {}
    VariableContinuity = []
    RowTimes = datetime.empty(0,1)
    StartTime = NaT
    SampleRate = NaN
    TimeStep = seconds(NaN)
    Events = [];
    CustomProperties = matlab.tabular.CustomProperties();
end

    %%%% PERSISTENCE BLOCK ensures correct save/load across releases Properties %%
    %%%% Properties and methods in this block maintain the exact class schema %%%%
    %%%% required for TIMETABLEPROPERTIES to persist through MATLAB releases %%%%%
    properties(Constant, Access='protected')
        % Version of this TIMETABLEPROPERTIES serialization and deserialization
        % format. This is used for managing forward compatibility. Value is
        % saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   1.0 : 18b. first shipping version
        %   2.0 : 23a. Events Property
        %   3.0 : 24a. VariableTypes Property
        version = 3.0;
    end    
    
    methods(Hidden)
        function tp_serialized = saveobj(obj)
            tp_serialized               = saveobj@matlab.tabular.TabularProperties(obj);
            tp_serialized.VariableTypes = obj.VariableTypes;
            tp_serialized.RowTimes      = obj.RowTimes;
            tp_serialized.StartTime     = obj.StartTime;
            tp_serialized.SampleRate    = obj.SampleRate;
            tp_serialized.TimeStep      = obj.TimeStep;
            tp_serialized.Events        = obj.Events;
            
            % Set minimum version this schema is backward compatible to
            tp_serialized = obj.setCompatibleVersionLimit(tp_serialized, 1.0);
        end
    end
    
    methods(Hidden, Static)
        function obj = loadobj(tp_serialized)
            % LOADOBJ has knowledge of the ingredients needed to create a
            % TIMETABLEPROPERTIES in the current version of MATLAB from a
            % serialized struct saved in either the current or previous
            % version; a serialized struct created in a future version of
            % MATLAB will have any new ingredients unknown to the current
            % version as fields of the struct, but those are never accessed

            % Always default construct an empty instance, and recreate a
            % proper TIMETABLEPROPERTIES in the current schema using
            % attributes loaded from the serialized struct
            obj = matlab.tabular.TimetableProperties();
            
            % Return an empty instance if current version is below the
            % minimum compatible version of the serialized object
            if obj.isIncompatible(tp_serialized, 'MATLAB:timetable:IncompatibleLoadProperties')
                return;
            end
            
            obj = loadobj@matlab.tabular.TabularProperties(obj,tp_serialized);
            obj.RowTimes     = tp_serialized.RowTimes;
            obj.StartTime    = tp_serialized.StartTime;
            obj.SampleRate   = tp_serialized.SampleRate;
            obj.TimeStep     = tp_serialized.TimeStep;

            if tp_serialized.versionSavedFrom >= 2.0
                obj.Events       = tp_serialized.Events;
            end

            if tp_serialized.versionSavedFrom >= 3.0
                obj.VariableTypes = tp_serialized.VariableTypes;
            else
                % Assign default values to variable types for older versions.
                n = numel(tp_serialized.VariableNames);
                obj.VariableTypes = string(repelem(missing,n));
            end
        end
        
        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.tabular.TimetableProperties';
        end
    end
end