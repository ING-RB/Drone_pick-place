function [rpath, localpath, istemp] = wsdlread(url,webOptions)
%wsdlread Return local path to a WSDL file
%
%   [RPATH, LOCALPATH, ISTEMP] = WSDLREAD(URL,WEBOPTIONS) reads the WSDL from URL.  
%
%   URL may be a file path or web address.  Currently file:// protocol not supported.
%
%   WEBOPTIONS is either empty or a weboptions structure to be passed into webread.
%   Ignored if URL is a local file.
%
%   RPATH is what we should pass into the WSDL reader. It is the absolute path
%   of a local file containing the contents of the URL. If URL is a local file
%   whose path is not a UNC path, this is the full path of that file; otherwise
%   it is the full path of a temporary file into which the URL was copied.
%
%   LOCALPATH is what wsdl2java accepts for the path. It the same as either
%   RPATH or URL. It is the same as RPATH if RPATH is a temporary file, or if
%   URL is a local file specified by a UNC path on Windows. It is the same as
%   URL if URL is a local path (relative or absolute) that is not a UNC path on
%   Windows. The purpose of LOCALPATH is to prevent passing in a UNC path to 
%   wsdl2java.
%
%   ISTEMP is true if RPATH is a temporary file.  Caller should delete RPATH when
%   no longer needed.

% Copyright 2014-2018 The MathWorks, Inc.
protocols = {'http://', 'https://'};
index = find(url == ':', 1);
protocol = url(1:index + min(length(url)-index, 2));

if any(strcmp(protocol, protocols))
    % if http or https, copy into temp file
    % localpath is same as rpath
    if isempty(webOptions)
        rpath = websave(tempname,url);
    else
        rpath = websave(tempname,url,webOptions);
    end
    istemp = true;
    localpath = rpath;
else
    if strcmp(protocol, 'file://')
        error(message('MATLAB:webservices:FileProtocolNotAccepted'));
    end
    if ispc && (strcmp(url(1:2),'//') || strcmp(url(1:2), '\\'))
        % if UNC path, copy to temp file also
        % localpath same as full path of temp file
        rpath = tempname;
        copyfile(url,rpath);
        istemp = true;
        localpath = rpath;
    else
        % If local non-UNC path, localpath is the input path, so this keeps the path
        % relative if it was originally relative
        localpath = url;
        istemp = false;
        if java.io.File(url).isAbsolute
            rpath = url;
        else
            rpath = fullfile(pwd,url);
        end
    end
end
    
        
    