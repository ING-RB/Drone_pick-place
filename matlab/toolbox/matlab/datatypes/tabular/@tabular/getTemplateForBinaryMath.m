function [template,rowOrder,varOrder] = getTemplateForBinaryMath(A,B,fun,unitsHelper)
%

% GETTEMPLATEFORBINARYMATH Helper function to get the template for
% tabular binary math operations.
%
% The template will have the correct class, as well as appropriately merged
% metadata. Since binary arithmetic functions do not require both tabular
% inputs to have the same row and variable order, this function also helps
% determines the appropriate row and var order that should be used for the
% second input when applying the arithmetic function.
%
% The tables must have the same var and row labels, but they can be in a
% different order. Use the first input to determine the order for the output.
% Also keep track of how the vars and rows of the second input need to be
% reordered.

%   Copyright 2023-2024 The MathWorks, Inc.

[tf,varOrder] = ismember(A.varDim.labels,B.varDim.labels);
if ~(A.varDim.length == B.varDim.length && sum(tf) == B.varDim.length)
    % Both inputs must have the same variables.
    error(message('MATLAB:table:math:DifferentVars'));
end

% By default start with rowOrder set to [], which would mean no reordering
% required. This would change if both A and B have row labels that are in
% different order.
rowOrder = [];
if A.rowDim.hasLabels && B.rowDim.hasLabels
    % If both inputs have row labels then implicit expansion is not supported so
    % they must have the same height. We throw a more helpful error for the case
    % when we suspect implicit expansion.
    if A.rowDim.length ~= B.rowDim.length
        if A.rowDim.length == 1 || B.rowDim.length == 1
            error(message('MATLAB:table:math:ImplicitExpansionRowLabels'));
        else
            error(message('MATLAB:table:math:WrongHeight'));
        end
    elseif ~matches(class(A.rowDim.labels),class(B.rowDim.labels))
        % When both inputs have row labels, they must be of the same type.
        error(message('MATLAB:table:math:MixedRowLabels'));
    end
    % Both inputs are either tables w row names or timetables, so select the
    % first input A as the template and get the row order for B.
    template = A;
    % Row labels can be in different order, so sort them before checking for
    % equality.
    [ASortedLabels,AOrder] = sort(A.rowDim.labels);
    [BSortedLabels,BOrder] = sort(B.rowDim.labels);
    if ~isequal(ASortedLabels,BSortedLabels)
        % Both inputs must have the same row labels.
        error(message('MATLAB:table:math:DifferentRowLabels'));
    end
    rowOrder(AOrder) = BOrder;
elseif A.rowDim.hasLabels
    % A is either a table with row names or a timetable and B is a table without
    % row names, so verify B's height and use A as our template.
    if A.rowDim.length ~= B.rowDim.length && B.rowDim.length ~= 1
        error(message('MATLAB:table:math:WrongHeight'));
    end
    template = A;
elseif B.rowDim.hasLabels
    % B is either a table with row names or a timetable and A is a table without
    % row names, so verify A's height and use B as our template.
    if A.rowDim.length ~= B.rowDim.length && A.rowDim.length ~= 1
        error(message('MATLAB:table:math:WrongHeight'));
    end
    template = B;
else % both A and B do not have labels
    if A.rowDim.length == B.rowDim.length
        % Both have the same height so use A as the template.
        template = A;
    else
        % If we are going to implicitly expand one of the inputs then use the
        % other input as our template as that would have the row dim with the
        % correct length.
        if A.rowDim.length == 1 % implicitly expand A
            template = B;
        elseif B.rowDim.length == 1 % implicitly expand B
            template = A;
        else
            error(message('MATLAB:table:math:WrongHeight'));
        end
    end
end

% Call createLike to create the correct type of rowDim with the correct labels
% and length and then merge the rowDim props in-order.
if template.rowDim.hasExplicitLabels
    rowDim = template.rowDim.createLike(template.rowDim.length,template.rowDim.labels,false);
else
    rowDim = template.rowDim.createLike(template.rowDim.length);
end
rowDim = rowDim.mergeProps(A.rowDim);
template.rowDim = rowDim.mergeProps(B.rowDim);

% Merge varDim properties. Use the variable order of the first input. The
% template selection logic above ensures that the output has the correct type,
% however, in cases where B is selected as the template, we might have the
% incorrect var order. That would be addressed here and we will update the
% template with the correct var order.
template.varDim = A.varDim.mergeProps(B.varDim,varOrder);
% Validate and merge the VariableUnits if at least one table has them defined.
if A.varDim.hasUnits || B.varDim.hasUnits
    if B.varDim.hasUnits && ~isequal(varOrder,1:numel(varOrder))
        % Rearrange the units of B to match the variable order of A. The unit in
        % varDim are now no longer in the same order as the other properties!
        B.varDim = B.varDim.setUnits(B.varDim.units(varOrder));
    end
    units = unitsHelper(A.varDim,B.varDim,fun);
    template.varDim = template.varDim.setUnits(units);
end
% Check for conflicts between per-var and per-table CustomProperties across both
% inputs.
if any(isfield(A.varDim.customProps, fieldnames(B.arrayProps.TableCustomProperties))) || ...
        any(isfield(B.varDim.customProps, fieldnames(A.arrayProps.TableCustomProperties)))
    error(message('MATLAB:table:math:CustomPropsClash'));
end
% Select the first non-default dimension names.
if ~isequal(A.metaDim.labels,A.defaultDimNames)
    template.metaDim = template.metaDim.setLabels(A.metaDim.labels);
elseif ~isequal(B.metaDim.labels,B.defaultDimNames)
    template.metaDim = template.metaDim.setLabels(B.metaDim.labels);
end
% Merge the per-array properties from both the inputs. We always use the first
% non-empty value.
template.arrayProps = tabular.mergeArrayProps(A.arrayProps,B.arrayProps);
end
