classdef XMLImportOptions < matlab.io.ImportOptions & ...
        matlab.io.xml.internal.parameter.SelectorProvider & ...
        matlab.io.xml.internal.parameter.RowSelectorProvider & ...
        matlab.io.xml.internal.parameter.TableSelectorProvider & ...
        matlab.io.xml.internal.parameter.RepeatedNodeRuleProvider & ...
        matlab.io.xml.internal.parameter.RegisteredNamespacesProvider & ...
        matlab.internal.datatypes.saveLoadCompatibility & ...
        matlab.io.internal.mixin.UsesStringsForPropertyValues
    %matlab.io.xml.XMLImportOptions Options for importing data from an XML file
    %
    %   matlab.io.xml.XMLImportOptions Properties:
    %
    %                    MissingRule - Rule for interpreting missing or
    %                                  unavailable data. Defaults to "fill".
    %                ImportErrorRule - Rule for interpreting nonconvertible
    %                                  or bad data. Defaults to "fill".
    %               RepeatedNodeRule - Rule for managing repeated XML Element
    %                                  nodes in a given row of a table.
    %                                  Defaults to "addcol".
    %                  VariableNames - Names of the variables in the file.
    %                  VariableTypes - The import types of the variables.
    %          SelectedVariableNames - Names of the variables to be imported.
    %                VariableOptions - Advanced options for variable import.
    %             VariableNamingRule - A character vector or a string scalar that
    %                                  specifies how the output variables are named.
    %                                  It can have either of the following values:
    %
    %                                  'modify'   Modify variable names to make them
    %                                             valid MATLAB Identifiers.
    %                                             (default)
    %                                  'preserve' Preserve original variable names
    %                                             allowing names with spaces and
    %                                             non-ASCII characters.
    %                  TableSelector - XPath expression that selects the XML Element
    %                                  node containing the table data.
    %                    RowSelector - XPath expression that selects the XML Element
    %                                  nodes which delineate rows of the output table.
    %              VariableSelectors - XPath expressions that select the XML Element
    %                                  nodes to be treated as variables of the output
    %                                  table.
    %          VariableUnitsSelector - XPath expression that selects the XML Element
    %                                  nodes containing the variable units.
    %   VariableDescriptionsSelector - XPath expression that selects the XML Element
    %                                  nodes containing the variable descriptions.
    %               RowNamesSelector - XPath expression that selects the XML Element
    %                                  nodes containing the row names.
    %           RegisteredNamespaces - The namespace prefixes that are mapped to
    %                                  namespace URLs for use in selector expressions.
    %
    %   matlab.io.xml.XMLImportOptions Methods:
    %
    %   getvaropts - get the options for a variable by name or number
    %   setvaropts - set the options for a variable by name or number
    %   setvartype - set the import type of a variable by name or number
    %      preview - read 8 rows of data from the file using import options
    %
    %   See also matlab.io.VariableImportOptions, detectImportOptions,
    %   readtable, xmlImportOptions

    %   Copyright 2019-2024 The MathWorks, Inc.

    properties(Constant, Access = protected)
        version = 1;
    end

    properties(Access = {?matlab.io.internal.functions.ReadTableWithImportOptionsXML, ...
                         ?matlab.io.internal.functions.DetectImportOptionsXML})
        %DetectedVariableNames stores the original variable names found
        %   during detection.
        %   This is used to print a warning when variable names are
        %   normalized during reading, and when storing the original variable
        %   names in the VariableDescriptions property.
        DetectedVariableNames(1, :) string;
    end

    methods
        function opts = XMLImportOptions(varargin)
        % set "PreserveVariableNames" to true by default
            varargin = ['PreserveVariableNames', true, varargin];
            
            % To ensure MissingRule and ImportErrorRule are string scalars
            % by default, we have to call the MissingRule and
            % ImportErrorRule setters.
            varargin = ['MissingRule', 'fill', 'ImportErrorRule', 'fill', varargin];
            
            [opts,otherArgs] = opts.parseInputs(varargin,{'NumVariables', ...
                                'VariableOptions','PreserveVariableNames','VariableNames'});
            opts.assertNoAdditionalParameters(fields(otherArgs),class(opts));
        end

        % Custom getter for DetectedVariableNames that accounts for the
        % possibility that more variables were added in the ImportOptions
        % object.
        function varNames = get.DetectedVariableNames(obj)
            % Check if we have any extra variables at the end.
            n = numel(obj.DetectedVariableNames);
            m = numel(obj.VariableNames);
            extraIndices = (n+1):m;

            % Add the extra variables from the original VariableNames list.
            varNames = obj.DetectedVariableNames;
            varNames(extraIndices) = obj.VariableNames(extraIndices);
        end

        function tf = isequaln(opts1,opts2)
            tf = false;

            % Same classes?
            if ~strcmp(class(opts1),class(opts2)); return; end
            
            % DetectedVariableNames should not participate in isequaln.
            opts1.DetectedVariableNames = opts2.DetectedVariableNames;
            
            % Use the ImportOptions superclass isequaln.
            tf = isequaln@matlab.io.ImportOptions(opts1, opts2);
        end
    end

    methods (Access = protected)
        function addCustomPropertyGroups(opts,h)
            addPropertyGroup(h,...
                             getString(message('MATLAB:textio:importOptionsProperties:Replacement')),opts,...
                             {'MissingRule','ImportErrorRule','RepeatedNodeRule'});

            varStruct.VariableNames = opts.VariableNames;
            varStruct.VariableTypes = opts.VariableTypes;
            varStruct.SelectedVariableNames = opts.SelectedVariableNames;
            varStruct.VariableOptions = [];
            varStruct.VariableNamingRule = opts.VariableNamingRule;

            addPropertyGroup(h,...
                             getString(message('MATLAB:textio:importOptionsProperties:VariableImport')),varStruct);
            addPropertyGroup(h,...
                             getString(message('MATLAB:textio:importOptionsProperties:Location')),opts,{'TableSelector','RowSelector','VariableSelectors',...
                                'VariableUnitsSelector', 'VariableDescriptionsSelector', 'RowNamesSelector', 'RegisteredNamespaces'});
        end

        function modifyCustomGroups(~,~)
        % update for string
        end

        function verifyMaxVarSize(~,~)
        % no op
        end

        function obj = updatePerVarSizes(obj,numNew)
        % Ensures the number of VariableSelectors and the number of
        % VariableNames are equal
            numOld = numel(obj.VariableSelectors);
            if numOld < numNew
                obj.VariableSelectors(numOld+1:numNew) = string(missing);
            elseif numOld > numNew
                if numNew == 0
                    obj.VariableSelectors = string.empty(0, 0);
                else
                    obj.VariableSelectors(numNew+1:numOld) = [];
                end
            end
        end
        
        function validateVariableSelectorsSize(obj, numSelectors)
            if numSelectors ~= numel(obj.VariableNames)
                error(message("MATLAB:io:xml:importOptions:NumVariableSelectors"));
            end
        end
    end

    methods (Hidden, Access = {?matlab.io.internal.functions.ReadTableWithImportOptionsXML})
        function params = getOptionsStruct(obj)
            params = struct();

            params.RepeatedNodeRule = obj.RepeatedNodeRule;

            params.TableSelector = (obj.TableSelector);
            params.RowSelector = (obj.RowSelector);
            params.VariableNames = obj.VariableNames;
            params.VariableSelectors = (obj.VariableSelectors);

            params.VariableUnitsSelector = (obj.VariableUnitsSelector);
            params.VariableDescriptionsSelector = (obj.VariableDescriptionsSelector);
            params.RowNamesSelector = (obj.RowNamesSelector);

            params.SelectedVariableIndices = cast(obj.selectedIDs - 1, "uint64");

            params.RegisteredNamespaces = obj.RegisteredNamespaces;
        end
    end

    methods(Access = protected)
        function s = saveToStruct(obj)
        % gets serialized struct of ImportOptions
            s = saveToStruct@matlab.io.ImportOptions(obj);
            
            % properties defined in SelectorProvider/TableSelectorProvider
            s.TableSelector = obj.TableSelector;
            s.RowSelector = obj.RowSelector;
            s.VariableSelectors = obj.VariableSelectors;
            s.VariableUnitsSelector = obj.VariableUnitsSelector;
            s.VariableDescriptionsSelector = obj.VariableDescriptionsSelector;
            s.RowNamesSelector = obj.RowNamesSelector;

            % properties defined in RepeatedNodeRuleProvider
            s.RepeatedNodeRule = obj.RepeatedNodeRule;

            % properties defined in RegisteredNamespacesProvider
            s.RegisteredNamespaces = obj.RegisteredNamespaces;

            % properties defined in XMLImportOptions
            s.DetectedVariableNames = obj.DetectedVariableNames;

            % sets the version and minCompatVersion fields
            s = obj.setCompatibleVersionLimit(s, 1);
            s.incompatibilityMsg = '';
        end

        function obj = loadFromStruct(obj, s)
        % Set properties defined in ImportOptions
            obj = loadFromStruct@matlab.io.ImportOptions(obj, s);

            % properties defined in SelectorProvider/TableSelectorProvider
            obj = trySetProp(obj, s, "TableSelector");
            obj = trySetProp(obj, s, "RowSelector");
            obj = trySetProp(obj, s, "VariableSelectors");
            obj = trySetProp(obj, s, "VariableUnitsSelector");
            obj = trySetProp(obj, s, "VariableDescriptionsSelector");
            obj = trySetProp(obj, s, "RowNamesSelector");

            % properties defined in RepeatedNodeRuleProvider
            obj = trySetProp(obj, s, "RepeatedNodeRule");

            % properties defined in RegisteredNamespacesProvider
            obj = trySetProp(obj, s, "RegisteredNamespaces");

            % properties defined in XMLImportOptions
            obj = trySetProp(obj, s, "DetectedVariableNames");
        end
    end

    methods(Hidden)
        function s = saveobj(obj)
            s = obj.saveToStruct();
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(serialized)
        % always construct a default XMLImportOptions
            obj = matlab.io.xml.XMLImportOptions();

            % Return a default XMLImportOptions if the current object
            % version is less than the minimum compatible version of the
            % serialized object.
            if obj.isIncompatible(serialized, 'MATLAB:io:xml:saveload:IncompatibleLoad')
                return;
            end
            obj = loadFromStruct(obj, serialized);
        end
    end

    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            props = ["TableSelector", "RowSelector", "VariablesSelector",...
                     "VariableUnitsSelector", "VariableDescriptionsSelector",...
                     "VariableDescriptionsSelector", "RowNamesSelector",...
                     "RepeatedNodeRule"];
        end
    end
end

function obj = trySetProp(obj, s, prop)
% Tries to set property to the saved value.
    try
        obj.(prop) = s.(prop);
    catch ME
        % Don't warn if the property is not a field on the struct. This
        % may happen when loading an object saved in a previous release.
        if ~strcmp(ME.identifier, "MATLAB:nonExistentField")
            % On error, the property is left as the default value.
            warning(message('MATLAB:io:xml:saveload:IncompatiblePropertyLoad',...
                            'matlab.io.xml.XMLImportOptions', prop));
        end
    end
end
