classdef categorical < matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign & ...
        coder.mixin.internal.indexing.ParenAssignSupportInParfor & ...
        coder.mixin.internal.SpoofReport  %#codegen
    %CATEGORICAL Arrays for Code Generation
    %
    % Additional Supported Functionality
    % - iscategorical
    
    %   Copyright 2018-2023 The MathWorks, Inc.
    
    properties(Constant, GetAccess='private')
        defaultCodesClass = 'uint8'; % see castCodes() method
    end
    
    properties(Constant, GetAccess='protected')
        % Internal code for undefined elements.
        % This does not need to be the same class as codes because zeros
        % compare correctly across numeric classes
        undefCode = 0;
    end
    
    properties(Hidden, Constant, GetAccess='public')
        % Text label for displaying undefined elements.
        undefLabel = '<undefined>';
        % label used in display of missing strings
        missingLabel = '<missing>'; 
        
        % Maximum number of categories
        maxNumCategories = intmax('int32'); % see castCodes() method
    end    
    
    properties(GetAccess='protected', SetAccess='protected')
        codes;
        categoryNames;        
        isProtected = false;
        isOrdinal = false;
    end
       
    properties(Access = 'private')
        numCategoriesUpperBound  
    end
       
    methods
        function b = categorical(inputData,varargin)
            %CATEGORICAL Create a categorical array
            if nargin == 0
                % initialize to defaults and return
                b.codes = zeros(0,0,'uint8');
                b.categoryNames = cell(0,0);
                b.numCategoriesUpperBound = 0;
            elseif nargin == 1 && isa(inputData, 'matlab.internal.coder.datatypes.uninitialized')
                % uninitialized object requested. Do nothing and return.
            else        
                % Catch some inputs that are specifically disallowed.
                coder.internal.errorIf(ischar(inputData), 'MATLAB:categorical:CharData');
                coder.internal.errorIf(isa(inputData,'table') || isa(inputData,'timetable'), ...
                    'MATLAB:categorical:TableData');
                coder.internal.errorIf(issparse(inputData), 'MATLAB:categorical:SparseData');
                coder.internal.errorIf(isobject(inputData) && ~isa(inputData, 'categorical'), ...
                    'MATLAB:categorical:InvalidDataClass');
                
                numvarargin = length(varargin);
                
                % Pull out optional positional inputs, which cannot be char
                if (nargin == 1) || isNVpair(varargin{1})
                    % categorical(inputData) or categorical(inputData,Name,Value,...)
                    suppliedValueSet = false;
                    suppliedCategoryNames = false;
                    
                    NVPairs = varargin;
                elseif (nargin == 2) || isNVpair(varargin{2})
                    % categorical(inputData,valueSet) or categorical(inputData,valueSet,Name,Value,...)
                    suppliedValueSet = true;
                    inputValueSet = varargin{1};
                    suppliedCategoryNames = false;
                    
                    NVPairs = cell(1,numvarargin-1);
                    for i = 2:numvarargin
                        NVPairs{i-1} = varargin{i};
                    end
                else
                    % categorical(inputData,valueSet,categoryNames) or categorical(inputData,valueSet,categoryNames,Name,Value,...)
                    suppliedValueSet = true;
                    inputValueSet = varargin{1};
                    suppliedCategoryNames = true;
                    inputCategoryNames = varargin{2};
                    
                    NVPairs = cell(1,numvarargin-2);
                    for i = 3:numvarargin
                        NVPairs{i-2} = varargin{i};
                    end
                end
                
                pnames = {'Ordinal' 'Protected'};
                if mod(numel(NVPairs),2) ~= 0 && isNVpair(NVPairs{1})
                    % Give a helpful error message for one-category edge cases like
                    %     categorical(data,'ordinal')
                    % OR  categorical(data,1,"protected")
                    pnameRaw = sprintf('''%s''',NVPairs{1});
                    matchedPname = coder.const(feval('startsWith',pnames,char(NVPairs{1}),IgnoreCase=true));
                    matchedPname = sprintf('''%s''',pnames{matchedPname});
                    coder.internal.errorIf(suppliedValueSet && ~suppliedCategoryNames, ...
                        'MATLAB:categorical:ParamNameCategoryNames',pnameRaw,matchedPname,NVPairs{1});
                    coder.internal.errorIf(~suppliedValueSet, ...
                        'MATLAB:categorical:ParamNameValueset',pnameRaw,matchedPname,NVPairs{1});
                end
                poptions = struct( ...
                    'CaseSensitivity',false, ...
                    'PartialMatching','unique', ...
                    'StructExpand',false);
                pstruct = coder.internal.parseParameterInputs(pnames,poptions,NVPairs{:});

                isOrdinal = coder.internal.getParameterValue(pstruct.Ordinal,false,NVPairs{:});
                isProtected = coder.internal.getParameterValue(pstruct.Protected,false,NVPairs{:});
                
                isOrdinal = matlab.internal.coder.datatypes.validateLogical(isOrdinal,'Ordinal');
                isProtected = matlab.internal.coder.datatypes.validateLogical(isProtected,'Protected');
                
                if isOrdinal
                    if pstruct.Protected
                        coder.internal.assert(isProtected,'MATLAB:categorical:UnprotectedOrdinal');
                    else
                        isProtected = true;
                    end
                end
                
                b.isOrdinal = isOrdinal;
                b.isProtected = isProtected;
                
                % Remove spaces from cellstrs
                if iscellstr(inputData) %#ok<ISCLSTR>
                    inData = matlab.internal.coder.datatypes.cellstr_strtrim(inputData);
                    % call varsize to force homogeneous, preferably with an upper
                    % bound
                    if coder.internal.isConst(size(inData)) && ~coder.internal.isConst(inputData)
                        % Forcing inData to be homogeneous here when inputData is constant and
                        % heteregeneous will cause inData to be treated as non-constant later on,
                        % preventing some constant folding that would make b.categoryNames a
                        % constant size. If inputData is constant, b.categoryNames is instead made
                        % homogeneous when it is assigned (prior to returning from the
                        % constructor).
                        coder.varsize('inData', [], [false false]);
                    end
                else
                    inData = inputData;
                end
                
                % Clean up valueSet if provided
                if suppliedValueSet
                    % Make sure valueset is same class as input data
                    coder.internal.errorIf(isnumeric(inputData) && ~isnumeric(inputValueSet), 'MATLAB:categorical:NumericTypeMismatchValueSet');
                    coder.internal.errorIf(~isnumeric(inputData) && ~isequal(class(inputData),class(inputValueSet)), 'MATLAB:categorical:TypeMismatchValueset');
                    coder.internal.errorIf(issparse(inputValueSet), 'MATLAB:categorical:SparseData');
                    
                    iscellstrValueSet = iscellstr(inputValueSet); %#ok<ISCLSTR>
                    if iscellstrValueSet
                        valueSet = reshape(matlab.internal.coder.datatypes.cellstr_strtrim(inputValueSet),[],1); %column vector
                        
                        % Ensure that the cellstr is a homogeneous cell array so we can use non-constant indices
                        % Do this only for nonconstant valueSet. Constant
                        % valueSet gets homogenized after unique below
                        if ~coder.internal.isConst(inputValueSet) && coder.internal.isConst(size(valueSet))
                            coder.varsize('valueSet', [], [false false]);
                        end
                    elseif isa(inputValueSet,'matlab.internal.coder.categorical')
                        % If both inputData and valueSet are ordinal, their categories must match,
                        % although the elements of valueSet might be a subset or reordering of that.
                        if isa(inData,'matlab.internal.coder.categorical')
                            coder.internal.errorIf(inputValueSet.isOrdinal && ~isequal(inData.categoryNames,inputValueSet.categoryNames), ...
                                'MATLAB:categorical:ValuesetOrdinalCategoriesMismatch');
                        end
                        valueSet = inputValueSet(:);
                    else
                        % Error if unique does not work on the given valueset type
                        valueSet = inputValueSet(:); % turn into column vector
                    end
                    
                    % Catch multiple missing values in the valueSet, since unique treats them as
                    % distinct.
                    nmissing = sum(matlab.internal.coder.datatypes.isMissingValues(valueSet));
                    
                    coder.internal.errorIf(nmissing > 1, 'MATLAB:categorical:MultipleMissingInValueset');
                    
                    if coder.internal.isConst(valueSet)
                        uvalueSet = coder.const(feval('unique', coder.const(valueSet)));
                        % force homogeneous
                        if iscellstrValueSet && coder.internal.isConst(size(valueSet))
                            coder.varsize('uvalueSet', [], [false false]);
                        end
                    else
                    if iscellstrValueSet
                        uvalueSet = matlab.internal.coder.datatypes.cellstr_unique(valueSet);
                    else
                            uvalueSet = unique(valueSet);
                        end
                    end
                    
                    coder.internal.assert(numel(uvalueSet) == numel(valueSet),'MATLAB:categorical:DuplicatedValues');
                    
                    % Verify the number of categories before trying to do anything else.
                    coder.internal.assert(length(valueSet) <= categorical.maxNumCategories,'MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories);
                end
                
                % Clean up categoryNames if provided
                if suppliedCategoryNames
                    % Force homogeneous cell array
                    % Category names given explicitly, do not reorder them
                    categoryNames = b.checkCategoryNames(inputCategoryNames,0); % error if '', or '<undefined>', but allow duplicates
                    numelMisMatch = numel(categoryNames) ~= numel(valueSet);
                    coder.internal.errorIf(numelMisMatch && suppliedValueSet, 'MATLAB:categorical:WrongNumCategoryNamesValueset');
                    coder.internal.errorIf(numelMisMatch && ~suppliedValueSet, 'MATLAB:categorical:WrongNumCategoryNames');
                end
                
                if suppliedValueSet
                    if coder.internal.isConst(numel(inputValueSet))
                        % Since valueSet size is fixed, we can choose the right
                        % upperbound at compile time to set the non-tunable
                        % property.
                        b.numCategoriesUpperBound = coder.const(numel(inputValueSet));
                    else
                        % With variable-sized valueSet, we must choose the safest
                        % upperbound
                        b.numCategoriesUpperBound = coder.const(b.maxNumCategories - 1);
                    end
                else
                    if coder.internal.isConst(numel(inputData))
                        % Since valueSet size is fixed, we can choose the right
                        % upperbound at compile time to set the non-tunable
                        % property.
                        b.numCategoriesUpperBound = coder.const(numel(inputData));
                    else
                        % With variable-sized valueSet, we must choose the safest
                        % upperbound
                        b.numCategoriesUpperBound = coder.const(b.maxNumCategories - 1);
                    end
                end
                
                if suppliedValueSet && suppliedCategoryNames
                    % use numel(inputCategoryNames) rather than
                    % numel(categoryNames) as the last input because categoryNames
                    % may be variable sized
                    b = b.initFull(inData, valueSet, categoryNames);
                elseif suppliedValueSet % && ~suppliedCategoryNames
                    b = b.initDataValueSet(inData, valueSet);
                else % ~suppliedValueSet && ~suppliedCategoryNames
                    b = b.initData(inData);
                end
            end
            
        end %constructor

        function t = isprotected(a)
            %ISPROTECTED True if the categories in a categorical array are protected.
            t = a.isProtected;
        end
        
        function t = isordinal(a)
            %ISORDINAL True if the categories in a categorical array have a mathematical ordering.
            t = a.isOrdinal;
        end
        
        function b = parenReference(a, varargin)
            b = matlab.internal.coder.categorical(matlab.internal.coder.datatypes.uninitialized());
            b.codes = a.codes(varargin{:});
            b.categoryNames = a.categoryNames;
            b.isProtected = a.isProtected;
            b.isOrdinal = a.isOrdinal;
            b.numCategoriesUpperBound = a.numCategoriesUpperBound;
        end
        
        function a = parenAssign(a, b, varargin)
            anames = a.categoryNames;

            if isa(b,'matlab.internal.coder.categorical')
                bcodes = b.codes;
                bnames = b.categoryNames;
                % If b is categorical, its ordinalness has to match a, and if they are
                % ordinal, their categories have to match.
                coder.internal.assert(a.isOrdinal == b.isOrdinal, ...
                    'MATLAB:categorical:OrdinalMismatchAssign');
                
                if ~isequal(anames,bnames)
                    coder.internal.errorIf(~isequal(anames,bnames) && a.isOrdinal, 'MATLAB:categorical:OrdinalCategoriesMismatch');
                    
                    % Convert b's codes to a's codes. a's new set of categories grows only by
                    % the categories that are actually being assigned, and a never needs to
                    % care about the others in value that are not assigned.
                    if coder.internal.isConst(size(bcodes)) && isscalar(bcodes)
                        % When value is an <undefined> scalar, bcodes is already correct in
                        % a's codes (undefCode is the same in all categoricals) and no
                        % conversion is needed; otherwise, we can behave as if it only
                        % has the one category, and conversion to a's codes is faster.
                        if bcodes ~= 0 % categorical.undefCode
                            convertedbcodes = convertCodesLocal(1,bnames{bcodes},anames,class(a.codes));
                        else  % bcodes == 0
                            convertedbcodes = cast(bcodes,'like',a.codes);
                        end
                    else
                        % safe to cast as a and b have the same number of
                        % categories and a must be using a large enough
                        % integer type
                        convertedbcodes = convertCodesLocal(bcodes,bnames,anames,class(a.codes));
                    end
                else
                    convertedbcodes = cast(bcodes,'like',a.codes);
                end
            else
                coder.internal.assert( (ischar(b) && (isrow(b) || isequal(b,''))) || ... 
                    matlab.internal.coder.datatypes.isCharStrings(b), ...
                    'MATLAB:categorical:InvalidRHS', class(a));
                [bcodes,bnames] = a.strings2codes(b);
                convertedbcodes = convertCodesLocal(bcodes,bnames,anames,class(a.codes));
            end
            
            a.codes(varargin{:}) = convertedbcodes;
            a.categoryNames = anames;
        end
        
        % Relational Operators
        b = cellstr(a)
        t = eq(a,b)
        t = ge(a,b)
        t = gt(a,b)
        t = le(a,b)
        t = lt(a,b)
        t = ne(a,b)
    end
    
    methods(Hidden)
        % Unsupported methods that simply return an error message
        function b = char(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'char', 'categorical');
        end
        
        function [b,i] = maxk(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'maxk', 'categorical');
        end
            
        function b = median(~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'median', 'categorical');
        end
           
        function [b,i] = mink(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mink', 'categorical');
        end
        
        function [b,f,c] = mode(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mode', 'categorical');
        end
        
        function b = string(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'string', 'categorical');
        end
        
        function [cnts,headings] = summary(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'summary', 'categorical');
        end
        
        function c = times(~,~) %#ok<STOUT>
            % When adding support to this method, enable implicit
            % expansion:
            %coder.internal.implicitExpansionBuiltin;
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'times', 'categorical');
        end
        
        function [b,i] = topkrows(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'topkrows', 'categorical');
        end
            
    end % methods block

    methods(Access='protected')
        
        function b = getIndices(a)
            %GETINDICES Get the category indices of a categorical array.
            b = a.codes;
        end
        
        function b = strings2categorical(s,a)
            %STRINGS2CATEGORICAL Create a categorical array "like" another from strings
            b = categorical(matlab.internal.coder.datatypes.uninitialized());
            [is,us] = a.strings2codes(s);
            % an upperbound is the upperbound in a + number of elements in
            % s
            if ischar(s)
                ub_numcats = a.numCategoriesUpperBound + 1;
            else % cellstr
                ub_numcats = a.numCategoriesUpperBound + numel(s);
            end
            [b.codes,b.categoryNames] = a.convertCodes(is,us,a.categoryNames,...
                false,false,ub_numcats);
            b.isProtected = a.isProtected;
            b.isOrdinal = a.isOrdinal;
            b.numCategoriesUpperBound = ub_numcats;
        end
        
        function b = initFull(b, inputData, valueSet, categoryNames)
            % Input data set given explicitly, do not reorder them
            coder.internal.prefer_const(categoryNames);
            coder.extrinsic('unique');

             % force homogeneous
            homogeneousNames = categoryNames;
            if coder.internal.isConst(size(homogeneousNames))
                coder.varsize('homogeneousNames', [], [false false]);
            end
            
            % Duplicate names are not allowed in categoryNames for codegen
            if coder.internal.isConst(categoryNames)
                unames = coder.const(unique(coder.const(categoryNames)));
            else
                unames = matlab.internal.coder.datatypes.cellstr_unique(homogeneousNames); 
            end
            coder.internal.assert(numel(unames) == numel(categoryNames),'MATLAB:categorical:CodegenDuplicateCategoryNames');
            
            b.categoryNames = homogeneousNames;
            b.codes = b.getCodes(inputData, valueSet);
        end
        
        
        function b = initDataValueSet(b, inputData, valueSet)
            % Get category names from the valueSet
            b.categoryNames = b.getCategoryNames(valueSet);
            
            % Turn input data into codes based on valueSet
            b.codes = b.getCodes(inputData, valueSet);
        end
        
        
        function b = initData(b, inputData)

            iscellstrInput = iscellstr(inputData); %#ok<ISCLSTR>
            
            % Infer categories from categorical data's categories
            if isa(inputData,'matlab.internal.coder.categorical')
                valueSet = categories(inputData);
                icats = double(inputData.codes);
            % Else create valueSet from inputData
%             elseif isempty(inputData)
%                 % no-op
            else
                % Numeric, logical, cellstr, or anything else that has a unique
                % method, except char (already weeded out).  Cellstr has already had
                % leading/trailing spaces removed. Save the index vector for later.
                %coder.internal.errorIf(~ismethod(inputData,'unique'), 'MATLAB:categorical:UniqueMethodFailedData');

                if coder.internal.isConst(inputData)
                    [tempValueSet,~,icats] = feval('unique',reshape(inputData,[],1));
                    tempValueSet = coder.const(tempValueSet);
                    icats = coder.const(icats);
                elseif iscellstrInput
                        [tempValueSet,~,icats] = matlab.internal.coder.datatypes.cellstr_unique(inputData);
                elseif ~(coder.internal.isConst(size(inputData)) && isempty(inputData))
                    [tempValueSet,~,icats] = unique(inputData(:));
                else
                    tempValueSet = inputData;
                    icats = inputData;
                end

                % '' or NaN or <undefined> all become <undefined> by default, remove
                % those from the list of categories.
                % can assume the ValueSet has the same type as Input, because
                % it's constructed from the input in this case.
                iscellstrValueSet = iscellstrInput;
                if iscellstrValueSet
                    if coder.internal.isConst(inputData)
                        mask = coder.const(feval('cellfun','isempty',tempValueSet));
                        [valueSet,icats] = removeUtil(tempValueSet,icats,mask);
                    else
                        mask = false(numel(tempValueSet),1);
                        for k = 1:numel(tempValueSet)
                            mask(k) = isempty(tempValueSet{k});
                        end

                        [valueSet,icats] = removeUtil(tempValueSet,icats,mask);
                    end
                elseif isa(tempValueSet,'matlab.internal.coder.categorical')
                    % remove undefineds from the given categorical's codes
                    valueSet = categorical(matlab.internal.coder.datatypes.uninitialized());
                    valueSet.categoryNames = tempValueSet.categoryNames;
                    [valueSet.codes,icats] = removeUtil(tempValueSet.codes,icats,isundefined(tempValueSet));
                else % numeric
                    [valueSet,icats] = removeUtil(tempValueSet,icats,isnan(tempValueSet));
                end
            end

            % Verify the number of categories before trying to do anything else.
            coder.internal.assert(length(valueSet) <= categorical.maxNumCategories,'MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories);

            % valueSet is a column vector at this point
            tmpCategoryNames = b.getCategoryNames(valueSet);
            if coder.internal.isConst(tmpCategoryNames)
                % force categoryNames to be homogenous before assigning into
                % b.categoryNames
                tmpCategoryNamesCopy = tmpCategoryNames;
                coder.varsize('tmpCategoryNamesCopy',[],[false false]);
                b.categoryNames = tmpCategoryNamesCopy;
            else
                b.categoryNames = tmpCategoryNames;
            end
            
            % Assign category codes to each element of output
            b.codes = b.createCodes(size(inputData), numel(inputData));

            % We already have indices into categories because it was created by
            % calling unique(inputData), use those and save a call to ismember.
            b.codes(:) = icats(:);
        end
        

        function c = cloneAsEmpty(a)
            %CLONEASEMPTY Create an empty catgegorical with the same categories.
            coder.inline('always');
            c = categorical(matlab.internal.coder.datatypes.uninitialized);
            c.categoryNames = a.categoryNames;
            c.isProtected = a.isProtected;
            c.isOrdinal = a.isOrdinal;
            c.numCategoriesUpperBound = a.numCategoriesUpperBound;
        end
    end % protected methods block

    methods (Access = 'private')
        % Helper methods for constructor
        outCategoryNames = getCategoryNames(a,valueSet)
        codes = getCodes(a,inputData, valueSet)
    end
    
    methods (Static, Hidden)
        function b = matlabCodegenFromRedirected(a)
            b = categorical.codegenInit(a.codes, a.categoryNames,a.isOrdinal,a.isProtected);
        end
        
        function b = matlabCodegenToRedirected(a)
            cats = categories(a);
            b = matlab.internal.coder.categorical(cellstr(a), cats, cats, 'Ordinal', isordinal(a), 'Protected', isprotected(a));
            if isequal(size(cats),[0,0])
                % If cats is a 0x0 empty then the original categorical was
                % created without specifying category names, so preserve that
                % fact.
                b.categoryNames = cell(0,0);
            end
        end

        function result = matlabCodegenSoftNontunableProperties(~)
            result = {'isOrdinal', 'isProtected', 'numCategoriesUpperBound'};
        end

        function name = matlabCodegenUserReadableName
            % Make this look like a categorical (not the redirected categorical) in the codegen report
            name = 'categorical';
        end

        function t = matlabCodegenTypeof(~)
            t = 'matlab.coder.type.CategoricalType';
        end
    end
    
    methods(Hidden = true)
        % The default properties method works as desired
        
        %% Methods we don't want to clutter things up with
        e = end(a,k,n)
    
        function [codes,categoryNames] = codesAndCats(obj)
            codes = obj.codes;
            categoryNames = obj.categoryNames;
        end
        function objOut = fastCtor(objIn,codesIn)
            % Copy information from objIn (categories, ordinal, protected) into a new output
            % with codesIn. Reusing objIn by overwriting objIn.codes fails in codegen when
            % codesIn is a different size than objIn.codes.
            %obj.codes = cast(codesIn,"like",obj.codes);
            objOut = matlab.internal.coder.categorical(matlab.internal.coder.datatypes.uninitialized());
            objOut.codes = cast(codesIn,"like",objIn.codes);
            objOut.categoryNames = objIn.categoryNames;
            objOut.isProtected = objIn.isProtected;
            objOut.isOrdinal = objIn.isOrdinal;
            objOut.numCategoriesUpperBound = objIn.numCategoriesUpperBound;
        end
    end
    
    methods(Static, Access = private)        
        function outputCodes = castCodes(codes, numCats)
            % CASTCODES picks an integer class that is capable of encoding 'numCats' many
            % unique categories, and casts the input codes to that class.
            
            % Cast codes to the new class. This turns NaN in floating point (see e.g. min
            % and max) into a 0 integer code (i.e. <undefined>).
            %
            % Number of categories is INTMAX(class) minus one to allow for an invalid
            % code at the high end        
            coder.internal.prefer_const(numCats);
            if coder.internal.isConst(numCats)
                % select the smallest integer type that can contain the
                % number of categories. 
                if numCats <= 255-1 % intmax('uint8')-1
                    outputCodes = uint8(codes);
                elseif numCats <= 65535-1 % intmax('uint16')-1
                    outputCodes = uint16(codes);
                else  
                    % maximum size uint32. Codegen doesn't need uint64 because 
                    % of the maximum array size limit 2^31-1
                    outputCodes = uint32(codes);
                end
            else
                % if there is no information about how many categories,
                % just use the largest integer type
                outputCodes = uint32(codes);
            end
        end
        
        function [aoutCodes, boutCodes] = castCodesForBuiltins(acodes, bcodes)
            % If there are undefined elements, convert to floating to leverage
            % builtin NaN behavior. But minimize the memory footprint. If the
            % values are not compile-time constants then always convert to float
            % but still try to minimize the memory footprint.
            if nargin == 1
                if ~coder.internal.isConst(acodes) ...
                        || (nnz(acodes) < numel(acodes)) % faster than any(acodes(:)==categorical.undefCode)
                    if categorical.invalidCode(acodes) <= flintmax('single')
                        aoutCodes = single(acodes);
                    else
                        aoutCodes = double(acodes);
                    end
                    aoutCodes(aoutCodes==categorical.undefCode) = NaN;
                else
                    aoutCodes = acodes;
                end
            else % nargin == 2
                aInvalidCode = categorical.invalidCode(acodes);
                bInvalidCode = categorical.invalidCode(bcodes);
                if ~coder.internal.isConst(acodes) || ~coder.internal.isConst(bcodes) ...
                    || (nnz(acodes) < numel(acodes)) || (nnz(bcodes) < numel(bcodes)) % faster than any(...)
                    single_flintmax = flintmax('single');
                    if (aInvalidCode <= single_flintmax) && (bInvalidCode <= single_flintmax)
                        aoutCodes = single(acodes);
                        boutCodes = single(bcodes);
                    else
                        aoutCodes = double(acodes);
                        boutCodes = double(bcodes);
                    end

                    aoutCodes(aoutCodes==categorical.undefCode) = NaN;
                    boutCodes(boutCodes==categorical.undefCode) = NaN;
                elseif aInvalidCode == bInvalidCode
                    % don't cast unless necessary
                    aoutCodes = acodes;
                    boutCodes = bcodes;
                elseif aInvalidCode > bInvalidCode
                    aoutCodes = acodes;
                    boutCodes = cast(bcodes, 'like', acodes);
                else % aIinvalidCode < bInvalidCode
                    aoutCodes = cast(acodes, 'like', bcodes);
                    boutCodes = bcodes;
                end
            end
        end
        
        code = invalidCode(codes)
        [bcodes,bnames] = convertCodes(bcodes,bnames,anames,aprotect,bprotect)
        [hasStable, hasRows] = processSetMembershipFlags(flags)
        [codes,ia,ib] = setmembershipHelper(setfun,acodes,bcodes,varargin)

        function codes = createCodes(codesize, numcats)
            coder.internal.prefer_const(numcats);
            if coder.internal.isConst(numcats)
                % select the smallest integer type that can contain the
                % number of categories
                if numcats <= 255-1 % intmax('uint8')-1
                    codes = zeros(codesize,'uint8');
                elseif numcats <= 65535-1 % intmax('uint16')-1
                    codes = zeros(codesize,'uint16');
                else
                    % maximum size uint32. Codegen doesn't need uint64 because 
                    % of the maximum array size limit 2^31-1
                    codes = zeros(codesize,'uint32');
                end
            else
                % if there is no information about how many categories,
                % just use the largest integer type
                codes = zeros(codesize,'uint32');
            end
        end
        
        [is,us] = strings2codes(s)
        
        checkednames = checkCategoryNames(names,dupFlag)
        
    end % static private methods block

    methods(Static, Access=protected)
        a = catUtil(dim,useSpecializedFcn,varargin)
    end
end % classdef

function [out,ic] = removeUtil(c,ic,t)
% Remove elements from c, and update ic's indices into c -- zero out the ones
% that point to elements being removed from c, and shift down the remaining
% ones to point into the reduced version of c
% Assume t is a column vector
if any(t,1)
    q = find(~t);
    convert = zeros(size(c)); convert(q) = 1:length(q);
    ic = convert(ic);
    if iscell(c)
        sz = numel(q);
        out = cell(sz,1);
        for i = 1:sz
            out{i} = c{q(i)};
        end
    else
        out = c(q);
    end
else
    out = c;
end
end

function tf = isNVpair(arg)
tf = (ischar(arg) || (isstring(arg) && isscalar(arg))) && coder.internal.isConst(arg) && ...
    strlength(arg) > 0 && (startsWith('Ordinal',arg,'IgnoreCase',true) || startsWith('Protected',arg,'IgnoreCase',true));
end


function bcodesout = convertCodesLocal(bcodes,bnames,anames,acodesclass)
% This is a version of convertCodes modified for the specifics of subsasgn.
% Assigning from b into a, with the limitation that b cannot introduce new
% categories(all b categories must be present in a), so:
% * Category names stay the same, no need to return
% * It doesn't matter if a or b is protected or not since category names
% stay the same, so no need to pass in
% * Requires the class of codes in a, codes in b will be the same class
% * Only error if the value actually being assigned are not categories in
% a. Unused categories in b are irrelevant.

% nothing to do if bnames is empty, all undefined
if ~isempty(bnames)  
    if ischar(bnames)
        % simplified code if bnames is a char vector
        bcodesout = zeros(acodesclass);  % same class as acodes
        for i = 1:numel(anames)
            if strcmp(bnames, anames{i})
                bcodesout(1) = i;
                break;
            end
        end
        coder.internal.assert(bcodesout > 0, 'MATLAB:categorical:AssignNewCategories');
                
    else % iscellstr(bnames)
        % Get a's codes for b's data.
        [tf,ia] = matlab.internal.coder.datatypes.cellstr_ismember(bnames,anames);
        tf = reshape(tf,1,[]);
        % only error if new categories are used, ignore unused categories
        bcodesrow = bcodes(:).';
        coder.internal.assert(all(tf(bcodesrow(bcodesrow > 0)),2), 'MATLAB:categorical:AssignNewCategories');
        
        % creating mapping from bcodes to acodes. The one extra element at the
        % beginning is for undefined category.
        b2a = zeros(1,length(bnames)+1, acodesclass); % same class as acodes
        b2a(2:end) = ia;

        % Add 1 to bcodes to deal with undefined category
        bcodesout = zeros(size(bcodes),acodesclass);
        bcodesout(:) = b2a(bcodes+1);
    end
else
    bcodesout = cast(bcodes, acodesclass);
end
end
