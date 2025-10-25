function [output, status] = readFromFtpUrl(ftpUrl, varargin)
% READFROMFTPURL Reads the contents of a ftp URL.
% This internal function is a urlread replacement for use with ftp URLs.
% For MathWorks use only.
% This function requires the user to have write access to TEMPDIR 
%
% OUTPUT = READFROMFTPURL('FTPURL') reads the contents of the FTPURL
% into a character array.
%
% OUTPUT = READFROMFTPURL(..., 'Charset', 'UTF-8') uses the character set
% provided to convert the file contents. If not specified, uses the default
% character encoding of the file.
%
% OUTPUT = READFROMFTPURL(..., 'Username', 'uname', 'Password', 'passwd') 
% uses the username and password provided to establish an ftp connection to
% the server.
%
% [OUTPUT, STATUS] = READFROMFTPURL(...) catches any errors and returns 1
% if the contents are read successfully and 0 otherwise.
%
%
% Examples:
% output = matlab.internal.readFromFtpUrl('ftp://ftp.ncbi.nih.gov/pub/taxonomy/Ccode_dump.txt');
% [output, status] = matlab.internal.readFromFtpUrl('ftp://ftp.ncbi.nih.gov/pub/taxonomy/Ccode_dump.txt');
% See Also: matlab.internal.writeFromFtpUrl


% Copyright 2020 The MathWorks, Inc.

    fcn = @convertStringsToChars;
    if nargin > 1
        [varargin{:}] = fcn(varargin{:});
    end
    inputs = parseInputs(fcn(ftpUrl), varargin);
    output = '';
    status = 0;
    catchErrors = catchFcnErrors(nargout);
    isFtp = checkProtocol(inputs.url);
    if(~isFtp && ~catchErrors)
        error(message('MATLAB:urlread:InvalidUrl'));
    elseif ~(isFtp)
        return;
    end
    try
        uri = matlab.net.URI(inputs.url);
        host = uri.Host;
        port = uri.Port;
        if ~isempty(port)
            server = strcat(host, ":", num2str(port));
        else
            server = host;
        end
        path = uri.EncodedPath;
        dirname = tempname;
        pd = pwd;
        mkdir(dirname);
        cd(dirname);
        if(~isempty(inputs.Username))
            ftpObj = ftp(server, inputs.Username, inputs.Password);
        else
            ftpObj = ftp(server);
        end
        res = ftpObj.mget(path);
        ftpObj.close();
        output = readFile(res{1}, inputs.Charset);
        deleteTempDir(pd, dirname);
        status = 1;
    catch ex
        deleteTempDir(pd, dirname);
        if ~catchErrors
            rethrow(ex);
        end
    end    
end

function inputs = parseInputs(fileUrl, args)
    parser = inputParser;
    parser.addRequired('url',           @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.addParameter('Charset',  '', @(x) validateattributes(x, {'char'}, {'scalartext'}));
    parser.addParameter('Username', '', @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.addParameter('Password', '', @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.parse(fileUrl, args{:});
    inputs = parser.Results;
end

function result = catchFcnErrors(in)
    result = (in == 2);
end

function isFtp = checkProtocol(url)
    uri = matlab.net.URI(url);
    isFtp = ~isempty(uri.Scheme) && (uri.Scheme == "ftp");
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

function deleteTempDir(currDir, tmpDir)
    cd(currDir);
    if(exist(tmpDir, 'dir'))
        rmdir(tmpDir, 's');
    end
end
