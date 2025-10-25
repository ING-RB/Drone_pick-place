function verifyXsltDestInputType(dest)
    if isjava(dest)
        if ~isSupportedJavaType(dest)
            error(message("MATLAB:xslt:UnsupportedDestInput"));
        end
    elseif ~isstring(dest) && ~ischar(dest)
        error(message("MATLAB:xslt:UnsupportedDestInput"));
    end
end

function tf = isSupportedJavaType(source)
    tf = false;
    types = ["javax.xml.transform.Result", "java.lang.String", ...
            "org.w3c.dom.Node", "org.xml.sax.ContentHandler" ...
            "java.io.File", "java.io.OutputStream", "java.io.Writer"];

    for ii = 1:numel(types)
        if isa(source, types(ii))
            tf = true;
            break;
        end
    end
end

% Copyright 2024 The MathWorks, Inc.