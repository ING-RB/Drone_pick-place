function t = setProperty(t,name,p)  %#codegen
%SETPROPERTY Set a table property.

%   Copyright 2019-2020 The MathWorks, Inc.

haveSubscript = false;

% Allow partial match for property names if this is via the set method;
% require exact match if it is direct assignment via subsasgn
name = tabular.matchPropertyName(name,t.propertyNames,haveSubscript);

% If we are not assigning into property, we want to error in one specific
% case, when the assignment is for the whole VariableContinuity property
% and the value being assigned is character vector.
coder.internal.errorIf(ischar(p) && strcmp(name,'VariableContinuity'), ...
    'MATLAB:table:InvalidContinuityFullAssignment');

% Assign the new property value into the dataset.
switch name
    case 'DimensionNames'
        coder.internal.assert(isequal(p, t.metaDim.labels), ...
            'MATLAB:table:UnsupportedPropertyChange', ...
            'DimensionNames', 'IfNotConst', 'Fail');
    case 'RowNames'
        coder.internal.assert(isequal(p, t.rowDim.labels), ...
            'MATLAB:table:UnsupportedPropertyChange', ...
            'RowNames');
    case 'RowTimes'
        t.rowDim = t.rowDim.setLabels(p); % error if duplicate, or empty
    case 'StartTime'
        t.rowDim = t.rowDim.setStartTime(p);
    case 'TimeStep'
        t.rowDim = t.rowDim.setTimeStep(p);
    case 'SampleRate'
        t.rowDim = t.rowDim.setSampleRate(p);
    case 'VariableNames'
        coder.internal.assert(isequal(p, t.varDim.labels), ...
            'MATLAB:table:UnsupportedPropertyChange', ...
            'VariableNames', 'IfNotConst', 'Fail');
    case 'VariableDescriptions'
        if iscell(p) && isequal(numel(p), numel(t.varDim.descrs))
            for i = 1:numel(p)
                coder.internal.errorIf(~coder.internal.isConst(size(p{i})) && ...
                    coder.internal.isConst(size(t.varDim.descrs{i})), ...
                    'MATLAB:table:CodegenPropertySizeMismatch', 'VariableDescriptions');
            end
        end
        t.varDim = t.varDim.setDescrs(p);
    case 'VariableUnits'
        if iscell(p) && isequal(numel(p), numel(t.varDim.units))
            for i = 1:numel(p)
                coder.internal.errorIf(~coder.internal.isConst(size(p{i})) && ...
                    coder.internal.isConst(size(t.varDim.units{i})), ...
                    'MATLAB:table:CodegenPropertySizeMismatch', 'VariableUnits');
            end
        end
        t.varDim = t.varDim.setUnits(p);
    case 'VariableContinuity'
        % Assigning single character vector to whole VariableContinuity property
        % should already be caught above.
        t.varDim = t.varDim.setContinuity(p);
    case 'Description'
        coder.internal.errorIf(~coder.internal.isConst(size(p)) && ...
            coder.internal.isConst(size(t.arrayProps.Description)), ...
            'MATLAB:table:CodegenPropertySizeMismatch', 'Description');
        t = t.setDescription(p);
    case 'UserData'
        coder.internal.errorIf(~coder.internal.isConst(size(p)) && ...
            coder.internal.isConst(size(t.arrayProps.UserData)), ...
            'MATLAB:table:CodegenPropertySizeMismatch', 'UserData');
        t = t.setUserData(p);
end
    
        
    
