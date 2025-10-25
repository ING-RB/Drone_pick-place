function [output, status] = writeFromFileUrl(fileUrl, outputFileLocation, varargin)
% WRITEFILEFROMURL Copies the contents of a file URL to the output file.
% This internal function is a urlwrite replacement for use with file URLs.
% For MathWorks use only.
% 
% OUTPUT = WRITEFROMFILEURL('FILEURL', 'OUTPUTFILELOCATION') copies the contents of the FILEURL
% into the file specified by OUTPUTFILELOCATION. User should have write access
% to the file at OUTPUTLOCATION.
%
% [OUTPUT, STATUS] = WRITEFROMFILEURL(...) catches any errors and returns 1
% if the file is copied successfully and 0 otherwise.
%
%
% Examples:
% output = matlab.internal.writeFromFileUrl(['file:///' fullfile(prefdir,'History.xml')],'myhistory.xml');
% [output, status] = matlab.internal.writeFromFileUrl(['file:///' fullfile(prefdir,'History.xml')],'myhistory.xml');
% See Also: matlab.net.readFromFileUrl


% Copyright 2020 The MathWorks, Inc.

    fcn = @convertStringsToChars;
    inputs = parseInputs(fcn(fileUrl), fcn(outputFileLocation), varargin);
    output = '';
    status = 0;
    catchErrors = catchFcnErrors(nargout);
    isFile = checkProtocol(inputs.Url);
    if(~isFile && ~catchErrors)
        error(message('MATLAB:urlwrite:InvalidUrl'));
    elseif ~(isFile)
        return;
    end

    try
        fileUrl = strrep(inputs.Url, filesep, '/');
        [status, msg, msgID] = copyfile(fileUrl, inputs.OutputFile);
        error(msgID, '%s', msg);
        status = 1;
        output = getFullPath(inputs.OutputFile);
    catch ex
        if ~catchErrors
            rethrow(ex);
        end
    end
end

function inputs = parseInputs(fileUrl, outputFileLocation, ~)
    parser = inputParser;
    parser.addRequired('Url',        @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.addRequired('OutputFile', @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.parse(fileUrl, outputFileLocation);
    inputs = parser.Results;
end

function result = catchFcnErrors(in)
    result = (in == 2);
end

function isFile = checkProtocol(url)
    uri = matlab.net.URI(url);
    isFile = ~isempty(uri.Scheme) && (uri.Scheme == "file");
end

function fullPath = getFullPath(location)
    fid = fopen(location);
    fullPath = fopen(fid);
    fclose(fid);
end
