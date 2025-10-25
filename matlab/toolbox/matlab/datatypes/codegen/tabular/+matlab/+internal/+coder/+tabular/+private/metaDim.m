classdef (Sealed) metaDim < matlab.internal.coder.tabular.private.tabularDimension %#codegen
%METASDIM Internal class to represent a tabular's list of dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Constant, GetAccess=public)
        propertyNames = {'DimensionNames'};
        requireLabels = true;
        requireUniqueLabels = true;
        reservedNames = {'VariableNames' 'RowNames' 'Properties' ':'};
        DuplicateLabelExceptionID = 'MATLAB:table:DuplicateDimNames';
        NumDimNamesExeptionID = 'MATLAB:table:IncorrectNumberOfDimNames';
        UnrecognizedLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingDimName';
        UnrecognizedAssignmentLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingDimName';
        NonconstantLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingNonconstantDimName';
        NonconstantAssignmentLabelExceptionID = 'MATLAB:table:UnrecognizedIndexingNonconstantDimName';
        IndexOutOfRangeExceptionID = 'MATLAB:table:DimIndexOutOfRange';
        AssignmentOutOfRangeExceptionID = 'MATLAB:table:DimIndexOutOfRange';
        InvalidSubscriptsExceptionID = 'MATLAB:table:InvalidDimSubscript';
        InvalidLabelExceptionID = 'MATLAB:table:InvalidDimSubscript';
        IncorrectNumberOfLabelsExceptionID = 'MATLAB:table:IncorrectNumberOfDimNames';
    end
    
    properties(Dependent)
        hasLabels
    end
    
    properties(GetAccess=public, SetAccess=protected)
        labels
        length
    end
    
    properties(Constant, GetAccess={?matlab.internal.coder.tabular,?matlab.unittest.TestCase})
        % These are the names used by default by metaDim. However, tabular
        % classes may initialize their metaDim with whatever they want.        
        dfltLabels = getDefaultLabels;
    end
    
    %===========================================================================
    methods
        function obj = metaDim(length,rawlabels)
            % Technically, this is not a table dimension, it's more like a table
            % meta-dimension. But it's close enough to var and row names to
            % reuse the infrastructure. Always initialize with two default
            % names, and oriented as a row.
            
            if nargin == 0
                length = 2;
                labels = matlab.internal.coder.tabular.private.metaDim.dfltLabels;
            elseif nargin == 1
                labels = matlab.internal.coder.tabular.private.metaDim.dfltLabels;
            else
                % This is the relevant parts of validateAndAssignLabels
                coder.internal.assert(matlab.internal.coder.datatypes.isCharStrings(rawlabels,true,false), ...
                    'MATLAB:table:InvalidDimNames');
                for i = 1:numel(rawlabels)
                    coder.internal.assert(strlength(rawlabels{i}) > 0, ...
                    'MATLAB:table:InvalidDimNames');
                end
                labels = reshape(rawlabels,1,[]);
                matlab.internal.coder.tabular.private.metaDim.makeValidName(labels,'error');
                obj.checkDuplicateLabelsSimple(labels);
            end
            
            obj = obj.init(length,labels);
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
        function labels = defaultLabels(obj,indices)
            if nargin < 2
                indices = 1:obj.length;
            end
            labels = obj.dfltLabels(indices);
        end
        
        
        %-----------------------------------------------------------------------
        function obj = checkAgainstVarLabels(obj,varLabels,errorMode)
            % In MATLAB, conflict between DimensionNames and VariableNames
            % is resolved by a warning and modifying the DimensionNames
            % using matlab.lang.makeUniqueStrings.
            % In codegen, we simply error.
            
            coder.extrinsic('ismember');
            
            if coder.internal.isConst(varLabels) && coder.internal.isConst(obj.labels)
                [lia, locb] = coder.const(@ismember, varLabels, obj.labels);
            else
                [lia, locb] = matlab.internal.coder.datatypes.cellstr_ismember(varLabels, obj.labels);
            end
            conflict = any(lia);
            if conflict
                if coder.internal.isConst(locb)
                    conflicts = locb(locb > 0);
                    if coder.const(any(conflicts))
                        % constant locb, ok to throw compile time errors
                        firstConflict = obj.labels{min(conflicts)};
                        % error if errorMode not supplied
                        coder.internal.errorIf(conflict && nargin <= 2, 'MATLAB:table:DuplicateDimNamesVarNames',firstConflict);
                        if nargin > 2  % if errorMode is supplied
                            coder.internal.errorIf(conflict && strcmp(errorMode, 'error'), ...
                                'MATLAB:table:DuplicateDimNamesVarNames',firstConflict);
                            if strcmp(errorMode, 'warn')
                                coder.internal.warning('MATLAB:table:DuplicateDimnamesVarnamesBackCompat',firstConflict);
                            end
                        end
                    end
                else  % non-constant locb, don't try to throw compile time error
                    % because the variable name in conflict will not be 
                    % known until runtime
                    
                    % force homogeneous to avoid non-constant indexing into
                    % heterogeneous cell arrays
                    labels_homogeneous = obj.labels;
                    coder.varsize('labels_homogeneous', size(labels_homogeneous), [0 0]);
                    firstConflict = labels_homogeneous{min(locb(locb > 0))};
                    % error if errorMode not supplied
                    if nargin <= 2 || strcmp(errorMode, 'error')
                        coder.internal.error('MATLAB:table:DuplicateDimNamesVarNames',firstConflict);
                    end
                    % issue warning if warning mode
                    if nargin > 2 && strcmp(errorMode, 'warn')
                        coder.internal.warning('MATLAB:table:DuplicateDimnamesVarnamesBackCompat',firstConflict);
                    end
                end
            end
        end
           
        %-----------------------------------------------------------------------
        function s = getProperties(~)
            s = struct;
            % Same order as metaDim.propertyNames
            % DimensionNames need to be handled separately because if is
            % often required to be constant. Don't copy.
            %s.DimensionNames = obj.labels;
        end
    end
    
    %===========================================================================
    methods (Access=protected)
        function obj = validateAndAssignLabels(obj,newLabels,dimIndices,fullAssignment,dimLength,fixDups,fixEmpties,fixIllegal)
            coder.internal.prefer_const(fullAssignment, dimLength, fixDups, fixEmpties, fixIllegal);
            assert(fullAssignment);   % no partial assignment until dotParenAssign available
            assert(~fixDups);         % fixDups currently not used in codegen
            assert(~fixEmpties);      % fixEmpties currently not used in codegen
            assert(~fixIllegal);      % fixIllegal currently not used in codegen
            
            coder.internal.assert(matlab.internal.coder.datatypes.isCharStrings(...
                newLabels,true,fixEmpties), 'MATLAB:table:InvalidDimNames');
            
            newLabels = obj.makeValidName(newLabels,'error');
            
            % Check that the whole set of new names is unique
            obj.checkDuplicateLabelsSimple(newLabels);
            
            obj = obj.assignLabels(newLabels,fullAssignment,dimIndices,dimLength);
        end
    end
    
    methods (Access={?matlab.internal.coder.tabular.private.tabularDimension})
        function obj = makeUniqueForRepeatedIndices(obj,~,~)
            assert(false);
        end
    end
    
    methods (Static)
        function conflicts = checkReservedNames(labels)
            coder.extrinsic('matlab.internal.coder.tabular.private.tabularDimension.checkReservedNames');
            errorOnConflicts = (nargout==0);
            reservedNames = matlab.internal.coder.tabular.private.metaDim.reservedNames;
            conflicts = coder.const(checkReservedNames@matlab.internal.coder.tabular.private.tabularDimension(...
                labels,reservedNames,false,'MATLAB:table:ReservedDimNameConflict'));
            if errorOnConflicts && any(conflicts)
                % conflicts is always constant. This block should only
                % be evaluated if there is at least one conflict.
                % Since we are using brace indexing and we only have one output arg,
                % i.e. firstconflict, it will contain the first label that
                % conflicted with the reservedNames.
                firstconflict = labels{conflicts};
                coder.internal.assert(false, 'MATLAB:table:ReservedDimNameConflict', ...
                    firstconflict);
            end
        end
        
        function result = matlabCodegenNontunableProperties(~)
            result = {'labels'};
        end
    end
    
    %===========================================================================   
    methods (Static, Access=protected)
        function y = orientAs(x)
            coder.internal.prefer_const(x);
            % orient as row
            if ~isrow(x)
                y = reshape(x,1,[]);
            else
                y = x;
            end
        end
    end    
    
    %===========================================================================
    methods(Static, Access={?tabular, ?matlab.unittest.TestCase})
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
            coder.internal.prefer_const(modException);
            assert(strcmp(modException,'error'));  % error is the only supported MODEXCEPTION in codegen
            
            validNames = names; % return the originals, or possibly error
            if ischar(names), names = { names }; end % unusual case, not optimized
            matlab.internal.coder.tabular.validateVariableNameLength(names,'MATLAB:table:DimNameLengthMax');
            matlab.internal.coder.tabular.private.metaDim.checkReservedNames(names);
            modified = false(size(names));
        end
            
        function labels = fixLabelsForCompatibility(rawlabels)
            % In MATLAB, if DimensionNames conflict with a reserved name or 
            % contains invalid MATLAB identifiers,
            % MATLAB returns a warning and modifies the DimensionNames. 
            % Codegen simply returns an error.
            matlab.internal.coder.tabular.private.metaDim.makeValidName(rawlabels,'error');
                        
            % Pre-2016b, names were not required to be distinct from the list of reserved names.
            wasReserved = matlab.internal.coder.tabular.private.metaDim.checkReservedNames(rawlabels);
            labels = cell(size(rawlabels));
            for i = 1:numel(rawlabels)
                coder.internal.errorIf(wasReserved(i), 'MATLAB:table:DimnamesReservedNameConflictBackCompat',rawlabels{i});
                labels{i} = rawlabels{i};
            end
        end
    end
end
%-----------------------------------------------------------------------
function dfltLabels = getDefaultLabels
% get the default dimension labels
coder.extrinsic('getString', 'message', 'matlab.internal.i18n.locale');
dfltLabels = { getString(message('MATLAB:table:uistrings:DfltRowDimName'),...
                      matlab.internal.i18n.locale('en_US')) ...
                      getString(message('MATLAB:table:uistrings:DfltVarDimName'),...
                      matlab.internal.i18n.locale('en_US')) };
coder.const(dfltLabels);  % make sure labels are returned as constants                 
end
