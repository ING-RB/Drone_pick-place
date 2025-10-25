classdef (AllowedSubclasses = {?matlab.internal.coder.table, ...
        ?matlab.internal.coder.timetable}) tabular < ...
        coder.mixin.internal.indexing.Paren & ...
        coder.mixin.internal.indexing.ParenAssignSupportInParfor & ...
        coder.mixin.internal.indexing.Brace & ...
        coder.mixin.internal.indexing.Dot %#codegen
% Internal abstract superclass for table (codegen).
% This class is for internal use only and will change in a future release. Do not use this class.

%   Copyright 2018-2022 The MathWorks, Inc.

    properties(Constant, Access='protected') % *** may go back to private if every instance is in tabular
        arrayPropsDflts = struct('Description', {char(zeros(1,0))}, ...
                                 'UserData'   , []);
    end
    
    % FIXME: should be protected
    properties(Abstract, Constant, Access='public')
        propertyNames
        defaultDimNames
        RowDimNameNondefaultExceptionID
    end
        
    properties(Abstract, Constant, Access='protected')
        % Constant properties are not persisted when serialized
        %propertyNames
        %defaultDimNames
        dispRowLabelsHeader
    end

    properties(Abstract, Access='protected')
        metaDim
        rowDim
        varDim
        data
        arrayProps
    end
    
    methods(Hidden)
        e = end(t,k,n)
        p = isscalar(~)
        
        function out = updateTabularProperties(t, varDim, metaDim, rowDim, arrayProps, data)
            % This function is for internal use only and will change in a future release.
            % It is a helper codegen function to update any of the internal tabular properties. 
            out = t.cloneAsEmpty();
            
            if nargin < 6 || isequal(data,[])
                out.data = t.data;
            else
                out.data = data;
            end
            
            if isempty(varDim)
                out.varDim = t.varDim;
            else
                out.varDim = varDim;
            end
            
            if isempty(metaDim)
                out.metaDim = t.metaDim;
            else
                out.metaDim = metaDim;
            end
            
            if isempty(rowDim)
                out.rowDim = t.rowDim;
            else
                out.rowDim = rowDim;
            end
            
            if isempty(arrayProps)
                out.arrayProps = t.arrayProps;
            else
                out.arrayProps = arrayProps;
            end
        end
        
        function [varDim, metaDim, rowDim, arrayProps] = getTabularProperties(t)
            % This function is for internal use only and will change in a future release.
            % It is currently used only in defaultarrayLike as a workaround for 
            % the lack of varfun in codegen. Consider removing this method 
            % once defaultarrayLike no longer has the need
            varDim = t.varDim;
            metaDim = t.metaDim;
            rowDim = t.rowDim;
            arrayProps = t.arrayProps;
        end
        
        function props = getProperties(t)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use t.Properties instead.            
            props = t.getEmptyProperties();  % TableProperties or TimetableProperties
            
            p = matlab.internal.coder.datatypes.mergeScalarStructs(t.arrayProps, ...
                                   t.metaDim.getProperties(), ...
                                   t.varDim.getProperties(), ...
                                   t.rowDim.getProperties());
            %p.CustomProperties = matlab.tabular.CustomProperties(...
            %    p.TableCustomProperties,...
            %    p.VariableCustomProperties);
            %p = rmfield(p,["VariableCustomProperties","TableCustomProperties"]);
            f = fieldnames(p);
            for i = 1:numel(f)
                props.(f{i}) = p.(f{i});
            end
            % copy DimensionNames and VariableNames directly from their
            % sources since we want to preserve their const-ness.
            props.DimensionNames = t.metaDim.labels;
            props.VariableNames = t.varDim.labels;            
        end
        
        function t = setProperties(t,s)
            %SET Set some or all table properties from a scalar struct or properties object.
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use t.Properties instead.
            if isstruct(s) && isscalar(s)
                fnames = fieldnames(s);
            else
                % cannot use isa(s, class(...)) because matlabCodegenUserReadableName
                % method can alter the returned class name. Use
                % isequal(class(...),class(...)) instead. This works
                % because the name redirection works equally in both
                % operands of isequal
                propobj = t.getEmptyProperties();
                coder.internal.assert(isequal(class(s), class(propobj)), ...
                    'MATLAB:table:InvalidPropertiesAssignment',...
                    class(propobj),class(t));
                fnames = t.propertyNames;
            end
            
            for i = 1:numel(coder.const(fnames))
                fn = fnames{i};
                t = t.setProperty(fn,s.(fn));
            end
        end
        
        % This function is for internal use only and will change in a future release.
        % Do not use this function.
        t2 = defaultarrayLike(varargin)

        function vars = getVars(t,asStruct)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use table2struct(t,'AsScalar',true) instead.
            if nargin < 2 || asStruct
                %{
                [fnames, fixed] =  t.varDim.makeValidName(t.varDim.labels,'warn');
                fnames = matlab.lang.makeUniqueStrings(fnames, fixed,namelengthmax);
                vars = cell2struct(t.data,fnames,2);
                %}
                % Note that this is different from MATLAB behavior where
                % MODEXCEPTION (second input) is 'warn' and invalid names
                % will be modifed to become valid. In codegen, we just
                % error if we encounter an invalid name.
                fnames =  t.varDim.makeValidName(t.varDim.labels,'error');
                coder.const(fnames);
                
                vars = struct();
                for i = 1:numel(fnames)
                    vars.(fnames{i}) = t.data{i};
                end
            else
                vars = t.data;
            end
        end
        
        function vars = getVarsAsStructArray(t)
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use table2struct(t,'AsScalar',false) instead.

            % Note that this is different from MATLAB behavior where
            % MODEXCEPTION (second input) is 'warn' and invalid names
            % will be modifed to become valid. In codegen, we just
            % error if we encounter an invalid name.            
            fnames =  t.varDim.makeValidName(t.varDim.labels,'error');         
            coder.const(fnames);            
            if isempty(t)
                % create a scalar struct first, then use indexing to make
                % empty
                dummyscalarstruct = struct();
                for i = 1:numel(fnames)
                    dummyscalarstruct.(fnames{i}) = [];
                end
                nrows = ones(size(t,1),1);
                ncols = 1;

                vars = dummyscalarstruct(nrows, ncols);
            else
                % use the syntax struct(field1, value1, field2, ...)
                % put all the inputs in a cell array, then use colon to
                % expand to a list
                c = cell(2,size(t,2));
                for i = 1:numel(fnames)
                    c{1,i} = fnames{i};
                    ti = parenReference(t,':',i);
                    c{2,i} = table2cell(ti);
                end
                vars = struct(c{:});
            end
        end
        
        % Error stubs
        % Methods to override functions and throw helpful errors 
        function d = double(t,varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:table:InvalidNumericConversion',...
                'double',class(t));
        end 
        
        function s = single(t,varargin)  %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:table:InvalidNumericConversion',...
                'single',class(t));
        end 
        
        function a = length(t,varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:table:UndefinedLengthFunction',...
                class(t));
        end
        
        function t = transpose(t,varargin)
            coder.internal.assert(false,'MATLAB:table:UndefinedTransposeFunction',...
                'transpose',class(t));
        end
        
        function t = ctranspose(t,varargin)
            coder.internal.assert(false,'MATLAB:table:UndefinedTransposeFunction',...
                'ctranspose',class(t)); 
        end
        
        function t = permute(t,varargin)
            coder.internal.assert(false,'MATLAB:table:UndefinedFunction',...
                'permute',class(t));
        end
        
        function t = reshape(t,varargin)
            coder.internal.assert(false,'MATLAB:table:UndefinedFunction',...
                'reshape',class(t));
        end
        
        function t = sort(t,varargin)
            coder.internal.assert(false,'MATLAB:table:UndefinedSortFunction',class(t));
        end
    end
    
    methods(Access = 'protected')
        varIndices = getVarOrRowLabelIndices(t,varSubscripts,allowEmptyRowLabels)
        varData = getVarOrRowLabelData(t,varIndices,warnMsg)
        t = parenAssignImpl(t,rhs,isInternalCall,numRows,varargin)
        
        function errID = throwSubclassSpecificErrorIf(~,msgid)
            % THROWSUBCLASSSPECIFICERRORIF is called by overloads in the subclasses and
            % returns an error id that is specific to the subclass which can then be
            % used when throwing an exception.
            errID = ['MATLAB:' msgid];
        end
        
        function t = initInternals(t, vars, nrows, rowLabels, nvars, varnames, ...
                dimnames, rowDimTemplate)
            % INITINTERNALS Fills an empty tabular object with data and dimension objects. This
            % function is for internal use only and will change in a future release.  Do not use
            % this function.
            coder.internal.prefer_const(nvars,varnames,dimnames);
            % Use rowDimTemplate instead of t.rowDim to initialize rowDim.
            % For timetables, rowDim may contain duration/datetime that may
            % use format of different lengths compared to default. Avoid
            % assigning to t.rowDim more than once.
            t.rowDim = rowDimTemplate.createLike(nrows,rowLabels);
            t.varDim = t.varDim.createLike(nvars,varnames); % error if invalid, duplicate, or empty
            t.metaDim = matlab.internal.coder.tabular.private.metaDim(2,dimnames);
            t.data = reshape(vars, 1, nvars);
        end
        
        % dimension lengths
        function n = rowDimLength(t)
            % avoids using t.rowDim.length whenever possible to return a
            % constant answer
            if ~isempty(t.data)
                n = size(t.data{1},1);
            else
                n = t.rowDim.length;
            end
        end
        
        function t = initializeArrayProps(t)
            defaultprops = t.arrayPropsDflts;
            coder.varsize('defaultprops.Description', [], [true true]);
            t.arrayProps = defaultprops;
        end
        
        % Used by varfun and rowfun
        id = specifyInvalidOutputFormatID(t,funName);
    end

    methods(Abstract, Access = 'protected')
        b = cloneAsEmpty(a)
    end % abstract protected methods block

    methods (Static, Hidden)
        vars = container2vars(c)
    end

    methods(Static, Access = 'protected')
        a_arrayProps = mergeArrayProps(a_arrayProps,b_arrayProps) 
        [ainds,binds] = table2midx(a,b)
        [leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys,outMetaDim] ...
                = joinUtil(a,b,type,leftTableName,rightTableName, ...
                           keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,supplied,merge)
        [c,il,ir] = joinInnerOuter(a,b,leftOuter,rightOuter,leftKeyvals,rightKeyvals, ...
                                   leftVars,rightVars,leftKeys,rightKeys,leftVarnames,rightVarnames, ...
                                   mergeKeyProps,c_metaDim)
        function [numVars, numRows] = countVarInputs(args,numNamedArguments)
            %COUNTVARINPUTS Count the number of data vars from a tabular input arg list
            numVars = 0;
            numRows = 0;
            coder.unroll();
            % The Name=Value args will be towards the end of the list. Since we
            % already know those arent variables, we dont need to scan through
            % those. So only check uptil the point where Name=Value args start.
            for i = 1:(numel(args) - 2*numNamedArguments)             
                arg = args{i};
                if matlab.internal.coder.datatypes.isCharString(arg) % Matches any character row vector (including ''), not just a parameter name
                    break
                else % an array that will become a variable in t
                    coder.internal.errorIf(isa(arg, 'function_handle'), 'MATLAB:table:FunAsVariable');
                    numVars = numVars + 1;
                end
                numRows_j = size(arg,1);
                if i == 1
                    numRows = numRows_j;
                else
                    coder.internal.assert(isequal(numRows_j,numRows), 'MATLAB:table:UnequalVarLengths');
                end
            end
        end
        
        function [nrows,nvars] = validateVarHeights(vars)
            %VALIDATEVARHEIGHTS Validate a cell array of prospective table variables
            nvars = length(vars);
            if nvars > 0
                % Check that variables are the same length.
                nrows = size(vars{1},1);
                for i = 1:nvars
                    coder.internal.assert(size(vars{i},1) == nrows, ...
                        'MATLAB:table:UnequalFieldLengths');                    
                end
            else
                nrows = 0;
            end
        end
        
        function vars = createVariables(types, nrows, nvars)
            % Create variables of the specified types, of the specified height,
            % for a preallocated table, filled with each type's default value.
            vars = cell(1,nvars); % a row vector

            % list of classes supported as VariableTypes in codegen
            supportedtypes = {'double' 'single' 'logical' 'doublenan' 'doubleNaN' ...
                'singlenan' 'singleNaN' 'int8' 'int16' 'int32' 'int64' 'uint8' ...
                'uint16' 'uint32' 'uint64' 'cellstr' 'char' 'duration' 'datetime'};
            
            % list of classes not supported as VariableTypes in codegen but
            % supported as VariableTypes in MATLAB
            unsupportedtypes = {'string' 'calendarDuration' ...
                'categorical' 'struct' 'table' 'timetable'};
            
            for ii = 1:nvars
                type = types{ii};
                
                % check for 'cell', which may be intended to mean 'cellstr'
                coder.internal.errorIf(strcmp(type, 'cell'), ...
                    'MATLAB:table:PreAllocationUnsupportedCell');
                
                % check for classes supported in MATLAB but not codegen 
                coder.internal.errorIf(matlab.internal.coder.datatypes.cellstr_ismember(type, unsupportedtypes), ...
                    'MATLAB:table:PreAllocationUnsupportedClass',type);
                
                % check for all other classs
                coder.internal.assert(matlab.internal.coder.datatypes.cellstr_ismember(type, supportedtypes), ...
                    'MATLAB:table:PreAllocationUndefinedClass',type);
                
                switch type
                    case {'double' 'single' 'logical'}
                        vars{ii} = zeros(nrows,1,type);
                    case {'doublenan' 'doubleNaN'}
                        vars{ii} = NaN(nrows,1);
                    case {'singlenan' 'singleNaN'}
                        vars{ii} = NaN(nrows,1, 'single');
                    case 'datetime'
                        vars{ii} = datetime.fromMillis(NaN(nrows,1));
                    case 'duration'
                        vars{ii} = duration.fromMillis(zeros(nrows,1));
                    case {'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                        vars{ii} = zeros(nrows,1,type);
                    case {'cellstr' 'char'}
                        if strcmp(type,'char')
                            % Special case: replace 'char' with 'cellstr', with a warning. A char
                            % array is tempting but not a good choice for text data in a table.
                            coder.internal.warning('MATLAB:table:PreallocateCharWarning');
                        end
                        % cellstr is a special case that's not actually a type name.
                        % preallocate to a cellstr where each element is
                        % variable sized in the second dimension
                        dummycharrow = reshape('',1,0);
                        coder.varsize('dummycharrow',[],[0 1]);
                        vars{ii} = repmat({dummycharrow},nrows,1);                    
                    otherwise  
                        vars{ii} = zeros(nrows,1,'double');  % just return doubles if error is disabled  
                end
            end
        end
    end
    
    methods(Static, Access = 'private')
        name = matchPropertyName(name,propertyNames,exact)
        flag = setmembershipFlagChecks(varargin)
        processedArgs = processSetMembershipFlags(varargin)
    end
    
    methods(Hidden,Static)
        % should be protected
        methodNames = getMethodNamesList()
    end

    methods(Abstract, Static, Access = 'protected')
        props = getEmptyProperties()
    end
    
    methods(Hidden, Access = 'public')
        function varargout = braceListReference(~, varargin) %#ok<STOUT>
            % dummy method to satisfy abstract superclass method
            coder.internal.assert(false, 'MATLAB:table:TooManyOutputsBracesIndexing');
        end
        
        function varargout = braceListAssign(~, ~, varargin) %#ok<STOUT>
            % dummy method to satisfy abstract superclass method
            coder.internal.assert(false, 'MATLAB:table:TooManyOutputs');
        end  
        
        function varargout = parenDelete(~, varargin) %#ok<STOUT>
            % dummy method to satisfy abstract superclass method
            coder.internal.assert(false, 'MATLAB:table:UnsupportedDelete');
        end
        
        
    end
end
