function lines = readlines(filename,varargin)
%READLINES reads the lines of a plain text file as a string array
%   LINES = READLINES(FILENAME)
%   LINES = READLINES(___, Name, Value)
%
%   FILENAME can be one of these:
%
%       - For local files, FILENAME can be an absolute path that contains
%         a filename and file extension. FILENAME can also be a relative
%         path to the current directory or to a directory on the MATLAB
%         path. For example, to import a file on the MATLAB path:
%
%            lines = readlines("readlines.m");
%
%       - For files from an Internet URL or stored at a remote location,
%         FILENAME must be a full path using a Uniform Resource Locator
%         (URL). For example, to import a remote file from Amazon S3,
%         specify the full URL for the file:
%
%            lines = readlines("s3://bucketname/path_to_file/readlines.m");
%
%         For more information on accessing remote data, see "Work with
%         Remote Data" in the documentation.
%
%   Name-Value Pairs:
%   --------------------------------------------------------
%
%  "LineEnding"     - The line ending for the file.
%                     Default: ["\n" "\r" "\r\n"]
%
%  "Whitespace"     - Characters to treat as whitespace.
%                     Default: [" \b\t"]
%
%  "WhitespaceRule" - What to do with whitespace surrounding the lines.
%                     - "preserve"     - Include both leading and trailing
%                                        whitespace. (default)
%                     - "trim"         - Remove both leading and trailing
%                                        whitespace.
%                     - "trimleading"  - Remove only the leading whitespace.
%                     - "trimtrailing" - Remove only the trailing whitespace.
%
%
%  "EmptyLineRule"  - What to do with empty lines in the file. Can have one
%                     of the values:
%                     - "read"  - Include blank lines in the output (default)
%                     - "skip"  - Do not include blank lines in the output
%                     - "error" - Issue an error if an empty line is found.
%
%  "Encoding"       - The character encoding scheme associated with
%                     the file. If not specified, the encoding is detected
%                     from the file. If the "Encoding" parameter value is
%                     "system", then readlines uses your system's default
%                     encoding.
%
%  "WebOptions"     - HTTP(s) request options, specified as a 
%                     weboptions object. 
%
%  Example, read the lines of this file:
%
%    lines = readlines("readlines.m");
%
%  Note: READLINES interprets all files as plain-text. 
%
%  See also writelines, fileread, readtable, readmatrix, readcell 

% Copyright 2020-2022 The MathWorks, Inc.

    try
        func = matlab.io.internal.functions.FunctionStore.getFunctionByName("readlines");
        lines = func.validateAndExecute(filename,varargin{:});
    catch ME
        throw(ME);
    end
end
