function opts = htmlImportOptions(varargin)
%htmlImportOptions Create options for importing HTML data
%
%   opts = htmlImportOptions("Prop1",val1,"Prop2",val2,...) creates
%           options for importing an HTML file.
%
%   Name-Value pairs for htmlImportOptions:
%
%    numVars - Number of variables
%
%    Variable Properties
%      VariableNames         - Variable names
%      VariableNamingRule    - Flag to preserve variable names
%      VariableTypes         - Data types of variable
%      SelectedVariableNames - Subset of variables to import
%      VariableOptions       - Type specific variable import options
%
%    Location Properties
%      TableSelector           - Table data XPath expression
%      DataRows                - Data location
%      RowNamesColumn          - Row names location
%      VariableNamesRow        - Variable names location
%      VariableUnitsRow        - Variable units location
%      VariableDescriptionsRow - Variable descriptions location
%
%    Replacement Rules
%      MissingRule          - Procedure to manage missing data
%      EmptyRowRule         - Procedure to handle empty rows
%      ImportErrorRule      - Procedure to handle import errors
%      ExtraColumnsRule     - Procedure to handle extra columns
%      MergedCellColumnRule - Procedure to handle cells with merged columns
%      MergedCellRowRule    - Procedure to handle cells with merged rows
%
%   See Also: detectImportOptions, readtable, matlab.io.html.HTMLImportOptions,
%             matlab.io.VariableImportOptions

% Copyright 2021 The MathWorks, Inc.

    opts = matlab.io.html.HTMLImportOptions(varargin{:});
end
