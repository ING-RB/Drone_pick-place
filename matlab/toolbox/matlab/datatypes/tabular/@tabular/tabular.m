classdef (AllowedSubclasses = {?timetable ?table}) tabular < ...
        matlab.internal.datatypes.saveLoadCompatibility & ...
        matlab.mixin.indexing.RedefinesDot & ...
        matlab.mixin.indexing.RedefinesParen & ...
        matlab.mixin.indexing.RedefinesBrace & ...
        matlab.mixin.indexing.OverridesPublicDotMethodCall & ...
        matlab.mixin.internal.indexing.RedefinesDotParen
%

% Internal abstract superclass for table and timetable.
% This class is for internal use only and will change in a future release. Do not use this class.

%   Copyright 2016-2024 The MathWorks, Inc.

    properties(Constant, Access='protected') % *** may go back to private if every instance is in tabular
        arrayPropsDflts = struct('Description', {''}, ...
                                 'UserData'   , [],...
                                 'TableCustomProperties',struct);
    end
    
    properties(Abstract, Constant, Access='protected')
        % Constant properties are not persisted when serialized

        defaultDimNames
        dispRowLabelsHeader
    end

    properties(Abstract, SetAccess='protected', GetAccess={?tabular,?matlab.internal.tabular.private.subscripter})
        metaDim
        rowDim
        varDim
        data
        arrayProps
    end

    properties(Dependent, Access='protected')
        Properties
    end
    methods % dependent property get methods
        function val = get.Properties(a)
            val = getProperties(a);
        end

        function a = set.Properties(a,~)
            % The set method needs to be defined but it should never be called.
            % This method cannot be accessed outside the tabular class and its
            % subclasses, and inside tabular code we should never use dot to
            % access the Properties.
            assert(false);
        end

        function t = keyMatch(t1,t2) %#ok<STOUT> 
            if isa(t1,"tabular")
                tabularType = t1;
            else
                tabularType = t2;
            end
            error(message("MATLAB:datatypes:InvalidTypeKeyMatch",class(tabularType)));
        end

        function h = keyHash(t) %#ok<STOUT> 
            error(message("MATLAB:datatypes:InvalidTypeKeyHash",class(t)));
        end
    end

    methods(Hidden)
        function props = getProperties(t)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use t.Properties instead.
            import matlab.internal.datatypes.mergeScalarStructs
            props = t.emptyPropertiesObj; % TableProperties or TimetableProperties
            
            p = mergeScalarStructs(t.arrayProps, ...
                                   t.metaDim.getProperties(), ...
                                   t.varDim.getProperties(), ...
                                   t.rowDim.getProperties());
            p.CustomProperties = matlab.tabular.CustomProperties(...
                p.TableCustomProperties,...
                p.VariableCustomProperties);
            p.VariableTypes = t.getVariableTypes();
            p = rmfield(p,["VariableCustomProperties","TableCustomProperties"]);
            f = fieldnames(p);
            for i = 1:numel(f)
                props.(f{i}) = p.(f{i});
            end
        end
        
        function t = setProperties(t,s)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use t.Properties instead.
            
            %SET Set some or all table properties from a scalar struct or properties object.
            if isstruct(s) && isscalar(s)
                fnames = fieldnames(s);
            elseif isa(s, class(t.emptyPropertiesObj))
                fnames = properties(s);
            else
                error(message('MATLAB:table:InvalidPropertiesAssignment',class(t.emptyPropertiesObj),class(t)));
            end
            
            for i = 1:length(fnames)
                fn = fnames{i};
                t = t.setProperty(fn,s.(fn));
            end
        end
        
        % Allows tab completion after dot to suggest variables
        function p = properties(t)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % This will be called for properties of an instance, but the built-in will
            % still be called for the class name.  It will return just Properties,
            % which is correct.
            import matlab.internal.display.lineSpacingCharacter
            pp = [t.varDim.labels(:); 'Properties'; t.metaDim.labels(:)];
            if nargout == 0
                % get 1 or 0 newlines based on format loose/compact
                fprintf([lineSpacingCharacter '%s\n' lineSpacingCharacter], getString(message('MATLAB:ClassUstring:PROPERTIES_FUNCTION_LABEL',class(t))));
                fprintf('    %s\n',pp{:});
                fprintf(lineSpacingCharacter);
            else
                p = pp;
            end
        end
        function f = fieldnames(t), f = properties(t); end
        function f = fields(t),     f = properties(t); end
                
        % This function is for internal use only and will change in a future release.
        % Do not use this function.
        t2 = defaultarrayLike(sz,~,t,ascellstr)

        function vars = getVars(t,asStruct)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use table2struct(t,'AsScalar',true) instead.
            if nargin < 2 || asStruct
                [fnames, fixed] =  t.varDim.makeValidName(t.varDim.labels,'warn');
                fnames = matlab.lang.makeUniqueStrings(fnames, fixed,namelengthmax);
                vars = cell2struct(t.data,fnames,2);
            else
                vars = t.data;
            end
        end
        
        function n = getCustomPropertyNames(t)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Used in tab completion for rmprop.
            n = [fieldnames(t.varDim.customProps); fieldnames(t.arrayProps.TableCustomProperties)]';
        end
        
        function t1 = transferNonRowProperties(t,t1)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Used by table2timetable and timetable2table.
            f = fieldnames(t.arrayProps);
            for ii = 1:numel(f)
                t1.arrayProps.(f{ii}) = t.arrayProps.(f{ii});
            end
            t_varDim = t.varDim;
            t1.varDim = t1.varDim.init(t_varDim.length,t_varDim.labels,t_varDim.descrs,t_varDim.units,t_varDim.continuity,t_varDim.customProps);
        end
        
        function [indices,isLabels] = subscripts2indices(t,subs,subsType,dim)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            switch subsType
            case 'assignment'
                sType = matlab.internal.tabular.private.tabularDimension.subsType_assignment;
            case 'reference'
                sType = matlab.internal.tabular.private.tabularDimension.subsType_reference;
            case 'deletion'
                sType = matlab.internal.tabular.private.tabularDimension.subsType_deletion;
            end
            [indices,~,~,~,isLabels] = t.subs2inds(subs,dim,sType);
        end
        
        function t = createArrayLike(template, sz, fillval)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            if numel(sz) ~= 2 % createArray function enforces integer values
                error(message("MATLAB:table:InvalidSize"));
            elseif sz(2) ~= template.varDim.length
                error(message("MATLAB:table:createArray:InvalidWidth"));
            end
            
            if nargin < 3
                t = defaultarrayLike(sz,'like',template);
            else
                if ~isscalar(fillval)
                    error(message("MATLAB:createArray:invalidFillValue"));
                end
                n = min(sz(1),template.rowDim.length);
                t = template(1:n,:);
                if sz(1) > n
                    t = lengthenVar(t,sz(1));
                end
                try
                    t{:,:} = fillval;
                catch meCause
                    me = addCause(MException(message("MATLAB:table:createArray:CantAssignFillValue")),meCause);
                    throw(me);
                end
            end
        end
        
        % Methods we don't want to clutter things up with
        e = end(t,k,n)
        B = repelem(A,M,N,varargin)
        disp(t,bold,indent,fullChar,nestedLevel,truncate)
        display(obj, name)
        
        % These functions are for internal use only and will change in a
        % future release.  Do not use these functions.
        displayWholeObj(obj,tblName)
        b = lengthenVar(a,n)
        b = dotParenReference(t,vn,s1,s2,varargin)
        [vars,varData,sortMode,varargout] = sortrowsFlagChecks(t,doIssortedrows,vars,sortMode,varargin)
        [vars,varData,sortMode,labels,varargin] =  topkrowsFlagChecks(a,vars,sortMode,varargin)
                
        %% Variable Editor methods
        % These functions are for internal use only and will change in a
        % future release.  Do not use these functions.
        varargout  = variableEditorGridSize(t)
        [names,indices,classes,iscellstr,charArrayWidths] = variableEditorColumnNames(t)
        rowNames   = variableEditorRowNames(t)
        [code,msg] = variableEditorRowDeleteCode(t,workspaceVariableName,rowIntervals)
        [code,msg] = variableEditorColumnDeleteCode(t,workspaceVariableName,columnIntervals)
        t          = variableEditorPaste(t,rows,columns,data)
        t          = variableEditorInsert(t,orientation,row,col,data)
        [code,msg] = variableEditorSetDataCode(t,workspaceVariableName,row,col,rhs)
        [code,msg] = variableEditorReplaceWithEmptyCode(t,workspaceVariableName,row,col,rowStr,colStr)
        [code,msg] = variableEditorUngroupCode(t,varName,col)
        [code,msg] = variableEditorGroupCode(t,varName,startCol,endCol)
        metaData   = variableEditorMetadata(t)
        [code,msg] = variableEditorMetadataCode(t,varName,index,propertyName,propertyString)
        [code,msg] = variableEditorRowNameCode(t,varName,index,rowName)
        [code,msg] = variableEditorSortCode(t,varName,tableVariableNames,direction)
        [code,msg] = variableEditorMoveColumn(t,varName,startCol,endCol)
                
        %% Error stubs
        % Methods to override functions and throw helpful errors
        function d = double(t,varargin),     throwInvalidNumericConversion(t); end %#ok<STOUT>
        function s = single(t,varargin),     throwInvalidNumericConversion(t); end %#ok<STOUT>
        function n = length(t,varargin),     error(message('MATLAB:table:UndefinedLengthFunction',class(t))); end %#ok<STOUT>
        function t = transpose(t,varargin),  throwUndefinedTransposeError(t); end
        function t = ctranspose(t,varargin), throwUndefinedTransposeError(t); end
        function t = permute(t,varargin),    throwUndefinedError(t); end
        function t = reshape(t,varargin),    throwUndefinedError(t); end

        function t = sort(t,varargin)
            import matlab.lang.correction.ReplaceIdentifierCorrection
            throw(MException(message('MATLAB:table:UndefinedSortFunction',class(t))) ...
            	.addCorrection(ReplaceIdentifierCorrection('sort','sortrows')));
        end
    end % hidden methods block
        
    methods(Abstract, Hidden, Static)
        t = empty(varargin)
        
        % These functions are for internal use only and will change in a
        % future release.  Do not use these functions.
        
        t = fromScalarStruct(s)
        t = init(vars, numRows, rowLabels, numVars, varnames)
    end % abstract hidden static methods block
    
    methods(Access = 'protected')
        t = setDescription(t,newDescr)
        t = setUserData(t,newData)

        b = extractData(t,vars,like,a)
        t = replaceData(t,x,vars)

        % Dot Indexing
        [b, varargout] = dotReference(t, idxOp)        
        t = dotAssign(t, idxOp, b)
        n = dotListLength(t, idxOp, context)

        % Brace Indexing
        varargout = braceReference(t, idxOp)        
        t = braceAssign(t, idxOp, b)
        n = braceListLength(t, idxOp, context)

        % Paren Indexing
        [b, varargout] = parenReference(t, idxOp)
        t = parenAssign(t, idxOp, b)
        t = parenDelete(t,idxOp)
        n = parenListLength(t, idxOp, context)
        t = oneLevelParenAssign(t, idxOp, b, creating, isInternalCall, numRows)
        
        % Indexing Helper Methods  
        sz = listLengthRecurser(t, tCurr, idxOp, context)
              
        varIndices = getVarOrRowLabelIndices(t,varSubscripts,allowEmptyRowLabels,matchRowDimName)
        varData = getVarOrRowLabelData(t,varIndices,warnMsg)
        [group,glabels,glocs] = table2gidx(a,avars,reduce)
        varIndex = subs2indsErrorHandler(a,varName,ME,callerID)

        % Concatenation Helper Methods 
        [t, t_idx, hasExplicitRowLabels] = getTemplateForConcatenation(catDim,varargin)
        t = primitiveHorzcat(t,varargin)
        
        % Binary Math Helper 
        [template,rowOrder,varOrder] = getTemplateForBinaryMath(A,B,fun,unitsHelper)

        function errID = throwSubclassSpecificError(~,msgid,varargin)
            %

            % THROWSUBCLASSSPECIFICERROR is called by overloads in the subclasses and returns an
            % MException that is specific to the subclass which can then be returned to the
            % caller or thrown.
            try
                errID = MException(message(['MATLAB:' msgid],varargin{:}));
            catch ME
                if ME.identifier == "MATLAB:builtins:MessageNotFound"
                    % This function should never be called with a non-existent ID
                    assert(false);
                else
                    rethrow(ME);
                end
            end
        end
        
        function t = initInternals(t, vars, nrows, rowLabels, nvars, varnames, dimnames)
            %

            % INITINTERNALS Fills an empty tabular object with data and dimension objects. This
            % function is for internal use only and will change in a future release.  Do not use
            % this function.
            try
                t.rowDim = t.rowDim.createLike(nrows,rowLabels);
                t.varDim = t.varDim.createLike(nvars,varnames); % error if invalid, duplicate, or empty
                t.data(1,1:nvars) = vars; % force 1xN, and hard error if vars is the wrong length
                if nargin == 7
                    t.metaDim = t.metaDim.setLabels(dimnames);
                end
            catch ME
                throwAsCaller(ME)
            end
        end

        function t = rmPerTableProperty(t, names)
            t.arrayProps.TableCustomProperties = rmfield(t.arrayProps.TableCustomProperties, names);
        end

        function t = setPerTableProperty(t, newProps,name)
            t.arrayProps.TableCustomProperties.(name) = newProps;
        end

        function t = addVarLenient(t,varName,varData)
            import matlab.lang.internal.move % Avoid unsharing of shared-data copy across function call boundary
            % Fix the varName before calling dotAssign.
            varName = matlab.lang.makeUniqueStrings(varName,[t.varDim.labels t.metaDim.labels],namelengthmax);
            t = move(t).dotAssign(varName,varData);
        end

        function h = getDisplayHeader(t, tblName) %#ok<INUSD>
        %

        % GETHEADER is called by display method to print the header
        % specific to the tabular subclass. The default implementation
        % gets the most basic version of the header.    
            h = matlab.internal.display.getHeader(t);
        end

        function [marginChars,lostWidth,rowLabelsDispWidth,rowDimName,rowDimNameDispWidth, headerIndent, ellipsisIndent] ...
                    = getRowMargin(t,lostWidth,between, indent,bold)            
            %

            % GETROWMARGIN is called by display method to print the row
            % margin specific to the tabular subclass.

            import matlab.internal.tabular.display.nSpaces;
            import matlab.internal.tabular.display.boldifyLabels;
            import matlab.internal.tabular.display.alignTabularContents;
            import matlab.internal.display.truncateLine;
            
            marginChars = nSpaces(indent);
            bold = matlab.internal.display.isHot() && bold;
            strongBegin = ''; strongEnd = '';
            if bold
                strongBegin = getString(message('MATLAB:table:localizedStrings:StrongBegin'));
                strongEnd = getString(message('MATLAB:table:localizedStrings:StrongEnd'));
            end
            
            rowlabelChars = string(t.rowDim.textLabels());
            rowlabelChars = matlab.display.internal.vectorizedTruncateLine(rowlabelChars);
            [rowlabelChars,rowLabelsDispWidth,lostWidth] = alignTabularContents(rowlabelChars,lostWidth);

            rowDimName = "";
            rowDimNameDispWidth = 0;

            % table doesn't print a header (dimname) for rownames, but we
            % still have to account for the width with additional spaces.
            headerIndent = indent + rowLabelsDispWidth + between;
            ellipsisIndent = indent;
            rowlabelChars = boldifyLabels(rowlabelChars,bold,strongBegin,strongEnd);
            marginChars = marginChars + rowlabelChars + nSpaces(between);
        end

        function [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
                     = subs2inds(t,subscripts,operatingDim,subsType)
            %

            % SUBS2INDS Converts table subscripts into indices.

            % All tabular methods that need to validate or translate subscripts
            % into indices should call tabular subs2inds. tabular subs2inds
            % is responsible for handling subscripts like subscripter objects
            % that might require information from different parts of the tabular
            % object. All other kinds of subscripts (numeric, logical, colon,
            % native subscripts) will be handled by the underlying dimension
            % object's subs2inds methods.

            if isobject(subscripts) && isa(subscripts,'matlab.internal.tabular.private.subscripter')
                % Convert subscripter objects into numeric/logical indices.
                subscripts = getSubscripts(subscripts,t,operatingDim);
            end
            
            switch operatingDim
                case 'varDim'
                    operatingDim = t.varDim;
                case 'rowDim'
                    operatingDim = t.rowDim;
                case 'metaDim'
                    operatingDim = t.metaDim;
                otherwise % Should never hit this branch.
                    assert(false);
            end

            % Default to reference if subsType is not supplied.
            if nargin < 4, subsType = operatingDim.subsType_reference; end

            % Avoid the costly operation of creating an updatedObj, if the
            % caller has not requested one.
            if nargout <= 3
                [indices,numIndices,maxIndex] = operatingDim.subs2inds(subscripts,subsType);
            else
                [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
                     = operatingDim.subs2inds(subscripts,subsType);
            end
        end

        function validateAcrossVars(varargin)
            %

            % VALIDATEACROSSVARS Handles validations that check for
            % compatibility across different variables and metadata in the
            % tabular. By default, tabulars do not have any such checks but sub
            % classes may use this method to implement such checks.
        end

        % Indexing helper methods
        indices = translateRowLabels(t, var, indices);
        [var,varargout] = translateAndForwardReference(t, var, idxOp);
        var = translateAndForwardAssign(t, var, idxOp, rhs);

        function variableTypes = getVariableTypes(t)
            numVars = t.varDim.length;
            % Gather variable types as cellstr for performance.
            variableTypes = cell(1, numVars); 
            for i = 1:numVars
                variableTypes{i} = class(t.data{i});
            end
            variableTypes = string(variableTypes);
        end

        function t = setVariableTypes(t,newVariableTypes)
            import matlab.internal.datatypes.throwInstead;
            numVars = t.varDim.length;
            
            if ~matlab.internal.datatypes.isText(newVariableTypes,true)
                % Do not allow character vector as input. empty text is not allowed, but
                % missing is legal, so can't use the empty/missing flag to isText. Let
                % convertvars catch empty text.
                error(message("MATLAB:table:InvalidVariableTypes"));
            elseif strcmp(class(newVariableTypes), "cell")
                % Convert cellstr inputs to string.
                newVariableTypes = string(newVariableTypes);
            end
            
            if length(newVariableTypes) ~= numVars
                error(message("MATLAB:table:VariableTypesLengthMismatch"));
            end
            
            % Although CONVERTVARS can convert multiple variables at a
            % time, the type conversion is done one variable at a time to
            % ensure that each variable is mapped correctly to its new
            % type.
            for i = 1:numVars
                oldType = class(t.data{i});
                newType = newVariableTypes(i);
                % Leave the variable untouched if the target type is the same as the
                % variable's, or if the target type is specified as a missing value.
                if ~(strcmp(oldType, newType) || ismissing(newType))
                    varName = t.varDim.labels{i};
                    try
                        tmp = convertvars(t, i, newVariableTypes(i));
                    catch ME
                        if strcmp(ME.identifier,"MATLAB:table:convertvars:InvalidType")
                            % Empty text. Assignment to VariableTypes doesn't support function handles,
                            % so give an err that doesn't suggest that.
                            ME = MException(message("MATLAB:table:InvalidVariableTypes"));
                        elseif strcmp(ME.identifier,"MATLAB:table:convertvars:InvalidTextType")
                            % convertvars caught MATLAB:UndefinedFunction, e.g. the specified type name doesn't
                            % exist, which became the cause for InvalidTextType. Assignment to VariableTypes
                            % doesn't support function handles, so give an err that doesn't suggest that, but
                            % that includes the original error as a cause.
                            cause = ME.cause{1}; % always MATLAB:UndefinedFunction, but may have varying text
                            ME = addCause(MException(message("MATLAB:table:InvalidTextType",varName,newType)),cause);
                        elseif strcmp(ME.identifier,"MATLAB:table:convertvars:VariableTypesConversionFailed")
                            % convertvars caught some other error that became the cause for VariableTypesConversionFailed.
                            % In this case, convertvars' error msg is fine.
                        else
                            % Wrap anything else convertvars threw as a cause in an err that's more meaningful
                            % for assignment to VariableTypes.
                            ME = addCause(MException(message("MATLAB:table:convertvars:VariableTypesConversionFailed",varName,newType)),ME);
                        end
                        throwAsCaller(ME);
                    end
                    resultType = class(tmp.data{i});
                    sameType = strcmp(resultType, newType);
                    if sameType || (newType=="cellstr" && iscellstr(tmp.data{i}))
                        t = tmp;
                    else
                        error(message("MATLAB:table:VariableTypesConvertedToWrongType",varName,newType,resultType));
                    end
                end
            end
        end
    end % protected methods block

    methods(Abstract, Access = 'protected')
        n = propertyNames(t);
        p = emptyPropertiesObj(t);
        
        b = cloneAsEmpty(a)
        
        % Used by summary method
        
        rowLabelsStruct = summarizeRowLabels(t,stats,statFields,fcnHandles);
        printRowLabelsSummary(t,rowLabelsStruct,detailIsLow);
        
        % Used by varfun and rowfun
        
        id = specifyInvalidOutputFormatID(t,funName);
    end % abstract protected methods block
    
    methods(Access = 'private')
        varIndex = getGroupingVarOrTime(t,varName)
        [varargout] = getProperty(t,name,createIfEmpty)
        t = setProperty(t,name,p) 
    end
    
    methods (Static, Hidden)
        % These functions are for internal use only and will change in a future release.
        % Do not use these functions.
        vars = container2vars(c)
        
        function name = matlabCodegenRedirect(~)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.tabular';
        end    
    end % static hidden methods block
    
    methods(Static, Access = 'protected')
        [ainds,binds] = table2midx(a,b)
        [leftKeys,rightKeys] = joinKeys(a,b,keys,leftKeys,rightKeys,supplied)
        [leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys,outMetaDim] ...
                = joinUtil(a,b,type,leftTableName,rightTableName, ...
                           keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,supplied,merge)
        [c,il,ir] = joinInnerOuter(a,b,leftOuter,rightOuter,leftKeyvals,rightKeyvals, ...
                                   leftVars,rightVars,leftKeys,rightKeys,leftVarnames,rightVarnames, ...
                                   mergeKeyProps,c_metaDim)
        a_arrayProps = mergeArrayProps(a_arrayProps,b_arrayProps) % Used by both table and timetable
        c = binaryFunHelper(a,b,fun,unitsHelper,funName)
        [b, varargout] = reductionFunHelper(a,fun,args,NameValueArgs)
        T = unaryFunHelper(A,fun,requiresSort,varargin)
        isBinary = minMaxValidationHelper(nout,fun,funName,a,args)
        validateTableAndDimUnary(a,dim)
        
        function [numVars, numRows, nvpairs] = countVarInputs(args,StringParamNameNotSupportedErrID,numNamedArguments)
        %

        %COUNTVARINPUTS Count the number of data vars from a tabular input arg list
            import matlab.internal.datatypes.isCharString
            argCnt = 0;
            numVars = 0;
            numRows = 0;
            % The Name=Value args will be towards the end of the list. Since we
            % already know those arent variables, we dont need to scan through
            % those. So only check uptil the point where Name=Value args start.
            while argCnt < (length(args) - 2*numNamedArguments)
                argCnt = argCnt + 1;
                arg = args{argCnt};
                if isCharString(arg) % Matches any character row vector (including ''), not just a parameter name
                    % Put that one back and start processing param name/value pairs
                    argCnt = argCnt - 1;
                    break
                elseif isa(arg,'function_handle')
                    throwAsCaller(MException(message('MATLAB:table:FunAsVariable')));
                elseif isa(arg,'dictionary')
                    throwAsCaller(MException(message('MATLAB:table:DictionaryAsVariable')));
                else % an array that will become a variable in t
                    numVars = numVars + 1;
                end
                numRows_j = size(arg,1);
                if argCnt == 1
                    numRows = numRows_j;
                elseif ~isequal(numRows_j,numRows)
                    ME = MException(message('MATLAB:table:UnequalVarLengths'));
                    if isstring(arg) && isscalar(arg) && numRows > 1
                        % A scalar string following inputs with more than one row
                        % is likely intended as a parameter name, give a helpful
                        % error.
                        cause = MException(message(StringParamNameNotSupportedErrID,arg));
                        ME = ME.addCause(cause);
                    end
                    throwAsCaller(ME);
                end
            end % while argCnt < numArgs, processing individual vars
            
            if numNamedArguments > 0
                % Name coming from Name=Value would be a scalar string. Convert
                % it to char row vector before returning.
                namedArgumentsStart = numel(args) - 2*numNamedArguments + 1;
                [args{namedArgumentsStart:2:end}] = convertStringsToChars(args{namedArgumentsStart:2:end});
            end
            nvpairs = args(argCnt+1:end);
        end
        
        function [nrows,nvars] = validateVarHeights(vars)
        %

        %VALIDATEVARROWS Validate a cell array of prospective table variables
            nvars = length(vars);
            if nvars > 0
                % Check that variables are the same height.
                nrows = size(vars{1},1);
                for i = 1:nvars
                    if size(vars{i},1) ~= nrows
                        error(message('MATLAB:table:UnequalFieldLengths'));
                    end
                end
            else
                nrows = 0;
            end
        end
        
        function vars = createVariables(types,sz)
            %

            % CREATEVARIABLES Create variables of the specified types, of the
            % specified height, for a preallocated table, filled with each
            % type's default value. 
            nrows = sz(1);
            nvars = sz(2);
            vars = cell(1,nvars); % a row vector
            for ii = 1:nvars
                type = types{ii};
                switch type
                case {'double' 'single' 'logical'}
                    vars{ii} = zeros(nrows,1,type);
                case {'doublenan' 'doubleNaN' 'singlenan' 'singleNaN'}
                    vars{ii} = NaN(nrows,1,extractBefore(lower(type),'nan'));
                case 'string'
                    vars{ii} = repmat(string(missing),nrows,1);
                case 'cell'
                    vars{ii} = cell(nrows,1);
                case 'datetime'
                    vars{ii} = datetime.fromMillis(NaN(nrows,1));
                case 'duration'
                    vars{ii} = duration.fromMillis(zeros(nrows,1));
                case 'calendarDuration'
                    vars{ii} = calendarDuration(zeros(nrows,1),0,0);
                case 'categorical'
                    vars{ii} = categorical(NaN(nrows,1));
                case {'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                    vars{ii} = zeros(nrows,1,type);
                case {'cellstr' 'char'}
                    if type == "char"
                        % Special case: replace 'char' with 'cellstr', with a warning. A char
                        % array is tempting but not a good choice for text data in a table.
                        matlab.internal.datatypes.warningWithoutTrace(message('MATLAB:table:PreallocateCharWarning'));
                    end
                    % cellstr is a special case that's not actually a type name.
                    vars{ii} = repmat({''},nrows,1);
                case {'table' 'timetable'}
                    % No way to know how many or what type vars, create an table/timetable
                    % with no vars but correct height
                    vars{ii} = eval([type '.empty(nrows,0)']);
                otherwise
                    if nrows > 0 % lengthenVar requires n > 0
                        % Use lengthenVar to create a var of the correct height. Not all
                        % types have their name as a constructor, e.g. double is a
                        % conversion not a ctor. So with no sure way to create a scalar
                        % instance to lengthen, create an empty instance.
                        try
                            % Create 0x1, lengthenVar will turn it into an Nx1, so the
                            % preallocated var will always have one column (unless
                            % lengthenVar below fails and we fall back to Nx0).
                            emptyVar = eval([type '.empty(0,1)']);
                        catch ME
                            throwAsCaller(preallocationClassErrorException(ME,type));
                        end
                        % lengthenVar creates an instance of var_ii that is nrows-by-1,
                        % filled in with the default (not necessarily "missing") value.
                        try
                            vars{ii} = matlab.internal.datatypes.lengthenVar(emptyVar,nrows);
                        catch
                            % lengthenVar failed, but we can still create an nrows-by-0 instance.
                            vars{ii} = eval([type '.empty(nrows,0)']); % don't use reshape, may not be one
                        end
                    else
                        try
                            vars{ii} = eval([type '.empty(0,1)']);
                        catch ME
                            throwAsCaller(preallocationClassErrorException(ME,type));
                        end
                    end
                end
            end
        end
        
        function t = createArrayImpl(fillvalCtor,sz,fillval)
            if nargin == 2
                error(message("MATLAB:table:createArray:NoFillValue"));
            elseif numel(sz) ~= 2 % caller enforces integer values
                error(message("MATLAB:table:InvalidSize"));
            elseif ~isscalar(fillval)
                error(message("MATLAB:createArray:invalidFillValue"));
            end
            % Callers pass a ctor function handle instead of a scalar tabular because the tabular
            % can be created only after the fillval has been validated. Use repmat on the scalar
            % tabular instead of repmat'ing fillval first, in case fillval is itself a tabular,
            % so the fillval's var names are not unnecessarily uniqueified by repmat.
            t = repmat(fillvalCtor(fillval),sz);
            t.varDim = t.varDim.setLabels(matlab.internal.tabular.defaultVariableNames(1:sz(2)));
        end
        
        function s = handleFailedToLoadVars(s,numRows,numVars,varNames)
            %

            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % Detect if some variables failed to load and replace those
            % variables with numRows-by-0 empty double
            
            % Tabular variables always have the same consistent number of
            % rows. When a variable's number of rows is inconsistent with
            % numRows, the variable _must_ have failed to load properly --
            % likely because the class is not defined in loading session.
            % Replace data in failed-to-load variables with numRows-by-0
            % empty double to maintain integrity of the tabular instance
            isVarNumRowsMismatch = false(1,numVars);
            for i = 1:numVars
                isVarNumRowsMismatch(i) = (size(s.data{i},1)~=numRows);
            end
            
            if any(isVarNumRowsMismatch)
                s.data(isVarNumRowsMismatch) = {zeros(numRows,0)};
                
                if (nnz(isVarNumRowsMismatch)==1)
                    matlab.internal.datatypes.warningWithoutTrace(message('MATLAB:tabular:CannotLoadVariable',varNames{isVarNumRowsMismatch}));
                else
                    matlab.internal.datatypes.warningWithoutTrace(message('MATLAB:tabular:CannotLoadVariables'));
                end
            end
        end
        
        function throwNDSubscriptError(nsubs)
            if nsubs == 1
                error(message('MATLAB:table:LinearSubscript'));
            else % 3 or more
                error(message('MATLAB:table:NDSubscript'));
            end
        end

        function [outVals,n] = numRowsCheck(outVals)
            %

            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            % Verify that all variables in a cell array of tabular data
            % have the same number of rows and error otherwise. Returns
            % the input and the number of rows.

            nvars = length(outVals);
            if nvars > 0
                n = size(outVals{1},1);
                for j = 2:nvars
                    if size(outVals{j},1) ~= n
                        error(message('MATLAB:table:UnequalVarLengths'));
                    end
                end
            else
                n = 0;
            end
        end
    end % static protected methods block
    
    methods(Static, Access = 'private')
        name = matchPropertyName(name,propertyNames,exact)
        flag = setmembershipFlagChecks(varargin)
        args = processSetMembershipFlags(varargin)
        var = writetableMatricize(var)
    end % static private methods block
    
    %%%%% TEST HOOKS BLOCK allows unit testing for protected methods. %%%%%
    %%%%% Methods in this block are for internal use only and will change %
    %%%%% in a future release. Do not use these methods. %%%%%%%%%%%%%%%%%%
    methods(Access = ?matlab.unittest.TestCase)
        function b = extractDataTestHook(t,vars)
            b = extractData(t,vars);
        end
        
        function [group,glabels,glocs] = table2gidxTestHook(a, avars, reduce)
            if nargin < 3, reduce = true; end
            [group,glabels,glocs] = table2gidx(a,avars,reduce);
        end
    end
    
    methods(Static, Access = ?matlab.unittest.TestCase)
        function methodList = methodsWithNonTabularFirstArgument, methodList = {'cat','rowfun','varfun'}; end
    end % test hooks block
    
    
    %%%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%
    %%%%% Properties and methods in this block maintain the exact class %%%
    %%%%% schema required for TABULAR to persist through MATLAB releases %%
    methods (Hidden)
        function s = saveobj(t,s)
            if (nargin == 1), s = struct; end
            
            s.CustomProps         = t.arrayProps.TableCustomProperties;
            s.VariableCustomProps = t.varDim.customProps;

            % Note that VariableTypes was introduced in 24a, but the
            % varible types are not saved or loaded because they are
            % derived from the data.
        end
    end
end % classdef

%-----------------------------------------------------------------------------
function throwUndefinedError(obj,varargin)
st = dbstack;
name = regexp(st(2).name,'\.','split');
throwAsCaller(MException(message('MATLAB:table:UndefinedFunction',name{2},class(obj))));
end % function

%-----------------------------------------------------------------------------
function throwUndefinedTransposeError(obj)
import matlab.lang.correction.ReplaceIdentifierCorrection
st = dbstack;
name = regexp(st(2).name,'\.','split');
throwAsCaller(MException(message('MATLAB:table:UndefinedTransposeFunction',name{2},class(obj))) ...
	.addCorrection(ReplaceIdentifierCorrection(name{2},'rows2vars')));
end % function

%-----------------------------------------------------------------------------
function throwInvalidNumericConversion(obj,varargin)
import matlab.lang.correction.ReplaceIdentifierCorrection
st = dbstack;
name = regexp(st(2).name,'\.','split');
throwAsCaller(MException(message('MATLAB:table:InvalidNumericConversion',name{2},class(obj))) ...
    .addCorrection(ReplaceIdentifierCorrection(name{2},'table2array')));
end % function

%-----------------------------------------------------------------------------
function ME = preallocationClassErrorException(ME,type)
if ME.identifier == "MATLAB:undefinedVarOrClass"
    theMatch = matlab.lang.internal.introspective.safeWhich(type,false);
    if isempty(theMatch)
        ME = MException(message('MATLAB:table:PreAllocationUndefinedClass',type));
    else
        [~,theMatch,~] = fileparts(theMatch);
        if exist(theMatch,'class') == 8 % theMatch is a class
            ME = MException(message('MATLAB:table:PreAllocationClassnameCase',type,theMatch));
        else
            ME = MException(message('MATLAB:table:PreAllocationUndefinedClass',type));
        end
    end
else
    ME = MException(message('MATLAB:table:InvalidPreallocationVariableType',type,ME.message));
end
end % function
