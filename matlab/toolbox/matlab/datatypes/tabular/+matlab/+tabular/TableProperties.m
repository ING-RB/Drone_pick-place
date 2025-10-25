classdef (Sealed) TableProperties < matlab.tabular.TabularProperties
% TABLEPROPERTIES Container for table metadata properties.
%   Access TABLEPROPERTIES using T.Properties, where T is a table.
%   TABLEPROPERTIES contains the following metadata:
%
%       Description           - A character vector describing the table
%       UserData              - A variable containing any additional information associated
%                               with the table.  You can assign any value to this property.
%       DimensionNames        - A two-element cell array of character vectors containing names
%                               of the dimensions of the table
%       VariableNames         - A cell array containing names of the variables in the table
%       VariableDescriptions  - A cell array of character vectors containing descriptions of
%                               the variables in the table
%       VariableUnits         - A cell array of character vectors containing units for the
%                               variables in table
%       VariableTypes         - A string array containing class names of each variable
%       RowNames              - A cell array of nonempty, distinct character vectors containing
%                               names of the rows in the table
%       CustomProperties      - A container for user-defined per-table or per-variable custom 
%                               metadata fields. Add custom properties using ADDPROP.

%   See also: TABLE.

%   Copyright 2018-2023 The MathWorks, Inc.

properties
    Description = ''
    UserData = []
    DimensionNames = {'Row' 'Variables'}
    VariableNames = cell(1,0)
    VariableTypes = string.empty(1,0)
    VariableDescriptions = {}
    VariableUnits = {}
    VariableContinuity = []
    RowNames = {}
    CustomProperties = matlab.tabular.CustomProperties();
end

    %%%% PERSISTENCE BLOCK ensures correct save/load across releases Properties %%
    %%%% Properties and methods in this block maintain the exact class schema %%%%
    %%%% required for TABLEPROPERTIES to persist through MATLAB releases %%%%%%%%%
    properties(Constant, Access='protected')
        % Version of this TABLEPROPERTIES serialization and deserialization
        % format. This is used for managing forward compatibility. Value is
        % saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   1.0 : 18b. first shipping version
        %   2.0 : 24a. VariableTypes Property.
        version = 2.0;
    end    
    
    methods(Hidden)
        function tp_serialized = saveobj(obj)
            tp_serialized               = saveobj@matlab.tabular.TabularProperties(obj);
            tp_serialized.RowNames      = obj.RowNames;
            tp_serialized.VariableTypes = obj.VariableTypes;
            
            % Set minimum version this schema is backward compatible to
            tp_serialized = obj.setCompatibleVersionLimit(tp_serialized, 1.0);
        end
    end
    
    methods(Hidden, Static)
        function obj = loadobj(tp_serialized)
            % LOADOBJ has knowledge of the ingredients needed to create a
            % TABLEPROPERTIES in the current version of MATLAB from a
            % serialized struct saved in either the current or previous
            % version; a serialized struct created in a future version of
            % MATLAB will have any new ingredients unknown to the current
            % version as fields of the struct, but those are never accessed

            % Always default construct an empty instance, and recreate a
            % proper TABLEPROPERTIES in the current schema using attributes
            % loaded from the serialized struct
            obj = matlab.tabular.TableProperties();
            
            % Return an empty instance if current version is below the
            % minimum compatible version of the serialized object
            if obj.isIncompatible(tp_serialized, 'MATLAB:table:IncompatibleLoadProperties')
                return;
            end
            
            obj = loadobj@matlab.tabular.TabularProperties(obj,tp_serialized);
            obj.RowNames = tp_serialized.RowNames;

            if tp_serialized.versionSavedFrom >= 2.0
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
            name = 'matlab.internal.coder.tabular.TableProperties';
        end
    end
end