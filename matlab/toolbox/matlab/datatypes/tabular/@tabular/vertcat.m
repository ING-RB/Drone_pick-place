function t = vertcat(varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

try
    haveCell = false;
    inputHeights = zeros(1,nargin);
    isIdentityElement = false(size(varargin));
    numNon0x0 = 0;
    for i = 1:nargin
        b = varargin{i};
        sz = size(b);
        haveCell = haveCell || iscell(b); % _any_ input is a cell array
        inputHeights(i) = sz(1); % dispatch to overloaded size, not built-in
        numNon0x0 = numNon0x0 + (sum(sz) ~= 0);
        isIdentityElement(i) = (isnumeric(b) && isequal(b,[])); % treat as "identity element", and ignore
    end
    varargin(isIdentityElement) = []; % remove []'s
    inputHeights(isIdentityElement) = [];
    
    % Call getTemplateForConcatenation to figure out the correct output
    % template and use that to initialize the output properties.
    t = getTemplateForConcatenation(1,varargin{:});
    t_nrows = sum(inputHeights);
    t_nvars = t.varDim.length;
    % Call createLike to create a rowDim of the correct type, with default
    % values for the properties. This is necessary to ensure that the
    % properties are merged in the correct order. The labels here might be
    % invalid, but those will be fixed towards the end.
    if t.rowDim.hasExplicitLabels
        t_rowDim = t.rowDim.createLike(t_nrows,t.rowDim.labels,false);
    else
        t_rowDim = t.rowDim.createLike(t_nrows);
    end
    % Unlike rowDim, varDim currently does not have any properties that could
    % exist without any variables (this is also true for eventtable tagged
    % variables). Since the template's varDim would be the first input that has
    % any variables, the property merging would only start from that input, so
    % we can directly use the template's varDim instead of calling createLike
    % (for performance).
    t_varDim = t.varDim;
    % We assume that the metaDim labels are default and update them as soon as 
    % we encounter a tabular with non-default dim names.
    hasDefaultDimNames = true;
    t_metaDim = t.metaDim;
    t_arrayProps = t.arrayPropsDflts; % initialize with default arrayprops
    [t_varLabelsSorted,t_varOrder] = sort(t_varDim.labels);
    % Pre-allocate a cell array to store the data for each non-0x0 entry.
    b_data = cell(numNon0x0,t_nvars);
    b_data_idx = 1;
    rowLabels = cell(nargin,1);
    % When explicitly creating row labels, store the indices of rows that did
    % not have row labels.
    rowsWithoutRowLabels = cell(nargin,1);
    hasExplicitRowLabels = t.rowDim.hasExplicitLabels;
    rowLabelType = t.rowDim.labelType;
    
    for j = 1:length(varargin)
        b = varargin{j};
        b_wasCell = iscell(b); % the current input is a cell array
        if b_wasCell
            b = cell2table(b); % default var names won't be used
        elseif ~isa(b,'tabular')
            % Only valid inputs at this point are cell and tabular, anything
            % else should be an error.
            error(message('MATLAB:table:vertcat:InvalidInput'));
        end
        b_nvars = b.varDim.length;
        b_nrows = b.rowDim.length;
        rows_j = sum(inputHeights(1:j-1)) + (1:inputHeights(j)); % row indices in t that b will go into
        
        if b_nvars==0 && b_nrows==0 % special case to mimic built-in behavior
            % No data change, but we will update the metadata later on.
            
            % Since there are no variables, we do not have to reorder anything.
            % So just assign [], as this will be later used by mergeProps.
            b_reord = [];
            
            % For 0x0 timetables, we ignore the row times and we do not check
            % for mismatch in the rowtimes type. This is done to allow
            % vertcating duration timetables with timetables constructed using
            % the default constructor (which would have datetime rowtimes).
        elseif b_nvars ~= t_nvars
            if haveCell
                error(message('MATLAB:table:vertcat:SizeMismatchWithCell'));
            else
                error(message('MATLAB:table:vertcat:SizeMismatch'));
            end
        else
            % It's a non-0x0 input with the right size and type.
            if b_wasCell
                % Assign positionally
                b_data(b_data_idx,:) = b.data;
            else % was always a table
                %[tf,b_reord] = ismember(t.varDim.labels,b.varDim.labels);
                [b_varLabelsSorted,b_varOrder] = sort(b.varDim.labels);
                if ~isequal(t_varLabelsSorted,b_varLabelsSorted)
                    error(message('MATLAB:table:vertcat:UnequalVarNames'));
                end
                b_reord(t_varOrder) = b_varOrder; %#ok<AGROW>, full reassignment each time
                b_data(b_data_idx,:) = b.data(b_reord);                
            end
            b_data_idx = b_data_idx + 1;
        end
        
        % Deal with row labels if the output stores them explicitly. Ignore the
        % row labels if the current input is 0x0, refer to comments above for
        % more details.
        if hasExplicitRowLabels && (b_nvars~=0 || b_nrows~=0)
            % If both t and b have the same type of row labels (i.e. text or
            % time), then use b's row labels. Otherwise use t's rowDim to
            % generate the appropriate default labels.
            if matches(rowLabelType, b.rowDim.labelType) && b.rowDim.hasLabels
                if ~isa(b.rowDim.labels,class(t.rowDim.labels)) 
                    t.throwSubclassSpecificError('RowLabelsTypeMismatch',class(b.rowDim.labels),class(t.rowDim.labels));
                end
                rowLabels{j} = b.rowDim.labels;
            else
                rowLabels{j} = t.rowDim.defaultLabels(rows_j);
                rowsWithoutRowLabels{j} = rows_j;
            end
        end
        
        % If it was originally a cell array, there are no row labels or other
        % properties to worry about.
        if ~b_wasCell
            % Check for conflicts between per-var and per-table
            % CustomProperties across tables.
            if any(isfield(t_varDim.customProps, fieldnames(b.arrayProps.TableCustomProperties))) || ...
               any(isfield(b.varDim.customProps, fieldnames(t_arrayProps.TableCustomProperties)))
                error(message('MATLAB:table:vertcat:CustomPropsClash'))
            end

            % Merge the rowDim props.
            % Prevent events on eventtables.
            if isa(t,"eventtable") && istimetable(b)
                b.rowDim = b.rowDim.setTimeEvents([]);
            end
            t_rowDim = t_rowDim.mergeProps(b.rowDim);
            
            t_varDim = t_varDim.mergeProps(b.varDim,b_reord);
            
            % Update the metaDim labels if this is the first time we are seeing
            % a non-default dimension name
            if hasDefaultDimNames && ~isequal(b.metaDim.labels,b.defaultDimNames)
                t_metaDim = t_metaDim.setLabels(b.metaDim.labels);
                hasDefaultDimNames = false;
            end

            % Use any per-array property values not already present.
            t_arrayProps = tabular.mergeArrayProps(t_arrayProps,b.arrayProps);
        end
    end

    t_data = cell(1,t_nvars);
    for i = 1:t_nvars
        try
            t_data{i} = vertcat(b_data{:,i}); % only vertcats data for non-0x0 entries
        catch ME
            throw(addCause(MException(message('MATLAB:table:vertcat:VertcatMethodFailed',t.varDim.labels{i})),ME));
        end
        % Something went badly wrong with whatever vertcat method was called.
        if size(t_data{i},1) ~= t_nrows
            % One reason for this is concatenation of a cell variable with a non-cell
            % variable, which adds only a single cell to the former, containing the
            % latter.  Check for cell/non-cell only after calling vertcat to allow
            % overloads such as categorical that can vertcat cell/non-cell sensibly.
            b_is0x0 = cellfun(@(c)isequal(size(c),[0 0]),varargin); % only check non-0x0 inputs
            cells = cellfun('isclass',b_data(~b_is0x0,i),'cell');
            if any(cells) && ~all(cells)
                error(message('MATLAB:table:vertcat:VertcatCellAndNonCell', t.varDim.labels{i}));
            else
                error(message('MATLAB:table:vertcat:VertcatWrongLength', t.varDim.labels{i}));
            end
        end
    end

    t.data = t_data;
    t.metaDim = t_metaDim;
    t.varDim = t_varDim;
    if hasExplicitRowLabels
        rowsWithoutRowLabels = [rowsWithoutRowLabels{:}];
        % We ignore the row labels for 0x0 inputs, so if all inputs are 0x0
        % vertcating rowLabels would result in a 0x0 double. To avoid this,
        % we vertcat rowLabels with empty row label of the same type as t. So if 
        % all inputs are 0x0, then this would create empty row labels of the
        % correct type and if we have at least one non 0x0 input, the first
        % empty row label input will be ignored by vertcat.
        rowLabels = vertcat(t.rowDim.labels([],:),rowLabels{:});
        if t.rowDim.requireUniqueLabels
            if ~isempty(rowsWithoutRowLabels)
                % vertcat creates rowlabels for rows that do not have them. However,
                % if the rowDim requires unique labels then fix any duplicates in
                % the labels created by vertcat before doing the assignment.  
                rowLabels = matlab.lang.makeUniqueStrings(rowLabels,rowsWithoutRowLabels,namelengthmax);
            end
            % Duplicates in other labels coming from user tabulars should still
            % error.
            t_rowDim.checkDuplicateLabels(rowLabels);
        end
        t_rowDim = t_rowDim.assignLabels(rowLabels,true);
    end
    t.rowDim = t_rowDim;
    t.arrayProps = t_arrayProps;
catch ME
    throw(ME)
end
