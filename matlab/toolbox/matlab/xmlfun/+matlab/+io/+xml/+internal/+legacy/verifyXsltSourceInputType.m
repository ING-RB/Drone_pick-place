function verifyXsltSourceInputType(source)
    if isjava(source)
        if ~isSupportedJavaType(source)
            error(message("MATLAB:xslt:UnsupportedSourceInput"));
        end
    elseif ~isstring(source) && ~ischar(source)
        error(message("MATLAB:xslt:UnsupportedSourceInput"));
    end
end


function tf = isSupportedJavaType(source)
    tf = false;
    types = ["org.w3c.dom.Node", "javax.xml.transform.Source",...
        "java.io.File", "java.lang.String", "org.xml.sax.InputSource",...
        "java.io.InputStream", "java.io.Reader"];

    for ii = 1:numel(types)
        if isa(source, types(ii))
            tf = true;
            break;
        end
    end
end

% Copyright 2024 The MathWorks, Inc.