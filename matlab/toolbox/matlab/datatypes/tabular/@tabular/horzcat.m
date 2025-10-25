function t = horzcat(varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.defaultarrayLike

try
    haveCell = false;
    inputWidths = zeros(1,nargin);
    isIdentityElement = false(1,length(varargin));
    for i = 1:nargin
        b = varargin{i};
        haveCell = haveCell || iscell(b); % _any_ input is a cell array
        inputWidths(i) = size(varargin{i},2); % dispatch to overloaded size, not built-in
        isIdentityElement(i) = (isnumeric(b) && isequal(b,[])); % treat as "identity element", and ignore
    end
    nvarsTotal = sum(inputWidths);
    varargin(isIdentityElement) = []; % remove []'s
    inputWidths(isIdentityElement) = [];
    
    % Call getTemplateForConcatenation to figure out the correct output
    % template and use that to initialize the output properties.
    [t,t_idx] = getTemplateForConcatenation(2,varargin{:});
    t_nrows = t.rowDim.length;
    % Call createLike to create a rowDim of the correct type, with default
    % values for the properties. This is necessary to ensure that the
    % properties are merged in the correct order.
    if t.rowDim.hasExplicitLabels
        t_rowDim = t.rowDim.createLike(t_nrows,t.rowDim.labels,false);
    else
        t_rowDim = t.rowDim.createLike(t_nrows);
    end
    
    % Create an empty varDim of the right size and assign the appropriate
    % variable names.
    t_nvars = 0;
    t_varDim = t.varDim.createLike(nvarsTotal);
    numInputs = numel(varargin);
    varNames = cell(1,numInputs);
    for i = 1:numInputs
        b = varargin{i};
        if isa(b,'tabular')
            % Use the variable names from tabular inputs.
            varNames{i} = b.varDim.labels;
        else
            % For non-tabular inputs, fill it with empties for now. The call to
            % setLabels below will assign the correct default varnames for these
            % variables and also correctly handle duplicates in these default
            % created labels.
            varNames{i} = t_varDim.emptyLabels(size(b,2));
        end
    end
    % Error if var labels are duplicates, and create default labels where labels are
    % not present from cell array inputs. Don't try to recognize and take one copy
    % of variables that have the same name and data, duplicate variable names are an
    % error regardless.
    t_varDim = t_varDim.setLabels([varNames{:}],[],false,true);

    % We assume that the metaDim labels are default and update them as soon as 
    % we encounter a tabular with non-default dim names.
    haveDefaultDimNames = true;
    t_metaDim = t.metaDim;
    t_arrayProps = t.arrayPropsDflts; % initialize with default arrayprops
    t_customVarProps = struct;
    if t_rowDim.hasLabels
        [t_rowLabelsSorted,t_rowOrder] = sort(t_rowDim.labels);
    end
    t_data = cell(1,0);
    
    for j = 1:numInputs
        b = varargin{j};
        b_wasCell = iscell(b); % the current input is a cell array
        if b_wasCell
            b = cell2table(b);
        elseif ~isa(b,'tabular')
            % Only valid inputs at this point are cell and tabular, anything
            % else should be an error.
            error(message('MATLAB:table:horzcat:InvalidInput'));
        end
        b_nrows = b.rowDim.length;
        b_nvars = b.varDim.length;
        vars_j = t_nvars+(1:size(b,2)); % var indices in t that b will go into
        
        if b_nvars==0 && b_nrows==0 % special case to mimic built-in behavior
            % do nothing with data, but need to manage metadata.
        elseif t_nrows ~= b_nrows
            if haveCell
                error(message('MATLAB:table:horzcat:SizeMismatchWithCell'));
            else
                error(message('MATLAB:table:horzcat:SizeMismatch'));
            end
        else
            % It's a non-0x0 input with the right size and type. Append it to
            % the right edge of t.
            b_rowDim = b.rowDim;
            if isa(t,'timetable') && isa(b,'table')
                t_data = horzcat(t_data, b.data); %#ok<AGROW>
            elseif b_rowDim.hasLabels && j ~= t_idx
                % If the current input has row labels then t is also guaranteed
                % to have row labels, so for this case we may need to reorder
                % the data to match the template's row label order.
                % We only need to do this if the template was not created using
                % the current input. (Another reason to skip this is to avoid
                % erroring for a single timetable with NaT/NaN row times).
                [b_rowLabelsSorted,b_rowOrder] = sort(b_rowDim.labels);
                if (j ~= t_idx) && ~isequal(t_rowLabelsSorted,b_rowLabelsSorted)
                    % Check the row labels for tables other than the table from
                    % which the template was obtained.
                    if isa(t,'timetable')
                        error(message('MATLAB:table:horzcat:UnequalRowTimes'));
                    else
                        error(message('MATLAB:table:horzcat:UnequalRowNames'));
                    end
                end
                b_reord(t_rowOrder) = b_rowOrder; %#ok<AGROW>, full reassignment each time
                t_data = horzcat(t_data, cell(1,b_nvars)); %#ok<AGROW>
                for i = 1:b_nvars
                    bVar = b.data{i};
                    sizeOut = size(bVar);
                    if istabular(bVar)
                        t_data{t_nvars+i} = bVar(b_reord,:);
                    else
                        t_data{t_nvars+i} = reshape(bVar(b_reord,:),sizeOut);
                    end
                end
            else
                t_data = horzcat(t_data, b.data); %#ok<AGROW>
            end
            
            % Make it official.
            t_nvars = t_nvars + b_nvars;
        end
        
        % If it was originally a cell array, there are no row labels or other
        % properties to worry about.
        if ~b_wasCell
            % Build up new customProps struct, initially with a cell array in
            % each field that will be concatenated together.
            b_customProps = b.varDim.customProps;
            fn = fieldnames(b_customProps);
            for ii = 1:numel(fn)
                if ~isfield(t_customVarProps,fn{ii}) % instantiate new customProp
                    t_customVarProps.(fn{ii}) = {};
                end
                if ~isequal(size(b_customProps.(fn{ii})),[0,0])
                    % fill in with default values if not yet done and there is an archetype to use.
                    if isequal(size(t_customVarProps.(fn{ii})),[0,0])
                        t_customVarProps.(fn{ii}) = cell(1,nargin);
                        dfltVarProp = defaultarrayLike([1,1],'Like',b_customProps.(fn{ii}), false);
                        for k = 1:nargin
                            t_customVarProps.(fn{ii}){k} = repmat(dfltVarProp,1,inputWidths(k));
                        end
                    end
                    t_customVarProps.(fn{ii}){j} = b_customProps.(fn{ii});
                end
            end
            % Clear out the customProps from the varDim to avoid duplicating work in assignInto.
            b.varDim = b.varDim.setCustomProps(struct);
            
            % If it was originally a table/timetable, get its var labels and
            % per-var properties.
            t_varDim = t_varDim.moveProps(b.varDim,1:b.varDim.length,vars_j);

            % Merge the rowDim props.
            % Prevent events on eventtables.
            if isa(t,"eventtable") && istimetable(b)
                b.rowDim = b.rowDim.setTimeEvents([]);
            end
            t_rowDim = t_rowDim.mergeProps(b.rowDim);
            
            % Update the metaDim labels if this is the first time we are seeing
            % a non-default dimension name
            if haveDefaultDimNames && ~isequal(b.metaDim.labels,b.defaultDimNames)
                t_metaDim = t_metaDim.setLabels(b.metaDim.labels);
                haveDefaultDimNames = false;
            end
        
            % Use any per-array property values not already present.
            t_arrayProps = tabular.mergeArrayProps(t_arrayProps,b.arrayProps);
        end
    end
    t.data = t_data;

    % Horzcat the per-variable customProps.
    fn = fieldnames(t_customVarProps);
    if ~isempty(fn)
        for ii = 1:numel(fn)
            try
                t_customVarProps.(fn{ii}) = [t_customVarProps.(fn{ii}){:}];
                nPropVals = numel(t_customVarProps.(fn{ii}));
                if ~(nPropVals == nvarsTotal || nPropVals == 0)
                    error(message('MATLAB:table:CustomProperties:CellCatChangesSize'))
                end
            catch ME
                throw(addCause(MException(message('MATLAB:table:CustomProperties:InvalidConcatenation',fn{ii})),ME))
            end
        end
    end
    % Check for conflicts between per-var and per-table
    % CustomProperties across tables.
    if any(isfield(t_customVarProps, fieldnames(t_arrayProps.TableCustomProperties)))
        error(message('MATLAB:table:horzcat:CustomPropsClash'))
    end
    t.varDim = t_varDim.setCustomProps(t_customVarProps);
    % Detect conflicts between the combined var names of the result and the dim
    % names of the leading time/table.
    t.metaDim = t_metaDim.checkAgainstVarLabels(t.varDim.labels);
    
    t.rowDim = t_rowDim;
    t.arrayProps = t_arrayProps;
catch ME
    throw(ME)
end
