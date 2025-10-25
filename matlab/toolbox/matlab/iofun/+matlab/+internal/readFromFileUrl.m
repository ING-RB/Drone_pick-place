function [output, status] = readFromFileUrl(fileUrl, varargin)
% READFROMFILEURL Reads the contents of a file URL.
% This internal function is a urlread replacement for use with file URLs.
% For MathWorks use only.
%
% OUTPUT = READFROMFILEURL('FILEURL') reads the contents of the FILEURL
% into a character array.
%
% OUTPUT = READFROMFILEURL(..., 'Charset', 'UTF-8') uses the character set
% provided to convert the file contents. If not specified, uses the default
% character encoding of the file.
%
% [OUTPUT, STATUS] = READFROMFILEURL(...) catches any errors and returns 1
% if the contents are read successfully and 0 otherwise.
%
%
% Examples:
% output = matlab.internal.readFromFileUrl(['file:///' fullfile(prefdir,'History.xml')]);
% [output, status] = matlab.internal.readFromFileUrl(['file:///' fullfile(prefdir,'History.xml')]);
% See Also: matlab.internal.writeFromFileUrl


% Copyright 2020 The MathWorks, Inc.

    fcn = @convertStringsToChars;
    if nargin > 1
        [varargin{:}] = fcn(varargin{:});
    end
    inputs = parseInputs(fcn(fileUrl), varargin);
    output = '';
    status = 0;
    catchErrors = catchFcnErrors(nargout);
    isFile = checkProtocol(inputs.url);
    if(~isFile && ~catchErrors)
        error(message('MATLAB:urlread:InvalidUrl'));
    elseif ~(isFile)
        return;
    end

    try
        fileUrl = strrep(inputs.url, filesep, '/');
        output = readFile(fileUrl, inputs.Charset);
        status = 1;
    catch ex
        if ~catchErrors
            rethrow(ex);
        end
    end
end

function inputs = parseInputs(fileUrl, args)
    parser = inputParser;
    parser.addRequired('url',         @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.addParameter('Charset','', @(x) validateattributes(x, {'char'}, {'scalartext'}));
    parser.parse(fileUrl, args{:});
    inputs = parser.Results;
end

function result = catchFcnErrors(in)
    result = (in == 2);
end

function isFile = checkProtocol(url)
    uri = matlab.net.URI(url);
    isFile = ~isempty(uri.Scheme) && (uri.Scheme == "file");
end

function out = readFile(filename, charset)
    if isempty(charset)
        out = fileread(filename);
    else
       fid = fopen(filename, 'r');
       bytes = fread(fid, 'uint8=>uint8');
       fclose(fid);
       out = native2unicode(bytes', charset);
    end
end
