classdef (Sealed) TallTimetableProperties < matlab.tabular.TabularProperties
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
%       RowTimes              - A tall datetime or durations vector containing times associated
%                               with each row in the timetable
%       CustomProperties      - A container for user-defined per-timetabletable or per-variable 
%                               custom metadata fields. Add custom properties using ADDPROP.
%                               

%   See also: TIMETABLE.

%   Copyright 2018 The MathWorks, Inc.

properties
    Description = ''
    UserData = []
    DimensionNames = {'Time', 'Variables'}
    VariableNames = cell(1,0)
    VariableDescriptions = {}
    VariableUnits = {}
    VariableContinuity = []
    RowTimes = tall(datetime.empty(0,1))
    CustomProperties = matlab.tabular.CustomProperties()
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
    version = 1.0;
end

methods(Hidden)
    function ttp_serialized = saveobj(obj)
    ttp_serialized              = saveobj@matlab.tabular.TabularProperties(obj);
    ttp_serialized.RowTimes     = obj.RowTimes;
    
    % Set minimum version this schema is backward compatible to
    ttp_serialized = obj.setCompatibleVersionLimit(ttp_serialized, 1.0);
    end
end

methods(Hidden, Static)
    function obj = loadobj(ttp_serialized)
    % LOADOBJ has knowledge of the ingredients needed to create a
    % TALLTIMETABLEPROPERTIES in the current version of MATLAB from
    % a serialized struct saved in either the current or previous
    % version; a serialized struct created in a future version of
    % MATLAB will have any new ingredients unknown to the current
    % version as fields of the struct, but those are never accessed
    
    % Always default construct an empty instance, and recreate a
    % proper TALLTIMETABLEPROPERTIES in the current schema using
    % attributes loaded from the serialized struct
    obj = matlab.tabular.TallTimetableProperties();
    
    % Return an empty instance if current version is below the
    % minimum compatible version of the serialized object
    if obj.isIncompatible(ttp_serialized, 'MATLAB:timetable:IncompatibleLoadProperties')
        return;
    end
    
    obj = loadobj@matlab.tabular.TabularProperties(obj,ttp_serialized);
    obj.RowTimes     = ttp_serialized.RowTimes;
    end
end
end