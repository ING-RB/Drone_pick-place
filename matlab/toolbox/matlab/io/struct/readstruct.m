function S = readstruct(filename,varargin)
%READSTRUCT   Create a struct by reading from a file.
%
%   Use the READSTRUCT function to create a struct by reading
%   structured data from a file. READSTRUCT automatically determines
%   the file format from its extension.
%
%   S = READSTRUCT(FILENAME) creates a struct by reading from a file, where
%   FILENAME can be one of these:
%
%       - For local files, FILENAME can be an absolute path that contains
%         a filename and file extension. FILENAME can also be a relative path
%         to the current folder, or to a folder on the MATLAB path.
%         For example, to import a file on the MATLAB path:
%
%            S = readstruct("music.xml");
%
%       - For files from an Internet URL or stored at a remote location,
%         FILENAME must be a full path using a Uniform Resource Locator
%         (URL). For example, to import a remote file from Amazon S3,
%         specify the full URL for the file:
%
%            S = readstruct("s3://bucketname/path_to_file/my_file.json");
%
%         For more information on accessing remote data, see "Work with
%         Remote Data" in the documentation.
%
%   S = READSTRUCT(FILENAME,"FileType",FILETYPE) specifies the file type, where
%   the default FILETYPE is "auto". This only needs to be specified if FILENAME
%   does not have a recognized extension (e.g. an XML file with a .gpx extension).
%
%   Name-value pairs supported for all file formats:
%   ------------------------------------------------
%
%   "FileType"             - Specifies the file type. It can be specified as:
%                            - "auto": infers the FileType from the file extension.
%                            - "json": treat as a JSON file, regardless of file
%                                      extension.
%                            - "xml":  treat as an XML file, regardless of file
%                                      extension.
%
%   "StructNodeName"       - Name of the node underneath which READSTRUCT
%                            should start reading a struct. StructNodeName
%                            behaves differently based on FileType:
%                             - For JSON files, StructNodeName must match the
%                               name of a key present in a JSON object in
%                               the file.
%                             - For XML files, StructNodeName must be the
%                               name of an XML element node in the file.
%
%   "StructSelector"       - Selects the node underneath which READSTRUCT
%                            should start reading a struct. StructSelector
%                            behaves differently based on FileType:
%                             - For JSON files, StructSelector must be a
%                               JSON Pointer expression that refers to a
%                               node in the JSON file.
%                             - For XML files, StructSelector must be an
%                               XPath expression which refers to an
%                               Element node in the XML file.
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
%   Name-value pairs supported for XML files only:
%   -----------------------------------------------
%
%   "ImportAttributes"     - Import XML node attributes as fields of the output
%                            struct. Defaults to true.
%
%   "AttributeSuffix"      - Suffix to append to all output struct field names
%                            corresponding to attributes in the XML file. Defaults
%                            to "Attribute".
%
%   "RegisteredNamespaces" - The namespace prefixes that are mapped to
%                            namespace URLs for use in selector expressions.
%
%   See also WRITESTRUCT, STRUCT, JSONENCODE, JSONDECODE

%   Copyright 2019-2023 The MathWorks, Inc.

    try
        func = matlab.io.internal.functions.FunctionStore.getFunctionByName("readstruct");
        S = func.validateAndExecute(filename,varargin{:});
    catch ME
        throw(ME);
    end
end
