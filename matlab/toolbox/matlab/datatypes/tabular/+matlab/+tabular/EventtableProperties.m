classdef (Sealed) EventtableProperties < matlab.tabular.TimetableProperties & matlab.internal.datatypes.saveLoadCompatibilityExtension
% EVENTTABLEPROPERTIES eventtable metadata properties.
%   Access EVENTTABLEPROPERTIES using ET.Properties, where ET is an eventtable.
%   EVENTTABLEPROPERTIES contains the following metadata:
%
%       EventLabelsVariable   - The name of an existing variable to represent event
%                               labels. Enables named event subscripting in a
%                               timetable with an attached eventtable.
%       EventLengthsVariable  - The name of an existing duration variable to represent
%                               event lengths. Enables event interval subscripting in a
%                               timetable with an attached eventtable.
%       EventEndsVariable     - The name of an existing variable to represent the end
%                               timestamp of an event. Must be the same type as the
%                               event rowtimes.
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
%       RowTimes              - A datetime or durations vector containing times associated
%                               with each row in the timetable
%       StartTime             - First time value in the timetable
%       SampleRate            - For a timetable with a regularly-spaced time
%                               vector, the frequency of the samples
%       TimeStep              - For a timetable with a regularly-spaced time
%                               vector, the time interval between samples
%       CustomProperties      - A container for user-defined per-timetabletable or per-variable 
%                               custom metadata fields. Add custom properties using ADDPROP.

%   See also: EVENTTABLE, TIMETABLE, TIMETABLEPROPERTIES.

%   Copyright 2022-2023 The MathWorks, Inc.

    properties
        EventLabelsVariable = [];
        EventLengthsVariable = [];
        EventEndsVariable = [];
    end
    
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases Properties %%
    %%%% Properties and methods in this block maintain the exact class schema %%%%
    %%%% required for EVENTTABLEPROPERTIES to persist through MATLAB releases %%%%
    properties(Constant, Access='protected')
        % Version of this EVENTTABLEPROPERTIES serialization and deserialization
        % format. This is used for managing forward compatibility. Value is
        % saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   1.0 : 23a. first shipping version
        eventtablePropertiesVersion = 1.0;
    end
    
    methods(Hidden)
        function pnames = properties(~)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            % Get the list of property names from the parent class. Remove
            % Events from the list and add the eventtable specific properties.
            pnames = properties('matlab.tabular.TimetableProperties');
            pnames(pnames == "Events") = [];
            pnames = [{'EventLabelsVariable'; 'EventLengthsVariable'; 'EventEndsVariable'}; pnames];
        end

        function f = fieldnames(obj), f = properties(obj); end
        function f = fields(obj),     f = properties(obj); end
        
        function tf = isprop(obj,propName)
            %

            % The empty comment above is needed to inherit the M-help from
            % the isprop function.

            % No need to handle the case where obj is an array, since
            % EventtableProperties is required to be a scalar.
            import matlab.internal.datatypes.isScalarText
            tf = isScalarText(propName) && ismember(propName,properties(obj));
        end

        function ep_serialized = saveobj(obj)
            ep_serialized                      = saveobj@matlab.tabular.TimetableProperties(obj);
            ep_serialized.EventLabelsVariable  = obj.EventLabelsVariable;
            ep_serialized.EventLengthsVariable = obj.EventLengthsVariable;
            ep_serialized.EventEndsVariable    = obj.EventEndsVariable;
            
            ep_serialized = obj.setCompatibleVersionExtensionLimit(ep_serialized, ...
                ClassName="EventtableProperties", ...
                VersionNum=obj.eventtablePropertiesVersion, ...
                MinCompatibleVersion=1.0);
        end
    end
    
    methods(Hidden, Static)
        function obj = loadobj(ep_serialized)
            % LOADOBJ has knowledge of the ingredients needed to create a
            % EVENTTABLEPROPERTIES in the current version of MATLAB from a
            % serialized struct saved in either the current or previous
            % version; a serialized struct created in a future version of
            % MATLAB will have any new ingredients unknown to the current
            % version as fields of the struct, but those are never accessed

            % Always default construct an empty instance, and recreate a
            % proper EVENTTABLEPROPERTIES in the current schema using
            % attributes loaded from the serialized struct
            obj = matlab.tabular.EventtableProperties();

            % Return an empty instance if current version is below the
            % minimum compatible version of the serialized object.
            if obj.isIncompatibleVersionExtension(ep_serialized, ...
                    ClassName="EventtableProperties", ...
                    VersionNum=obj.eventtablePropertiesVersion, ...
                    WarnMsgId="MATLAB:eventtable:IncompatibleLoadProperties")
                return
            end
            
            tpObj = loadobj@matlab.tabular.TimetableProperties(ep_serialized);
            propNames = string(properties(tpObj));
            for i = 1:numel(propNames)
                obj.(propNames(i)) = tpObj.(propNames(i));
            end
            obj.EventLabelsVariable  = ep_serialized.EventLabelsVariable;
            obj.EventLengthsVariable = ep_serialized.EventLengthsVariable;
            obj.EventEndsVariable    = ep_serialized.EventEndsVariable;
        end
    end
end
