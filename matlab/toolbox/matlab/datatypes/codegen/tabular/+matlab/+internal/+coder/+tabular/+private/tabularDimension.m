classdef (AllowedSubclasses = {?matlab.internal.coder.tabular.private.rowNamesDim, ...
                               ?matlab.internal.coder.tabular.private.varNamesDim, ...
                               ?matlab.internal.coder.tabular.private.metaDim, ...
                               ?matlab.internal.coder.tabular.private.rowTimesDim}) tabularDimension %#codegen
%tabularDimension Internal abstract class to represent a tabular's dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2018-2022 The MathWorks, Inc.
        
    properties(Abstract, Constant, GetAccess=public)
        propertyNames
        requireLabels
        requireUniqueLabels
        DuplicateLabelExceptionID
        NumDimNamesExeptionID
        UnrecognizedLabelExceptionID
        UnrecognizedAssignmentLabelExceptionID
        NonconstantLabelExceptionID
        NonconstantAssignmentLabelExceptionID
        IndexOutOfRangeExceptionID
        AssignmentOutOfRangeExceptionID
        InvalidSubscriptsExceptionID
        InvalidLabelExceptionID
        IncorrectNumberOfLabelsExceptionID 
    end
    
    properties(Abstract, Dependent)
        hasLabels
    end
    
    properties(Abstract, GetAccess=public, SetAccess=protected)
        % Abstract because one subclass doesn't store this explicitly. Assign
        % via the public setLabels method.
        labels
        
        % SetAccess=protected because subclass lengthenTo methods write to these
        % Abstract because each subclass want to implement its own get
        % method and try to return values derived from property sizes
        length
    end
    
    properties(Constant, GetAccess=public)
        subsType = struct('reference',0,'assignment',1,'deletion',2)
    end
    
    %===========================================================================
    methods        
        function obj = init(obj,dimLength,dimLabels)
        % INIT is called by both the dimension objects' constructor and
        % tabular objects' loadobj method. In the latter case, because 
        % a default dimension object is already constructed, it is faster
        % to 'initialize' through INIT rather reconstruct a new one
            obj.length = dimLength;
            if nargin == 3
                coder.internal.assert(isvector(dimLabels) && (numel(dimLabels) == dimLength), ...
                    obj.NumDimNamesExeptionID);
                
                obj.labels = obj.orientAs(dimLabels);
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = createLike(obj,dimLength,dimLabels)
            %CREATELIKE Create a tabularDimension of the same kind as an existing one.
            coder.internal.prefer_const(dimLength,dimLabels);
            obj.length = dimLength;
            if nargin > 2
                obj = obj.setLabels(dimLabels,[],dimLength);
            end
        end
        
        %-----------------------------------------------------------------------
        function newObj = shortenTo(obj,maxIndex)
            % SHORTENTO Returns dim object that is shortened to the specified
            % length.
            if obj.hasLabels
                if iscellstr(obj.labels)
                    % For rownames use cellstr_parenReference
                    newLabels = matlab.internal.coder.datatypes.cellstr_parenReference(obj.labels,1:maxIndex);
                else
                    % For rowtimes rely on duration/datetime parenReference
                    newLabels = obj.labels(1:maxIndex);
                end
                newLabels = obj.orientAs(newLabels);
                newObj = obj.createLike(maxIndex,newLabels);
            else
                newObj = obj.createLike(maxIndex,{});
            end
            
        end
        
        %-----------------------------------------------------------------------
        function newObj = selectFrom(obj,toSelect)
            %SELECTFROM Return a subset of a tableDimimension for the specified indices.
            % The indices might be out of order, that's OK or repeated, that's handled.
            if obj.hasLabels
                if iscell(obj.labels)   % cellstr
                    nonConstIdxIntoConstSizeLabels = coder.internal.isConst(size(obj.labels)) && ~coder.internal.isConst(toSelect);
                    if nonConstIdxIntoConstSizeLabels
                        % if indices are non-constant, make sure labels is a
                        % homogeneous cell array
                        templabels = obj.labels;
                        coder.varsize('templabels', size(obj.labels), [0 0]);
                    else
                        templabels = obj.labels;
                    end
                    if isnumeric(toSelect)
                        % If 'templabels' is empty and 'toSelect' is a variable index
                        % that is going to be empty at runtime, then this is a
                        % completely valid workflow, however, the indexing loop below
                        % would error stating that we are trying to index into an empty
                        % cell array. To work around this, if 'templabels' is empty,
                        % then return it as it is. We will add a runtime error check
                        % to ensure that 'toSelect' is empty at runtime.
                        if nonConstIdxIntoConstSizeLabels && isempty(templabels)
                            coder.internal.assert(isempty(toSelect),'Coder:builtins:CellSubscriptEmpty');
                            newlabels = templabels;
                        else
                            newlabelsTmp = coder.nullcopy(cell(size(toSelect)));
                            for i = 1:numel(toSelect)
                                newlabelsTmp{i} = templabels{toSelect(i)};
                            end
                            newlabelsTmp = obj.orientAs(newlabelsTmp);
                        
                            % Only numeric subscripts can lead to repeated rows (thus labels), no
                            % need to check otherwise.
                            if ~matlab.internal.coder.datatypes.isUniqueNumeric(toSelect)
                                newlabels = obj.makeUniqueForRepeatedIndices(toSelect,newlabelsTmp);
                            else
                                newlabels = newlabelsTmp;
                            end
                        end
                        newlength = numel(newlabels);
                    elseif islogical(toSelect)
                        newlength = sum(toSelect);
                        % If 'templabels' is empty and 'toSelect' is a variable index
                        % that is going to be empty at runtime, then this is a
                        % completely valid workflow, however, the indexing loop below
                        % would error stating that we are trying to index into an empty
                        % cell array. To work around this, if 'templabels' is empty,
                        % then return it as it is. We will add a runtime error check
                        % to ensure that 'toSelect' is empty at runtime.
                        if nonConstIdxIntoConstSizeLabels && isempty(templabels)
                            coder.internal.assert(newlength == 0,'Coder:builtins:CellSubscriptEmpty');
                            newlabels = templabels;
                        else
                            newlabels = coder.nullcopy(cell(1, newlength));
                            if ~isempty(newlabels)
                                count = 1;
                                coder.unroll(coder.internal.isConst(numel(toSelect)));
                                for i = 1:numel(toSelect)
                                    if toSelect(i)
                                        newlabels{count} = templabels{i};
                                        count = count + 1;
                                    end
                                end
                            end
                            newlabels = obj.orientAs(newlabels);
                        end
                    end
                else
                    labelscolumn = obj.labels(:);
                    newlabels = obj.orientAs(labelscolumn(toSelect(:)));
                    newlength = numel(newlabels);
                end
                    
                newObj = createLike(obj,newlength,newlabels);
            elseif isnumeric(toSelect)
                newlength = numel(toSelect);
                newObj = createLike(obj,newlength,{});
            elseif islogical(toSelect)
                newlength = sum(toSelect);
                newObj = createLike(obj,newlength,{});
            elseif matlab.internal.datatypes.isColon(toSelect)
                % leave obj.length alone
                newObj = createLike(obj,obj.length,{});
            else
                assert(false);
                newObj = createLike(obj,obj.length,{});
            end
            
        end
        
        %-----------------------------------------------------------------------
        function objOut = deleteFrom(obj,toDelete)
            coder.extrinsic('setdiff', 'subsref', 'substruct');
            keepIndices = 1:obj.length;
            keepIndices = coder.const(setdiff(keepIndices,toDelete));
            if obj.hasLabels
                obj_labels = coder.const(subsref(obj.labels,substruct('()',{keepIndices})));
                obj_labels = obj.orientAs(obj_labels);
            else
                obj_labels = obj.labels;
            end
            obj_length = numel(keepIndices);
            objOut = obj.createLike(obj_length,obj_labels);
        end
        
        %-----------------------------------------------------------------------
        function obj = setLabels(obj,newLabelsRaw,subscripts,dimLength,fixDups,fixEmpties,fixIllegal)
            coder.internal.prefer_const(dimLength,newLabelsRaw);
            %SETLABELS Modify, overwrite, or remove a tabularDimension's labels.
            if isstring(newLabelsRaw)
                % cannot use convertStringsToChars because scalar string
                % must convert to cellstr, not char vector.
                newLabels = cellstr(newLabelsRaw);
            else
                newLabels = newLabelsRaw;
            end
            if nargin < 7
                % Should illegal labels be modified to make them legal?
                fixIllegal = false;
                if nargin < 6
                    % Should empty labels be filled in wth default labels?
                    fixEmpties = false;
                    if nargin < 5
                        % Should duplicate labels be made unique?
                        fixDups = false;
                    end
                end
            end
            
            % Subscripts equal to [] denotes a full assignment while the edge case of a
            % partial assignment to zero labels requires a 1x0 or 0x1 empty.
            fullAssignment = (nargin == 2) || isequal(subscripts,[]);
            if fullAssignment % replacing all labels
                indices = zeros(1,dimLength);
                for i = 1:dimLength
                    indices(i) = i;
                end
            elseif obj.hasLabels % replacing some labels
                indices = obj.subs2inds(subscripts);
                if islogical(indices)
                    % subs2inds leaves logical untouched, validateAndAssignLabels requires indices
                    indices = find(indices);
                end
            else % don't allow a subscripted assignment to an empty property
                obj.throwInvalidPartialLabelsAssignment();
            end
            
            % Check the type of the new labels, and convert them to the canonical type as
            % necessary (and allowed). If this is a full assignment of a 0x0, and removing
            % the labels is allowed, validateLabels leaves the shape alone, otherwise it
            % reshapes to a vector of the appropriate orientation.
            obj = obj.validateAndAssignLabels(newLabels,indices,fullAssignment,dimLength,fixDups,fixEmpties,fixIllegal);
        end
        
        
        %-----------------------------------------------------------------------
        function [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
               = subs2inds(obj,rawsubscripts,subsType)
            %SUBS2INDS Convert table subscripts (labels, logical, numeric) to indices.
            %if nargin < 3, subsType = obj.subsType.reference; end
            
            coder.internal.prefer_const(rawsubscripts);
            
            if nargin < 3, subsType = obj.subsType.reference; end
            
            % Translate a table subscript object into actual subscripts,
            % take note of a colon object. The concrete dim class may have
            % already translated some kinds of subscript objects that need
            % dim-specific infomration to do the translation.
            isColonObj = false;

            if isobject(rawsubscripts) && isa(rawsubscripts,'matlab.internal.coder.tabular.private.subscripter')
                subscripts = rawsubscripts.getSubscripts(obj);
                % The subscript may be a colonobj, or a timerange subscripter may return one.
                %if isa(subscripts,'matlab.internal.ColonDescriptor')
                %    isColonObj = true;
                %end
            else
                subscripts = rawsubscripts;
            end

            if isnumeric(subscripts) || islogical(subscripts) || isColonObj
                isLiteralColon = false;
                isLabels = false;
                
                % Leave numeric and logical indices alone.
                if isnumeric(subscripts)
                    indices = subscripts(:);    
                    coder.internal.errorIf(any(isnan(indices)), ...
                        'CatalogID','MATLAB:badsubscriptTextRange',...
                        'ReportedID','MATLAB:badsubscript');
                    numIndices = numel(indices);
                    if isempty(indices)
                        % empty branch necessary for variable sized
                        % indices -- max does not support variable sized
                        % array which turns into empty an runtime
                        maxIndex = zeros('like', indices);
                    else
                        maxIndex = max(indices);
                    end
                elseif islogical(subscripts)
                    indices = subscripts(:);
                    numIndices = sum(indices);
                    %maxIndex = find(indices,1,'last');
                    maxIndex = 0;
                    for i = numel(indices):-1:1
                        if indices(i)
                            maxIndex = i;
                            break;
                        end
                    end
                else % isColonObj
                    indices = subscripts; % unexpanded
                    numIndices = length(subscripts); %#ok<CPROPLC>
                    maxIndex = double(subscripts.Stop);
                end
                
                subsTypes = obj.subsType;
                switch subsType
                    case subsTypes.reference
                        coder.internal.errorIf(~isempty(maxIndex) && maxIndex > obj.length, ...
                            obj.IndexOutOfRangeExceptionID);
                        if nargout > 5
                            updatedObj = obj.selectFrom(indices);
                        end

                    case subsTypes.assignment
                        coder.internal.errorIf(~isempty(maxIndex) && maxIndex > obj.length, ...
                            obj.AssignmentOutOfRangeExceptionID);
                        if nargout > 5                            
                            updatedObj = obj;
                        end
                        %{
                    case subsTypes.deletion
                        if maxIndex > obj.length
                            obj.throwIndexOutOfRange();
                        elseif nargout > 4
                            updatedObj = obj.deleteFrom(indices);
                        end
                        %}
                    otherwise
                        assert(false);
                end
                
            elseif coder.internal.isConst(subscripts) && matlab.internal.datatypes.isColon(subscripts)
                % Leave ':' alone. The : is evaluated with respect to the existing
                % dimension. Cases where : needs to be evaluated with respect to the
                % RHS of an assignment (i.e. assigning to a 0x0) need to be handled
                % elsewhere.
                isLiteralColon = true;
                isLabels = false;
                indices = subscripts;
                numIndices = obj.length;
                maxIndex = obj.length;
                
                if nargout > 5
                    updatedObj = obj;
                end
                
            else % "native" subscripts, i.e. names or times
                isLiteralColon = false;
                isLabels = true;
                
                % Translate labels into indices.
                [subscriptscells,rawindices] = obj.validateNativeSubscripts(subscripts,obj.labels);
                rawindices = rawindices(:);  % force into a column
                numIndices = numel(rawindices);
                maxIndex = max(rawindices);
                
                % locate the first bad index, for error message
                badindex = 0;
                coder.unroll(coder.internal.isConst(numel(rawindices)));
                for i = 1:numel(rawindices)
                    if ~rawindices(i)
                        badindex = i;
                        break;
                    end
                end
                
                subsTypes = obj.subsType;
                switch subsType
                    case subsTypes.reference     
                        if obj.requireUniqueLabels
                            % Unmatched row labels are an error for reference.
                            if coder.internal.isConst(subscriptscells) && ...
                                    coder.internal.isConst(badindex) && ...
                                    iscell(subscriptscells) && badindex > 0
                                coder.internal.assert(all(rawindices>0), ...
                                    obj.UnrecognizedLabelExceptionID,subscriptscells{badindex});
                            else
                                coder.internal.assert(all(rawindices>0), ...
                                    obj.NonconstantLabelExceptionID);
                            end
                            indices = rawindices;
                        else
                            % Unmatched row labels are ignored for reference.
                            indices = rawindices(rawindices > 0);
                            numIndices = numel(indices);
                            % Don't need to thin subscriptscells, it isn't returned.
                        end

                        if nargout > 5
                            updatedObj = obj.selectFrom(indices);
                        end
                    case subsTypes.assignment
                        if obj.requireUniqueLabels
                            % codegen does not support growing by assignment. Out of range numeric/logical
                            % indices on the LHS of an assignment are an error caught above. For tabulars that
                            % require unique row labels, unmatched native subscripts on the LHS are also an error.
                            if coder.internal.isConst(subscriptscells) && ...
                                    coder.internal.isConst(badindex) && ...
                                    iscell(subscriptscells) && badindex > 0
                                coder.internal.assert(all(rawindices>0), ...
                                    obj.UnrecognizedAssignmentLabelExceptionID, subscriptscells{badindex});
                            else
                                coder.internal.assert(all(rawindices>0), ...
                                    obj.NonconstantAssignmentLabelExceptionID);
                            end
                            indices = rawindices;
                        else
                            % codegen does not support growing by assignment. Out of range numeric/logical
                            % indices on the LHS of an assignment are an error caught above. But for tabulars
                            % that allow row labels to be duplicates, unmatched native subscripts are just
                            % ignored. ***This is by design, and different than MATLAB, and different than
                            % reference in codegen.*** However, the actual ignoring is done by subs2ind's caller
                            % (parenAssign), because rows of the assignment's RHS also need to be ignored.
                            indices = rawindices;
                        end
                        
                        if nargout > 5
                            updatedObj = obj;
                        end
                                                %{
                    case subsTypes.deletion
                        if nnz(indices) < numIndices
                            newLabels = unique(subscripts(~indices),'stable');
                            obj.throwUnrecognizedLabel(newLabels(1));
                        elseif nargout > 4
                            updatedObj = obj.deleteFrom(indices);
                        end
                        %}
                    otherwise
                        assert(false);
                end
            end
            %if ~isColonObj
                indices = obj.orientAs(indices);
            %end
        end
    end
    
    %===========================================================================
    methods (Access=protected)
        function obj = assignLabels(obj,newLabels,fullAssignment,indices,dimLength)
            coder.internal.prefer_const(dimLength, newLabels, fullAssignment);
            if fullAssignment
                if isvector(newLabels)
                    % The number of new labels has to match what's being assigned to.
                    coder.internal.assert(numel(newLabels) == dimLength, ...
                        obj.IncorrectNumberOfLabelsExceptionID);                    
                    obj.labels = newLabels;
                else % a 0x0
                    % Full assignment of a 0x0 clears out the existing labels, if allowed above by
                    % the subclass's validateLabels.
                    %obj.labels = newLabels([]); % force a 0x0, for cosmetics
                    obj.labels = cell(0,0);
                end
            else % subscripted assignment
                % The number of new labels has to match what's being assigned to.
                if numel(newLabels) ~= numel(indices)
                    obj.throwIncorrectNumberOfLabelsPartial();
                end
                obj.labels(indices) = newLabels;
            end
        end
        
        %-----------------------------------------------------------------------
        function [subscripts,indices] = validateNativeSubscripts(obj,inputsubscripts,labels)
            coder.internal.prefer_const(inputsubscripts, labels);
            rawsubscripts = convertStringsToChars(inputsubscripts);
            
            % Default behavior assumes the labels are names, subclasses with
            % non-name labels need to overload.
            charsubscripts = ischar(rawsubscripts);
            coder.internal.assert(charsubscripts || matlab.internal.coder.datatypes.isText(rawsubscripts,true), ...
                obj.InvalidSubscriptsExceptionID);
            if charsubscripts % already weeded out ':'
                % Depending on whether the rawsubscripts were passed in or
                % created in generated code, '' might either be 0x0 or 1x0 char,
                % so verify that rawsubscripts are non-empty char row vector. On
                % MATLAB side simply checking isrow would have been sufficient here.
                coder.internal.assert(isrow(rawsubscripts) && ~isempty(rawsubscripts), obj.InvalidLabelExceptionID);
                subscripts = { rawsubscripts };
            else % matlab.internal.coder.datatypes.isText(rawsubscripts,true) 
                % require a cell array or string array, don't allow empty character vectors in it
                
                % Don't allow scalar missing string or "", and handle it the
                % same as ''.
                %if isstring(subscripts) && isscalar(subscripts) && strlength(subscripts) < 1 
                %    obj.throwInvalidLabel();
                %end
                subscripts = rawsubscripts;
            end
            
            coder.extrinsic('ismember');
            if coder.internal.isConst(subscripts) && coder.internal.isConst(labels)
                [~,indices] = coder.const(@ismember,subscripts, labels);
            else
                [~,indices] = matlab.internal.coder.datatypes.cellstr_ismember(subscripts,labels);
            end
        end
        
        %-----------------------------------------------------------------------
        function checkDuplicateLabelsSimple(obj, labels)
            % simple version of checkDuplicateLabels that scans through one
            % label cell array for duplciates, and errors if found
            coder.internal.prefer_const(labels);
            coder.extrinsic('unique', 'setdiff');
            
            % If constant, do the work in MATLAB, which is more efficient
            % and reduces codegen time
            if coder.internal.isConst(labels)
                [uniqueLabels, ia] = coder.const(@unique,labels);
                if numel(labels) > numel(uniqueLabels)
                    duplicateindices = coder.const(setdiff(1:numel(labels), ia));
                    coder.internal.errorIf(true, ...
                        obj.DuplicateLabelExceptionID, labels{duplicateindices(1)});
                end
            else
                presortedLabels = labels;
                if coder.internal.isConst(size(labels))
                    coder.varsize('presortedLabels', [], [false false]);  % force homogeneous
                end
                sortedLabels = matlab.internal.coder.datatypes.cellstr_sort(presortedLabels);
                for i = 1:numel(sortedLabels)-1
                    coder.internal.errorIf(strcmp(sortedLabels{i}, sortedLabels{i+1}), ...
                        obj.DuplicateLabelExceptionID, sortedLabels{i});
                end
            end
        end
    end

    %===========================================================================
    methods (Static)
        function conflicts = checkReservedNames(labels,reservedNames,errorOnConflicts,msgID)
            %CHECKRESERVEDNAMES Check if variable names conflict with reserved names.
            firstconflict = 0;            
            if ischar(labels) % names is either a single character vector ...
                conflicts = any(strcmp(labels, reservedNames), 2);
                if conflicts
                    firstconflict = 1;
                end
            else             % ... or a cell array of character vectors
                conflicts = false(size(labels));                
                for i = 1:numel(labels)
                    conflicts(i) = any(strcmp(labels{i}, reservedNames), 2);
                    if firstconflict == 0 && conflicts(i)
                        firstconflict = i;
                    end
                end
            end
            
            if errorOnConflicts 
                coder.internal.errorIf(firstconflict > 0, msgID, firstconflict);
            end
        end
    end
    
    
    %===========================================================================
    methods (Abstract, Access=protected)
        obj = validateAndAssignLabels(obj,newLabels,indices,fullAssignment,fixDups,fixEmpties,fixIllegal)
    end
   
    %===========================================================================  
    methods (Abstract, Static, Access=protected)
        y = orientAs(x); % Reshape x as a vector in the specified orientation
    end
end
