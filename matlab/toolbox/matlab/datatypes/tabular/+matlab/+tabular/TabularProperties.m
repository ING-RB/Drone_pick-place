classdef (AllowedSubclasses = {?matlab.tabular.TableProperties ?matlab.tabular.TimetableProperties ?matlab.tabular.TallTableProperties ?matlab.tabular.TallTimetableProperties}) TabularProperties < matlab.mixin.internal.Scalar & matlab.internal.datatypes.saveLoadCompatibility
    % Internal abstract superclass for matlab.tabular.TableProperties and
    % matlab.tabular.TimetableProperties. This class is for internal use only
    % and will change in a future release. Do not use this class.
    
    %   Copyright 2018-2023 The MathWorks, Inc.
    
    properties ( Abstract )
        % Declare the properties common to all tables/timetables abstract
        % rather than having a mix of abstract and concrete properties in
        % order to preserve the order.
        Description
        UserData
        DimensionNames
        VariableNames
        VariableDescriptions
        VariableUnits
        VariableContinuity
        %RowNames/RowTimes
        CustomProperties
    end
    
    methods ( Hidden )
        function s = struct(obj)
            p = properties(obj);
            for idx = 1:numel(p)
                s.(p{idx}) = obj.(p{idx});
            end
        end
    	
        function disp(obj)
            name = inputname(1);
            h = matlab.internal.datatypes.DisplayHelper(class(obj));
            pnames = properties(obj);
            % remove CustomProperties because it is displayed separately.
            
            [vnames, tnames] = getNames(obj.CustomProperties);
            customNames = [tnames; vnames];
            if ~isempty(customNames)
                pnames(pnames == "CustomProperties") = [];
                h.addPropertyGroupNoTitle(obj, pnames);
                cpTitle = getString(message('MATLAB:table:TabularProperties:UIStringCustomPropertiesHeader'));
                h.addPropertyGroupCustomTitle(cpTitle, obj.CustomProperties, customNames)
            else
                h.addPropertyGroupNoTitle(obj, pnames);
                addpropLink = h.helpTextLink("addprop",getClass(obj) + "/addprop");
                rmpropLink = h.helpTextLink("rmprop",getClass(obj) + "/rmprop");
                h.replacePropDisp('CustomProperties', getString(message('MATLAB:table:TabularProperties:UIStringNoCustomPropertiesHeader', addpropLink,rmpropLink))); % "No custom properties are set..."
            end
            
            h.printToScreen(name,false);
        end
        
        function tp = fromScalarStruct(tp,s)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            %
            %   This function has no error checking. The input must be a scalar struct.
            assert(isscalar(s) && isstruct(s));
            fnames = fieldnames(s);
            for i = 1:numel(fnames)
                tp.(fnames{i}) = s.(fnames{i});
            end
        end
    end
    
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases Properties %%
    %%%% Properties and methods in this block maintain the exact class schema %%%%
    %%%% required for TabularProperties to persist through MATLAB releases %%%%%%%    
    methods(Hidden)
        function tp_serialized = saveobj(obj)
            % SAVEOBJ must maintain that all ingredients required to recreate
            % a valid TABULARPROPERTIES in this and previous version of MATLAB 
            % are present and valid in TP_SERIALIZED; any new ingredients
            % needed by future version are created in that version's LOADOBJ.
            % New ingredients MUST ONLY be saved as new fields in TP_SERIALIZED,
            % rather than as modifications to existing fields
            tp_serialized.CustomProperties      = saveobj(obj.CustomProperties);
            tp_serialized.Description           = obj.Description;
            tp_serialized.DimensionNames        = obj.DimensionNames;
            tp_serialized.UserData              = obj.UserData;
            tp_serialized.VariableNames         = obj.VariableNames;
            tp_serialized.VariableDescriptions  = obj.VariableDescriptions;
            tp_serialized.VariableUnits         = obj.VariableUnits;
            tp_serialized.VariableContinuity    = obj.VariableContinuity;
        end
        
        function obj = loadobj(obj, tp_serialized)
            % LOADOBJ has knowledge of the ingredients needed to create a
            % TABULARPROPERTIES in the current version of MATLAB from a
            % serialized struct saved in either the current or previous
            % version; a serialized struct created in a future version of
            % MATLAB will have any new ingredients unknown to the current
            % version as fields of the struct, but those are never accessed
                        
            % Restore serialized properties
            obj.CustomProperties     = matlab.tabular.CustomProperties.loadobj(tp_serialized.CustomProperties);
            obj.Description          = tp_serialized.Description;
            obj.DimensionNames       = tp_serialized.DimensionNames;
            obj.UserData             = tp_serialized.UserData;
            obj.VariableNames        = tp_serialized.VariableNames;
            obj.VariableDescriptions = tp_serialized.VariableDescriptions;
            obj.VariableUnits        = tp_serialized.VariableUnits;
            obj.VariableContinuity   = tp_serialized.VariableContinuity;
        end
    end
end

function classname = getClass(obj)
% Get the name of the class that contains the current TabularProperties object.
% This is used to get the class specific links for addprop and rmprop.

    switch class(obj)
        case 'matlab.tabular.TableProperties'
            classname = 'table';
        case 'matlab.tabular.TimetableProperties'
            classname = 'timetable';
        case 'matlab.tabular.TallTableProperties'
            classname = 'tall';
        case 'matlab.tabular.TallTimetableProperties'
            classname = 'tall';
        case 'matlab.tabular.EventtableProperties'
            classname = 'eventtable';    
        otherwise
            % All allowed classes should have been handled above
            assert(false);
    end
end
