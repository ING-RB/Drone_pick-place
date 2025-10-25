function a = catUtil(dim, useSpecializedFcn, varargin)
%

%   Copyright 2021-2023 The MathWorks, Inc.

if ~isnumeric(dim)
    error(message('MATLAB:categorical:cat:NonNumericDim'))
end

% Number of concatenating arrays
numArrays = numel(varargin);

% Start out the concatenation with the first array. Find the first
% "real" categorical as a prototype for converting cell arrays of character
% vectors.
a = varargin{1};
if isa(a,'categorical')
    prototype = a;
else
    % This is expensive if nargin is large, so only do it if necessary.
    for i = 1:numArrays
        input_i = varargin{i};
        if isa(input_i,'categorical')
            prototype = input_i;
            break
        end
    end
    
    % The first array needs to be converted to categorical.
    if isnumeric(a) && isequal(a,[])
        a = prototype; a.codes = a.codes([]); % empty 'like' a.codes
    else
        a = convertInputToCategorical(a,prototype); % if it is not already
    end
end

% Cache the 'ordinal-ness'
isOrdinal = a.isOrdinal;

% Special case algorithm optimized for small number of categoricals (<=10)
% with identical categories: categories equality are checked and codes 
% concatenated pairwise - break out upon hitting the first unequal pairs of 
% categories or non-categorical array. Remainer of inputs (if any) are 
% delegated to the general algorithm 
if (numArrays <= 10)
    allCodes = cell(numArrays, 1); allCodes{1} = a.codes;
    for i = 2:numArrays
        input_i = varargin{i};        
        if isa(input_i,'categorical') && isequal(a.categoryNames, input_i.categoryNames)
            if (isOrdinal ~= input_i.isOrdinal)
                error(message('MATLAB:categorical:OrdinalCategoriesMismatch'))
            end            
            allCodes{i} = input_i.codes;
            a.isProtected = a.isProtected || input_i.isProtected;
            numArrays = numArrays - 1; % one less remaining arrays to concatenate
        else
            % delete from args inputs that are already concatenated,
            % and delegate remainders to the general algorithm
            varargin(1:i-2) = [];
            break;
        end
    end    
    
    % Concatenate the equal categories ones all at once. Empty cell in
    % allCodes are no-op in concatenation
    if useSpecializedFcn
        if dim == 1
            a.codes = vertcat(allCodes{:});
        elseif dim == 2
            a.codes = horzcat(allCodes{:});
        else
            assert(false);
        end
    else
        a.codes = cat(dim, allCodes{:});
    end
end

% General case two-phases algorithm
%   1) loop through concatenating arrays and gather all categoryNames
%   2) compute unique category names from all arrays and reconcile internal codes
if (numArrays >= 2) % no-op if 'concatenating' only one array
    % Phase 1: gather number of categories and categoryNames from all arrays
    allNumCats = [length(a.categoryNames); zeros(numArrays-1,1)];
    allCategoryNames = cell(numArrays,1); allCategoryNames{1} = a.categoryNames;
    allCodes = cell(numArrays, 1); allCodes{1} = a.codes;    
    allIsProtected = false(numArrays,1); allIsProtected(1) = a.isProtected;
    isIdentityElem = false(numArrays,1);
    for i = 2:numArrays
        input_i = varargin{i};
        if isa(input_i, 'categorical') 
            % concatenating categorical arrays must be all ordinal or non-ordinal
            if isOrdinal ~= input_i.isOrdinal
                error(message('MATLAB:categorical:OrdinalMismatchConcatenate'));
            end
            allIsProtected(i) = input_i.isProtected;
        elseif isnumeric(input_i) && isequal(input_i,[]) % Accept [] as a valid "no-op" element
            isIdentityElem(i) = true;
            continue; % completely ignore this input
        else % ~isa(this,'categorical') - turn this array into a categorical
            input_i = convertInputToCategorical(input_i,prototype);
        end
        
        allCategoryNames{i} = input_i.categoryNames;
        allNumCats(i) = length(allCategoryNames{i});
        allCodes{i} = input_i.codes;
    end
    
    a.isProtected = any(allIsProtected);
    
    % Remove identity elements
    if any(isIdentityElem)
        allCategoryNames(isIdentityElem) = [];
        allCodes(isIdentityElem) = [];        
        allNumCats(isIdentityElem) = [];
        allIsProtected(isIdentityElem) = [];
        numArrays = numArrays - sum(isIdentityElem);
    end
    
    % Phase 2: unique categories from all input arrays + reconcile codes
    if (numArrays > 1) && ~isequal(allCategoryNames{:}) % No need to reconcile categories unless they are different
        if isOrdinal
            error(message('MATLAB:categorical:OrdinalCategoriesMismatch'))
        end
        
        % Unique categories from all arrays - call unique with 'stable'
        % to preserve the first-occurence order of categories across
        % all inputs
        [uCatNames, ~, namesIdxMap] = unique(vertcat(allCategoryNames{:}),'stable');
        
        % Protected categorical must not grow categories in concatenation
        if any(allIsProtected & (allNumCats < length(uCatNames)))
            error(message('MATLAB:categorical:ProtectedForCombination'))
        else
            a.categoryNames = uCatNames;
        end
        
        % Cast the first code w.r.t. total number of categories:
        % concatentation rule ensures final codes class remains consistent
        allCodes{1} = categorical.castCodes(allCodes{1},length(a.categoryNames));        
        
        % Reconcile internal codes by mapping indices into list of unique categories
        idxMapPtr = cumsum([1; allNumCats]); % not using the last idx
        for i = 2:numArrays
            % 'allCodes' can contain '0' (i.e. categorical.undefCode) when
            % input array has <undefined> categories and thus may not be a 
            % valid index vector. Prepend this array's IdxMap section with
            % one additional element to increment allCodes index by one
            thisMap = [NaN; namesIdxMap(idxMapPtr(i):(idxMapPtr(i+1)-1))];
            allCodes{i} = reshape(thisMap(allCodes{i}+1), size(allCodes{i}));
        end        
    end
    
    % Concatenate internal data codes from all input arrays
    if useSpecializedFcn
        if dim == 1
            a.codes = vertcat(allCodes{:});
        elseif dim == 2
            a.codes = horzcat(allCodes{:});
        else
            assert(false);
        end
    else
        a.codes = cat(dim, allCodes{:});
    end
end


%-----------------------------------------------------------------------
function input = convertInputToCategorical(input,prototype)
import matlab.internal.datatypes.isCharStrings

if isCharStrings(input) || (isstring(input) && isscalar(input))
    input = strings2categorical(input,prototype);
elseif isa(input, 'missing')
    is = zeros(size(input), 'uint8');
    input = prototype;
    [input.codes, input.categoryNames] = convertCodes(is, {}, input.categoryNames);
elseif iscell(input)
    error(message('MATLAB:categorical:cat:TypeMismatchCell'));
elseif isstring(input) % non-scalar string is an error, but cellstr is grandfathered in
    error(message('MATLAB:categorical:cat:TypeMismatchString'));
else
    error(message('MATLAB:categorical:cat:TypeMismatch',class(input)));
end

