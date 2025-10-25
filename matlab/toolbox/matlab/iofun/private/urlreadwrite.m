function [output,status] = urlreadwrite(fcn,catchErrors,varargin)
%URLREADWRITE A helper function for URLREAD and URLWRITE.

% Copyright 1984-2020 The MathWorks, Inc.

% Check if Java is present on the machine
javaPresent = isempty(javachk('jvm'));

% Parse inputs.
inputs = parseInputs(fcn,varargin);
urlChar = inputs.url;

% Set default outputs.
output = '';
status = 0;

% Clean the URL for any anomolies
urlChar = cleanUrlChar(urlChar);

import matlab.net.URI;
uri = URI(strrep(urlChar, filesep, '/'), 'literal');
readFcn = strcmpi(fcn, 'urlread');

% If no URL scheme is specified or if the URL scheme is not one of the 
% following ones, return/error
% Allowed URL schemes: file, http, https, ftp
schemes = ["http", "https", "file", "ftp"];
if isempty(uri.Scheme) || ~(any(contains(schemes, uri.Scheme)))
    if ~catchErrors
        error(mm(fcn, 'InvalidUrl'));
    end
    return;
end
if ~readFcn
    inputs.filename = validateFileAccess(inputs.filename);
end

try
    if (uri.Scheme == "file" && readFcn)
        [filepath, name, ext] = fileparts(char(uri));
        if (strcmpi(filepath, 'file:/') || strcmpi(filepath, 'file:\')) % For relative file URLs like 'file:page.htm'
            newUri = [filepath, pwd, filesep, name, ext];
            uri = URI(strrep(newUri, filesep, '/'), 'literal');
        end
        fileUrl = strrep(char(uri), 'file:/', 'file:///');
        output = matlab.internal.readFromFileUrl(fileUrl, 'Charset', inputs.charset);
        status = 1;
    elseif (uri.Scheme == "file" && ~readFcn)
        [filepath, name, ext] = fileparts(char(uri));
        if (strcmpi(filepath, 'file:/') || strcmpi(filepath, 'file:\'))
            newUri = [filepath, pwd, filesep, name, ext];
            uri = URI(strrep(newUri, filesep, '/'), 'literal');
        end
        fileUrl = strrep(char(uri), 'file:/', 'file:///');
        output = matlab.internal.writeFromFileUrl(fileUrl, inputs.filename);
        status = 1;
    elseif (uri.Scheme == "http" || uri.Scheme == "https")
        [output, status] = handleHTTP(fcn, uri, inputs, readFcn, catchErrors);
    elseif (uri.Scheme == "ftp" && readFcn)
        if ~isempty(uri.UserInfo)
            creds = strsplit(uri.UserInfo, ':');
            uname  = creds(1);
            passwd = creds(2);
            output = matlab.internal.readFromFtpUrl(char(uri), 'Charset', inputs.charset,...
                     'Username', char(uname), 'Password', char(passwd));
        else
            output = matlab.internal.readFromFtpUrl(char(uri), 'Charset', inputs.charset);
        end
        status = 1;
    elseif (uri.Scheme == "ftp" && ~readFcn)
        if ~isempty(uri.UserInfo)
            creds = strsplit(uri.UserInfo, ':');
            uname  = creds(1);
            passwd = creds(2);
            output = matlab.internal.writeFromFtpUrl(char(uri), inputs.filename,...
                     'Username', char(uname), 'Password', char(passwd));
        else
            output = matlab.internal.writeFromFtpUrl(char(uri), inputs.filename);
        end
        status = 1;
    end
    
catch ex
    if ~readFcn && isfile(inputs.filename)
        delete(inputs.filename);
    end
    if(javaPresent) % If Java is present, try the workflow with Java
        [output,status] = urlreadwrite_legacy(fcn,catchErrors,varargin{:});
        return;
    elseif ~catchErrors % Do not catch errors and return an exception
        if (strcmpi(ex.identifier, 'MATLAB:fileread:cannotOpenFile') ||...
                strcmpi(ex.identifier, 'MATLAB:FileIO:InvalidFid')   ||...
                strcmpi(ex.identifier, 'MATLAB:fopen:InvalidFileLocation') ||...
                strcmpi(ex.identifier, 'MATLAB:virtualfilesystem:resourceNotFound') ||...
                strcmpi(ex.identifier, 'MATLAB:webservices:FileNotFound'))
            error(mm(fcn, 'FileNotFound'));
        elseif strcmpi(ex.identifier, 'MATLAB:webservices:Timeout')
            error(mm(fcn, 'Timeout'));
        elseif strcmpi(ex.identifier, 'MATLAB:webservices:StatusError')
            error(mm(fcn,'AuthenticationFailed'));
        elseif strcmpi(ex.identifier, 'MATLAB:webservices:HTTP401StatusCodeError')
            error(mm(fcn,'AuthenticationFailed'));
        elseif strcmpi(ex.identifier, 'MATLAB:webservices:UnknownHost')
            msg = ex.message;
            index = strfind(msg, 'http');
            error(mm(fcn,'UnknownHost', msg(index:numel(msg)-1)));
        elseif strcmpi(ex.identifier, 'MATLAB:PostFailed')
            error(mm(fcn,'PostFailed'));
        else
            error(mm(fcn, 'ConnectionFailed'));
        end
    else % Catch errors and Java is not present
        status = 0;
        output = '';
    end
end


end


function m = mm(fcn,id,varargin)
m = message(['MATLAB:' fcn ':' id],varargin{:});
end

function results = parseInputs(fcn,args)
p = inputParser;
p.addRequired('url',@(x)validateattributes(x,{'char'},{'nonempty'}))
if strcmp(fcn,'urlwrite')
    p.addRequired('filename',@(x)validateattributes(x,{'char'},{'nonempty'}))
end
p.addParameter('get',{},@(x)checkpv(fcn,x))
p.addParameter('post',{},@(x)checkpv(fcn,x))
p.addParameter('timeout',[],@isnumeric)
p.addParameter('useragent','',@ischar)
p.addParameter('charset','',@ischar)
p.addParameter('authentication', '', @(x)(ischar(x) && strcmpi(x, 'basic')))
p.addParameter('username', '', @ischar)
p.addParameter('password', '', @ischar)
p.FunctionName = fcn;
p.parse(args{:})
results = p.Results;
end

function checkpv(fcn,params)
if mod(length(params),2) == 1
    error(mm(fcn,'InvalidInput'));
end
end


function cleanUrl = cleanUrlChar(cleanUrl)
% Replace space with %20 for HTTP and HTTPS
protocol = cleanUrl(1:find(cleanUrl == ':', 1) -1);
if (strcmp(protocol, 'http') || strcmp(protocol, 'https')) && ~isempty(strfind(cleanUrl, ' '))
    warning(mm('urlread', 'ReplacingSpaces'));
    cleanUrl = regexprep(cleanUrl, ' ', '%20');
end
end

function filename = validateFileAccess(location)
% Ensure that the file is writeable and return full path name.

% Validate the the file can be opened. This results in a file on the disk.
fid = fopen(location,'w');
if fid == -1
    error(mm('urlwrite','InvalidOutputLocation',location))
end
fclose(fid);

% Use fopen to obtain full path to the file and to translate ~ on Unix.
fid = fopen(location);
filename = fopen(fid);
fclose(fid);

% Remove this file in case an error is issued later.
delete(location)
end
