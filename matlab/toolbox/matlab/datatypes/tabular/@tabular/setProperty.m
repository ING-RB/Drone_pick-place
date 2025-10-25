function t = setProperty(t,name,p)
%SETPROPERTY Set a table property.

%   Copyright 2012-2024 The MathWorks, Inc.

% We may be given a name (when called from set), or a subscript expression
% that starts with a '.name' subscript (when called from subsasgn).  Get the
% name and validate it in any case.

import matlab.tabular.Continuity
import matlab.internal.datatypes.defaultarrayLike
import matlab.internal.datatypes.throwInstead

if isa(name, 'matlab.indexing.IndexingOperation')
    idxOp = name;
    if idxOp(1).Type ~= matlab.indexing.IndexingOperationType.Dot
        error(message('MATLAB:table:InvalidSubscript'));
    end
    name = idxOp(1).Name;
    haveSubscript = true;
else
    haveSubscript = false;
end
% Allow partial match for property names if this is via the set method;
% require exact match if it is direct assignment via subsasgn
name = tabular.matchPropertyName(name,t.propertyNames,haveSubscript);

if haveSubscript && ~isscalar(idxOp)
    % If we are subscripting into a regular Property like VariableDescription,
    % VariableUnits, etc. then the second level might use var/row labels or if
    % we are indexing into CustomProperties, then the third level might use var
    % labels. These cases would require translating these labels into numeric
    % indices before we can forward the subscripting expression to the
    % underlying type. We use the translatedIndices, to store the these
    % translated values. If no translation is required, then translatedIndices
    % would be [].
    translatedIndices = [];
    indexingType = [];
    % If this is 1-D named parens/braces subscripting, convert labels to 
    % correct indices for properties that support subscripting with labels. 
    % e.g. t.Properties.RowNames('SomeRowName')
    if (idxOp(2).Type ~= matlab.indexing.IndexingOperationType.Dot) ...
            && isscalar(idxOp(2).Indices)
        indices = idxOp(2).Indices;
        indexingType = idxOp(2).Type;
        if matlab.internal.datatypes.isText(indices{1}) % a name, names, or colon
            translatedIndices = indices;
            switch name
            case {'VariableNames' 'VariableDescriptions' 'VariableUnits' 'VariableTypes' 'VariableContinuity'}
                translatedIndices{1} = t.subs2inds(translatedIndices{1},'varDim');
            case {'RowNames' 'RowTimes'}
                translatedIndices{1} = t.subs2inds(translatedIndices{1},'rowDim');
            case 'DimensionNames'
                translatedIndices{1} = t.subs2inds(translatedIndices{1},'metaDim'); 
            case  'CustomProperties' % Error for any non-dot subscript below t.Properties.CustomProperties
                error(message('MATLAB:table:InvalidSubscript'))
            end
        end
    end
    
    if name == "CustomProperties"
        % Because CustomProperties can be either per-variable or per-table, they
        % need to be handled separately. Avoid getProperty and constructing the
        % object. Instead, work directly on the custom props structs.
        if (idxOp(2).Type == matlab.indexing.IndexingOperationType.Dot) ... 
            && isfield(t.varDim.customProps,idxOp(2).Name) % per-variable
            isPerVar = true;
            customProps = t.varDim.customProps;
            % Support assignment to a single variable
            % (t.Properties.CustomProperties.prop(3) = x), by first filling the
            % variables with default of the right type and to ensure that
            % the properties are the same length as the width of the table.
            if numel(idxOp) > 2 && (idxOp(3).Type ~= matlab.indexing.IndexingOperationType.Dot)
                translatedIndices = idxOp(3).Indices;
                indexingType = idxOp(3).Type;
                % Support named subscript in () or {} on per-variable.
                translatedIndices{1} = t.subs2inds(translatedIndices{1},'varDim');
                if isequal(size(customProps.(idxOp(2))),[0,0])
                    % Support assigning to a particular element of a previously empty custom property. e.g. t.Properties.CustomProperties.Foo{3} = 'abc'
                    if indexingType == matlab.indexing.IndexingOperationType.Paren
                        defaultValue = defaultarrayLike(size(t.varDim.labels), 'like', p, false);
                    else % Brace
                        defaultValue = defaultarrayLike(size(t.varDim.labels), 'like', {p}, false);
                    end
                    customProps.(idxOp(2)) = defaultValue;
                end
                currentProp = customProps.(idxOp(2));
                currentProp = translatedAssign(currentProp,idxOp(3:end),translatedIndices,indexingType,p);
                customProps.(idxOp(2)) = currentProp;
            else
                customProps.(idxOp(2:end)) = p;
            end
            theProperty = customProps;
        elseif (idxOp(2).Type == matlab.indexing.IndexingOperationType.Dot) ...
                && isfield(t.arrayProps.TableCustomProperties,idxOp(2).Name) % per-table
            isPerVar = false;
            theProperty = t.arrayProps.TableCustomProperties;
            theProperty.(idxOp(2:end)) = p;
        else
            error(message('MATLAB:table:InvalidCustomPropName'))
        end
    else
        % If there's cascaded subscripting into the property, get the existing
        % property value and let the property's subsasgn handle the assignment.
        % The property may currently be empty, ask for a non-empty default
        % version to allow assignment into only some elements.
        theProperty = t.getProperty(name,true);

        % Patch up two cases for parenthesis assignment into the property. The parentheses
        % are necessarily the last level of subscripting, so this only affects assignments
        % directly to the tabular property's elements, never anything deeper.
        if idxOp(2).Type == matlab.indexing.IndexingOperationType.Paren ...
           && name ~= "UserData" % leave RHS of assignments to UserData alone even if it's a cellstr
            if isstring(p)
                % Properties that are cellstrs are not (yet) string-accepting, so
                % convert a string RHS (either scalar or non-scalar) to cellstr to make
                % assignments like t.Properties.VariableNames(1) = "X" work. Assignments
                % like t.Properties.VariableNames{1} = "X" won't work and shouldn't.
                if iscellstr(theProperty), p = cellstr(p); end %#ok<ISCLSTR>

            elseif isequal(p,'')
                % Assigning '' into a cellstr property like RowNames, VariableNames, or
                % DimensionNames using parens means deletion, and deleting a single value
                % from a per-row, per-variable, or per-dim property is not allowed, since
                % the number of elements must match the (meta)dimension length. Thus, an
                % error will be thrown later on for incorrect number of elements, which
                % will be confusing. But most likely deletion wasn't the user's intention
                % for these properties - they probably wanted to assign empty text, but
                % have done it incorrectly. Throw a better error here instead.
                %
                % VariableContinuity is cellstr-like, so same deal. For other properties
                % RowTimes/StartTime/TimeStep, SampleRate, VariableTypes, Description,
                % Event[Labels/Lengths/Ends]Variable, assigning '' does the expected thing.
                if iscellstr(theProperty) %#ok<ISCLSTR>
                    error(message('MATLAB:invalidConversion','cell','char'));
                elseif name == "VariableContinuity"
                    error(message('MATLAB:table:InvalidContinuityValue'));
                end           
            end
        end

        try
            theProperty = translatedAssign(theProperty,idxOp(2:end),translatedIndices,indexingType,p);
        catch ME
            if name == "VariableContinuity"
                % Throw an error that lists valid values as text, and avoids
                % mentioning matlab.tabular.Continuity.
                throwInstead(ME,"MATLAB:UnableToConvert","MATLAB:table:InvalidContinuityValue");
            elseif name == "VariableTypes"
                throwInstead(ME,"MATLAB:UnableToConvert","MATLAB:table:InvalidVariableTypes");
            else
                rethrow(ME);
            end
        end
    end
    p = theProperty;
    % The assignment may change the property's shape or size or otherwise make
    % it invalid; that gets checked by the individual setproperty methods called
    % below.
else
    % If we are not assigning into property, we want to error in one specific
    % case, when the assignment is for the whole VariableContinuity property
    % and the value being assigned is character vector.
    if ischar(p) && name == "VariableContinuity"
        error(message('MATLAB:table:InvalidContinuityFullAssignment')); 
    end
end

% Assign the new property value into the dataset.
try
    switch name
        case {'RowNames' 'RowTimes'}
            t.rowDim = t.rowDim.setLabels(p); % error if duplicate, or empty
        
        % These three have already been verified present by matchPropertyName
        case 'StartTime'
            t.rowDim = t.rowDim.setStartTime(p);
        case 'TimeStep'
            t.rowDim = t.rowDim.setTimeStep(p);
        case 'SampleRate'
            t.rowDim = t.rowDim.setSampleRate(p);
        case 'Events'
            t.rowDim = t.rowDim.setTimeEvents(p);
        case 'EventLabelsVariable'
            t.varDim = t.varDim.setEventLabelsVariable(p,t.data);
        case 'EventLengthsVariable'
            t.varDim = t.varDim.setEventLengthsVariable(p,t.data,class(t.rowDim.startTime));
        case 'EventEndsVariable'
            t.varDim = t.varDim.setEventEndsVariable(p,t.data,t.rowDim.startTime);
        case 'VariableNames'
            t.varDim = t.varDim.setLabels(p); % error if invalid, duplicate, or empty
            % Check for conflicts between the new VariableNames and the existing
            % DimensionNames. For backwards compatibility, a table will modify
            % DimensionNames and warn, while a timetable will error.
            t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
        case 'DimensionNames'
            t.metaDim = t.metaDim.setLabels(p); % error if duplicate, or empty
            % Check for conflicts between the new DimensionNames and the existing
            % VariableNames.
            t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
        case 'VariableDescriptions'
            t.varDim = t.varDim.setDescrs(p);
        case 'VariableUnits'
            t.varDim = t.varDim.setUnits(p);
        case 'VariableTypes'
            t = t.setVariableTypes(p);
        case 'VariableContinuity'
            % Assigning single character vector to whole VariableContinuity property
            % should already be caught above.
            t.varDim = t.varDim.setContinuity(p);
        case 'Description'
            t = t.setDescription(p);
        case 'UserData'
            t = t.setUserData(p);
        case 'CustomProperties'
            if ~haveSubscript || isscalar(idxOp)
                if isa(p,'matlab.tabular.CustomProperties')
                    % t.Properties.CustomProperties = p
                    % Assign CustomProperties object back into table.
                    [vnames, tnames] = getNames(p);
                    % First clear custom properties
                    t.varDim = t.varDim.setCustomProps(struct);
                    t.arrayProps.TableCustomProperties = struct;
                    for ii = 1:numel(vnames)
                        t.varDim = t.varDim.setCustomProp(p.(vnames{ii}),vnames{ii});
                    end
                    for ii = 1:numel(tnames)
                        t = t.setPerTableProperty(p.(tnames{ii}),tnames{ii});
                    end
                else
                    error(message('MATLAB:table:InvalidCustomPropertiesAssignment'))
                end
            else
                % Deeper assignment to a particular custom property. The
                % subscripted assignment was already done above, and it was
                % determined whether it is per-var or per-table, so just do
                % the assignment here.
                propName = idxOp(2).Name;
                if isPerVar
                    t.varDim = t.varDim.setCustomProp(p.(propName), propName);
                else % isPerTable
                    t = t.setPerTableProperty(p.(propName), propName);
                end
            end
    end
catch ME
    % Distinguish between full-assignment and partial assignment of variable
    % names and throw different messages.
    if ME.identifier == "MATLAB:table:InvalidVarNames" ...
            && (haveSubscript && ~isscalar(idxOp)) && (idxOp(2).Type == matlab.indexing.IndexingOperationType.Brace)
        error(message('MATLAB:table:InvalidVarNameBraces'));
    else
        rethrow(ME)
    end
end
        
    
function x = translatedAssign(x,idxOp,translatedIndices,indexingType,rhs)

if isempty(translatedIndices)
    x.(idxOp) = rhs;
elseif indexingType == matlab.indexing.IndexingOperationType.Brace
    if numel(idxOp) == 1
        x{translatedIndices{:}} = rhs;
    else
        x{translatedIndices{:}}.(idxOp(2:end)) = rhs;
    end
else
    if numel(idxOp) == 1
        x(translatedIndices{:}) = rhs;
    else
        x(translatedIndices{:}).(idxOp(2:end)) = rhs;
    end
end