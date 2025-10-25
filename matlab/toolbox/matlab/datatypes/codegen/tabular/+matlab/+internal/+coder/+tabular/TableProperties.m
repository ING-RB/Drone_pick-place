classdef (Sealed) TableProperties < matlab.internal.coder.tabular.TabularProperties  %#codegen
% TABLEPROPERTIES Container for table metadata properties.

%   Copyright 2019-2020 The MathWorks, Inc.

properties
    Description = ''
    UserData
    DimensionNames = {'Row' 'Variables'}
    VariableNames = {}
    VariableDescriptions = {}
    VariableUnits = {}
    VariableContinuity = []
    RowNames = {}
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
end

methods (Static)    
    function out = matlabCodegenFromRedirected(t)
        out = matlab.tabular.TableProperties;
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
        out.RowNames = t.RowNames;
    end
    
    function out = matlabCodegenToRedirected(t)
        out = matlab.internal.coder.tabular.TableProperties;
        out.Description = t.Description;
        out.UserData = t.UserData;
        out.DimensionNames = t.DimensionNames;
        out.VariableNames = t.VariableNames;
        tablewidth = numel(t.VariableNames);
        if isempty(t.VariableDescriptions)
            out.VariableDescriptions = repmat({''},1,tablewidth);
        else
            out.VariableDescriptions = t.VariableDescriptions;
        end
        if isempty(t.VariableUnits)
            out.VariableUnits = repmat({''},1,tablewidth);
        else
            out.VariableUnits = t.VariableUnits;
        end
        % manual conversion from matlab.tabular.Continuity
        % to matlab.internal.coder.tabular.Continuity
        if isempty(t.VariableContinuity)
            if tablewidth > 0
                out.VariableContinuity = repmat(matlab.internal.coder.tabular.Continuity.unset,1,tablewidth);
            else
                out.VariableContinuity = [];
            end
        else            
            out.VariableContinuity = matlab.internal.coder.tabular.Continuity(cellstr(t.VariableContinuity));
        end
        out.RowNames = t.RowNames;
    end
    
    function result = matlabCodegenNontunableProperties(~)
        result = {'VariableNames', 'DimensionNames'};
    end
end


methods (Static, Hidden)
    function name = matlabCodegenUserReadableName
        % Make this look like a TableProperties (not the redirected TableProperties) in the codegen report
        name = 'TableProperties';
    end
end
end