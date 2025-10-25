classdef (Sealed) rowNamesDim < matlab.internal.coder.tabular.private.tabularDimension %#codegen
%ROWNAMESDIM Internal class to represent a table's rows dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

%   Copyright 2018-2022 The MathWorks, Inc.
    
    properties(Constant, GetAccess=public)
        propertyNames = {'RowNames'};
        requireLabels = false;
        requireUniqueLabels = true;
        constantLabels = true;
        reservedNames = {':'};
        DuplicateLabelExceptionID = 'MATLAB:table:DuplicateRowNames'; 
        NumDimNamesExeptionID = 'MATLAB:table:IncorrectNumberOfRowNames';
        UnrecognizedLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingRowName';
        UnrecognizedAssignmentLabelExceptionID = 'MATLAB:table:UnrecognizedAssignmentRowName';
        NonconstantLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingNonconstantRowName';
        NonconstantAssignmentLabelExceptionID = 'MATLAB:table:UnrecognizedAssignmentNonconstantRowName';
        IndexOutOfRangeExceptionID = 'MATLAB:table:RowIndexOutOfRange';
        AssignmentOutOfRangeExceptionID = 'MATLAB:table:AssignmentRowIndexOutOfRange';
        InvalidSubscriptsExceptionID = 'MATLAB:table:InvalidRowSubscript';
        InvalidLabelExceptionID = 'MATLAB:table:InvalidRowName';
        IncorrectNumberOfLabelsExceptionID = 'MATLAB:table:IncorrectNumberOfRowNames';
    end
    
    properties(Dependent)
        hasLabels
    end
    
    properties(GetAccess=public, SetAccess=protected)
        labels
        length
    end
    
    %===========================================================================
    methods
        function obj = rowNamesDim(length)
         
            % Do nothing if nargin==0. This syntax is reserved
            % for the situation where the caller will set the rest of the
            % properties manually afterwards.
            if nargin > 0
                obj = obj.init(length);
            end
        end
        
        function newobj = createLike(obj,dimLength,dimLabels)
            coder.internal.prefer_const(dimLength);
            % create a new object
            newobj = matlab.internal.coder.tabular.private.rowNamesDim;
            if nargin < 3
                newobj = newobj.createLike@matlab.internal.coder.tabular.private.tabularDimension(dimLength);
            else
                newobj = newobj.createLike@matlab.internal.coder.tabular.private.tabularDimension(dimLength,dimLabels);
            end
        end
        
        
        %-----------------------------------------------------------------------
        function newObj = lengthenTo(obj,maxIndex,newLabels)
            hadLabels = obj.hasLabels;
            oldLength = obj.length;
            obj_labels = obj.labels;
            if ~coder.internal.isConst(maxIndex)
                coder.varsize('obj_labels',[],[0 0]);
            end
            
            if nargin < 3
                % If the table has row names, create default names for the new rows, making sure
                % they don't conflict with existing names. If the table has no row names, leave
                % them that way.
                if hadLabels
                    newObjLabels = coder.nullcopy(cell(maxIndex,1));
                    coder.unroll(coder.internal.isConst(maxIndex));
                    for i = 1:maxIndex
                        if i <= oldLength
                            newObjLabels{i} = obj_labels{i};
                        else
                            newObjLabels{i} = obj.dfltLabels(i,true);
                        end
                    end
                    % Cannot use makeUniqueStrings extrinsically since row
                    % labels are not always constant.
                    % newLabels = matlab.lang.makeUniqueStrings(newLabels,obj.labels);
                    newObj = obj.createLike(maxIndex,newObjLabels);
                else
                    newObj = obj.createLike(maxIndex,{});
                end
            else
                newObjLabels = coder.nullcopy(cell(maxIndex,1));
                for i = 1:maxIndex
                    if i <= oldLength
                        % If the old obj had labels, then use them, otherwise
                        % fill with default labels.
                        if hadLabels
                            newObjLabels{i} = obj_labels{i};
                        else
                            newObjLabels{i} = obj.dfltLabels(i,true);
                        end
                    else
                        newObjLabels{i} = newLabels{i-oldLength};
                    end
                end
                newObj = obj.createLike(maxIndex,newObjLabels);
            end
        end
        
        
        %-----------------------------------------------------------------------
        function len = get.length(obj)
            % avoids using the length property stored value. Using
            % numel(labels) is more likely to return a constant value.
            if ~isempty(obj.labels)
                len = numel(obj.labels);
            else
                len = obj.length;
            end
        end
        
        %-----------------------------------------------------------------------
        function tf = get.hasLabels(obj)
            labs = obj.labels;
            tf = ~(coder.internal.isConst(size(labs)) && sum(size(labs))==0);
        end
        
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            % Same order as rowNamesDim.propertyNames
            s.RowNames = obj.labels;
        end
    end
    
    %===========================================================================
    methods (Access=protected)
        function obj = validateAndAssignLabels(obj,rawnewLabels,rowIndices,fullAssignment,dimLength,fixDups,fixEmpties,~)
            coder.internal.prefer_const(fullAssignment, dimLength, fixDups, fixEmpties);
            assert(fullAssignment);   % no partial assignment until dotParenAssign available
            assert(~fixDups);         % fixDups currently not used in codegen
            assert(~fixEmpties);      % fixEmpties currently not used in codegen
            
            coder.internal.assert(matlab.internal.coder.datatypes.isCharStrings(rawnewLabels,true,fixEmpties), ...
                'MATLAB:table:InvalidRowNames');
            if fullAssignment && isequal(rawnewLabels,{}) % Accept {} to remove row names
                obj.labels = rawnewLabels;  % force a 0x0, for cosmetics
                return
            end
            % Accept a cellstr, allow empty character vectors per caller.
            rawnewLabels = reshape(rawnewLabels,[],1);
                newLabels = matlab.internal.coder.datatypes.cellstr_strtrim(rawnewLabels);
            
            obj.makeValidName(newLabels,'error');
            
            % Check that the whole set of new names is unique
            obj.checkDuplicateLabelsSimple(newLabels);
            
            obj = obj.assignLabels(newLabels,fullAssignment,rowIndices,dimLength);
        end
    end
    
    methods (Access={?matlab.internal.coder.tabular.private.tabularDimension})
        function newlabels = makeUniqueForRepeatedIndices(obj,indices,labels)
            % Sort the row indices, then find the first occurrence of each unique index
            % and the length of each group of indices.
            coder.internal.prefer_const(indices,labels);
            if nargin < 3
                labels = obj.labels;
            end
            if coder.internal.isConst(indices) && coder.internal.isConst(labels)
                newlabels = obj.makeUniqueForRepeatedIndicesConst(indices,labels);
                return
            end
            
            [sindices,ord] = sort(indices);
            [~,startLoc] = unique(sindices);
            groupLens = diff([startLoc; numel(indices)+1]);
            
            % Number the rows from 0:length(group), within each group.
            numbers = cumsum(ones(size(indices))) - repelem(startLoc,groupLens,1); % force repelem to create a column
            
            % Create suffixes to make repeated names unique, and put the suffixes back into
            % the original order.
            suffixes = coder.nullcopy(cell(size(numbers)));
            for i = 1:numel(suffixes)
                if ismember(i,startLoc)
                    suffixes{i} = ''; % no suffix for first occurrence
                else
                    suffixes{i} = sprintf('_%-.0g',numbers(i)); % suffixes = compose('_%-d',numbers);
                end
            end
            
            % Append to the names. No concern for length, row names need not be valid identifiers.
            newlabels = coder.nullcopy(cell(size(labels)));
            for i = 1:numel(labels)
                newlabels{ord(i)} = [labels{ord(i)} suffixes{i}]; % newlabels(ord) = append(labels(ord),suffixes);
            end
            checkDuplicateLabelsSimple(obj, newlabels)
        end
        
        function newlabels = makeUniqueForRepeatedIndicesConst(~,indices,labels)
            % Sort the row indices, then find the first occurrence of each unique index
            % and the length of each group of indices.
            coder.internal.prefer_const(indices,labels);
            coder.extrinsic('matlab.lang.makeUniqueStrings')
            newlabels = coder.const(matlab.lang.makeUniqueStrings(labels,{}));
        end
    end
    
        
    methods(Static)
        function result = matlabCodegenSoftNontunableProperties(~)
            result = {'length', 'labels'};
        end
        
        function conflicts = checkReservedNames(labels)
            errorOnConflicts = (nargout==0);
            reservedNames = matlab.internal.coder.tabular.private.rowNamesDim.reservedNames;
            conflicts = checkReservedNames@matlab.internal.coder.tabular.private.tabularDimension(...
                labels,reservedNames,errorOnConflicts,'MATLAB:table:ReservedDimNameConflict');
        end
        
        function [validNames, modified] = makeValidName(names, modException)
            %MAKEVALIDNAME Construct valid table row names. The only row
            %   not allowed is ':' to avoid ambiguous subscripting.
            %
            %   MODEXCEPTION controls warning or error response when NAMES
            %   contains invalid names. Valid values for MODEXCEPTION are
            %   'silent' and 'error'.           
            coder.internal.prefer_const(modException);
            assert(strcmp(modException,'error'));  % error is the only supported MODEXCEPTION in codegen
            
            % If an invalid name should error, no point in calling makeValidName. Call
            % isvarname instead, faster when _all_ names are valid.
            validNames = names; % return the originals, or possibly error
            if ischar(names), names = { names }; end % unusual case, not optimized
            matlab.internal.coder.tabular.private.rowNamesDim.checkReservedNames(names);
            modified = false(size(names));
        end
    end
    
    %===========================================================================
    methods(Static, Access=protected)
        function y = orientAs(x)
            coder.internal.prefer_const(x);
            % orient as column
            if ~iscolumn(x)
                y = reshape(x, [], 1);
            else
                y = x;
            end
        end
    end
    
    %===========================================================================
    methods(Static, Access={?matlab.internal.coder.tabular,?matlab.unittest.TestCase})
        function labels = dfltLabels(rowIndices,oneName)
            %DFLTLABELS Default row names for a table.
            
            coder.extrinsic('getString', 'message', 'matlab.internal.i18n.locale');
            prefix = getString(message('MATLAB:table:uistrings:DfltRowNamePrefix'),...
                        matlab.internal.i18n.locale('en_US'));
            if nargin < 2 || ~oneName % return cellstr
                labels = matlab.internal.coder.datatypes.numberedNames(...
                    coder.const(prefix),rowIndices(:),false); % column vector
            else % return one character vector
                labels = matlab.internal.coder.datatypes.numberedNames(coder.const(prefix),rowIndices,true);
            end
        end
    end
end
