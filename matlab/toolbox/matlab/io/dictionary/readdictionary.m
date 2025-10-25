function D = readdictionary(filename,varargin)
%READDICTIONARY   Create a dictionary by reading from a file.
%
%   Use the READDICTIONARY function to create a dictionary by reading
%   structured data from a file. READDICTIONARY automatically determines
%   the file format from its extension.
%
%   D = READDICTIONARY(FILENAME) creates a dictionary by reading from a file,
%   where FILENAME can be one of these:
%
%       - For local files, FILENAME can be an absolute path that contains
%         a filename and file extension. FILENAME can also be a relative path
%         to the current folder, or to a folder on the MATLAB path.
%         For example, to import a file on the MATLAB path:
%
%            D = readdictionary("music.json");
%
%       - For files from an Internet URL or stored at a remote location,
%         FILENAME must be a full path using a Uniform Resource Locator
%         (URL). For example, to import a remote file from Amazon S3,
%         specify the full URL for the file:
%
%            D = readdictionary("s3://bucketname/path_to_file/my_file.json");
%
%         For more information on accessing remote data, see "Work with
%         Remote Data" in the documentation.
%
%   D = READDICTIONARY(FILENAME,"FileType",FILETYPE) specifies the file type, where
%   the default FILETYPE is "auto". This only needs to be specified if FILENAME
%   does not have a recognized extension (e.g. an JSON file with a non-standard extension).
%
%   Name-value pairs supported for all file formats:
%   ------------------------------------------------
%
%   "FileType"             - Specifies the file type. It can be specified as:
%                            - "auto": infers the FileType from the file extension.
%                            - "json": treat as a JSON file, regardless of file
%                                      extension.
%
%   "DictionaryNodeName"   - Name of the node underneath which READDICTIONARY
%                            should start reading a dictionary.
%                            DictionaryNodeName may behave differently based on
%                            FileType:
%                             - For JSON files, DictionaryNodeName must match
%                               the name of a key present in a JSON object in
%                               the file.
%
%   "DictionarySelector"   - Selects the node underneath which READDICTIONARY
%                            should start reading a Dictionary. DictionarySelector
%                            may behave differently based on FileType:
%                             - For JSON files, DictionarySelector must be a
%                               JSON Pointer expression that refers to a
%                               node in the JSON file.
%
%   "ValueType"            - Specifies the output dictionary value type.
%
%   "DuplicateKeyRule"     - Specifies the behavior of READDICTIONARY when
%                            a duplicate JSON object key is encountered.
%
%   "DateLocale"           - The locale used to interpret month and day
%                            names in datetime text. Must be a character
%                            vector or a scalar string in the form xx_YY.
%                            See the documentation for DATETIME for more
%                            information.
%
%   "WebOptions"           - HTTP(S) request options, specified as a
%                            weboptions object.
%
%   Name-value pairs supported for JSON files only:
%   -----------------------------------------------
%
%   "ParsingMode"          - Read JSON files with non-standard syntax such
%                            as JavaScript-style comments, Inf/NaN literals, and
%                            trailing commas. Must be specified as a string
%                            scalar or character vector matching:
%                             - "lenient": Allow non-standard JSON syntax.
%                                          Enabled by default.
%                             - "strict": Error when reading non-standard
%                                         JSON files.
%
%   "AllowComments"        - Read JSON files with non-standard JavaScript-style
%                            comment syntax. Defaults to true.
%
%   "AllowInfAndNaN"       - Read JSON files with non-standard Inf and NaN
%                            literal syntax. Defaults to true.
%
%   "AllowTrailingCommas"  - Read JSON files with non-standard trailing
%                            comma syntax. Defaults to true.
%
%
%   See also WRITEDICTIONARY, DICTIONARY, JSONENCODE, JSONDECODE

%   Copyright 2024 The MathWorks, Inc.

    try
        func = matlab.io.internal.functions.FunctionStore.getFunctionByName("readdictionary");
        D = func.validateAndExecute(filename,varargin{:});
    catch ME
        throw(ME);
    end
end
