function aout = catUtil(dim, useSpecializedFcn, varargin) %#codegen
%

%   Copyright 2021 The MathWorks, Inc.
coder.internal.assert(coder.internal.isConst(dim),'Coder:toolbox:dimNotConst');
dim = coder.const(dim);
useSpecializedFcn = coder.const(useSpecializedFcn);

% Number of concatenating arrays
numArrays = numel(varargin);

% Start out the concatenation with the first array. Find the first
% "real" categorical as a prototype for converting cell arrays of character
% vectors.
araw = varargin{1};

if isa(araw,'categorical')
    prototype = araw;
    a = araw;
    numCategoriesUpperBound = a.numCategoriesUpperBound;
else
    prototype = categorical(matlab.internal.coder.datatypes.uninitialized());  % this will be overriden in the FOR loop
    for i = 2:numArrays
        if isa(varargin{i}, 'categorical')
            prototype = varargin{i};
            break;
        end            
    end
    
    % The first array needs to be converted to categorical.
    if isnumeric(araw) && isequal(araw,[])
        a = categorical(matlab.internal.coder.datatypes.uninitialized());
        a.codes = zeros(0,0,class(prototype.codes));
        a.categoryNames = prototype.categoryNames;
        a.isProtected = prototype.isProtected;
        a.isOrdinal = prototype.isOrdinal;
        numCategoriesUpperBound = 0;
    elseif matlab.internal.coder.datatypes.isCharStrings(araw) || (isstring(araw) && isscalar(araw))
        a = strings2categorical(araw,prototype);
        if ischar(araw)
            numCategoriesUpperBound = 1;
        else % cellstr
            numCategoriesUpperBound = numel(araw);
        end
    else
        iscella = iscell(araw);
        coder.internal.errorIf(iscella, 'MATLAB:categorical:cat:TypeMismatchCell');
        coder.internal.errorIf(~iscella, 'MATLAB:categorical:cat:TypeMismatch',class(araw));
    end
end
% The inputs must be all ordinal or not, so need only save one setting.
isOrdinal = a.isOrdinal;

% Note: the non-codegen categorical has a special case algorithm for small number of categoricals (<=10)
% with identical categories. I have not implemented this algorithm in the 
% codegen class since I am unsure if the performance gain in codegen is
% significant. If performance becomes an issue in codegen, consider implementing it. 

% General case two-phases algorithm
%   1) loop through concatenating arrays and gather all categoryNames
%   2) compute unique category names from all arrays and reconcile internal codes
if (numArrays >= 2) % no-op if 'concatenating' only one array
    % Phase 1: gather number of categories and categoryNames from all arrays
    allNumCats = [length(a.categoryNames); zeros(numArrays-1,1)];
    allCategoryNames = cell(numArrays,1); allCategoryNames{1} = a.categoryNames;
    coder.varsize('allCategoryNames', size(allCategoryNames), zeros(1,ndims(allCategoryNames)));
    allCodes = cell(numArrays, 1); allCodes{1} = a.codes;    
    allIsProtected = false(numArrays,1); allIsProtected(1) = a.isProtected;
    input_i_cell = cell(1,numArrays-1);
    aout = categorical(matlab.internal.coder.datatypes.uninitialized());
    
    for i = 2:numArrays
        input_i = varargin{i};
        if isa(input_i, 'categorical') 
            % concatenating categorical arrays must be all ordinal or non-ordinal
            coder.internal.assert(isOrdinal == input_i.isOrdinal, ...
                'MATLAB:categorical:OrdinalMismatchConcatenate');
            input_i_cell{i-1} = input_i;
            allIsProtected(i) = input_i_cell{i-1}.isProtected;
            numCategoriesUpperBound = numCategoriesUpperBound + input_i_cell{i-1}.numCategoriesUpperBound;
        elseif isnumeric(input_i) && isequal(input_i,[]) % Accept [] as a valid "no-op" element
            allCategoryNames{i} = cell(0,1);
            allCodes{i} = [];
            continue; % completely ignore this input
        else % ~isa(this,'categorical') - turn this array into a categorical
            if matlab.internal.coder.datatypes.isCharStrings(input_i) || ...
                    (isstring(input_i) && isscalar(input_i))
                input_i_cell{i-1} = strings2categorical(input_i,prototype);
                if ischar(varargin{i})
                    numCategoriesUpperBound = numCategoriesUpperBound + 1;
                else
                    numCategoriesUpperBound = numCategoriesUpperBound + numel(varargin{i});
                end
            else
                iscelli = iscell(input_i);
                coder.internal.errorIf(iscelli, 'MATLAB:categorical:cat:TypeMismatchCell');
                coder.internal.errorIf(~iscelli, 'MATLAB:categorical:cat:TypeMismatch',class(input_i));
            end
        end
        
        allCategoryNames{i} = input_i_cell{i-1}.categoryNames;
        allNumCats(i) = length(allCategoryNames{i});
        allCodes{i} = input_i_cell{i-1}.codes;
    end
    
    aout.isProtected = any(allIsProtected);
    
    % Phase 2: unique categories from all input arrays + reconcile codes
    sameCatNames = isequal(allCategoryNames{:});
    if ~sameCatNames % No need to reconcile categories unless they are different
        coder.internal.errorIf(~sameCatNames && isOrdinal, 'MATLAB:categorical:OrdinalCategoriesMismatch');
         
        % concatenate all category names into one long cellstr
        % first, find out the total number of categories
        nAllCategoryNames = numel(allCategoryNames{1});
        for i = 2:numel(allCategoryNames)
            nAllCategoryNames = nAllCategoryNames + numel(allCategoryNames{i});
        end
        allCatNamesInOneCellstr = cell(nAllCategoryNames, 1);
        % populate the cellstr
        % allCatNamesInOneCellstr = [allCategoryNames{:}];
        counter = 0;  % array index in the current cell in allCategoryNames
        cellidx = 1;  % cell index in allCategoryNames
        for i = 1:numel(allCatNamesInOneCellstr)
            counter = counter + 1;
            if counter > numel(allCategoryNames{cellidx})
                % finished processing one cell, move on to the next cell
                counter = 1;
                cellidx = cellidx + 1;
            end
            allCatNamesInOneCellstr{i} = allCategoryNames{cellidx}{counter};
        end
        
        % Unique categories from all arrays
        % Need stable order to preserve the first-occurence order of categories 
        % across all inputs. 
        % Since cellstr_unique currently does not support 'stable' option,
        % use the returned ia index to reorder to stable.
        [uCatNamesRaw, ia, namesIdxMapRaw] = matlab.internal.coder.datatypes.cellstr_unique(...
            allCatNamesInOneCellstr);
        
        % uCatNamesRaw is in sorted order. To get stable order, need to
        % sort the ia, and use the resulting index to reorder uCatNames
        catNamesOrder = coder.internal.sortIdx(ia, 'a');
        uCatNames = cell(numel(uCatNamesRaw),1);
        for i = 1:numel(uCatNames)
            uCatNames{i} = uCatNamesRaw{catNamesOrder(i)};
        end
        % namesIdxMapRaw also needs to be sorted accordingly
        reverseOrder = coder.internal.sortIdx(catNamesOrder(:), 'a');
        namesIdxMap = reverseOrder(namesIdxMapRaw);

        % Protected categorical must not grow categories in concatenation
        coder.internal.errorIf(any(allIsProtected & (allNumCats < length(uCatNames))), ...
            'MATLAB:categorical:ProtectedForCombination');
        aout.categoryNames = uCatNames;
        
        % Cast the first code w.r.t. total number of categories:
        % concatentation rule ensures final codes class remains consistent
        allCodesCast = cell(size(allCodes));  
        allCodesCast{1} = categorical.castCodes(allCodes{1},numCategoriesUpperBound);        
        
        % Reconcile internal codes by mapping indices into list of unique categories
        idxMapPtr = cumsum([1; allNumCats]); % not using the last idx
        for i = 2:numArrays
            % 'allCodes' can contain '0' (i.e. categorical.undefCode) when
            % input array has <undefined> categories and thus may not be a 
            % valid index vector. Prepend this array's IdxMap section with
            % one additional element to increment allCodes index by one
            thisMap = [0; namesIdxMap((idxMapPtr(i):(idxMapPtr(i+1)-1)).')];
            allCodesCast{i} = categorical.castCodes(reshape(thisMap(allCodes{i}(:)+1), size(allCodes{i})), numCategoriesUpperBound);
        end   
        % Concatenate internal data codes from all input arrays
        if useSpecializedFcn
            if dim == 1
                aout.codes = vertcat(allCodesCast{:});
            elseif dim == 2
                aout.codes = horzcat(allCodesCast{:});
            else
                assert(false);
            end
        else
            aout.codes = cat(dim, allCodesCast{:});
        end
    else
        aout.categoryNames = a.categoryNames;
        % Concatenate internal data codes from all input arrays
        if useSpecializedFcn
            if dim == 1
                aOutCodes = vertcat(allCodes{:});
            elseif dim == 2
                aOutCodes = horzcat(allCodes{:});
            else
                assert(false);
            end
        else
            aOutCodes = cat(dim, allCodes{:});
        end
        aout.codes = categorical.castCodes(aOutCodes,numCategoriesUpperBound);
    end
    aout.isOrdinal = isOrdinal;
    aout.numCategoriesUpperBound = numCategoriesUpperBound;
else
    % no-op if 'concatenating' only one array
    aout = a;
end
