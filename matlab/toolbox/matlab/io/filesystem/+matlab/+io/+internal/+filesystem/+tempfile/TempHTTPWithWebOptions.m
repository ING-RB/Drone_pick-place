classdef TempHTTPWithWebOptions < matlab.io.internal.filesystem.tempfile.TempFile
    % TempFile implementation for HTTP when using weboptions.

    properties
        WebOptions(1,1) weboptions
        OverrideExtension(1,1) string
    end

    methods
        function obj = TempHTTPWithWebOptions(url,opts)
            arguments
                url(1,1) string
                opts(1,1) matlab.io.internal.filesystem.tempfile.TempFileOptions = matlab.io.internal.filesystem.tempfile.TempFileOptions()
            end
            if ~startsWith(url,"http",IgnoreCase=true)
                error(message("MATLAB:io:filesystem:tempfile:MustBeHTTP"))
            end
            obj = obj@matlab.io.internal.filesystem.tempfile.TempFile(url,opts.OriginalName);
            obj.WebOptions = opts.WebOptions;
            obj.OverrideExtension = opts.OverrideExtension;
        end
    end

    methods (Access = protected)
        function doLocalCopy(obj,resolvedname)
            if ~ismissing(obj.OverrideExtension)
                ext = "." + obj.OverrideExtension;
            else
                ext = obj.Extension;
            end
            [~,name,~] = fileparts(obj.Filename);
            if ~(strlength(name) > 0)
                name = matlab.lang.internal.uuid();
            end
            localName = obj.getUniqueLocalName(name + ext);
            try
                obj.LocalName =  websave(localName, resolvedname, obj.WebOptions);
            catch ME
                if matches(ME.identifier,"MATLAB:webservices:HTTP401StatusCodeError")
                    error("MATLAB:virtualfileio:stream:fileNotFound",obj.OriginalName);
                end
            end
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
