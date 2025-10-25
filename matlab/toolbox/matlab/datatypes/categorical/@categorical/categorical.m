classdef (AllowedSubclasses = {?nominal, ?ordinal}, ...
        InferiorClasses = {?matlab.graphics.axis.Axes, ?matlab.ui.control.UIAxes} ) categorical ...
        < matlab.mixin.internal.MatrixDisplay ...
        & matlab.mixin.internal.indexing.Paren ...
        & matlab.mixin.internal.indexing.ParenAssign
%

%   Copyright 2013-2024 The MathWorks, Inc.
          
    properties(Constant, GetAccess='private')
        defaultCodesClass = 'uint8'; % see castCodes() method
        % label used in display of missing strings
        missingLabel = '<missing>'; 
    end
    
    properties(Constant, GetAccess={?categorical, ?matlab.unittest.TestCase})
        % Internal code for undefined elements.
        % This does not need to be the same class as codes because zeros
        % compare correctly across numeric classes
        
        undefCode = 0;
    end
    
    properties(Hidden, Constant, GetAccess='public')
        % Text label for displaying undefined elements.
        undefLabel = '<undefined>';

        
        % Maximum number of categories: even with UINT64 codesClass, limit
        % this to maximum array size allowed in MATLAB
        maxNumCategories = maxArraySizeLimit; % see castCodes() method
    end    
    
    properties(GetAccess='protected', SetAccess='protected')
        categoryNames = {};
        codes = zeros(0,categorical.defaultCodesClass);
        isProtected = false;
        isOrdinal = false;
    end
    
    methods(Access='public')
        function b = categorical(inputData,varargin)
        import matlab.internal.datatypes.validateLogical

        if nargin == 0
            % Nothing to do
            return
        end
        
        % Pull out optional positional inputs, which cannot be char
        if (nargin == 1) || isNVpair(varargin{1})
            % categorical(inputData) or categorical(inputData,Name,Value,...)
            suppliedValueSet = false;
            suppliedCategoryNames = false;
        elseif (nargin == 2) || isNVpair(varargin{2})
            % categorical(inputData,valueSet) or categorical(inputData,valueSet,Name,Value,...)
            suppliedValueSet = true;
            valueSet = varargin{1};
            suppliedCategoryNames = false;
            varargin = varargin(2:end);
        else
            % categorical(inputData,valueSet,categoryNames) or categorical(inputData,valueSet,categoryNames,Name,Value,...)
            suppliedValueSet = true;
            valueSet = varargin{1};
            suppliedCategoryNames = true;
            categoryNames = varargin{2};
            varargin = varargin(3:end);
        end
            
        pnames = {'Ordinal' 'Protected'};
        dflts =  {   false       false };
        try
            [isOrdinal,isProtected,supplied] = ...
                matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:}); %#ok<*PROP>
        catch ME
            if ME.identifier == "MATLAB:table:parseArgs:WrongNumberArgs" && isNVpair(varargin{1})
                % Give a helpful error message for one-category edge cases like
                %     categorical(data,'ordinal')
                % OR  categorical(data,1,"protected")
                pnameRaw = mat2str(varargin{1});
                matchedPname = mat2str(pnames{startsWith(pnames,varargin{1},IgnoreCase=true)});
                if suppliedValueSet
                    if ~suppliedCategoryNames
                        ME = ME.addCause(MException(message('MATLAB:categorical:ParamNameCategoryNames',pnameRaw,matchedPname,varargin{1})));
                    end
                else
                    ME = ME.addCause(MException(message('MATLAB:categorical:ParamNameValueset',pnameRaw,matchedPname,varargin{1})));
                end
            end
            throw(ME);
        end
        isOrdinal = validateLogical(isOrdinal,'Ordinal');
        isProtected = validateLogical(isProtected,'Protected');
        if isOrdinal
            if supplied.Protected
               if ~isProtected
                   error(message('MATLAB:categorical:UnprotectedOrdinal'));
               end
            else
                isProtected = true;
            end
        end
        b.isOrdinal = isOrdinal;
        b.isProtected = isProtected;
        
        if isa(inputData, 'missing')
            
            if ~suppliedValueSet
                inputData = string(inputData);
            elseif iscellstr(valueSet) %#ok<ISCLSTR>
                % Missing and missingLike do not generally support cell, but for
                % flexibility in supporting text inputs in categorical, force it
                % to string.
                inputData = string(inputData);
            else
                % Use the same approach to convert missing to the type-specific
                % missing value as is used in missing.convertCell.
                inputData = matlab.internal.datatypes.missingLike(inputData,valueSet);
            end
        end
        
        iscellstrInput = iscellstr(inputData);
        isstringInput =  isstring(inputData);
        
        % Catch some inputs that are specifically disallowed.
        if ischar(inputData)
            error(message('MATLAB:categorical:CharData'));
        elseif istabular(inputData)
            error(message('MATLAB:categorical:TableData'));
        end
        % Remove spaces from cellstrs or strings
        if iscellstrInput || isstringInput
            inputData = strtrim(inputData);
        end
        
        % Input data set given explicitly, do not reorder them
        if suppliedValueSet
            % input set can never be char, char is recognized as a param name
            iscellstrValueSet = iscellstr(valueSet); %#ok<ISCLSTR>
            isstringValueSet = isstring(valueSet);
            
            % Allow mixed input of string data and cellstr valueSet, e.g.
            % categorical(["a" "b" "c"],{'a' 'b' 'c'}). Convert the valueSet to
            % string.
            if isstringInput && iscellstrValueSet
                valueSet = string(valueSet);
                % reset flags after converting valueSet to string
                iscellstrValueSet = false;
                isstringValueSet = true;
            end
            
            if iscellstrValueSet || isstringValueSet
                valueSet = strtrim(valueSet(:));
                % unique will remove duplicate empty character vectors or strings
            elseif isa(valueSet,'categorical')
                % If both inputData and valueSet are ordinal, their categories must match,
                % although the elements of valueSet might be a subset or reordering of that.
                if isa(inputData,'categorical') && valueSet.isOrdinal
                    if ~isequal(inputData.categoryNames,valueSet.categoryNames)
                        error(message('MATLAB:categorical:ValuesetOrdinalCategoriesMismatch'));
                    end
                end
                valueSet.codes = valueSet.codes(:);
            else
                valueSet = valueSet(:);
            end
            
            % Catch multiple missing values in the valueSet, since unique treats them as
            % distinct.
            try
                nmissing = sum(ismissing(valueSet));
            catch % in case the valueset is made up of objects for which ismissing is not defined.
                nmissing = 0;
            end
            if nmissing > 1
                error(message('MATLAB:categorical:MultipleMissingInValueset'));
            end
            
            try
                uvalueSet = unique(valueSet);
            catch ME
                throw(addCause(MException(message('MATLAB:categorical:UniqueMethodFailedValueset')),ME));
            end
            if length(uvalueSet) < length(valueSet)
                error(message('MATLAB:categorical:DuplicatedValues'));
            end
            
        % Infer categories from categorical data's categories
        elseif isa(inputData,'categorical')
            valueSet = categories(inputData);
            icats = double(inputData.codes);
            iscellstrValueSet = true;
            
        % Infer categories from the data, they are first sorted
        else % ~suppliedValueSet
            % Numeric, logical, cellstr, or anything else that has a unique
            % method, except char (already weeded out).  Cellstr has already had
            % leading/trailing spaces removed. Save the index vector for later.
            % Unique enforces cellstr - it errors for cell arrays that contain char
            % matrices.
            try
                [valueSet,~,icats] = unique(inputData(:));
            catch ME
                throw(addCause(MException(message('MATLAB:categorical:UniqueMethodFailedData')),ME));
            end
            
            % When valueSet is not provided, '' or NaN or <undefined> in the
            % data become <undefined> elements, no category is created for them.
            % Only when specified in valueSet do those values become non-missing
            % in the output. Remove those from the list of categories.
            %
            % valueSet has the same type as the data, it's constructed from the data.
            iscellstrValueSet = iscellstrInput;
            isstringValueSet = isstringInput;
            if iscellstrValueSet
                [valueSet,icats] = removeUtil(valueSet,icats,cellfun('isempty',valueSet));
            elseif isstringValueSet
                [valueSet,icats] = removeUtil(valueSet,icats,valueSet=="" | ismissing(valueSet));
            elseif isa(valueSet,'categorical')
                % can't use categorical subscripting on valueSet, go directly to the codes
                [valueSet.codes,icats] = removeUtil(valueSet.codes,icats,isundefined(valueSet));
            else 
                [valueSet,icats] = removeUtil(valueSet,icats,ismissing(valueSet));
            end
        end
        
        % Verify the number of categories before trying to do anything else.
        if length(valueSet) > categorical.maxNumCategories
            error(message('MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories));
        end
        
        % valueSet is a column vector at this point

        % Category names given explicitly, do not reorder them
        mergingCategories = false;
        if suppliedCategoryNames
            categoryNames = checkCategoryNames(categoryNames,0); % error if '', or '<undefined>', but allow duplicates
            if length(categoryNames) ~= length(valueSet)
                if suppliedValueSet
                    error(message('MATLAB:categorical:WrongNumCategoryNamesValueset'));
                else
                    error(message('MATLAB:categorical:WrongNumCategoryNames'));
                end
            end
            
            % If the category names contain duplicates, those will be merged
            % into identical categories.  Remove the duplicate names, put the
            % categories corresponding to those names at the end so they'll
            % be easier to remove, and create a map from categories to the
            % ultimate internal codes.
            [unames,i,j] = unique(categoryNames,'stable');
            mergingCategories = (length(unames) < length(categoryNames));
            if mergingCategories
                dups = setdiff(1:length(categoryNames),i);
                categoryNames = unames;
                ord = [i(:); dups(:)];
                valueSet = valueSet(ord);
                mergeConvert(2:(length(ord)+1)) = j(ord);
            end
            
            b.categoryNames = cellstr(categoryNames);
            
        % Infer category names from the input data set, which in turn may be
        % inferred from the input data.  The value set has already been unique'd
        % and turned into a column vector
        elseif ~isempty(valueSet) % if valueSet is empty, no need to create names
            if isnumeric(valueSet) && ~isenum(valueSet)
                if isfloat(valueSet) && any(valueSet ~= round(valueSet))
                    % Create names using 5 digits. If that fails to create
                    % unique names, the caller will have to provide names.
                    b.categoryNames = strtrim(cellstr(num2str(valueSet,'%-0.5g')));
                else
                    % Create names that preserve all digits of integers and
                    % (up to 16 digits of) flints.
                    b.categoryNames = strtrim(cellstr(num2str(valueSet)));
                end
                if length(unique(b.categoryNames)) < length(b.categoryNames)
                    error(message('MATLAB:categorical:CantCreateCategoryNames'));
                end
            elseif islogical(valueSet)
                categoryNames = {'false'; 'true'};
                b.categoryNames = categoryNames(valueSet+1);
                % elseif ischar(valueSet)
                % Char valueSet is not possible
            elseif isenum(valueSet)
                % char gives size+type on enum, use string to get enum names.
                b.categoryNames = cellstr(string(valueSet));
            elseif iscellstrValueSet
                % These may be specifying character values, or they may be
                % specifying categorical values via their names.
                
                % We will not attempt to create a name for the empty char
                % vectors or the undefined categorical label.  Names must
                % given explicitly.
                if matches(categorical.undefLabel,valueSet) %undefLabel is scalar
                    error(message('MATLAB:categorical:UndefinedLabelCategoryName', categorical.undefLabel));
                elseif matches(categorical.missingLabel,valueSet) %missingLabel is scalar
                    error(message('MATLAB:categorical:UndefinedLabelCategoryName', categorical.missingLabel));
                elseif matches("",valueSet)
                    error(message('MATLAB:categorical:EmptyCategoryName'));
                end
                b.categoryNames = valueSet(:);
            elseif isstringValueSet
                % Similar to cellstr case. We will not attempt to create a name
                % for the empty or missing string, or for the undefined
                % categorical label. Names must given explicitly.
                if matches(categorical.undefLabel,valueSet)
                    error(message('MATLAB:categorical:UndefinedLabelCategoryName', categorical.undefLabel));
                elseif matches(categorical.missingLabel,valueSet)
                    error(message('MATLAB:categorical:UndefinedLabelCategoryName', categorical.missingLabel));
                elseif matches("",valueSet) || any(ismissing(valueSet))
                    error(message('MATLAB:categorical:EmptyCategoryName'));
                end
                b.categoryNames = cellstr(valueSet);
            elseif isa(valueSet,'categorical')
                % We will not attempt to create a name for an undefined
                % categorical element.  Names must given explicitly.
                if any(isundefined(valueSet))
                    error(message('MATLAB:categorical:UndefinedInValueset'));
                end
                bnames = cellstr(valueSet);  % can't use categorical subscripting to
                b.categoryNames = bnames(:); % get a col, force the cellstr instead
            else
                % Anything else that has a char method
                try
                    charcats = char(valueSet); % valueSet a column vector
                catch ME
                    if suppliedValueSet
                        m = message('MATLAB:categorical:CharMethodFailedValueset');
                    else
                        m = message('MATLAB:categorical:CharMethodFailedData');
                    end
                    throw(addCause(MException(m),ME));
                end
                if ~ischar(charcats) || (size(charcats,1) ~= numel(valueSet))
                    if suppliedValueSet
                        error(message('MATLAB:categorical:CharMethodFailedValuesetNumRows'));
                    else
                        error(message('MATLAB:categorical:CharMethodFailedDataNumRows'));
                    end
                end
                
                catNames = strtrim(cellstr(charcats));
                if length(unique(catNames)) ~= numel(valueSet)
                    if isa(valueSet,'datetime')
                        valueSet.Format = 'default';
                        catNames = strtrim(cellstr(valueSet));
                        if length(unique(catNames)) ~= numel(valueSet)
                            error(message('MATLAB:categorical:DuplicatedCatNamesDatetime'));
                        end
                    elseif isa(valueSet,'duration')
                        error(message('MATLAB:categorical:DuplicatedCatNamesDuration'));
                    else
                        error(message('MATLAB:categorical:DuplicatedCatNames'));
                    end
                end
                b.categoryNames = catNames;
            end
        end
        
        % Assign category codes to each element of output.
        % Use the length of the valueSet to determine the type of codes to avoid
        % potential overflow issues. If the number of unique categories is less
        % than the number of values, then we might end up updating the type
        % later on.
        codes = zeros(size(inputData),categorical.defaultCodesClass);
        b.codes = categorical.castCodes(codes,length(valueSet));
        if ~suppliedValueSet
            % If we already have indices into categories because it was created by
            % calling unique(inputData), use those and save a call to ismember.
            b.codes(:) = icats(:);
        else
            if isnumeric(inputData)
                if ~isnumeric(valueSet)
                    error(message('MATLAB:categorical:NumericTypeMismatchValueSet'));
                end
                [~,b.codes(:)] = ismember(inputData,valueSet);
                % NaN may have been given explicitly as a category, but there's
                % at most one by now
                if any(isnan(valueSet))
                    b.codes(isnan(inputData)) = find(isnan(valueSet));
                end
            elseif islogical(inputData)
                if islogical(valueSet)
                    % OK, nothing to do
                elseif isnumeric(valueSet)
                    valueSet = logical(valueSet);
                else
                    error(message('MATLAB:categorical:TypeMismatchValueset'));
                end
                trueCode = find(valueSet);
                falseCode = find(~valueSet);
                % Already checked that valueSet contains unique values, but
                % still need to make sure it has at most one non-zero.
                if length(trueCode) > 1
                    error(message('MATLAB:categorical:DuplicatedLogicalValueset'));
                end
                if ~isempty(trueCode),  b.codes(inputData)  = trueCode;  end
                if ~isempty(falseCode), b.codes(~inputData) = falseCode; end
            elseif iscellstrInput
                if ~(iscellstrValueSet||isstringValueSet) % ismember requires that both inputs be of the same type
                    error(message('MATLAB:categorical:TypeMismatchValueset'));
                end
                % inputData and valueSet have already had leading/trailing spaces removed
                [~,b.codes(:)] = ismember(inputData,valueSet);
            elseif isstringInput
                if ~(iscellstrValueSet||isstringValueSet) % ismember requires that both inputs be of the same type
                    error(message('MATLAB:categorical:TypeMismatchValueset'));
                end
                % inputData and valueSet have already had leading/trailing spaces removed
                [~,b.codes(:)] = ismember(inputData,valueSet);
                if any(ismissing(valueSet))
                    b.codes(ismissing(inputData)) = find(ismissing(valueSet));
                end

            elseif isa(inputData,'categorical')
                % This could be done in the generic case that follows, but this
                % should be faster.
                convert = zeros(1,length(inputData.categoryNames)+1,'like',b.codes);
                if isa(valueSet,class(inputData))
                    undef = find(isundefined(valueSet)); % at most 1 by now
                    if ~isempty(undef), convert(1) = undef(1); end
                    valueSet = cellstr(valueSet); iscellstrValueSet = true;  %#ok<NASGU>
                elseif iscellstrValueSet || isstringValueSet
                    % Leave them alone
                else
                    error(message('MATLAB:categorical:TypeMismatchValueset'));
                end
                [~,convert(2:end)] = ismember(inputData.categoryNames,valueSet);
                b.codes(:) = reshape(convert(inputData.codes+1), size(inputData.codes));
            else % anything else that has an eq method, except char (already weeded out)
                if  ~isa(valueSet,class(inputData))
                    error(message('MATLAB:categorical:TypeMismatchValueset'));
                end
                try
                    for i = 1:length(valueSet)
                        b.codes(inputData==valueSet(i)) = i;
                    end
                catch ME
                    throw(addCause(MException(message('MATLAB:categorical:EQMethodFailedDataValueset')),ME));
                end
            end
        end
        
        % Merge categories that were given identical names. If the unique number
        % of categories can be encoded using a smaller type then update the
        % type of b.codes.
        if mergingCategories
            b.codes = categorical.castCodes(reshape(mergeConvert(b.codes+1),size(b.codes)), length(b.categoryNames));
        end

        end % categorical constructor
        
        function t = isprotected(a)
            t = a.isProtected;
        end
        
        function t = isordinal(a)
            t = a.isOrdinal;
        end

        function t = keyMatch(a,b)
            if isa(a,"categorical") && isa(b,"categorical")
                aIsOrdinal = a.isOrdinal;
                if b.isOrdinal ~= aIsOrdinal 
                    t = false; return
                elseif isequal(b.categoryNames,a.categoryNames)
                    bcodes = b.codes;
                elseif ~aIsOrdinal
                    % Get a's codes for b's data, ignoring protectedness.
                    bcodes = convertCodes(b.codes,b.categoryNames,a.categoryNames);
                else
                    t = false; return
                end
                t = isequal(a.codes,bcodes); % isequaln is not required as codes are integers
            else
                t = false;
            end
        end

        function h = keyHash(c)
            %

            % Use a combination ({cats, counts}) of the category names that are
            % present in the categorical array and their respective counts to
            % generate the hash. This is necessary to ensure that matching
            % categorical keys generate the same hash even if they have the
            % category names in different order or they contain different set of
            % category names.
            cats = c.categoryNames;

            % Get the counts for each category name (including <undefined>).
            counts = accumarray(c.codes(:)+1,1);

            % Filter out non-existent categories and their counts
            idx = counts > 0;
            counts = counts(idx);
            % The first entry in the counts array refers to the counts for
            % <undefined> values, since we do not include categorical.undefLabel
            % in cats, exclude that element when indexing into cats.
            cats = cats(idx(2:end));

            % Sort the category names and reorder the counts before calculating
            % the hash of {cats, counts}. This  would ensure that we generate
            % the same hash for categoricals with category names in different
            % order.
            [cats,sortOrder] = sort(cats);
            h = keyHash({cats,counts(sortOrder)});
        end

    end % methods block

    methods(Access='protected')
        function b = strings2categorical(s,a)
            %

            %STRINGS2CATEGORICAL Create a categorical array "like" another from strings
            b = a;
            [is,us] = strings2codes(s);
            [b.codes,b.categoryNames] = convertCodes(is,us,a.categoryNames);
        end
        function missingText = getMissingTextDisplay(obj)
            %

            % Return display text for categorical missing elements
            missingText = obj.missingLabel;
        end
    end % protected methods block
            
    methods(Hidden = true)
        % The default properties method works as desired

        %% For createArray
        function c = createArrayLike(template, sz, fillval)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            arguments
                template
                sz
                % Use missing as the default fill value instead of
                % categorical(NaN) to ensure createArray doesn't error when
                % template is a protected or ordinal categorical.
                fillval = missing;
            end
            c = matlab.internal.datatypes.createArrayLike(template, sz, fillval);
        end
        
        %% Methods we don't want to clutter things up with
        disp(a,name)
        e = end(a,k,n)
        [varargout] = subsref(this,s)
        this = subsasgn(this,s,rhs)
        i = subsindex(a)
        that = parenReference(this,rowIndices,colIndices,varargin)
        this = parenAssign(this,that,rowIndices,colIndices,varargin)
        sz = numArgumentsFromSubscript(c,s,context)
        
        %% Charting helpers
        % These functions are for internal use only and will change in a
        % future release.  Do not use this function.        
        [ax,ycodes,ctrs,xnames] = categoricalHist(ax,y,x)
        h = categoricalHistogram(~,args,cax)
        
        %% Variable Editor methods
        % These functions are for internal use only and will change in a
        % future release.  Do not use this function.
        out = variableEditorPaste(this,rows,columns,data)
        out = variableEditorInsert(this,orientation,row,col,data)
        [out,warnmsg] = variableEditorColumnDeleteCode(~,varName,colIntervals)
        [out,warnmsg] = variableEditorRowDeleteCode(~,varName,rowIntervals)
        [str,msg] = variableEditorSetDataCode(a,varname,row,col,rhs)
        [sortCode,msg] = variableEditorSortCode(~,varName,columnIndexStrings,direction)
        [out,warnmsg] = variableEditorClearDataCode(a,varname,rows,cols)

        %% summary helper
        % This function is for internal use only and will change in a
        % future release.  Do not use this function.
        displayWholeSummary(a,dim)
    
        %% Error stubs
        % Methods to override functions and throw helpful errors
        function a = fields(varargin), throwUndefinedError; end %#ok<STOUT>
        function a = fieldnames(varargin), throwUndefinedError; end %#ok<STOUT>
    end
    
    methods(Static = true, Hidden = true)
        function a = empty(varargin)
            if nargin == 0
                acodes = [];
            else
                acodes = zeros(varargin{:});
                if ~isempty(acodes)
                    error(message('MATLAB:class:emptyMustBeZero'));
                end
            end
            a = categorical(acodes);
        end

        function c = createArray(sz, fillval)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            if nargin == 1
                fillval = categorical(missing); % default fill value
            elseif ~isscalar(fillval) % must be scalar
                error(message("MATLAB:createArray:invalidFillValueForClass","categorical"));
            elseif ~iscategorical(fillval)
                % If the fill value isn't already a categorical, try
                % converting it to a categorical and throw a more helpful
                % error if it fails.
                try
                    fillval = categorical(fillval);
                catch ME
                    ME = addCause(MException(message('MATLAB:invalidConversion', "categorical", class(fillval))), ME);
                    throw(ME);
                end
            end
            % At this point fillval is a scalar categorical with the right
            % value, so repmat it to the right size.
            c = repmat(fillval, sz);
        end
        
        function obj = loadobj(obj)
            if isstruct(obj)
                obj = categorical(obj.codes, 1:length(obj.categoryNames), obj.categoryNames);
            else
                % If the saved object was a previous version of categorical that always 
                % used uint16 codes, we may be able to shrink it to uint8.
                obj.codes = categorical.castCodes(obj.codes,length(obj.categoryNames));
            end
        end
         
        function a = codegenInit(codes, categories, isordinal, isprotected)
            a = categorical;
            a.codes = codes;
            a.categoryNames = categories;
            a.isOrdinal = isordinal;
            a.isProtected = isprotected;
        end
             
        function name = matlabCodegenRedirect(~)
            % This function is for internal use only and will be removed in a
            % future release.  Do not use this function.
            
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.categorical';
        end
    end
    
    methods(Access = {?matlab.internal.math.categoricalAccessor})
        function [codes,categoryNames] = codesAndCats(obj)
            codes = obj.codes;
            categoryNames = obj.categoryNames;
        end
        function obj = fastCtor(obj,codesIn)
            obj.codes = cast(codesIn,"like",obj.codes);
        end
    end
    
    methods(Static, Access = {?matlab.unittest.TestCase})
        function codes = castCodes(codes, numCats)
            % CASTCODES picks an integer class that is capable of encoding 'numCats' many
            % unique categories, and casts the input codes to that class.
            
            % Cast codes to the new class. This turns NaN in floating point (see e.g. min
            % and max) into a 0 integer code (i.e. <undefined>).
            %
            % Number of categories is INTMAX(class) minus one to allow for an invalid
            % code at the high end; except with UINT64, the limit is maximum array size
            % allowed in MATLAB (i.e. categorical.maxNumCategories)
            if numCats <= 255-1 % intmax('uint8')-1
                codes = uint8(codes);
            elseif numCats <= 65535-1 % intmax('uint16')-1
                codes = uint16(codes);
            elseif numCats <= 4294967295-1 % intmax('uint32')-1
                codes = uint32(codes);
            elseif numCats < categorical.maxNumCategories
                codes = uint64(codes);
            else % Error if exceeded maximum allowed number of categories
                throwAsCaller(message('MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories));
            end
        end
        
        function [acodes, bcodes] = castCodesForBuiltins(acodes, bcodes)
        % If there are undefined elements, convert to floating to leverage
        % builtin NaN behavior. But minimize the memory footprint.
            if nargin == 1
                if nnz(acodes) < numel(acodes) % faster than any(acodes(:)==categorical.undefCode)
                    if invalidCode(acodes) <= flintmax('single')
                        acodes = single(acodes);
                    else
                        acodes = double(acodes);
                    end
                    acodes(acodes==categorical.undefCode) = NaN;
                end
            else % nargin == 2
                aInvalidCode = invalidCode(acodes);
                bInvalidCode = invalidCode(bcodes);
                if (nnz(acodes) < numel(acodes)) || (nnz(bcodes) < numel(bcodes)) % faster than any(...)
                    single_flintmax = flintmax('single');
                    if (aInvalidCode <= single_flintmax) && (bInvalidCode <= single_flintmax)
                        acodes = single(acodes);
                        bcodes = single(bcodes);
                    else
                        acodes = double(acodes);
                        bcodes = double(bcodes);
                    end

                    acodes(acodes==categorical.undefCode) = NaN;
                    bcodes(bcodes==categorical.undefCode) = NaN;
                elseif aInvalidCode == bInvalidCode
                    % don't cast unless necessary
                elseif aInvalidCode > bInvalidCode
                    bcodes = cast(bcodes, 'like', acodes);
                else % aIinvalidCode < bInvalidCode
                    acodes = cast(acodes, 'like', bcodes);
                end
            end
        end
    end % static private methods block

    methods(Static, Access=protected)
        a = catUtil(dim,useSpecializedFcn,varargin)
    end
end % classdef


function throwUndefinedError
st = dbstack;
name = regexp(st(2).name,'\.','split');
throwAsCaller(MException(message('MATLAB:categorical:UndefinedFunction',name{2},'categorical')));
end


function [c,ic] = removeUtil(c,ic,t)
% Remove elements from c, and update ic's indices into c -- zero out the ones
% that point to elements being removed from c, and shift down the remaining
% ones to point into the reduced version of c
if any(t)
    q = find(~t);
    convert = zeros(size(c)); convert(q) = 1:length(q);
    ic = convert(ic);
    c = c(q);
end
end

function maxNumCats = maxArraySizeLimit
    % maxArraySizeLimit returns the maximum array allowed in MATLAB to
    % initialize the categorical.maxNumCategories property
    [~, maxNumCats] = computer;
end

function tf = isNVpair(arg)
tf = (ischar(arg) || (isstring(arg) && isscalar(arg))) && strlength(arg) > 0 && any(startsWith(["Ordinal"; "Protected"],arg,'IgnoreCase',true));
end
