classdef (AllowedSubclasses = {?matlab.internal.tabular.private.rowNamesDim, ...
                               ?matlab.internal.tabular.private.rowTimesDim, ...
                               ?matlab.internal.tabular.private.varNamesDim, ...
                               ?matlab.internal.tabular.private.varNamesWithEventsDim, ...
                               ?matlab.internal.tabular.private.metaDim}) tabularDimension
%tabularDimension Internal abstract class to represent a tabular's dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2016-2023 The MathWorks, Inc.
        
    properties(Abstract, Constant, GetAccess=public)
        labelType
        requireLabels
        requireUniqueLabels
        DuplicateLabelExceptionID
    end
    
    properties(GetAccess=public, SetAccess=protected)
        % SetAccess=protected because subclass lengthenTo methods write to these
        length
        
        % Distinguish between not having labels and a zero-length dimension with no labels.
        hasLabels = false
    end
    properties(Abstract, GetAccess=public, SetAccess=protected)
        % Abstract because one subclass doesn't store this explicitly. Assign
        % via the public setLabels method.
        labels
    end
    
    properties(Constant, GetAccess=public)
        subsType_reference = 0;
        subsType_forwardedReference = 1;
        subsType_assignment = 2
        subsType_deletion = 3;
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
                if isvector(dimLabels) && (numel(dimLabels) == dimLength)
                    obj.hasLabels = true;
                    obj.labels = obj.orientAs(dimLabels);
                else
                    obj.throwIncorrectNumberOfLabels();
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = createLike(obj,dimLength,dimLabels,validateLabels)
            %CREATELIKE Create a tabularDimension of the same kind as an existing one.
            obj.length = dimLength;
            if nargin < 3
                if obj.hasLabels
                    % These are invalid empty labels that must be filled in later.
                    obj.labels = obj.emptyLabels(dimLength); 
                else
                    obj.hasLabels = false;
                    obj.labels = obj.labels([]);
                end
            elseif nargin < 4 || validateLabels
                % Do full validation using setLabels.
                obj = obj.setLabels(dimLabels,[]);
            else % ~validateLabels
                % Directly assign the labels, no validation is done.
                obj = obj.assignLabels(dimLabels,true);
            end
        end
                
        
        %-----------------------------------------------------------------------
        function obj = removeLabels(obj)
            if obj.requireLabels
                obj.throwRequiresLabels();
            else
                obj.labels = {}; % optional labels is usually names
                obj.hasLabels = false;
            end
        end
        
        %-----------------------------------------------------------------------
        function labels = emptyLabels(obj,num)
            % EMPTYLABELS Return a vector of empty labels of the right kind.
            
            % Default behavior assumes the labels are names, subclasses with
            % non-name labels need to overload.
            labels = obj.orientAs(repmat({''},num,1));
        end
        
        %-----------------------------------------------------------------------
        function labels = textLabels(obj,indices)
            % TEXTLABELS Return the labels converted to text.
            
            % Default behavior assumes the labels are names, subclasses with
            % non-name labels need to overload.
            if nargin < 2
                labels = obj.labels;
            else
                labels = obj.labels(indices);
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = selectFrom(obj,toSelect)
            %SELECTFROM Return a subset of a tableDimimension for the specified indices.
            % The indices might be out of order, that's OK or repeated, that's handled.
            import matlab.internal.datatypes.isUniqueNumeric
            import matlab.internal.datatypes.isColon
            
            if obj.hasLabels
                obj.labels = obj.orientAs(obj.labels(toSelect));
                
                % Only numeric subscripts can lead to repeated rows (thus labels), no
                % need to check otherwise.
                if isnumeric(toSelect) && ~isUniqueNumeric(toSelect)
                    obj = obj.makeUniqueForRepeatedIndices(toSelect);
                end
                
                obj.length = numel(obj.labels);
            elseif isnumeric(toSelect)
                obj.length = numel(toSelect);
            elseif islogical(toSelect)
                obj.length = nnz(toSelect);
            elseif isColon(toSelect)
                % leave obj.length alone
            elseif isa(toSelect,'matlab.internal.ColonDescriptor')
                obj.length = toSelect.length;
            else
                assert(false);
            end
        end
                        
        %-----------------------------------------------------------------------
        function obj = shortenTo(obj,maxIndex)
            if obj.hasLabels
                obj.labels = obj.orientAs(obj.labels(1:maxIndex));
            end
            obj.length = maxIndex;
        end
        
        %-----------------------------------------------------------------------
        function obj = deleteFrom(obj,toDelete)
            if obj.hasLabels
                obj.labels(toDelete) = [];
                obj.labels = obj.orientAs(obj.labels);
            end
            keepIndices = 1:obj.length;
            keepIndices(toDelete) = [];
            obj.length = numel(keepIndices);
        end        
        
        %-----------------------------------------------------------------------
        function obj = assignInto(obj,obj2,assignInto)
            if obj.hasLabels && obj2.hasLabels
                obj.labels(assignInto) = obj2.labels;
            elseif obj.hasLabels % && ~obj2.hasLabels
                % These are invalid empty labels that must be filled in later.
                obj.labels(assignInto) = obj2.emptyLabels(obj2.length);
            elseif obj2.hasLabels % && ~obj.hasLabels
                obj.labels = obj.emptyLabels(obj.length);
                obj.labels(assignInto) = obj2.labels;
                obj.hasLabels = true;
            end
        end
        
        %-----------------------------------------------------------------------
        function target = moveProps(target,source,fromLocs,toLocs) %#ok<INUSD>
            % MOVEPROPS Assign values from a tableDimension's properties into another's.
            % Replace property values in the target with values from the source,
            % across all properties that this dimension manages. If a property
            % that exists in the source doesn't exist in the target, first create
            % it in the target filled with default values. If a property that
            % exists in the target doesn't exist in the source, replace the target
            % values with default values. If a property doesn't exist in either,
            % do nothing for that property.
            %
            % Labels are not replaced.
            
            % By default, there are no properties (other than labels).
        end
        
        %-----------------------------------------------------------------------
        function target = mergeProps(target,source,fromLocs) %#ok<INUSD>
            % MERGEPROPS Merge a tableDimension's properties into another's.
            % Create properties that don't exist in the target using the
            % corresponding properties from the source (if the latter exist).
            % Properties that are already present in the target are left alone.
            % Labels are left alone.
            
            % By default, there are no properties (other than labels).
        end
        
        %-----------------------------------------------------------------------
        function obj = setLabels(obj,newLabels,subscripts,fixDups,fixEmpties,fixIllegal)
            %SETLABELS Modify, overwrite, or remove a tabularDimension's labels.
            if isstring(newLabels)
                % cannot use convertStringsToChars because scalar string
                % must convert to cellstr, not char vector.
                newLabels = cellstr(newLabels);
            end
            if nargin < 6
                % Should illegal labels be modified to make them legal?
                fixIllegal = false;
                if nargin < 5
                    % Should empty labels be filled in wth default labels?
                    fixEmpties = false;
                    if nargin < 4
                        % Should duplicate labels be made unique?
                        fixDups = false;
                    end
                end
            end
                        
            % Subscripts equal to [] denotes a full assignment while the edge case of a
            % partial assignment to zero labels requires a 1x0 or 0x1 empty.
            fullAssignment = (nargin == 2) || isequal(subscripts,[]);
            if fullAssignment % replacing all labels
                indices = 1:obj.length;
            elseif obj.hasLabels % replacing some labels
                indices = obj.subs2inds(subscripts);
                if islogical(indices)
                    % subs2inds leaves logical untouched, validateAndAssignLabels requires indices
                    indices = find(indices);
                end
            else % don't allow a subscripted assignment to an empty label property
                assert(false,'Partial/Subscripted assignment to empty label is not supported');
            end
            
            % Check the type of the new labels, and convert them to the canonical type as
            % necessary (and allowed). If this is a full assignment of a 0x0, and removing
            % the labels is allowed, validateLabels leaves the shape alone, otherwise it
            % reshapes to a vector of the appropriate orientation.
            obj = obj.validateAndAssignLabels(newLabels,indices,fullAssignment,fixDups,fixEmpties,fixIllegal);
        end

        %-----------------------------------------------------------------------
        function obj = assignLabels(obj,newLabels,fullAssignment,indices)
            % assignLabels does not do any kind of error checking and assumes
            % that the size and type of newLabels and indices have already been
            % validated by the caller. Use validateAndAssignLabels if you need
            % to do both validation and assignment.
            if fullAssignment
                if isvector(newLabels)
                    obj.hasLabels = true;
                    obj.labels = newLabels;
                else % a 0x0
                    % Full assignment of a 0x0 clears out the existing labels, if allowed above by
                    % the subclass's validateLabels.
                    obj.labels = newLabels([]); % force a 0x0, for cosmetics
                    obj.hasLabels = false;
                end
            else % subscripted assignment
                obj.labels(indices) = newLabels;
            end
        end

        %-----------------------------------------------------------------------
        function [tf,duplicated] = checkDuplicateLabels(obj,labels1,labels2,okLocs)
            %CHECKDUPLICATELABELS Check for duplicated names.
            
            % Check for any duplicate names in names1            
            if nargin == 2 % checkDuplicateLabels(obj,labels1)
                % names1 is always a cellstr
                duplicated = false(size(labels1));
                [labels1Sorted,lids] = sort(labels1);
                duplicated(2:end) = strcmp(labels1Sorted(1:end-1),labels1Sorted(2:end));
                % Put duplicated back in the original order.
                duplicated(lids) = duplicated; 
                
            % Check if any name in names1 is already in names2, except that
            % names1(i) may be at names2(okLocs(i)).  This does not check if
            % names1 contains duplicates within itself
            elseif nargin == 4 % checkDuplicateLabels(obj,labels1,labels2,okLocs)
                % names2 is always a cellstr
                if ischar(labels1) % names1 is either a single character vector ...
                    tmp = strcmp(labels1, labels2); tmp(okLocs) = false;
                    duplicated = any(tmp);
                else             % ... or a cell array of character vectors
                    duplicated = false(size(labels1));
                    for i = 1:length(labels1) %#ok<CPROPLC>
                        tmp = strcmp(labels1{i}, labels2); tmp(okLocs(i)) = false;
                        duplicated(i) = any(tmp);
                    end
                end
                
            % Check if any name in names1 is already in names2.  This does not check if
            % names1 contains duplicates within itself
            else % nargin==3, checkDuplicateLabels(obj,labels1,labels2) - least frequent syntax
                % names2 is always a cellstr
                if ischar(labels1) % names1 is either a single character vector ...
                    duplicated = any(strcmp(labels1, labels2));
                else             % ... or a cell array of character vectors
                    duplicated = false(size(labels1));
                    for i = 1:length(labels1) %#ok<CPROPLC>
                        duplicated(i) = any(strcmp(labels1{i}, labels2));
                    end
                end
                
            
            end
            
            tf = any(duplicated);
            
            if tf && obj.requireUniqueLabels && (nargout == 0)
                allDups = labels1(duplicated); 
                throwAsCaller(MException(message(obj.DuplicateLabelExceptionID,allDups{1}))); % Report the first dup in the message
            end
        end
        
        %-----------------------------------------------------------------------
        function [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
                     = subs2inds(obj,subscripts,subsType)
            %SUBS2INDS Convert table subscripts (labels, logical, numeric) to indices.
            
            import matlab.internal.datatypes.isColon
            
            try
                if nargin < 3, subsType = obj.subsType_reference; end
                
                % Take a note of colon object and handle core (numeric, logical
                % or colon) and dimension specific native subscripts.
                isColonObj = false;
                
                % By default subs2inds converts the translated indices into a
                % row/col vector (depending on the type of dim). However, if the 
                % caller supplied the subsType as forwardedReference then
                % subs2inds would preserve the original shape if it is allowed
                % by 1. the dim object and 2. the type of the subscript.
                preserveShape = (subsType == obj.subsType_forwardedReference);
                
                % Check isobject first since isa check is slightly expensive.
                % This allows core (numeric, logical, ':') subscripts to quickly
                % flow through.
                if isobject(subscripts)
                    % The caller (tabular.subs2inds) is responsible for handling
                    % subscripter objects, since some of them may require information
                    % from different components of the tabular object. Those would
                    % have been converted to numeric or logical indices before
                    % coming here.
                    if isa(subscripts,'matlab.internal.ColonDescriptor')
                        % The subscript may have originally been a colonobj, or a timerange
                        % subscripter may have returned one when handled by tabular/subs2indices.
                        isColonObj = true;
                        % The shape cannot be preserved for a ColonDescriptor.
                        preserveShape = false;
%                    else % if ismethod(obj,'subsindex')
%                        % If the class has subsindex, call that to get something usable.
%                        try
%                            subscripts = subsindex(subscripts) + 1; % -> one-based
%                        catch
%                            % If no subsindex, let the object fall through. If it does not
%                            % claims to be numeric or logical, validateNativeSubscripts gets
%                            % to try to recognize it. Otherwise it had better behave reasonably.
%                        end
                    end
                end
                
                if isnumeric(subscripts) || islogical(subscripts) || isColonObj
                    isLiteralColon = false;
                    isLabels = false;
                    
                    % Leave numeric and logical indices alone.
                    if isnumeric(subscripts)
                        indices = subscripts(:);
                        if any(isnan(indices))
                            error(message('MATLAB:badsubscript',getString(message('MATLAB:badsubscriptTextRange'))));
                        end
                        numIndices = numel(indices);
                        maxIndex = max(indices);
                    elseif islogical(subscripts)
                        indices = subscripts(:);
                        numIndices = nnz(indices);
                        maxIndex = find(indices,1,'last');
                    else % isColonObj
                        preserveShape = false;
                        indices = subscripts; % unexpanded
                        numIndices = length(subscripts); %#ok<CPROPLC>
                        maxIndex = double(subscripts.Stop);
                    end
                    
                    switch subsType
                        case {obj.subsType_reference, obj.subsType_forwardedReference}
                        if maxIndex > obj.length
                            obj.throwIndexOutOfRange();
                        elseif nargout > 4
                            updatedObj = obj.selectFrom(indices);
                        end
                        case obj.subsType_assignment
                        if nargout > 4
                            if maxIndex > obj.length
                                % Grow the dimension with default labels.
                                updatedObj = obj.lengthenTo(maxIndex);
                            else
                                updatedObj = obj;
                            end
                        end
                        case obj.subsType_deletion
                        if maxIndex > obj.length
                            obj.throwIndexOutOfRange();
                        elseif nargout > 4
                            updatedObj = obj.deleteFrom(indices);
                        end
                    otherwise
                        assert(false);
                    end
                    
                elseif isColon(subscripts)
                    % Leave ':' alone. The : is evaluated with respect to the existing
                    % dimension. Cases where : needs to be evaluated with respect to the
                    % RHS of an assignment (i.e. assigning to a 0x0) need to be handled
                    % elsewhere.
                    isLiteralColon = true;
                    isLabels = false;
                    indices = subscripts;
                    numIndices = obj.length;
                    maxIndex = obj.length;
                    preserveShape = false;

                    if nargout > 4
                        updatedObj = obj;
                    end
                    
                else % "native" subscripts, i.e. names, times, or pattern
                    isLiteralColon = false;
                    isLabels = true;
                    
                    % Translate labels into indices.
                    [subscripts,indices,canPreserveShape] = obj.validateNativeSubscripts(subscripts);
                    preserveShape = preserveShape & canPreserveShape;
                    indices = indices(:);  % force into a column
                    numIndices = numel(indices);
                    maxIndex = max(indices);
                    
                    switch subsType
                        case {obj.subsType_reference, obj.subsType_forwardedReference}
                        if nnz(indices) < numIndices
                            if obj.requireUniqueLabels
                                newLabels = unique(subscripts(~indices),'stable');
                                obj.throwUnrecognizedLabel(newLabels(1));
                            end
                            indices = indices(indices>0);
                        end
                        if nargout > 4
                            updatedObj = obj.selectFrom(indices);
                        end
                        case obj.subsType_assignment
                        if nnz(indices) < numIndices
                            [newLabels,~,newIndices] = unique(subscripts(~indices),'stable');
                            indices(~indices) = obj.length + newIndices;
                            maxIndex = max(indices(:));
                            if nargout > 4
                                % The new labels are guaranteed be distinct from the existing
                                % labels, otherwise the assignment would not need to
                                % lengthen the dimension.
                                updatedObj = obj.lengthenTo(maxIndex,newLabels);
                            end
                        elseif nargout > 4
                            updatedObj = obj;
                        end
                        case obj.subsType_deletion
                        if nnz(indices) < numIndices
                            newLabels = unique(subscripts(~indices),'stable');
                            obj.throwUnrecognizedLabel(newLabels(1));
                        elseif nargout > 4
                            updatedObj = obj.deleteFrom(indices);
                        end
                    otherwise
                        assert(false);
                    end
                end

                if preserveShape
                    indices = reshape(indices,size(subscripts));              
                elseif ~isColonObj
                    indices = obj.orientAs(indices);                
                end
            catch ME
                throwAsCaller(ME)
            end
        end
    end
       
    %===========================================================================
    methods (Access=protected)
        function [subscripts,indices,canPreserveShape] = validateNativeSubscripts(obj,subscripts)
            import matlab.internal.datatypes.isText

            % canPreserveShape output argument is used to let the caller know if the
            % the indices could be reshaped (if needed) to match the shape of
            % the original subscripts.
            % For named subscripting, char names and pattern subscripts should
            % not be reshaped. Cellstrs and string can be reshaped.
            canPreserveShape = false;
            subscripts = convertStringsToChars(subscripts);
            
            % Default behavior assumes the labels are names, subclasses with
            % non-name labels need to overload.
            if ischar(subscripts) % already weeded out ':'
                if isrow(subscripts)
                    subscripts = { subscripts };
                else
                    obj.throwInvalidLabel();
                end
            elseif isText(subscripts,true) % require a cell array or string array, don't allow empty character vectors in it
                canPreserveShape = true;
                % Don't allow scalar missing string or "", and handle it the
                % same as ''.
                if isstring(subscripts) && isscalar(subscripts) && strlength(subscripts) < 1 
                    obj.throwInvalidLabel();
                end
            elseif isa(subscripts,"pattern")
                if ~isscalar(subscripts)
                    obj.throwInvalidSubscripts();
                end
                indices = find(matches(obj.labels,subscripts));
                if isempty(indices)
                    subscripts = {};
                else
                    subscripts = obj.labels(indices);
                end
                return
            else
                obj.throwInvalidSubscripts();
            end

            indices = zeros(size(subscripts));
            labs = obj.labels;
            for i = 1:numel(indices)
                indFirstMatch = find(strcmp(subscripts{i},labs), 1);
                if indFirstMatch
                    indices(i) = indFirstMatch;
                end
            end
        end
    end

    %===========================================================================
    methods (Static)
        function conflicts = checkReservedNamesImpl(labels,reservedNames)
            %CHECKRESERVEDNAMES Check if variable names conflict with reserved names.
            conflicts = matches(labels,reservedNames);                
        end

        s = makeLegacyNames(varNames,dimNames)
    end
    
    %===========================================================================
    methods (Abstract)
        labels = defaultLabels(indices);
        obj = lengthenTo(obj,maxIndex,newLabels)
        s = getProperties(obj)
        propNames = propertyNames(obj)
    end
    
    %===========================================================================
    methods (Abstract, Access=protected)
        obj = validateAndAssignLabels(obj,newLabels,indices,fullAssignment,fixDups,fixEmpties,fixIllegal)
        obj = makeUniqueForRepeatedIndices(obj,indices)
        
        throwRequiresLabels(obj)
        throwIncorrectNumberOfLabels(obj)
        throwIncorrectNumberOfLabelsPartial(obj)
        throwIndexOutOfRange(obj)
        throwUnrecognizedLabel(obj,label)
        throwInvalidLabel(obj)
        throwInvalidSubscripts(obj)
    end
   
    %===========================================================================
    methods (Abstract, Static, Access=protected)
        x = orientAs(x); % Reshape x as a vector in the specified orientation
    end
end