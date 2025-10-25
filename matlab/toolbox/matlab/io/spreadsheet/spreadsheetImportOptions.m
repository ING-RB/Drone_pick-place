function opts = spreadsheetImportOptions(varargin)
%Create options for importing spreadsheet data
% opts = spreadsheetImportOptions('Prop1',val1,'Prop2',val2,...) creates
%        options for importing a spreadsheet.
%
%   SpreadsheetImportOptions Properties:
%
%                          Sheet - The name or number where the table is located
%                      DataRange - Where the table data is located
%             VariableNamesRange - Where the variable names are located
%                  RowNamesRange - Where the row names are located
%             VariableUnitsRange - Where the variable units are located
%      VariableDescriptionsRange - Where the variable descriptions are located
%                  VariableNames - Names of the variables in the file
%          SelectedVariableNames - Names of the variables to be imported
%                  VariableTypes - The import types of the variables
%                VariableOptions - Advanced options for variable import
%          PreserveVariableNames - Whether or not to convert variable names
%                                  to valid MATLAB identifiers.
%                ImportErrorRule - Rules for interpreting nonconvertible or bad data
%                    MissingRule - Rules for interpreting missing or unavailable data
%                   NumVariables - The number of variables to import
%
% See Also
%   detectImportOptions, readtable,
%   matlab.io.spreadsheet.SpreadSheetImportOptions

% Copyright 2018-2019 MathWorks, Inc.

    opts = matlab.io.spreadsheet.SpreadsheetImportOptions(varargin{:});
end
