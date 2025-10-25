function writedictionary(D, filename, varargin)
%WRITEDICTIONARY   Write a dictionary to a file.
%
%   WRITEDICTIONARY(D, FILENAME) writes the dictionary D to the file FILENAME.
%
%   D must be a dictionary.
%   The data in D must be one of the following datatypes: dictionary, string,
%   datetime, duration, categorical, logical, struct, cell, or any 
%   numeric datatype.
%
%   FILENAME can be one of these:
%
%       - For local files, FILENAME can contain an absolute file name with a
%         file extension. FILENAME can also be a relative path to the current
%         folder, or to a folder on the MATLAB path.
%         For example, to export to a file in the current folder:
%
%            writedictionary(D, "microscopy.json");
%
%       - For remote files, FILENAME must be a full path specified as a
%         uniform resource locator (URL). For example, to export a remote
%         file to Amazon S3, specify the full URL for the file:
%
%            writedictionary(D, "s3://bucketname/path_to_file/my_setup.json");
%
%         For more information on accessing remote data, see "Work with
%         Remote Data" in the documentation.
%
%   WRITEDICTIONARY(D, FILENAME, "FileType", FILETYPE) specifies the file type.
%
%       The default value for FILETYPE is "auto", which makes
%       WRITEDICTIONARY
%       detect the output file type from the extension of the supplied file name.
%
%       FILETYPE should be manually specified when the file extension and the
%       type of the file can differ.
%       For example, specify FILETYPE to write an JSON file with a ".js"
%       extension:
%
%           writedictionary(D, "data.js", "FileType", "json");
%
%   Name-value pairs supported for all file formats:
%   ------------------------------------------------
%
%   "FileType"    - Specifies the file type. Supported values include:
%                    "auto" - detect the file type to write based on the
%                             extension of the file name
%                    "json" - export as a JSON file
%
%   "PrettyPrint" - Add indentation, specified as true (default) or false.
%
%   Name-value pairs supported for JSON files only:
%   -----------------------------------------------
%
%   "PreserveInfAndNaN" - Specify whether to write literal Inf and NaN
%                         values to JSON files. Defaults to true.
%                         Setting this to false will result in Inf and NaN
%                         values being written as JSON null values.
%
%
%   See also READDICTIONARY, DICTIONARY, JSONDECODE, JSONENCODE

% Copyright 2024 The MathWorks, Inc.

    try
        [filename, ~, nvStruct] = commonWriteDictionaryValidation(D, filename, varargin{:});

        writeDictionaryJSON(D, filename, nvStruct);

    catch ME
        if strcmp(ME.identifier, "MATLAB:io:common:file:InvalidURLScheme")
            S = matlab.io.internal.filesystem.Path(filename);
            error(message("MATLAB:virtualfileio:stream:CannotFindLocation", ...
                filename, S.Parent));
        else
            throw(ME);
        end
    end
end

function [filename, fileType, nvStruct] = commonWriteDictionaryValidation(D, filename, varargin)
    % Validate order of required arguments
    validateRequiredArgumentOrder(D, filename);

    % Check that a valid filename for writing has been passed in.
    import matlab.io.internal.struct.write.validateFilename;
    filename = validateFilename(filename, "writedictionary");

    % Parse N-V args.
    import matlab.io.internal.dictionary.parseWriteDictionaryNVPairs;
    [nvStruct, fileType] = parseWriteDictionaryNVPairs(filename, varargin{:});
end

function writeDictionaryJSON(D, filename, nvStruct)
    matlab.io.json.internal.write.writedictionary(D, filename, nvStruct);
end

function validateRequiredArgumentOrder(d, filename)

    import matlab.io.xml.internal.write.validateRequiredArgumentOrder;
    import matlab.io.internal.interface.suggestWriteFunctionCorrection;

    validateRequiredArgumentOrder(d, filename, "dictionary");

    if ~isa(d, "dictionary")
        suggestWriteFunctionCorrection(d, "writedictionary");
    end
end
