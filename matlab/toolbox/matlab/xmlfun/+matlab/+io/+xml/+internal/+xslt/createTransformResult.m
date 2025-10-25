function result = createTransformResult(dest)
%CREATETRANSFORMRESULT Returns a StringTransformResult if dest is
% "-tostring". Otherwise returns a FileTransformResult.


% Copyright 2024 The MathWorks, Inc.

    arguments
        dest(1, 1) string {mustBeNonmissing}
    end

    if dest == "-tostring"
        result = matlab.io.xml.internal.xslt.StringTransformResult();
    else
        result = matlab.io.xml.internal.xslt.FileTransformResult(dest);
    end
end