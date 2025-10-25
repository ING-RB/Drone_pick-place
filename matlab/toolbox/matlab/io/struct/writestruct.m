function writestruct(S, filename, varargin)
%WRITESTRUCT   Write a struct to a file.
%
%   WRITESTRUCT(S, FILENAME) writes the struct S to the file FILENAME.
%
%   S must be a scalar struct containing fields with scalar or vector data.
%   The data in each field must be one of the following datatypes: string,
%   datetime, duration, categorical, logical, struct, cell, or any numeric datatype.
%
%   FILENAME can be one of these:
%
%       - For local files, FILENAME can contain an absolute file name with a
%         file extension. FILENAME can also be a relative path to the current
%         folder, or to a folder on the MATLAB path.
%         For example, to export to a file in the current folder:
%
%            writestruct(S, "microscopy.json");
%
%       - For remote files, FILENAME must be a full path specified as a
%         uniform resource locator (URL). For example, to export a remote
%         file to Amazon S3, specify the full URL for the file:
%
%            writestruct(S, "s3://bucketname/path_to_file/my_setup.xml");
%
%         For more information on accessing remote data, see "Work with
%         Remote Data" in the documentation.
%
%   WRITESTRUCT(S, FILENAME, "FileType", FILETYPE) specifies the file type.
%
%       The default value for FILETYPE is "auto", which makes WRITESTRUCT
%       detect the output file type from the extension of the supplied file name.
%
%       FILETYPE should be manually specified when the file extension and the
%       type of the file can differ.
%       For example, specify FILETYPE to write an XML file with a ".kml"
%       extension:
%
%           writestruct(S, "data.kml", "FileType", "xml");
%
%   Name-value pairs supported for all file formats:
%   ------------------------------------------------
%
%   "FileType"    - Specifies the file type. Supported values include:
%                    "auto" - detect the file type to write based on the
%                             extension of the file name
%                    "xml"  - export as an XML file
%                    "json" - export as a JSON file
%
%   "Encoding"    - The encoding to use when creating the file. Default is
%                   "UTF-8".
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
%   Name-value pairs supported for XML files only:
%   ----------------------------------------------
%
%   "StructNodeName"  - This will be the name of the root node of the XML
%                       file written. For instance, consider the following
%                       struct S:
%
%                          S.Product(1) = struct("Name", "Widget1", "Price", 2);
%                          S.Product(2) = struct("Name", "Widget2", "Price", 5);
%                          writestruct(S, "products.xml", "StructNodeName", "Products");
%
%                       If "StructNodeName" is specified as "Products", the XML
%                       written will have the following contents:
%
%                          <?xml version="1.0" encoding="UTF-8"?>
%                          <Products>
%                              <Product>
%                                  <Name>Widget1</Name>
%                                  <Price>2</Price>
%                              </Product>
%                              <Product>
%                                  <Name>Widget2</Name>
%                                  <Price>5</Price>
%                              </Product>
%                          </Products>
%
%                       If not specified, "StructNodeName" defaults to "struct".
%
%   "AttributeSuffix" - Suffix indicating fields to write out as XML
%                       attributes. All fields with the specified suffix
%                       will be written out as XML attributes, excluding
%                       the suffix in the resulting attribute name. This is
%                       particularly helpful for round-trip I/O workflows.
%                       For instance, if a struct contains a field named
%                       "PriceAttribute", via AttributeSuffix, this field
%                       can be written out to the XML file as "Price" by
%                       specifying the value of AttributeSuffix as
%                       "Attribute". The default value of "AttributeSuffix"
%                       is "Attribute".
%
%   See also READSTRUCT, STRUCT, WRITETABLE

% Copyright 2019-2023 The MathWorks, Inc.

    try
        [filename, fileType, nvStruct] = commonWriteStructValidation(S, filename, varargin{:});

        % Call into C++ with the input struct, filename, and options.
        switch fileType
          case "xml"
            writeStructXML(S, filename, nvStruct);
          case "json"
            writeStructJSON(S, filename, nvStruct);
        end
    catch ME
        if strcmp(ME.identifier, "MATLAB:io:common:file:InvalidURLScheme")
            S = matlab.io.internal.filesystem.Path(filename);
            error(message("MATLAB:virtualfileio:stream:CannotFindLocation", ...
                filename, S.Parent));
        else
            throwAsCaller(ME);
        end
    end
end

function [filename, fileType, nvStruct] = commonWriteStructValidation(S, filename, varargin)
% Validate order of required arguments
    import matlab.io.internal.struct.write.validateRequiredArgumentOrder
    validateRequiredArgumentOrder(S, filename);

    % Check that a valid filename for writing has been passed in.
    import matlab.io.internal.struct.write.validateFilename;
    filename = validateFilename(filename);

    % Input parsing and validity checking.
    import matlab.io.internal.struct.write.parseWriteStructNVPairs;
    [nvStruct, fileType] = parseWriteStructNVPairs(filename, varargin{:});
end

function writeStructXML(S, filename, nvStruct)
% Validate input struct.
    S = matlab.io.xml.internal.write.validateStruct(S, nvStruct.AttributeSuffix);

    matlab.io.xml.internal.write.builtin.writestruct_xx(S, filename, nvStruct);
end

function writeStructJSON(S, filename, nvStruct)
    % Validate JSON struct.
    S = matlab.io.json.internal.write.validateJSONStruct(S);

    % Call into the JSON writestruct builtin.
    matlab.io.json.internal.write_struct(S, filename, nvStruct);
end
