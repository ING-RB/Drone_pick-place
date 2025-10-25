classdef (Sealed) metaDim < matlab.internal.tabular.private.tabularDimension
%METASDIM Internal class to represent a tabular's list of dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Constant, GetAccess=public)
        labelType = "text";
        requireLabels = true;
        requireUniqueLabels = true;
        DuplicateLabelExceptionID = 'MATLAB:table:DuplicateDimNames';
        reservedNames = {'VariableNames' 'RowNames' 'Properties' ':'};
    end
        
    properties(GetAccess=public, SetAccess=protected)
        labels
    end
    
    properties(Constant, GetAccess={?tabular,?matlab.unittest.TestCase})
        % These are the names used by default by metaDim. However, tabular
        % classes may initialize their metaDim with whatever they want.
        dfltLabels = { getString(message('MATLAB:table:uistrings:DfltRowDimName')) ...
                       getString(message('MATLAB:table:uistrings:DfltVarDimName')) };        
    end
    
    %===========================================================================
    methods
        function obj = metaDim(length,labels)
            % Technically, this is not a table dimension, it's more like a table
            % meta-dimension. But it's close enough to var and row names to
            % reuse the infrastructure. Always initialize with two default
            % names, and oriented as a row.
            import matlab.internal.datatypes.isCharStrings
            import matlab.internal.tabular.private.metaDim
            
            if nargin == 0
                length = 2;
                labels = metaDim.dfltLabels;
            elseif nargin == 1
                labels = metaDim.dfltLabels;
            else
                % This is the relevant parts of validateAndAssignLabels
                if ~(isCharStrings(labels,true) && all(strlength(labels) > 0, 'all')) % require cellstr, whitespace, but not empty allowed
                    error(message('MATLAB:table:InvalidDimNames'));
                end
                labels = strtrim(labels(:)'); % a row vector, conveniently forces any empty to 0x1
                metaDim.makeValidName(labels,'error');
                obj.checkDuplicateLabels(labels);
            end
            
            obj = obj.init(length,labels);
        end
        
        %-----------------------------------------------------------------------
        function labels = defaultLabels(obj,indices)
            if nargin < 2
                indices = 1:obj.length;
            end
            labels = obj.dfltLabels(indices);
        end
        
        %-----------------------------------------------------------------------
        function obj = lengthenTo(obj,~,~)
            assert(false);
        end
        
        %-----------------------------------------------------------------------
        function obj = shortenTo(obj,~)
            assert(false);
        end
        
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            % Same order as metaDim.propertyNames
            s.DimensionNames = obj.labels;
        end
        
        %-----------------------------------------------------------------------
        function obj = checkAgainstVarLabels(obj,varLabels,errorMode)
            import matlab.internal.datatypes.warningWithoutTrace
            % Pre-2016b, DimensionNames were not required to be distinct from VariableNames,
            % but now they are. The caller may ask to error if they conflict, or to modify
            % DimensionNames with a warning or silently.
            [modifiedLabels,wasConflicted] = matlab.lang.makeUniqueStrings(obj.labels,varLabels,namelengthmax);
            matlab.internal.tabular.validateVariableNameLength(obj.labels,'MATLAB:table:DimNameLengthMax');
            if any(wasConflicted)
                if nargin > 2
                    switch errorMode
                    case 'silent'
                        % OK
                    case 'warn'
                        warningWithoutTrace(message('MATLAB:table:DuplicateDimNamesVarNamesWarn',obj.labels{find(wasConflicted,1)}));
                    case 'error'
                        throwAsCaller(MException(message('MATLAB:table:DuplicateDimNamesVarNames',obj.labels{find(wasConflicted,1)})));
                    case 'warnBackCompat' % Only used for table loadobj. From 2019b on, table dimname-varname clashes typically error.
                        warningWithoutTrace(message('MATLAB:table:DuplicateDimnamesVarnamesBackCompat',obj.labels{find(wasConflicted,1)}));
                    otherwise
                        assert(false);
                    end
                else
                    throwAsCaller(MException(message('MATLAB:table:DuplicateDimNamesVarNames',obj.labels{find(wasConflicted,1)})));
                end
                obj.labels = modifiedLabels;
            end
        end
    
        function propNames = propertyNames(obj)
            propNames = {'DimensionNames'};
        end

    end
    
    %===========================================================================
    methods (Access=protected)
        function obj = validateAndAssignLabels(obj,newLabels,dimIndices,fullAssignment,fixDups,fixEmpties,fixIllegal)
            import matlab.internal.datatypes.isCharString
            import matlab.internal.datatypes.isCharStrings
            
            if ~fullAssignment && isCharString(newLabels) && (fixEmpties || (newLabels ~= ""))
                % Accept one character vector for (partial) assignment to one name, allow empty character vectors per caller.
                newLabels = { newLabels };
            elseif isCharStrings(newLabels,true) && (fixEmpties || ~any((newLabels == ""),'all'))
                % Accept a cellstr, allow empty character vectors per caller.
                newLabels = newLabels(:)'; % a row vector, conveniently forces any empty to 0x1
            else
                error(message('MATLAB:table:InvalidDimNames'));
            end

            if fixEmpties
                % Fill in empty names if allowed, and make them unique with respect
                % to the other new names. If not allowed, an error was already thrown.
                [newLabels,wasEmpty] = fillEmptyNames(newLabels,dimIndices);
                newLabels = matlab.lang.makeUniqueStrings(newLabels,wasEmpty,namelengthmax);
            end
            
            if fixIllegal
                newLabels = obj.makeValidName(newLabels,'warn');
            else
                newLabels = obj.makeValidName(newLabels,'error');
            end
            
            % The number of new labels has to match what's being assigned to.
            if fullAssignment 
                if numel(newLabels) ~= obj.length
                    obj.throwIncorrectNumberOfLabels();
                end
            else
                if numel(newLabels) ~= numel(dimIndices)
                    obj.throwIncorrectNumberOfLabelsPartial();
                end
            end
            
            if fixDups
                % Make the new names (in their possibly modified form) unique with respect to
                % each other and to existing names.
                allNewLabels = obj.labels; allNewLabels(dimIndices) = newLabels;
                allNewLabels = matlab.lang.makeUniqueStrings(allNewLabels,dimIndices,namelengthmax);
                newLabels = allNewLabels(dimIndices);
            elseif fullAssignment
                % Check that the whole set of new names is unique
                obj.checkDuplicateLabels(newLabels);
            else
                % Check that the new names do not duplicate each other or existing names.
                allNewLabels = obj.labels; allNewLabels(dimIndices) = newLabels;
                obj.checkDuplicateLabels(newLabels,allNewLabels,dimIndices);
            end
            
            obj = obj.assignLabels(newLabels,fullAssignment,dimIndices);
        end
        
        %-----------------------------------------------------------------------
        function obj = makeUniqueForRepeatedIndices(obj,~)
            assert(false);
        end
        
        %-----------------------------------------------------------------------
        function throwRequiresLabels(obj) %#ok<MANU>
            throwAsCaller(MException(message('MATLAB:table:CannotRemoveDimNames')));
        end
        function throwIncorrectNumberOfLabels(obj) %#ok<MANU>
           throwAsCaller(MException(message('MATLAB:table:IncorrectNumberOfDimNames')));
        end
        function throwIncorrectNumberOfLabelsPartial(obj) %#ok<MANU>
            throwAsCaller(MException(message('MATLAB:table:IncorrectNumberOfDimNamesPartial')));
        end
        function throwIndexOutOfRange(obj) %#ok<MANU>
            throwAsCaller(MException(message('MATLAB:table:DimIndexOutOfRange')));
        end
        function throwUnrecognizedLabel(obj,label) %#ok<INUSL>
            throwAsCaller(MException(message('MATLAB:table:UnrecognizedDimName',label{1})));
        end
        function throwInvalidLabel(obj) %#ok<MANU>
            throwAsCaller(MException(message('MATLAB:table:InvalidDimName')));
        end
        function throwInvalidSubscripts(obj) %#ok<MANU>
            throwAsCaller(MException(message('MATLAB:table:InvalidDimSubscript')));
        end
    end
    
    methods (Static)
        function conflicts = checkReservedNames(labels)
            reservedNames = matlab.internal.tabular.private.metaDim.reservedNames;
            conflicts = matlab.internal.tabular.private.tabularDimension.checkReservedNamesImpl(labels,reservedNames);
            if nargout==0 && any(conflicts)
                dup = labels{find(conflicts,1)};
                throwAsCaller( MException(message('MATLAB:table:ReservedDimNameConflict',dup)) );
            end
        end
    end
    
    %===========================================================================
    methods (Static, Access=protected)
        function x = orientAs(x)
            % orient as row
            if ~isrow(x)
                x = x(:)';
            end
        end
    end    
    
    %===========================================================================
    methods(Static, Access={?tabular, ?matlab.unittest.TestCase, ?matlab.io.internal.functions.ReadTable})
        function [validNames, modified] = makeValidName(names, modException)
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
            import matlab.internal.datatypes.warningWithoutTrace;            
            import matlab.internal.tabular.private.metaDim.checkReservedNames;

            if modException == "error"
                % If an invalid name should error, no point in calling makeValidName. Call
                % isvarname instead, faster when _all_ names are valid.
                validNames = names; % return the originals, or possibly error
                if ischar(names), names = { names }; end % unusual case, not optimized
                matlab.internal.tabular.validateVariableNameLength(names,'MATLAB:table:DimNameLengthMax');
                checkReservedNames(names);
                modified = false(size(names));
            else
                [validNames, modified] = matlab.lang.makeValidName(names);
                conflicted = checkReservedNames(validNames);
                if any(conflicted)
                    validNames(conflicted) = matlab.lang.makeUniqueStrings(validNames(conflicted), validNames,namelengthmax);
                end
                modified = modified | conflicted;
                if any(modified)
                % Find first modified name
                firstModifiedName = names;
                if iscell(names)
                    firstModifiedName = names{find(modified,1)};
                end
                    switch modException % error or warn per level specified
                        case 'warn'
                            warningWithoutTrace(message('MATLAB:table:ModifiedDimnames',firstModifiedName));
                        otherwise
                            assert(false);
                    end
                end
            end
        end 
            
        function labels = fixLabelsForCompatibility(labels)
            % Pre-R2016b, DimensionNames had almost no constraints, but there are new
            % requirements to support new dot subscripting functionality added in R2016b.
            % The old defaults met those requirements, so if the names are not (now) valid,
            % they must have been intentionally changed from their old defaults (or perhaps
            % DimensionNames{1} came from a column header in a file). In any case, to avoid
            % breaking existing table code, modify any invalid names and warn.
            import matlab.internal.datatypes.warningWithoutTrace
            
            originalLabels = labels;
            % Pre-R2016b and from R2019b onward, names are not required to be valid MATLAB
            % identifiers. But post-R2019b, they must still be shorter than namelengthmax.
            matlab.internal.tabular.validateVariableNameLength(labels,'MATLAB:table:DimNameLengthMax');
            % Pre-2016b, names were not required to be distinct from the list of reserved names.
            wasReserved = matlab.internal.tabular.private.metaDim.checkReservedNames(labels);
            if any(wasReserved)
                warningWithoutTrace(message('MATLAB:table:DimnamesReservedNameConflictBackCompat',originalLabels{find(wasReserved,1)}));
                labels(wasReserved) = matlab.lang.makeUniqueStrings(labels(wasReserved),labels(wasReserved),namelengthmax);
            end
        end
    end
end
%-----------------------------------------------------------------------
function [names,empties] = fillEmptyNames(names,indices)
empties = cellfun('isempty',names);
if any(empties)
    names(empties) = matlab.internal.tabular.private.metaDim.dfltLabels(indices(empties));
end
end
