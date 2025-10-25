classdef PreserveVariableNamesInput < handle
    %PreserveVariableNamesInput Common mixin class for datastores that use
    % a PreserveVariableNames property.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    properties (Access = private, Transient)
        props = matlab.io.internal.shared.PreserveVariableNamesInput;
    end
    
    properties (Hidden)
        PreserveVariableNames;
    end
    
    properties (Dependent)
        %VARIABLENAMINGRULE Controls the normalization of variable names.
        %
        %   "modify"   - Converts variable names to unique nonempty valid MATLAB
        %                identifiers.
        %
        %   "preserve" - Preserves variable names when importing. Will still
        %                make variable names unique and nonempty.
        %
        % See also READTABLE, PARQUETREAD
        VariableNamingRule(1, :) char;
    end
    
    % We need to update the VariableNames property when PreserveVariableNames
    % changes to make sure that the VariableNames are valid for the current
    % value of PreserveVariableNames.
    methods (Abstract, Access = protected)
        updateVariableNamesWithPreservationBehavior(ds);
    end
    
    methods
        function set.PreserveVariableNames(ds, preserveVariableNames)
            try
                validateScalarLogical(preserveVariableNames);
                
                ds.props.PreserveVariableNames = preserveVariableNames;
                % Re-set VariableNames to normalize them according to the
                % current value of PreserveVariableNames.
                updateVariableNamesWithPreservationBehavior(ds);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function val = get.PreserveVariableNames(ds)
            val = ds.props.PreserveVariableNames;
        end
        
        function set.VariableNamingRule(ds, namingRule)
            try
                ds.props.VariableNamingRule = namingRule;
                updateVariableNamesWithPreservationBehavior(ds);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function val = get.VariableNamingRule(ds)
            val = ds.props.VariableNamingRule;
        end
    end
    
    methods (Access = protected)
        function variableNames = normalizeVariableNames(ds, variableNames)
            %normalizeVariableNames normalizes an input array of variable
            % names based on the value of PreserveVariableNames.
            
            % Call into the appropriate table utility. 'warnLength'
            % encompasses the new behavior, while 'warn' follows the
            % old behavior.
            if ds.props.PreserveVariableNames
                preservationBehavior = 'warnLength';
            else
                preservationBehavior = 'warn';
            end
            
            import matlab.internal.tabular.makeValidVariableNames;
            variableNames = makeValidVariableNames(variableNames, preservationBehavior);
        end
    end
    
    methods (Static, Access = protected)
        function configureInputParser(inputParser)
            %configureInputParser adds rules for parsing
            % PreserveVariableNames from an input parser object.
            addParameter(inputParser, "PreserveVariableNames", false, ...
                @validateScalarLogical);
            addParameter(inputParser, "VariableNamingRule", 'modify', ...
                @validateNamingRule);
        end
        
        function resStruct = crossUpdate(resStruct)
            if any(~ismember({'VariableNamingRule','PreserveVariableNames'},resStruct.UsingDefaults))
                pnr = matlab.io.internal.shared.PreserveVariableNamesInput;
                % These are dependent properties, need to cross update
                if ismember('PreserveVariableNames',resStruct.UsingDefaults)
                    pnr.VariableNamingRule = resStruct.VariableNamingRule;
                else
                    pnr.PreserveVariableNames = resStruct.PreserveVariableNames;
                end
                resStruct.PreserveVariableNames = pnr.PreserveVariableNames;
                resStruct.VariableNamingRule = pnr.VariableNamingRule;
                resStruct.UsingDefaults = setdiff(resStruct.UsingDefaults,{'VariableNamingRule','PreserveVariableNames'});
            end
        end
    end
end

function validateScalarLogical(value)
%validatePreserveVariableNames internal function that ensures that the
% input is a scalar logical value.
import matlab.io.datastore.internal.validators.isNumLogical;

if ~isNumLogical(value)
    msgid = 'MATLAB:datastoreio:tabulardatastore:invalidLogical';
    error(message(msgid, 'PreserveVariableNames'));
end
end

function validateNamingRule(val)
matlab.io.internal.shared.PreserveVariableNamesInput.validateNamingRule(val);
end