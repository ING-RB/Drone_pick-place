function opts = xmlImportOptions(varargin)
%xmlImportOptions Create options for importing XML data
%
%   opts = xmlImportOptions("Prop1",val1,"Prop2",val2,...) creates
%           options for importing an XML file.
%
%   Name-Value pairs for xmlImportOptions:
%
%   "MissingRule"                  - Rule for interpreting missing or
%                                    unavailable data. Defaults to "fill".
%   "ImportErrorRule"              - Rule for interpreting nonconvertible
%                                    or bad data. Defaults to "fill".
%   "RepeatedNodeRule"             - Rule for managing repeated nodes in
%                                    a given row of a table. Defaults to
%                                    "addcol".
%   "VariableNames"                - Names of the variables in the file.
%   "VariableTypes"                - The import types of the variables.
%   "SelectedVariableNames"        - Names of the variables to be imported.
%   "VariableOptions"              - Advanced options for variable import.
%   "PreserveVariableNames"        - Whether to keep variable names from file
%                                    or to convert variable names to valid
%                                    MATLAB identifiers. Defaults to true.
%   "TableSelector"                - XPath expression that selects the XML Element
%                                    node containing the table data.
%   "RowSelector"                  - XPath expression that selects the XML Element
%                                    nodes which delineate rows of the output table.
%   "VariableSelectors"            - XPath expressions that select the XML Element
%                                    nodes to be treated as variables of the output
%                                    table.
%   "VariableUnitsSelector"        - XPath expression that selects the XML Element
%                                    nodes containing the variable units.
%   "VariableDescriptionsSelector" - XPath expression that selects the XML Element
%                                    nodes containing the variable descriptions.
%   "RowNamesSelector"             - XPath expression that selects the XML Element
%                                    nodes containing the row names.
%   "RegisteredNamespaces"         - The namespace prefixes that are mapped to
%                                    namespace URLs for use in selector expressions.
%
%   See Also: detectImportOptions, readtable, matlab.io.xml.XMLImportOptions,
%             matlab.io.VariableImportOptions

% Copyright 2019-2020 The MathWorks, Inc.

    opts = matlab.io.xml.XMLImportOptions(varargin{:});
end
