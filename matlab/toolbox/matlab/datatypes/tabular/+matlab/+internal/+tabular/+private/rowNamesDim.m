classdef (Sealed) rowNamesDim < matlab.internal.tabular.private.tabularDimension
%ROWNAMESDIM Internal class to represent a table's rows dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Constant, GetAccess=public)
        labelType = "text";
        requireLabels = false;
        requireUniqueLabels = true;
        DuplicateLabelExceptionID = 'MATLAB:table:DuplicateRowNames'; 
        reservedNames = {':'};
    end
    
    properties(GetAccess=public, SetAccess=protected)
        labels
    end
    
    %===========================================================================
    methods
        function obj = rowNamesDim(length,labels)
            import matlab.internal.datatypes.isCharStrings
            
            labelsArg = { };
            if nargin == 0
                length = 0;
            elseif nargin == 1
                % OK
            else
                % This is the relevant parts of validateAndAssignLabels
                if ~isCharStrings(labels,true,false) % require cellstr, no empties
                    error(message('MATLAB:table:InvalidRowNames'));
                elseif isequal(labels,{})
                    % OK
                else
                    labels = strtrim(labels(:)); % a col vector, conveniently forces any empty to 0x1
                    obj.checkDuplicateLabels(labels);
                    labelsArg = { labels };
                end
            end            
            obj = obj.init(length,labelsArg{:});
            
            % Row names are optional, and tabularDimension's default is [],
            % replace that with an empty cellstr.
            if ~obj.hasLabels
                obj.labels = {};
            end
        end
        
        %-----------------------------------------------------------------------
        function labels = defaultLabels(obj,indices)
            if nargin < 2
                indices = 1:obj.length;
            end
            labels = obj.dfltLabels(indices);
        end

        %-----------------------------------------------------------------------
        function tf = hasExplicitLabels(obj)
            % HASEXPLICITLABELS Determine if the rowDim obj has explicitly stored
            % labels.
            % Since rowLabels are optional in this case, check if it has labels.
            % If it does then they are always store explicitly.
            tf = obj.hasLabels;
        end
                
        %-----------------------------------------------------------------------
        function obj = lengthenTo(obj,maxIndex,newLabels)
            if nargin < 3
                % If the table has row names, create default names for the new rows, making sure
                % they don't conflict with existing names. If the table has no row names, leave
                % them that way.
                if obj.hasLabels
                    newIndices = (obj.length+1):maxIndex; % don't create this unless needed
                    newLabels = obj.dfltLabels(newIndices);
                    newLabels = matlab.lang.makeUniqueStrings(newLabels,obj.labels);
                    obj.labels(newIndices,1) = newLabels(:);
                end
            else
                % If the original table doesn't have row names, create default names.
                if ~obj.hasLabels
                    obj.labels = obj.dfltLabels(1:obj.length);
                    obj.hasLabels = true;
                end
                
                % Assume that newLabels has already been checked by validateNativeSubscripts,
                % and that the new names don't conflict with existing names.
                newIndices = (obj.length+1):maxIndex; % don't create this unless needed
                obj.labels(newIndices,1) = newLabels(:)';
            end
            obj.length = maxIndex;
        end
        
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            % Same order as rowNamesDim.propertyNames
            s.RowNames = obj.labels;
        end
    
        function propNames = propertyNames(obj)
            propNames = {'RowNames'};
        end
    end
    
    %===========================================================================
    methods (Access=protected)
        function obj = validateAndAssignLabels(obj,newLabels,rowIndices,fullAssignment,fixDups,fixEmpties,fixIllegal)
            import matlab.internal.datatypes.isCharString
            import matlab.internal.datatypes.isCharStrings
            import matlab.internal.tabular.private.rowNamesDim.checkReservedNames;
            try
                if ~fullAssignment && isCharString(newLabels,fixEmpties)
                    % Accept one character vector for (partial) assignment to one name, allow empty character vectors per caller.
                    newLabels = { strtrim(newLabels) };
                elseif isCharStrings(newLabels,true,fixEmpties)
                    if fullAssignment && isequal(newLabels,{}) % Accept {} to remove row names
                        obj.labels = {}; % force a 0x0, for cosmetics
                        obj.hasLabels = false;
                        return
                    end
                    % Accept a cellstr, allow empty character vectors per caller.
                    newLabels = strtrim(newLabels(:)); % a col vector, conveniently forces any empty to 0x1
                else
                    error(message('MATLAB:table:InvalidRowNames'));
                end
                
                if fixEmpties
                    % Fill in empty names if allowed, and make them unique with respect
                    % to the other new names. If not allowed, an error was already thrown.
                    [newLabels,wasEmpty] = fillEmptyNames(newLabels,rowIndices);
                    newLabels = matlab.lang.makeUniqueStrings(newLabels,wasEmpty,namelengthmax);
                end
                
                if ~fixIllegal
                    exceptionMode = 'error';
                else
                    exceptionMode = 'silent';
                end
                newLabels = obj.makeValidName(newLabels,exceptionMode);
                
                % The number of new labels has to match what's being assigned to.
                if fullAssignment 
                    if numel(newLabels) ~= obj.length
                        obj.throwIncorrectNumberOfLabels();
                    end
                else
                    if numel(newLabels) ~= numel(rowIndices)
                        obj.throwIncorrectNumberOfLabelsPartial();
                    end
                end

                
                if fixDups
                    % Make the new names unique with respect to each other and to existing names (if any).
                    newAndOldLabels = obj.labels;
                    if isempty(newAndOldLabels)
                        newLabels = matlab.lang.makeUniqueStrings(newLabels,1:length(newLabels),inf);
                    else
                        newAndOldLabels(rowIndices) = newLabels;
                        newAndOldLabels = matlab.lang.makeUniqueStrings(newAndOldLabels,rowIndices,inf);
                        newLabels = newAndOldLabels(rowIndices);
                    end
                elseif fullAssignment
                    % Check that the whole set of new names is unique
                    obj.checkDuplicateLabels(newLabels);
                else
                    % Check that the new names do not duplicate each other or existing names.
                    newAndOldLabels = obj.labels; newAndOldLabels(rowIndices) = newLabels;
                    obj.checkDuplicateLabels(newLabels,newAndOldLabels,rowIndices);
                end
                
                obj = obj.assignLabels(newLabels,fullAssignment,rowIndices);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = makeUniqueForRepeatedIndices(obj,~)
                obj.labels = matlab.lang.makeUniqueStrings(obj.labels,{});
        end
        
        %-----------------------------------------------------------------------
        function throwRequiresLabels(~)
            assert(false);
        end
        function throwIncorrectNumberOfLabels(~) 
            throwAsCaller(MException(message('MATLAB:table:IncorrectNumberOfRowNames')));
        end
        function throwIncorrectNumberOfLabelsPartial(~)
            throwAsCaller(MException(message('MATLAB:table:IncorrectNumberOfRowNamesPartial')));
        end
        function throwIndexOutOfRange(~)
            throwAsCaller(MException(message('MATLAB:table:RowIndexOutOfRange')));
        end
        function throwUnrecognizedLabel(~,label)
            throwAsCaller(MException(message('MATLAB:table:UnrecognizedRowName', label{1})));
        end
        function throwInvalidLabel(~)
            throwAsCaller(MException(message('MATLAB:table:InvalidRowName')));
        end
        function throwInvalidSubscripts(~)
            throwAsCaller(MException(message('MATLAB:table:InvalidRowSubscript')));
        end
    end
    
    %===========================================================================
    methods (Static)
        function conflicts = checkReservedNames(labels)
            reservedNames = matlab.internal.tabular.private.rowNamesDim.reservedNames;
            conflicts = matlab.internal.tabular.private.tabularDimension.checkReservedNamesImpl(labels,reservedNames);
            if nargout==0 && any(conflicts)
                dup = labels{find(conflicts,1)};
                throwAsCaller( MException(message('MATLAB:table:ReservedRowNameConflict',dup)) );
            end
        end
        
        function [validNames, modified] = makeValidName(names, modException)
            %MAKEVALIDNAME Construct valid table row names. The only row
            %   not allowed is ':' to avoid ambiguous subscripting.
            %
            %   MODEXCEPTION controls warning or error response when NAMES
            %   contains invalid names. Valid values for MODEXCEPTION are
            %   'silent' and 'error'.
            import matlab.internal.datatypes.warningWithoutTrace;
            import matlab.internal.tabular.private.rowNamesDim.checkReservedNames;

            if modException == "error"
                validNames = names; % return the originals, or possibly error
                if ischar(names), names = { names }; end % unusual case, not optimized
                checkReservedNames(names);
                modified = false(size(names));
            else % make names valid
                validNames = names;
                conflicted = checkReservedNames(names);
                if any(conflicted)
                    validNames(conflicted) = matlab.lang.makeUniqueStrings(validNames(conflicted), validNames,namelengthmax);
                end
                modified = conflicted;
                if any(modified)
                    switch modException % error or warn per level specified
                        case 'silent'
                            % Only used by readtable
                        case 'warn' % Only used by loadobj
                            warningWithoutTrace(message('MATLAB:table:RowNameReservedBackCompat'));
                        otherwise
                            assert(false);
                    end
                end
            end
        end
    end
    
    %===========================================================================
    methods(Static, Access=protected)
        function x = orientAs(x)
            % orient as column
            if ~iscolumn(x)
                x = x(:);
            end
        end
    end
    
    %===========================================================================
    methods(Static, Access={?tabular,?matlab.unittest.TestCase})
        function labels = dfltLabels(rowIndices,oneName)
            %DFLTLABELS Default row names for a table.
           
            prefix = getString(message('MATLAB:table:uistrings:DfltRowNamePrefix'));
            if nargin < 2 || ~oneName % return cellstr
                labels = matlab.internal.datatypes.numberedNames(prefix,rowIndices(:),false); % column vector
            else % return one character vector
                labels = matlab.internal.datatypes.numberedNames(prefix,rowIndices,true);
            end
        end
    end
end

%-----------------------------------------------------------------------
function [names,empties] = fillEmptyNames(names,indices)
empties = cellfun('isempty',names);
if any(empties)
    names(empties) = matlab.internal.tabular.private.rowNamesDim.dfltLabels(indices(empties));
end
end
