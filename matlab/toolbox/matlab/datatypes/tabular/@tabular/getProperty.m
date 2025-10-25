function [p,idxOp,translatedIndices] = getProperty(t,name,createIfEmpty)
%GETPROPERTY Get a table property.

%   Copyright 2012-2022 The MathWorks, Inc.

import matlab.tabular.Continuity
import matlab.internal.datatypes.isColon

if nargin < 3, createIfEmpty = false; end
translatedIndices = [];

% We may be given a name (when called from get), or an IndexingOperation
% that starts with a '.name' subscript (when called from
% dotReference/dotListLength). For both the cases, getProperty will return the
% property being asked for as the first output. When getProperty is called with
% an IndexingOperaion, it will also return the trailing part of the
% IndexingOperation left after extracting the property, and translatedIndices if
% the next level was using named-indexing.
if isa(name, 'matlab.indexing.IndexingOperation')
    idxOp = name;
    if idxOp(1).Type == matlab.indexing.IndexingOperationType.Dot
        name = idxOp(1).Name;
    else
        error(message('MATLAB:table:InvalidSubscript'));
    end
    haveIndexingOperation = true;
else
    % For this case there is no IndexingOperation or translatedIndices involved so
    % ensure that getProperty is only being called with one or zero outputs.
    nargoutchk(0,1);
    haveIndexingOperation = false;
end
% Allow partial match for property names if this is via the get method;
% require exact match if it is via dot subscripting.
name = tabular.matchPropertyName(name,t.propertyNames,haveIndexingOperation);
isPerVarCustomProp = false;

% Get the property out of the table.  Some properties need special handling
% when empty:  create either a non-empty default version or a "canonical" 0x0
% cell array (subscripting can sometimes make them 1x0 or 0x1), depending on
% what the caller asks for.
switch name
case {'RowNames' 'RowTimes'}
    if t.rowDim.hasLabels || ~createIfEmpty
        p = t.rowDim.labels;
    else
        p = t.rowDim.defaultLabels();
    end

% These three have already been verified present by matchPropertyName
case 'StartTime'
    p = t.rowDim.startTime;
case 'TimeStep'
    p = t.rowDim.timeStep;
case 'SampleRate'
    p = t.rowDim.sampleRate;
case 'Events'
    p = t.rowDim.timeEvents;
case 'EventLabelsVariable'
    p = t.varDim.eventLabelsVariable;
case 'EventLengthsVariable'
    p = t.varDim.eventLengthsVariable;
case 'EventEndsVariable'
    p = t.varDim.eventEndsVariable;
case 'VariableNames'
    p = t.varDim.labels;
    % varnames are "always there", so leave them 1x0 when empty
case 'DimensionNames'
    p = t.metaDim.labels;
case 'VariableDescriptions'
    p = t.varDim.descrs;
    if ~t.varDim.hasDescrs && createIfEmpty
        p = repmat({''},1,t.varDim.length);
    end
case 'VariableUnits'
    p = t.varDim.units;
    if ~t.varDim.hasUnits && createIfEmpty
        p = repmat({''},1,t.varDim.length);
    end
case 'VariableTypes'
    p = t.getVariableTypes();
case 'VariableContinuity'
    p = t.varDim.continuity;
    if ~t.varDim.hasContinuity && createIfEmpty
        p = repmat(Continuity.unset,1,t.varDim.length);
    end
case 'Description'
    p = t.arrayProps.Description;
case 'CustomProperties'
    % Construct CustomProperties object from per-var and per-table. Avoid
    % constructing the object if it's not needed.
    if ~haveIndexingOperation || isscalar(idxOp)
        p = matlab.tabular.CustomProperties(t.arrayProps.TableCustomProperties, t.varDim.customProps);
    elseif idxOp(2).Type ~= matlab.indexing.IndexingOperationType.Dot
        if idxOp(2).Type == matlab.indexing.IndexingOperationType.Brace
            error(message('MATLAB:table:CustomProperties:CellReferenceNotAllowed'))
        else % '()'
            error(message('MATLAB:table:CustomProperties:ParensReferenceNotAllowed'))
        end
    else
        % Get the particular custom property. Cascading subscripting
        % happens later.
        customPropName = idxOp(2).Name;
        if isfield(t.varDim.customProps, customPropName) % per-variable custom property
            isPerVarCustomProp = true;
            p = t.varDim.customProps.(customPropName);
        elseif isfield(t.arrayProps.TableCustomProperties, customPropName) % per-table custom property
            p = t.arrayProps.TableCustomProperties.(customPropName);
        else
            error(message('MATLAB:table:UnrecognizedCustomProperty',customPropName))
        end
        % Peel off the first layer of subscripting because it's already
        % done.
        idxOp = idxOp(2:end);
    end
case 'UserData'
    p = t.arrayProps.UserData;
end


% If getProperty was called with a property name, no further work is required
% and we can simply return the extracted property p. But if getProperty was
% called with an IndexingOperation we need to return the trailing
% IndexingOperation and also handle translation of subscripts.
if haveIndexingOperation
    % Strip off the first level from the IndexingOperation, since that has
    % already been handled above.
    idxOp = idxOp(2:end);

    % If there are more levels, then they might need translation. So figure that
    % out and update the translatedIndices if required.
    if ~isempty(idxOp)
        % If this is 1-D named parens/braces subscripting, convert
        % labels/subscripter objects to correct indices for properties that
        % support such subscripting. e.g. t.Properties.VariableUnits('SomeVarName')
        % For the other cases we leave the translatedIndices as [] to
        % inform the caller than next level does not require any translation.
        if (idxOp(1).Type ~= matlab.indexing.IndexingOperationType.Dot) && isscalar(idxOp(1).Indices) % () or {}
            sub = idxOp(1).Indices{1};
            % Keep track of whether or not a property supports named indexing.
            allowNamedIndexing = false;
            % Call subs2inds on all subscript types to get nice error
            % handling. subs2inds returns the indices as row/col/col vectors, but a
            % table's properties aren't "on the grid", and so should follow the usual
            % reshaping rules for subscripting. Call subs2inds with subsType
            % forwardedReference to ensure that the original shape is preserved
            % if both the subscript type and the dim object allow it.
            switch name
            case {'VariableNames' 'VariableDescriptions' 'VariableUnits' 'VariableContinuity' 'VariableTypes'}
                % Most subs2inds callers want a colon expanded out, here we don't.
                if isColon(sub)
                    inds = sub;
                else
                    inds = t.subs2inds(sub,'varDim',matlab.internal.tabular.private.tabularDimension.subsType_forwardedReference);
                end
                allowNamedIndexing = true;
            case {'RowNames' 'RowTimes'}
                % Allow subscripting into the row labels using things like,
                % withtol, timerange or patterns. This would also allow using
                % row labels to subscript into the row labels property. This
                % does not seem like something useful, but allow it for the sake
                % of completeness.
                inds = t.subs2inds(sub,'rowDim',matlab.internal.tabular.private.tabularDimension.subsType_forwardedReference);
                allowNamedIndexing = true;
            case 'DimensionNames'
                inds = t.subs2inds(sub,'metaDim',matlab.internal.tabular.private.tabularDimension.subsType_forwardedReference);
                allowNamedIndexing = true;
            case 'CustomProperties'
                % Only pre-variable CustomProperties support named-indexing.
                if isPerVarCustomProp
                    inds = t.subs2inds(sub,'varDim',matlab.internal.tabular.private.tabularDimension.subsType_forwardedReference);
                    allowNamedIndexing = true;
                end
            end
            
            % If the property allows named-indexing and subs were not numeric,
            % logical or colon, then subs2inds would have translated them into
            % numeric inds. Return those numeric indices as the
            % translatedIndices output. The caller would use it when forwarding
            % the expression. 
            % For properties, like Description, UserData, etc., that do not
            % allow text or subscripter based indexing, leave the indices
            % untouched. This would throw the appropriate error when the caller
            % forwards the subscripting expression.
            if allowNamedIndexing && ~(isnumeric(sub) || islogical(sub) || isColon(sub))
                translatedIndices = idxOp(1).Indices;
                translatedIndices{1} = inds;
            end
        end
    end
end