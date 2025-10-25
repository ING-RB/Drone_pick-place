function [output, status] = writeFromFtpUrl(ftpUrl, outputFileLocation, varargin)
% WRITEFROMFTPURL Reads the contents of a ftp URL.
% This internal function is a urlwrite replacement for use with ftp URLs.
% For MathWorks use only.
% This function requires the user to have write access to their TEMPDIR. 
%
% OUTPUT = WRITEFROMFTPURL('FTPURL', 'OUTPUTFILELOCATION') copies over the
% contents of the FTPURL into the file specified by OUTPUTFILELOCATION. User should 
% have write access to the file at OUTPUTFILELOCATION.
%
% OUTPUT = WRITEFROMFTPURL(..., 'Username', 'uname', 'Password', 'passwd') 
% uses the username and password provided to establish an ftp connection to
% the server.
%
% [OUTPUT, STATUS] = WRITEFROMFTPURL(...) catches any errors and returns 1
% if the contents are read successfully and 0 otherwise.
%
%
% Examples:
% output = matlab.internal.writeFromFtpUrl('ftp://ftp.ncbi.nih.gov/pub/taxonomy/Ccode_dump.txt', 'dump.txt');
% [output, status] = matlab.internal.writeFromFtpUrl('ftp://ftp.ncbi.nih.gov/pub/taxonomy/Ccode_dump.txt', 'dump.txt');
% See Also: matlab.internal.readFromFtpUrl


% Copyright 2020 The MathWorks, Inc.

    fcn = @convertStringsToChars;
    if nargin > 1
        [varargin{:}] = fcn(varargin{:});
    end
    inputs = parseInputs(fcn(ftpUrl), fcn(outputFileLocation), varargin);
    output = '';
    status = 0;
    catchErrors = catchFcnErrors(nargout);
    isFtp = checkProtocol(inputs.Url);
    if(~isFtp && ~catchErrors)
        error(message('MATLAB:urlwrite:InvalidUrl'));
    elseif ~(isFtp)
        return;
    end
    
    try
        uri = matlab.net.URI(inputs.Url);
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
        if ~isempty(inputs.Username)
            ftpObj = ftp(server, inputs.Username, inputs.Password);
        else
            ftpObj = ftp(server);
        end
        res = ftpObj.mget(path);
        ftpObj.close();
        [status, msg, msgID] = copyfile(res{1}, inputs.OutputFile);
        error(msgID, '%s', msg);
        deleteTempDir(pd, dirname);
        status = 1;
        output = getFullPath(inputs.OutputFile);
    catch ex
        deleteTempDir(pd, dirname);
        if ~catchErrors
            rethrow(ex);
        end
    end
end


function inputs = parseInputs(fileUrl, outputFileLocation, args)
    parser = inputParser;
    parser.addRequired('Url',           @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.addRequired('OutputFile',    @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.addParameter('Username', '', @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.addParameter('Password', '', @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
    parser.parse(fileUrl, outputFileLocation, args{:});
    inputs = parser.Results;
end

function result = catchFcnErrors(in)
    result = (in == 2);
end

function isFtp = checkProtocol(url)
    uri = matlab.net.URI(url);
    isFtp = ~isempty(uri.Scheme) && (uri.Scheme == "ftp");
end

function fullPath = getFullPath(location)
    fid = fopen(location);
    fullPath = fopen(fid);
    fclose(fid);
end

function deleteTempDir(currDir, tmpDir)
    cd(currDir);
    if(exist(tmpDir, 'dir'))
        rmdir(tmpDir, 's');
    end
end
