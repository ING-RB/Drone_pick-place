classdef (Sealed) varNamesDim < matlab.internal.coder.tabular.private.tabularDimension  %#codegen
%VARNAMESDIM Internal class to represent a tabular's variables dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

%   Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Constant, GetAccess=public)
        propertyNames = {'VariableNames'; 'VariableDescriptions'; 'VariableUnits'; 'VariableContinuity'};
        requireLabels = true;
        requireUniqueLabels = true;
        reservedNames = {'VariableNames' 'RowNames' 'Properties' ':'};
        DuplicateLabelExceptionID = 'MATLAB:table:DuplicateVarNames';
        NumDimNamesExeptionID = 'MATLAB:table:IncorrectNumberOfVarNames';
        UnrecognizedLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingVarName';
        UnrecognizedAssignmentLabelExceptionID = 'MATLAB:table:UnrecognizedAssignmentVarName';
        NonconstantLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingNonconstantVarName';
        NonconstantAssignmentLabelExceptionID = 'MATLAB:table:UnrecognizedAssignmentNonconstantVarName';
        IndexOutOfRangeExceptionID = 'MATLAB:table:VarIndexOutOfRange';
        AssignmentOutOfRangeExceptionID = 'MATLAB:table:AssignmentVarIndexOutOfRange';
        InvalidSubscriptsExceptionID = 'MATLAB:table:InvalidVarSubscript';
        InvalidLabelExceptionID = 'MATLAB:table:InvalidVarName';
        IncorrectNumberOfLabelsExceptionID = 'MATLAB:table:IncorrectNumberOfVarNames';
    end
   
    properties(Dependent)
        hasLabels
    end
    
    properties(GetAccess=public, SetAccess=private)
        %descrs = {}
        descrs
        %units = {}
        units
        %continuity = []; % Empty 0x0 enum
        continuity
        customProps = struct;
        
        % Having no descrs/units is not the same as a zero-length dimension that
        % has zero descrs/units.
        hasDescrs = false
        hasUnits = false
        hasContinuity = false
        hasCustomProps = false
    end
    
    properties(GetAccess=public, SetAccess=protected)
        labels
        length
    end
   
    %===========================================================================
    methods
        function obj = varNamesDim(length,labels)
            if nargin == 0        
                % Do nothing. This syntax is reserved
                % for the situation where the caller will set the rest of the 
                % properties manually afterwards.
                return;
            elseif nargin == 1
                obj = obj.init(length);  % don't use default labels                
            else
                % require cellstr, no empties
                coder.internal.assert(matlab.internal.coder.datatypes.isCharStrings(...
                    labels,true,false), 'MATLAB:table:InvalidVarNames');

                labels = reshape(labels, 1, []); % a row vector
                
                matlab.internal.coder.tabular.private.varNamesDim.makeValidName(labels,'error');
                obj.checkDuplicateLabelsSimple(labels);
                obj = obj.init(length,labels);
            end      
            % make units and descrs properties a cellstr with variable sized elements
            units = cell(1,length);
            for i = 1:numel(units)
                units{i} = char(zeros(1,0));
            end
            if ~isempty(units)
                coder.varsize('units{:}', [], [true true]);
            end
            obj.units = units;
            descrs = cell(1,length);
            for i = 1:numel(descrs)
                descrs{i} = char(zeros(1,0));
            end
            if ~isempty(descrs)
                coder.varsize('descrs{:}', [], [true true]);
            end
            obj.descrs = descrs;
            
            if length > 0
                obj.continuity = repmat(matlab.internal.coder.tabular.Continuity.unset, 1, length);
            else
                % Empty array of enumerations not supported in codegen. Use
                % empty double.
                obj.continuity = [];
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = init(obj,dimLength,dimLabels)
            if nargin == 2
                obj = init@matlab.internal.coder.tabular.private.tabularDimension(...
                    obj,dimLength);
            else
                obj = init@matlab.internal.coder.tabular.private.tabularDimension(...
                    obj,dimLength,dimLabels);
            end
        end
        
        %-----------------------------------------------------------------------
        function newobj = lengthenTo(obj,maxIndex,newLabels)
            coder.internal.prefer_const(maxIndex,newLabels);
            coder.extrinsic('horzcat','matlab.lang.makeUniqueStrings','namelengthmax');
            newIndices = (obj.length+1):maxIndex;
            if nargin < 3
                % Create default names for the new vars, making sure they don't conflict with
                % existing names.
                labs = coder.const(matlab.lang.makeUniqueStrings(...
                    coder.const(obj.dfltLabels(newIndices)),obj.labels,namelengthmax));
            else
                % Assume that newLabels has already been checked by validateNativeSubscripts as
                % names, and that the new names don't conflict with existing names. But still have
                % to make sure the names are legal.
                obj.makeValidName(newLabels,'error');
                labs = coder.const([coder.const(obj.labels),newLabels]);
            end
            
            oldLen = obj.length;
            newobj = matlab.internal.coder.tabular.private.varNamesDim;
            newobj = newobj.init(maxIndex,labs);
            
            % VariableUnits
            newobj.hasUnits = obj.hasUnits;
            uts = cell(1,maxIndex);
            for i = 1:maxIndex
                if i <= oldLen
                    uts{i} = obj.units{i};
                else
                    uts{i} = char(zeros(1,0));
                end
            end
            if ~isempty(uts)
                coder.varsize('uts{:}', [], true(1,2));
            end
            newobj.units = uts;
            
            % VariableDescriptions
            newobj.hasDescrs = obj.hasDescrs;
            dcs = cell(1,maxIndex);
            for i = 1:maxIndex
                if i <= oldLen
                    dcs{i} = obj.descrs{i};
                else
                    dcs{i} = char(zeros(1,0));
                end
            end
            if ~isempty(dcs)
                coder.varsize('dcs{:}', [], true(1,2));
            end
            newobj.descrs = dcs;
            
            % VariableContinuity
            newobj.hasContinuity = obj.hasContinuity;
            if maxIndex > 0
                newobj.continuity = repmat(matlab.internal.coder.tabular.Continuity.unset, ...
                    1, maxIndex);
                if oldLen > 0
                    % Only try to assign old values if the old length was
                    % greater than zero to avoid type mismatch error because of
                    % [].
                newobj.continuity(1:oldLen) = obj.continuity;
                end
            else
                newobj.continuity = [];
            end
            
            % Custom properties
            % Currently not supported in codegen
            newobj.hasCustomProps = false;
            newobj.customProps = struct;
        end
        
        %-----------------------------------------------------------------------
        function newobj = createLike(obj,dimLength,dimLabels)
            coder.internal.prefer_const(dimLength);
            % create a new object
            newobj = matlab.internal.coder.tabular.private.varNamesDim;
            if nargin < 3
                newobj = newobj.createLike@matlab.internal.coder.tabular.private.tabularDimension(dimLength);
            else
                newobj = newobj.createLike@matlab.internal.coder.tabular.private.tabularDimension(dimLength,dimLabels);
            end
            newobj.hasUnits = false;
            % make units and descrs properties a cellstr with variable sized elements
            uts = cell(1,dimLength);
            for i = 1:numel(uts)
                uts{i} = char(zeros(1,0));
            end
            if ~isempty(uts)
                coder.varsize('uts{:}', [], [true true]);
            end
            newobj.units = uts;
            %newobj.units = {};
            newobj.hasDescrs = false;
            dcs = cell(1,dimLength);
            for i = 1:numel(dcs)
                dcs{i} = char(zeros(1,0));
            end
            if ~isempty(dcs)
                coder.varsize('dcs{:}', [], [true true]);
            end
            newobj.descrs = dcs;
            %newobj.descrs = {};
            newobj.hasContinuity = false;
            %newobj.continuity =  [];
            if dimLength > 0
                newobj.continuity = repmat(matlab.internal.coder.tabular.Continuity.unset, ...
                    1, dimLength);
            else
                newobj.continuity = [];
            end
            newobj.hasCustomProps = false;
            newobj.customProps = struct;
        end
        
        %-----------------------------------------------------------------------
        function newobj = clone(obj)
            % clone the varNamesDim object
            newobj = createLike(obj,obj.length,obj.labels);
            if obj.hasDescrs
                newobj = newobj.setDescrs(obj.descrs);
            end
            if obj.hasUnits
                newobj = newobj.setUnits(obj.units);
            end
            if obj.hasContinuity && ~isempty(obj.continuity)
                newobj = newobj.setContinuity(obj.continuity);
            end
        end
        
        %-----------------------------------------------------------------------
        function len = get.length(obj)
            % avoids using the length property stored value. Using
            % numel(labels) is more likely to return a constant value.
            len = numel(obj.labels);
        end
        
        %-----------------------------------------------------------------------
        function tf = get.hasLabels(~)
            tf = true;
        end
        
        %-----------------------------------------------------------------------
        function [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
                = subs2inds(obj,subscripts,subsType,tData)
            %SUBS2INDS Convert table subscripts (labels, logical, numeric) to indices.
            
            coder.internal.prefer_const(subscripts);
            
            oldLength = obj.length;
            
            if nargin < 3, subsType = matlab.internal.coder.tabular.private.tabularDimension.subsType.reference; end
                       
            coder.internal.assert(coder.internal.isConst(subscripts), 'MATLAB:table:NonconstantVarIndex');
            
            % Translate a vartype subscript object into actual subscripts.
            % Do this here, because the tabularDimension superclass's
            % doesn't know that the vartype's getSubscripts needs to know
            % the variable types.
            %{
                if isobject(subscripts)
                    if isa(subscripts,'vartype')
                        subscripts = subscripts.getSubscripts(obj,tData);
                    end
                end
            %}
            
            % Let the superclass handle the (rest of the) real work. Avoid
            % creating the updated object if not needed.
            if nargout > 5
                [rawindices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] = ...
                    obj.subs2inds@matlab.internal.coder.tabular.private.tabularDimension(subscripts,subsType);
            else
                [rawindices,numIndices,maxIndex,isLiteralColon,isLabels] = ...
                    obj.subs2inds@matlab.internal.coder.tabular.private.tabularDimension(subscripts,subsType);
            end
            
            if isnumeric(subscripts)
                if maxIndex > oldLength
                    coder.internal.errorIf(any(diff(unique([oldLength rawindices(:)'])) > 1), ...
                        'MATLAB:table:DiscontiguousVars');
                end
                % Ensure that all indices greater than 0
                coder.internal.assert(isempty(rawindices) || coder.internal.scalarizedAll(@(x)x>0,rawindices), ...
                        'CatalogID','MATLAB:badsubscriptTextRange',...
                        'ReportedID','MATLAB:badsubscript');
                indices = rawindices;
                % Translate logical and ':' to indices, since table var indexing is not done by
                % the built-in indexing code
            elseif islogical(rawindices)
                indices = coder.const(feval('find',rawindices));
            elseif matlab.internal.datatypes.isColon(rawindices)
                indices = 1:numel(obj.labels);
            else
                indices = rawindices;
            end
            coder.const(indices);  % variable indices must be constant
        end
        
        %-----------------------------------------------------------------------
         function newobj = selectFrom(obj,toSelect)
            newobj = obj.selectFrom@matlab.internal.coder.tabular.private.tabularDimension(toSelect);
            if islogical(toSelect)
                fromIndices = find(toSelect);
            else
                fromIndices = toSelect;
            end
            newobj = moveProps(newobj,obj,fromIndices,1:newobj.length);
         end
         
         %-----------------------------------------------------------------------
         function objOut = deleteFrom(obj,toDelete)
             %DELETEFROM Return a subset of a tableDimProps with the specified indices removed.
             coder.extrinsic('setdiff');
             
             objTmp = obj.deleteFrom@matlab.internal.coder.tabular.private.tabularDimension(toDelete);
             objTmp.hasDescrs = obj.hasDescrs;
             objTmp.hasUnits = obj.hasUnits;
             objTmp.hasContinuity = obj.hasContinuity;
             objTmp.hasCustomProps = obj.hasCustomProps;

             keepIndices = 1:obj.length;
             keepIndices = coder.const(setdiff(keepIndices,toDelete));

             % Var-based or properties need to be shrunk.
             objOut = objTmp;
             if obj.hasDescrs && ~isempty(keepIndices)
                 objOut.descrs = matlab.internal.coder.datatypes.cellstr_parenReference(obj.descrs,keepIndices);
             end
             if obj.hasUnits && ~isempty(keepIndices)
                 objOut.units = matlab.internal.coder.datatypes.cellstr_parenReference(obj.units,keepIndices);
             end
             if obj.hasContinuity && ~isempty(keepIndices)
                 objOut.continuity = obj.continuity(keepIndices);
             end
         end
         
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            % Same order as varNamesDim.propertyNames
            % VariableNames need to be handled separately because if is
            % often required to be constant. Don't copy.
            %s.VariableNames = obj.labels;
            s.VariableUnits = obj.units;
            s.VariableDescriptions =  obj.descrs;
            s.VariableContinuity = obj.continuity;
            %s.VariableCustomProperties = obj.customProps;
        end
        
        %-----------------------------------------------------------------------
        function target = moveProps(target,source,fromLocs,toLocs)
            if ~isempty(toLocs)
                if target.hasUnits
                    if source.hasUnits
                        % Replace the specified target units with the source's
                        for i=1:numel(toLocs)
                            target.units{toLocs(i)} = source.units{fromLocs(i)};
                        end
                    else
                        % Replace the specified target units with defaults
                        for i=1:numel(toLocs)
                            target.units{toLocs(i)} = '';
                        end
                    end
                elseif source.hasUnits
                    % Create property in target, assign source values into it
                    for i=1:toLocs(1)-1
                        target.units{i} = '';
                    end
                    for i=1:numel(toLocs)
                        target.units{toLocs(i)} = source.units{fromLocs(i)};
                    end
                    target.hasUnits = true;
                end
                if target.hasDescrs
                    if source.hasDescrs
                        % Replace the specified target descrs with the source's
                        for i=1:numel(toLocs)
                            target.descrs{toLocs(i)} = source.descrs{fromLocs(i)};
                        end
                    else
                        % Replace the specified target descrs with defaults
                        for i=1:numel(toLocs)
                            target.descrs{toLocs(i)} = '';
                        end
                    end
                elseif source.hasDescrs
                    % Create property in target, assign source descrs into it
                    for i=1:toLocs(1)-1
                        target.descrs{i} = '';
                    end
                    for i=1:numel(toLocs)
                        target.descrs{toLocs(i)} = source.descrs{fromLocs(i)};
                    end
                    target.hasDescrs = true;
                end
                if target.hasContinuity
                    if source.hasContinuity
                        % Replace the specified target descrs with the source's
                        target.continuity(toLocs) = source.continuity(fromLocs);
                    else
                        % Replace the specified target descrs with defaults
                        target.continuity(toLocs) = matlab.internal.coder.tabular.Continuity.unset;
                    end
                elseif source.hasContinuity
                    % Create property in target, assign source descrs into it
                    target.continuity = repmat(matlab.internal.coder.tabular.Continuity.unset,1,numel(target.continuity));
                    target.continuity(toLocs) = source.continuity(fromLocs);
                    target.hasContinuity = true;
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function target = mergeProps(target,source)
            % Copy the source's per-var properties to the target if the target
            % doesn't have them
            if ~target.hasDescrs && source.hasDescrs
                target = target.setDescrs(source.descrs);
            end
            if ~target.hasUnits && source.hasUnits
                target = target.setUnits(source.units);
            end
            if ~target.hasContinuity && source.hasContinuity
                target = target.setContinuity(source.continuity,false);
            end
        end
        
        %-----------------------------------------------------------------------
        function target = fillEmptyProps(target,source,fromLocs,toLocs) % merge specified variable properties only
            % The indices in fromLocs and toLocs may contain 0 because row
            % times can be used as a key variable in
            % join/innerjoin/outerjoin, which will be converted to 0 by
            % subs2inds before being passed in. Remove any 0s and remove
            % the corresponding index from the other indices.
            idxToDelete = (fromLocs == 0) | (toLocs == 0);
            fromLocs = fromLocs(~idxToDelete);
            toLocs = toLocs(~idxToDelete);

            if isempty(fromLocs) || isempty(toLocs)
                % no-op for empty to/from locs
                return 
            end
            
            if target.hasUnits
                % only merge for empty target locs  
                if source.hasUnits
                    idx = false(size(toLocs));
                    for i = 1:numel(idx)
                        idx(i) = isempty(target.units{toLocs(i)});
                    end
                    % Replace the specified target units with the source's
                    fromLocsIdx = fromLocs(idx);
                    toLocsIdx = toLocs(idx);
                    fromUnits = source.units;
                    toUnits = target.units;
                    coder.varsize('fromUnits',[],false(1,ndims(fromUnits)));
                    coder.varsize('toUnits',[],false(1,ndims(toUnits)));
                    for i = 1:numel(fromLocsIdx)
                        toUnits{toLocsIdx(i)} = fromUnits{fromLocsIdx(i)};
                    end
                    target.units = toUnits;
                end
            elseif source.hasUnits
                % Create property in target, assign source values into it
                target.units = repmat({''},1,target.length);
                for i = 1:numel(toLocs)
                    target.units{toLocs(i)} = source.units{fromLocs(i)};
                end
                target.hasUnits = true;
            else
                % Neither has units, leave it alone
            end
            if target.hasDescrs
                if source.hasDescrs
                    idx = false(size(toLocs));
                    for i = 1:numel(idx)
                        idx(i) = isempty(target.descrs{toLocs(i)});
                    end
                    % Replace the specified target descrs with the source's
                    fromLocsIdx = fromLocs(idx);
                    toLocsIdx = toLocs(idx);
                    for i = 1:numel(fromLocsIdx)
                        target.descrs{toLocsIdx(i)} = source.descrs{fromLocsIdx(i)};
                    end
                end
            elseif source.hasDescrs
                % Create property in target, assign source descrs into it
                target.descrs = repmat({''},1,target.length);
                for i = 1:numel(toLocs)
                    target.descrs{toLocs(i)} = source.descrs{fromLocs(i)};
                end
                target.hasDescrs = true;
            else
                % Neither has descrs, leave it alone
            end
            if target.hasContinuity
                if source.hasContinuity
                    idx = arrayfun(@(x)(x == matlab.internal.coder.tabular.Continuity.unset),target.continuity(toLocs));    
                    % Replace the specified target descrs with the source's
                    target.continuity(toLocs(idx)) = source.continuity(fromLocs(idx));
                end
            elseif source.hasContinuity
                % Create property in target, assign source descrs into it
                target.continuity = repmat(matlab.internal.coder.tabular.Continuity.unset,1,target.length);
                target.continuity(toLocs) = source.continuity(fromLocs);
                target.hasContinuity = true;
            else
                % Neither has continuity, leave it alone
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = setDescrs(obj,newDescrs,noErrorCheck)
            if (nargin<3) || (nargin==3 && ~noErrorCheck)
                coder.internal.assert(matlab.internal.coder.datatypes.isText(newDescrs,true), ...
                    'MATLAB:table:InvalidVarDescr'); % require a cell array, allow empty character vectors in that cell array
                coder.internal.assert(coder.internal.isConst(size(newDescrs)) && ...
                    numel(newDescrs) == numel(obj.labels), 'MATLAB:table:IncorrectNumberOfVarDescrs');
            end
            
            % avoid calling strtrim as it results in variable sized array
            % even when descrs is not variable sized
            %obj.descrs = matlab.internal.coder.datatypes.cellstr_strtrim(reshape(newDescrs,1,[])); 
            obj.descrs = reshape(newDescrs,1,[]); % a row vector
            
            % set hasDescrs
            hasdescrs = false;
            for i = 1:numel(obj.descrs)
                if ~isempty(obj.descrs{i})
                    hasdescrs = true;
                    break;
                end
            end
            obj.hasDescrs = hasdescrs;     
        end
        
        function obj = setUnits(obj,newUnits,noErrorCheck)
            if (nargin<3) || (nargin==3 && ~noErrorCheck)
                coder.internal.assert(matlab.internal.coder.datatypes.isText(newUnits,true), ...
                    'MATLAB:table:InvalidUnits');
                coder.internal.assert(coder.internal.isConst(size(newUnits)) && ...
                    numel(newUnits) == numel(obj.labels), 'MATLAB:table:IncorrectNumberOfUnits');
            end
            
            % avoid calling strtrim as it results in variable sized array
            % even when units is not variable sized
            %obj.units = matlab.internal.coder.datatypes.cellstr_strtrim(reshape(newUnits,1,[]));
            obj.units = reshape(newUnits,1,[]); % a row vector

            % set hasUnits
            hasunits = false;
            for i = 1:numel(obj.units)
                if ~isempty(obj.units{i})
                    hasunits = true;
                    break;
                end
            end
            obj.hasUnits = hasunits;            
        end
        
        function obj = setContinuity(obj,newContinuity,noErrorCheck)
            if (nargin < 3) || ~noErrorCheck
                coder.internal.assert(matlab.internal.coder.datatypes.isText(newContinuity,true) || ...
                    isa(newContinuity,'matlab.internal.coder.tabular.Continuity') || ...
                    (isequal(newContinuity,[]) && isnumeric(newContinuity)), ...
                    'MATLAB:table:InvalidContinuityAssignment'); % [] is allowed for 'clearing' the entire property
                    
                coder.internal.assert(coder.internal.isConst(size(newContinuity)) && ...
                    numel(newContinuity) == numel(obj.labels), 'MATLAB:table:IncorrectNumberOfContinuity');
            end

            if ~isempty(newContinuity)
                newContinuity = newContinuity(:)'; %convert everything to row vector
                % Convert the character vectors to the enumeration class
                if matlab.internal.coder.datatypes.isText(newContinuity,true) % char vector is not allowed
                    newContinuityObj = matlab.internal.coder.tabular.Continuity(newContinuity);
                else
                    newContinuityObj = newContinuity;
                end
            else
                newContinuityObj = [];
            end
            
            obj.continuity = newContinuityObj;
            
            % set hasContinuity
            hascontinuity = false;
            for i = 1:numel(obj.continuity)
                if obj.continuity(i) ~= matlab.internal.coder.tabular.Continuity.unset
                    hascontinuity = true;
                    break;
                end
            end
            obj.hasContinuity = hascontinuity;    
        end
    end
    
    %===========================================================================
    methods (Access=protected)
        function obj = 	validateAndAssignLabels(obj,rawnewLabels,varIndices,fullAssignment,dimLength,fixDups,fixEmpties,fixIllegal)
            coder.internal.prefer_const(fullAssignment, dimLength, fixDups, fixEmpties, fixIllegal);
            assert(fullAssignment);   % no partial assignment until dotParenAssign available
            assert(~fixDups);         % fixDups currently not used in codegen
            assert(~fixEmpties);      % fixEmpties currently not used in codegen
            assert(~fixIllegal);      % fixIllegal currently not used in codegen
            
            coder.internal.assert(matlab.internal.coder.datatypes.isText(...
                rawnewLabels,true), 'MATLAB:table:InvalidVarNames');
            % Accept a cellstr, allow empty character vectors per caller.
            newLabels = reshape(rawnewLabels,1,[]);
            matlab.internal.coder.tabular.private.varNamesDim.makeValidName(newLabels,'error');
            
            % Check that the whole set of new names is unique
            obj.checkDuplicateLabelsSimple(newLabels);

            obj = obj.assignLabels(newLabels,fullAssignment,varIndices,dimLength);
        end
    
        function [subscripts,indices] = validateNativeSubscripts(obj,rawsubscripts,labels)
            % varNamesDim overloads validateNativeSubscripts only to call
            % coder.const on labels to ensure it is constant, and then
            % redirects to the superclass version to do the actual work
            [subscripts,indices] = ...
                obj.validateNativeSubscripts@matlab.internal.coder.tabular.private.tabularDimension(...
                coder.const(rawsubscripts), coder.const(labels));
        end
    end
    
    methods (Access={?matlab.internal.coder.tabular.private.tabularDimension})
        function newlabels = makeUniqueForRepeatedIndices(~,~,labels)
            coder.extrinsic('matlab.lang.makeUniqueStrings', 'namelengthmax')
            newlabels = coder.const(matlab.lang.makeUniqueStrings(...
                coder.const(labels),{},coder.const(namelengthmax)));
        end
    end
    
    %===========================================================================    
    methods (Static)
        function labels = dfltLabels(varIndices,oneName)
            %DFLTLABELS Default variable names for a table.
            coder.extrinsic('message', 'getString', 'matlab.internal.i18n.locale');
            prefix = getString(message('MATLAB:table:uistrings:DfltVarNamePrefix'),...
                        matlab.internal.i18n.locale('en_US'));
            if nargin < 2 || ~oneName % return cellstr
                labels = matlab.internal.coder.datatypes.numberedNames(coder.const(prefix),varIndices(:)',false); % row vector
            else % return one character vector
                labels = matlab.internal.coder.datatypes.numberedNames(coder.const(prefix),varIndices,true);
            end
        end

        function conflicts = checkReservedNames(labels)
            coder.extrinsic('matlab.internal.coder.tabular.private.tabularDimension.checkReservedNames');
            errorOnConflicts = (nargout==0);
            reservedNames = matlab.internal.coder.tabular.private.varNamesDim.reservedNames;
            conflicts = coder.const(checkReservedNames@matlab.internal.coder.tabular.private.tabularDimension(labels,reservedNames,false,'MATLAB:table:ReservedVarNameConflict'));
            if errorOnConflicts && coder.const(any(conflicts))
                % conflicts is always constant. This block should only
                % be evaluated if there is at least one conflict.
                % Since we are using brace indexing and we only have one output arg,
                % i.e. firstconflict, it will contain the first label that
                % conflicted with the reservedNames.
                firstconflict = labels{conflicts};
                coder.internal.assert(false, 'MATLAB:table:ReservedVarNameConflict', ...
                    firstconflict);
            end
        end
        
        function [validNames, modified] = makeValidName(namesIn, modException)
            %MAKEVALIDNAME Construct valid MATLAB identifiers from input names
            %   MAKEVALIDNAME is a private function for table that wraps
            %   around MATLAB.LANG.MAKEVALIDNAME. It adds exception control
            %   for when input names contains invalid identifier.
            %
            %   MODEXCEPTION controls warning or error response when NAMES
            %   contains invalid MATLAB identifiers. Valid values for
            %   MODEXCEPTION are 'warn' and 'error', respectively meaning a
            %   warning or an error will be thrown when NAMES contain
            %   invalid identifiers.            
            coder.internal.prefer_const(modException);
            coder.extrinsic('matches', 'matlab.lang.makeValidName', ...
                'matlab.internal.coder.tabular.private.varNamesDim.makeUniqueStringsExtrinsic');
            
            % Only a subset of MODEXCEPTION is currently supported in codegen
            assert(strcmp(modException,'error') || strcmp(modException,'silent') || ...
                strcmp(modException,'resolveConflict') || strcmp(modException, 'warnRows2Vars') || ...
                strcmp(modException,'warnLength'));  
            
            if modException == "error"
            % If an invalid name should error, no point in calling makeValidName. Call
            % isvarname instead, faster when _all_ names are valid.
            validNames = namesIn; % return the originals, or possibly error
            if ischar(namesIn), names = { namesIn }; else, names = namesIn; end % unusual case, not optimized
            matlab.internal.coder.tabular.validateVariableNameLength(names,'MATLAB:table:VariableNameLengthMax');
            matlab.internal.coder.tabular.private.varNamesDim.checkReservedNames(names);
            modified = false(size(names));
            elseif modException == "warnLength"
                % For variable names that no longer need to be valid MATLAB identifiers,
                % check length and conflicts with reserved names. If a tabular method is
                % making a name, warn rather than erroring if the name is too long or
                % conflicts with a reserved name.
                if ischar(namesIn), names = { namesIn }; else, names = namesIn; end % unusual case, not optimized
                tooLong = matlab.internal.coder.tabular.validateVariableNameLength(names,'MATLAB:table:VariableNameLengthMax');
                conflicts = matlab.internal.coder.tabular.private.varNamesDim.checkReservedNames(names);
                modified = tooLong | conflicts;
                if any(modified)
                    % Unlike in the 'warn' case below that calls makeValidName, here
                    % makeUniqueStrings fixes both names that are too long and names that
                    % conflict with reservedNames.
                    validNames = coder.const(...
                        matlab.internal.coder.tabular.private.varNamesDim.makeUniqueStringsExtrinsic(...
                        coder.const(names), modified));
                    if any(conflicts)
                        reservedNameConflicts = names{conflicts};
                        coder.internal.compileWarning('MATLAB:table:ModifiedVarnamesReservedConflict',reservedNameConflicts);
                    end
                    if any(tooLong)
                        coder.internal.compileWarning('MATLAB:table:ModifiedVarnamesLengthMax');
                    end
                else
                    validNames = names;
                end
            elseif modException == "resolveConflict"
                % For variable names that no longer need to be valid MATLAB identifiers,
                % check length and conflicts with reserved names.                   
                if ischar(namesIn), names = { namesIn }; else, names = namesIn; end % unusual case, not optimized
                
                % handle the case when the names contain empty char ''
                emptyNames = coder.const(matches(names,''));
                nonemptyNames = cell(size(names));
                coder.unroll(~coder.target('MATLAB') && ~coder.internal.isHomogeneousCell(names));
                for i = 1:numel(nonemptyNames)
                    if emptyNames(i)
                        nonemptyNames{i} = 'x';
                    else
                        nonemptyNames{i} = names{i};
                    end
                end
                
                tooLong = matlab.internal.coder.tabular.validateVariableNameLength(...
                    nonemptyNames,'MATLAB:table:VariableNameLengthMax');
                conflicts = matlab.internal.coder.tabular.private.varNamesDim.checkReservedNames(nonemptyNames);
                modified = coder.const(tooLong | conflicts);
                
                if any(modified)
                    % Unlike in the 'warn' case below that calls makeValidName, here
                    % makeUniqueStrings fixes both names that are too long and names that
                    % conflict with reservedNames.
                    validNames = coder.const(...
                        matlab.internal.coder.tabular.private.varNamesDim.makeUniqueStringsExtrinsic(...
                        coder.const(nonemptyNames), modified));
                else
                    validNames = nonemptyNames;
                end
            else % 'warnRows2Vars', 'silent'
                [processedNames, modified] = coder.const(@matlab.lang.makeValidName,namesIn);
                conflicted = coder.const(...
                    matlab.internal.coder.tabular.private.varNamesDim.checkReservedNames(processedNames));
                if any(conflicted)
                    validNames = coder.const(...
                        matlab.internal.coder.tabular.private.varNamesDim.makeUniqueStringsExtrinsic(...
                        coder.const(processedNames), conflicted));
                else
                    validNames = processedNames;
                end

                modified = modified | conflicted;
                if any(modified)
                    switch modException % error or warn per level specified
                        case 'warnRows2Vars'
                            % warn at compile time since the names are
                            % constant
                            coder.internal.compileWarning('MATLAB:table:ModifiedVarnamesRows2Vars');
                        case 'silent'
                            % Used by summary and other functions where we would like to convert to
                            % valid MATLAB identifiers without displaying any warning
                        otherwise
                            assert(false);
                    end
                end
            end
        end
        
        function result = matlabCodegenNontunableProperties(~)
            result = {'labels'};
        end
    end

    %===========================================================================
    methods (Static, Hidden)      
        function names = makeUniqueStringsExtrinsic(names, modifyIdx)
            % Helper method for makeValidName, in order to do cell array
            % parentheses indexing and assignment, and
            % matlab.lang.makeUniqueStrings all in MATLAB.
            % This entire method is meant to be called as an extrinsic
            % function.
            names(modifyIdx) = matlab.lang.makeUniqueStrings(names(modifyIdx),...
                names,namelengthmax);
        end
    end
    
    %===========================================================================
    methods (Static, Access=protected)
        function y = orientAs(x)
            coder.internal.prefer_const(x);
            % orient as row
            if ~isrow(x)
                y = reshape(x, 1, []);
            else
                y = x;
            end
        end
    end
end
