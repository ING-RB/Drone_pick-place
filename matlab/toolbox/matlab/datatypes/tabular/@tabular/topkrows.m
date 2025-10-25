function [b,idx] = topkrows(a,k,varargin)
%

%   Copyright 2018-2024 The MathWorks, Inc.

% Avoid unsharing of shared-data copy across function call boundary
import matlab.lang.internal.move

% Parse K and error if incorrect value given
if (~isnumeric(k) || ~isscalar(k) || (k ~= floor(k)) || (k < 0))
    error(message('MATLAB:table:topkrows:InvalidK'));
end

% Change K to numrows if more were asked
if (k > a.rowDim.length)
    k = a.rowDim.length;
end
    
% Parse columns, directions and extract data to select on
[varargin{:}] = convertStringsToChars(varargin{:});
[vars,varData,sortMode,labels,vararginNV] = topkrowsFlagChecks(a,varargin{:});

% Cells besides cellstrs are not supported at this time by topkrows
for ii = 1:numel(varData)
    if iscell(varData{ii}) && ~iscellstr(varData{ii})
        error(message('MATLAB:table:topkrows:GenCellNotSupported'));
    end
end

% If k is 0 fast exit
if (k == 0)
    idx = [];
    b = a(idx,:);
    return
end

% If no columns to sort by fast exit
if (numel(vars)== 0)
    idx = (1:k)';
    b = a(idx,:);
    return
end 

% If sorting by RowNames with no labels fast exit
if (isequal(vars,0) && ~a.rowDim.hasLabels)
    idx = (1:k)';
    b = a(idx,:);
    return
end

% Compute gradual maxk/mink computation on each succesive column of data in
% a. After each column check the kth element, find its ties and sort those
% based on next columns. 
if isequal(vars,0) 
    % fast special case for simple row labels cases
    curdata = varData{1};
    if iscellstr(curdata) %#ok<ISCLSTR>
            curdata = string(curdata);
    end
    [~,idx] = topk(curdata,k,sortMode(1),vararginNV,labels{1});
    b = a(idx,:);
    return;
else
    % Set up initial starting data
    kleft = k;
    indv = 1;
    idxleft = (1:size(varData{1},1))';
    idx = [];
    
    while (indv <= numel(vars))
        % Select only data from column that needs to be compared
        curdata = varData{indv};
        
        % Since we do not handle cellstr convert to String
        if iscellstr(curdata) %#ok<ISCLSTR>
            curdata = string(curdata);
        end
        
        % If ND error because indexing below could squeeze out extra dims
        if ~ismatrix(curdata)
            error(message('MATLAB:table:topkrows:NDVar',labels{indv}));
        elseif istabular(curdata)
            % Error gracefully when trying to compare tables of tables
            error(message('MATLAB:table:topkrows:SortOnVarFailed',labels{indv},class(curdata)));
        end
        curdata = curdata(idxleft,:);
        
        % Find max or min kleft elements
        [kdata,it] = topk(curdata,kleft,sortMode(indv),vararginNV,labels{indv});
        
        if iscolumn(kdata)
            % Extract kth element and see which are same in kdata and
            % curdata
            kth = kdata(kleft);
            if (ismissing(kth))
                ksame = ismissing(kdata);
                datasame = ismissing(curdata);
            else
                ksame = (kdata == kth);
                datasame = (curdata == kth);
            end
        else
            % Extract kth row and compare with others in kdata and curdata
            kth = kdata(kleft,:);
            kthnan = ismissing(kth);
            
            % find same rows in kdata
            ksamem = (kdata == kth);
            misksame = ismissing(kdata) & kthnan;
            ksamem(misksame) = true;
            ksame = all(ksamem,2);
            
            % find same rows in curdata
            datasamem = (curdata == kth);
            misdatasame = ismissing(curdata) & kthnan;
            datasamem(misdatasame) = true;
            datasame = all(datasamem,2);
        end
            
        % Compute how many are same and how many left to compare
        kleft = sum(ksame);
        ktotal = sum(datasame);
        
        % Update indices decided and still to consider
        idx = [idx; idxleft(it(~ksame))]; %#ok<AGROW>
        idxleft = idxleft(datasame);
            
        % If done then exit
        if (kleft == ktotal)
            break;
        end
        
        % Advance to next column
        indv = indv +1;
    end
    
    % Need to grab last kleft into index
    idx = [idx; idxleft(1:kleft)];
end

% grab only rows in idx
b = a(idx,:);
datachange = false;
for j=1:numel(vars)
    % change char to uint16 to allow sorting of final k elements with all
    % flags, 'ComparisonMethod' and 'MissingPlacement'.
    if ischar(varData{j})
        b = convertvars(b, vars(j), 'uint16');
        datachange= true;
    end
    
    % change cellstr to string to allow sorting of final k elements with all
    % flags, 'ComparisonMethod' and 'MissingPlacement'.
    if iscellstr(varData{j})
        repData=string(varData{j}(idx,:));
        if vars(j) == 0
            varpos = b.varDim.length + 1;
            % Explicitly call dotAssign to always dispatch to subscripting code, even
            % when the variable name matches an internal tabular property/method.
            b = move(b).dotAssign(varpos,repData); % b.(varpos) = repData
            vars(j) = varpos;
        else
            b = convertvars(b, vars(j), 'string');
        end
        datachange= true;
    end
end

% Once k rows are selected need to perform one last sort as ties before the
% kth element would not have been solved correctly above
sortVals = {'ascend' 'descend'};

% If having RowTimes use labels
if any(vars == 0)
    vars = labels;
end

% Faster to perform sort of k elements in all cases
[b,it] = sortrows(b,vars,sortVals(sortMode),vararginNV{:},'MissingPlacement','last');

% fix index also
idx = idx(it);

% If changed datatype reindex to get correct data
if datachange
    b = a(idx,:);
end

end


% Subfunction to call maxk/mink with correct argument list or topkrows for 
% multi-column variables; This function also throws appropriate errors if
% encountering issues
% As a workaround for topkrows not supporting string calling sortrows and
% indexing 1:k
function [t,i]=topk(var,k,sortvar,vararginNV,label)
    if ~ismatrix(var)
            error(message('MATLAB:table:topkrows:NDVar',label));
    elseif istabular(var)
            % Error gracefully when trying to compare tables of tables
            error(message('MATLAB:table:topkrows:SortOnVarFailed',label,class(var)));
    else
        try
            if (isstring(var))
                col = 1:size(var,2);
                if isempty(vararginNV)
                    if sortvar == 1
                        [t,i] = sortrows(var,col,'ascend','MissingPlacement','last');
                    else % sortvar = 2
                        [t,i] = sortrows(var,col,'descend','MissingPlacement','last');
                    end 
                else
                    if sortvar == 1
                        [t,i] = sortrows(var,col,'ascend',vararginNV{:},'MissingPlacement','last');
                    else
                        [t,i] = sortrows(var,col,'descend',vararginNV{:},'MissingPlacement','last');
                    end
                end
                t = t(1:k,:);
                i = i(1:k,:);
            else
                % Try selecting top k elements with maxk/mink or topkrows
                if iscolumn(var)
                    if isempty(vararginNV)
                        if sortvar == 1
                            [t,i] = mink(var,k);
                        else % sortvar == 2
                            [t,i] = maxk(var,k);
                        end
                    else
                        if sortvar == 1
                            [t,i] = mink(var,k,vararginNV{:});
                        else % sortvar == 2
                            [t,i] = maxk(var,k,vararginNV{:});
                        end
                    end
                else
                    col = 1:size(var,2);
                    if isempty(vararginNV)
                        if sortvar == 1
                            [t,i] = topkrows(var,k,col,'ascend');
                        else % sortvar = 2
                            [t,i] = topkrows(var,k,col,'descend');
                        end 
                    else
                        if sortvar == 1
                            [t,i] = topkrows(var,k,col,'ascend',vararginNV{:});
                        else
                            [t,i] = topkrows(var,k,col,'descend',vararginNV{:});
                        end
                    end
                end
            end
        catch ME
            % Return error message 
            throw(addCause(MException(message('MATLAB:table:topkrows:SortOnVarFailed',label,class(var))),ME));
        end
    end
end
