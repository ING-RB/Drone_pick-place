function opts = detectImportOptions(filename,varargin)
%DETECTIMPORTOPTIONS Creates import options based on the contents of a file.
%
%   OPTS = DETECTIMPORTOPTIONS(FILENAME) locates a table in a file and
%          returns import options describing rules to import that table.
%          FILENAME can be one of these:
%
%          - For local files, FILENAME can be an absolute path that contains
%            a filename and file extension. FILENAME can also be a relative
%            path to the current directory, or to a directory on the MATLAB
%            path. For example, to import a file on the MATLAB path:
%
%                opts = DETECTIMPORTOPTIONS("patients.xls");
%
%          - For remote files, FILENAME must be a full path using an
%            internationalized resource identifier (IRI). For example, to
%            import a remote file from Amazon S3 cloud specify the full IRI
%            for the file:
%
%                opts = DETECTIMPORTOPTIONS("s3://bucketname/path_to_file/my_table.xls");
%
%            For more information on accessing remote data, see "Work with
%            Remote Data" in the documentation.
%
%          detectImportOptions returns different OPTS objects based on the
%          input file type:
%
%            - DelimitedTextImportOptions or FixedWidthImportOptions when
%              a text file is provided as input.
%
%            - SpreadsheetImportOptions when a spreadsheet file is provided
%              as input.
%
%            - XMLImportOptions when an XML file is provided as input.
%
%            - WordDocumentImportOptions when a Microsoft Word (.docx) file
%              is provided as input.
%
%            - HTMLImportOptions when an HTML file is provided as input.
%
%   OPTS = DETECTIMPORTOPTIONS(___, ... Name-Value Parameters) locates a
%          table given the input parameters. Many parameters can affect how
%          the other parameters are detected in the file.
%
%          DETECTIMPORTOPTIONS sets the parameters below based on the
%          contents of the file.
%
%           For all file types:
%              * VariableTypes
%           For Text and Spreadsheet Files:
%              * DataLines/DataRange
%              * VariableNamesLine/VariableNamesRange
%              * VariableNames (if any)
%              * Delimiter (delimited text only)
%              * ConsecutiveDelimitersRule (if space is delimiter)
%              * LeadingDelimitersRule (if space is delimiter)
%              * VariableWidths (if file is fixed width)
%              * PartialFieldRule (if file is fixed width)
%           For XML Files:
%              * TableSelector
%              * RowSelector
%              * VariableSelectors
%           For HTML and Word document files:
%              * TableSelector OR TableIndex
%              * DataRows
%              * VariableNamesRow
%              * VariableNames (if any)
%              * VariableDescriptionsRow, VariableUnitsRow
%              * EmptyColumnRule, EmptyRowRule
%              * MergedCellColumnRule, MergedCellRowRule
%
%   Example: Import a subset of the data in a file:
%
%       opts = DETECTIMPORTOPTIONS("patients.xls");
%       opts.SelectedVariableNames = ["Systolic", "Diastolic"];
%       T = readtable("patients.xls", opts)
%
%   Example: Change the data type of a variable:
%
%       opts = setvartype(opts, ["Systolic", "Diastolic"], "int32");
%       T = readtable("patients.xls", opts)
%
%   Example: Change the FillValue of a variable:
%
%       opts = setvaropts(opts, ["Systolic", "Diastolic"], "FillValue", -99);
%       T = readtable("patients.xls",opts)
%
%   Name-Value Pairs for ALL file types:
%   ------------------------------------
%
%   "FileType"              - Specify the file as "text", "delimitedtext",
%                             "fixedwidth", "spreadsheet", "xml", "html",
%                             or "worddocument".
%
%   "VariableNamingRule"    - A character vector or a string scalar that
%                             specifies how the output variables are named.
%                             It can have either of the following values:
%
%                             'modify'   Modify variable names to make them
%                                        valid MATLAB Identifiers.
%                                        (default)
%                             'preserve' Preserve original variable names
%                                        allowing names with spaces and
%                                        non-ASCII characters.
%
%   "MissingRule"           - Rules for interpreting missing or
%                             unavailable data:
%                             "fill"      Replace missing data with the
%                                         contents of the "FillValue"
%                                         property.
%                             "error"     Stop importing and display an
%                                         error message showing the missing
%                                         record and field.
%                             "omitrow"   Omit rows that contain missing
%                                         data.
%                             "omitvar"   Omit variables that contain
%                                         missing data.
%
%   "ImportErrorRule"       - Rules for interpreting nonconvertible
%                             or bad data:
%                             "fill"      Replace the data where errors
%                                         occur with the contents of the
%                                         "FillValue" property.
%                             "error"     Stop importing and display an
%                                         error message showing the
%                                         error-causing record and field.
%                             "omitrow"   Omit rows where errors occur.
%                             "omitvar"   Omit variables where errors
%                                         occur.
%
%   "ReadRowNames"          - Whether or not to import the first variable
%                             as row names. Will set the RowNamesColumn,
%                             RowNamesRange, or RowNamesSelector property
%                             in the generated ImportOptions object.
%                             Defaults to false.
%
%   "TreatAsMissing"        - Text which is used in a file to represent
%                             missing data, e.g. "NA".
%
%   "TextType"              - The type to use for text variables, specified
%                             as "char" or "string".
%
%   "DatetimeType"          - The type to use for date variables, specified
%                             as "datetime", "text", or "exceldatenum".
%                             Defaults to "datetime".
%
%   Name-Value Pairs for TEXT and SPREADSHEET only:
%   -----------------------------------------------
%
%   "Range"                 - The range to consider when detecting data.
%                             Specified using any of the following syntaxes:
%                             - Starting cell: A string or character vector
%                               containing a column letter and a row number,
%                               or a 2 element numeric vector indicating
%                               the starting row and column.
%                             - Rectangular range: A start and end cell separated
%                               by colon, e.g. "C2:N15", or a four element
%                               numeric vector containing start row, start
%                               column, end row, end column, e.g. [2 3 15 13].
%                             - Row range: A string or character vector
%                               containing a starting row number and ending
%                               row number, separated by a colon.
%                             - Column range: A string or character vector
%                               containing a starting column letter and
%                               ending column letter, separated by a colon.
%                             - Starting row number: A numeric scalar
%                               indicating the first row where data is found.
%
%   "NumHeaderLines"        - The number of header lines in the file.
%
%   "ExpectedNumVariables"  - The expected number of variables.
%
%   "ReadVariableNames"     - Whether or not to expect variable names in
%                             the file. Defaults to true.
%
%   Name-Value Pairs for TEXT, XML, HTML, and Word documents only:
%   --------------------------------------------------------------
%
%   "DateLocale"         - The locale used to interpret month and day
%                          names in datetime text. Must be a character
%                          vector or scalar string in the form xx_YY.
%                          See the documentation for DATETIME for more
%                          information.
%
%   "DecimalSeparator"   - Character used to separate the integer part
%                          of a number from the decimal part of the
%                          number.
%
%   "ThousandsSeparator" - Character used to separate the thousands
%                          place digits.
%
%   Name-Value Pairs for TEXT, XML, and HTML only:
%   ----------------------------------------------
%
%   "Encoding"           - The character encoding scheme associated with
%                          the file.
%
%   Name-Value Pairs for TEXT and XML only:
%   ---------------------------------------
%
%   "DurationType"       - The type to use for duration, specified as
%                          "duration" or "text". Defaults to "duration".
%
%   "Whitespace"         - Characters to treat as whitespace.
%
%   "TrimNonNumeric"     - Whether or not to remove nonnumeric characters
%                          from a numeric variable. Defaults to false.
%
%   "HexType"            - Set the output type of a hexadecimal
%                          variable.
%
%   "BinaryType"         - Set the output type of a binary variable.
%
%   Name-Value Pairs for TEXT, HTML, and Word documents only:
%   ---------------------------------------------------------
%
%   "RowNamesColumn"     - The column where the row names are
%                          located.
%
%   Name-Value Pairs for TEXT only:
%   -------------------------------
%
%   "Delimiter"                 - Field delimiter characters in a delimited
%                                 text file, specified as a character
%                                 vector, string scalar, cell array of
%                                 character vectors, or string array.
%
%   "CommentStyle"              - Style of comments, specified as a
%                                 character vector, string scalar, cell
%                                 array of character vectors, or string
%                                 array.
%
%   "LineEnding"                - End-of-line characters, specified as a
%                                 character vector, string scalar, cell
%                                 array of character vectors, or string
%                                 array.
%
%   "ConsecutiveDelimitersRule" - Rule to apply to fields containing
%                                 multiple consecutive delimiters:
%                                 "split"     Split consecutive delimiters
%                                             into multiple fields.
%                                 "join"      Join the delimiters into one
%                                             single delimiter.
%                                 "error"     Ignore consecutive delimiters
%                                             during detection (treated as
%                                             "split"), but the
%                                             resulting read will error.
%
%   "LeadingDelimitersRule"     - Rule to apply to delimiters at the
%                                 beginning of a line:
%                                 "keep"      Keep leading delimiters.
%                                 "ignore"    Ignore leading delimiters.
%                                 "error"     Ignore leading delimiters
%                                             during detection, but the
%                                             resulting read will error.
%
%   "TrailingDelimiterRule"     - Rule to apply to delimiters at the
%                                 end of a line:
%                                 "keep"      Keep trailing delimiters.
%                                 "ignore"    Ignore trailing delimiters.
%                                 "error"     Ignore trailing delimiters
%                                             during detection, but the
%                                             resulting read will error.
%
%   "VariableWidths"            - Widths of the variables for a fixed width
%                                 file.
%
%   "EmptyLineRule"             - Rule to apply to empty lines in the file:
%                                 "skip"      Skip empty lines.
%                                 "read"      Read empty lines.
%                                 "error"     Ignore empty lines during
%                                             detection, but the resulting
%                                             read will error.
%
%   "VariableNamesLine"         - The line where the variable names are
%                                 located.
%
%   "PartialFieldRule"          - Rule to handle partial fields in the data:
%                                 "keep"      Keep the partial field data
%                                             and convert the text to the
%                                             appropriate data type.
%                                 "fill"      Replace missing data with the
%                                             contents of the "FillValue"
%                                             property.
%                                 "omitrow"   Omit rows that contain
%                                             partial data.
%                                 "omitvar"   Omit variables that contain
%                                             partial data.
%                                 "wrap"      Begin reading the next line
%                                             of characters.
%                                 "error"     Ignore partial field data
%                                             during detection, but the
%                                             resulting read will error.
%
%   "VariableUnitsLine"         - The line where the variable units are
%                                 located.
%
%   "VariableDescriptionsLine"  - The line where the variable descriptions
%                                 are located.
%
%   "ExtraColumnsRule"          - Rule to apply to extra columns of data
%                                 that appear after the expected variables:
%                                 "addvars"   Creates new variables to
%                                             import extra columns. If there
%                                             are N extra columns, then import
%                                             new variables as "ExtraVar1",
%                                             "ExtraVar2",..., "ExtraVarN".
%                                 "ignore"    Ignore the extra columns of
%                                             data.
%                                 "wrap"      Wrap the extra columns of
%                                             data to new records.
%                                 "error"     Display an error message and
%                                             abort the import operation.
%
%   Name-Value Pairs for SPREADSHEET only:
%   --------------------------------------
%
%   "Sheet"                     - The sheet from which to detect the table.
%
%   "DataRange"                 - Where the table data is located.
%
%   "RowNamesRange"             - Where the row names are located.
%
%   "VariableNamesRange"        - Where the variable names are located.
%
%   "VariableUnitsRange"        - Where the variable units are located.
%
%   "VariableDescriptionsRange" - Where the variable descriptions are
%                                 located.
%
%   Name-Value Pairs for HTML and Word documents only:
%   --------------------------------------------------
%
%   "TableIndex"                - Integer selection which table to extract.
%
%   "VariableNamesRow"          - The row where the variable names are
%                                 located.
%
%   "VariableUnitsRow"          - The row where the variable units are
%                                 located.
%
%   "VariableDescriptionsRow"   - The row where the variable descriptions
%                                 are located.
%
%   "EmptyRowRule"              - Rule to apply to empty lines in the file:
%                                 "skip"      Skip empty lines.
%                                 "read"      Read empty lines.
%                                 "error"     Ignore empty lines during
%                                             detection, but the resulting
%                                             read will error.
%
%   "EmptyColumnRule"           - Rule to apply to empty columns in the file:
%                                 "skip"      Skip empty columns.
%                                 "read"      Read empty columns.
%                                 "error"     Error on empty columns.
%
%   Name-Value Pairs for HTML, Word documents, and XML only:
%   --------------------------------------------------------
%
%   "TableSelector"             - XPath expression that selects the table
%                                 to extract.
%
%   Name-Value Pairs for XML only:
%   ------------------------------
%
%   "RowNodeName"                  - Node name which delineates rows of
%                                    the output table.
%
%   "RowSelector"                  - XPath expression that selects the XML
%                                    Element nodes which delineate rows of
%                                    the output table.
%
%   "VariableNodeNames"            - Node names which will be treated as
%                                    variables of the output table.
%
%   "VariableSelectors"            - XPath expressions that select the XML
%                                    Element nodes to be treated as variables
%                                    of the output table.
%
%   "TableNodeName"                - Name of the node which contains table
%                                    data. If multiple nodes have the same
%                                    name, READTABLE uses the first node
%                                    with that name.
%
%   "VariableUnitsSelector"        - XPath expression that selects the XML
%                                    Element nodes containing the variable
%                                    units.
%
%   "VariableDescriptionsSelector" - XPath expression that selects the XML
%                                    Element nodes containing the variable
%                                    descriptions.
%
%   "RowNamesSelector"             - XPath expression that selects the XML
%                                    Element nodes containing the row names.
%
%   "RepeatedNodeRule"             - Rule for managing repeated nodes in a
%                                    given row of a table:
%                                    "addcol"     Add a column for each
%                                                 repeated node.
%                                    "ignore"     Ignore repeated nodes.
%                                    "error"      Ignore repeated nodes
%                                                 during detection, but the
%                                                 resulting read will error.
%
%   "ImportAttributes"             - Import XML node attributes as variables
%                                    of the output table. Defaults to true.
%
%   "AttributeSuffix"              - Suffix to append to all output table
%                                    variable names corresponding to
%                                    attributes in the XML file. Defaults
%                                    to "Attribute".
%
%   "RegisteredNamespaces"         - The namespace prefixes that are mapped
%                                    to namespace URLs for use in selector
%                                    expressions.
%
%     See also spreadsheetImportOptions, delimitedTextImportOptions, fixedWidthImportOptions,
%              htmlImportOptions, wordDocumentImportOptions, xmlImportOptions,
%              readtable, readtimetable, readmatrix, readcell

% Copyright 2016-2021 The MathWorks, Inc.

    try
        func = matlab.io.internal.functions.FunctionStore.getFunctionByName('detectImportOptions');
        C = onCleanup(@()func.WorkSheet.clear());
        opts = func.validateAndExecute(filename,varargin{:});
    catch ME
        throw(ME)
    end
