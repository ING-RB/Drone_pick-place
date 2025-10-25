function opts = fixedWidthImportOptions(varargin)
%Create options for importing fixed-width data
% opts = fixedWidthImportOptions('Prop1',val1,'Prop2',val2,...) creates
%        options for importing a fixed-width file.
%
%   FixedWidthImportOptions Properties:
%
%                     DataLines - The lines in the text file where the data is located.
%             VariableNamesLine - Where the variable names are located
%                RowNamesColumn - Where the row names are located
%             VariableUnitsLine - Where the variable units are located
%      VariableDescriptionsLine - Where the variable descriptions are located
%                 VariableNames - Names of the variables in the file
%         SelectedVariableNames - Names of the variables to be imported
%                 VariableTypes - The import types of the variables
%                VariableWidths - Number of characters in each field to be imported
%               VariableOptions - Advanced options for variable import
%         PreserveVariableNames - Whether or not to convert variable names
%                                 to valid MATLAB identifiers.
%               ImportErrorRule - Rules for interpreting nonconvertible or bad data
%                   MissingRule - Rules for interpreting missing or unavailable data
%              ExtraColumnsRule - What to do with extra columns of data that appear
%                                 after the expected variables
%              PartialFieldRule - What to do with fields that end before matching the
%                                 requested width
%                 EmptyLineRule - What to do with empty lines in the file
%                    Whitespace - Characters to be treated as whitespace.
%                    LineEnding - Symbol(s) indicating the end of a line in the file
%                  CommentStyle - Symbol(s) designating text to ignore
%                      Encoding - Text encoding of the file to be imported
%                  NumVariables - The number of variables to import
%
% See Also
%   detectImportOptions, readtable,
%   matlab.io.text.FixedWidthImportOptions

% Copyright 2018-2019 MathWorks, Inc.

    opts = matlab.io.text.FixedWidthImportOptions(varargin{:});
end
