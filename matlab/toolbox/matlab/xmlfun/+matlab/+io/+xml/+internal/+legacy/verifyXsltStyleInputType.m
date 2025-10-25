function verifyXsltStyleInputType(style)
    if isjava(style)
        if ~isSupportedJavaType(style)
            error(message("MATLAB:xslt:UnsupportedStyleInput"));
        end
    elseif ~isstring(style) && ~ischar(style)
        error(message("MATLAB:xslt:UnsupportedStyleInput"));
    end
end


function tf = isSupportedJavaType(source)
    tf = false;
    types = ["javax.xml.transform.Transformer", "org.w3c.dom.Node",...
        "javax.xml.transform.Source", "java.io.File", "java.lang.String",...
        "org.xml.sax.InputSource", "java.io.InputStream", "java.io.Reader"];
    for ii = 1:numel(types)
        if isa(source, types(ii))
            tf = true;
            break;
        end
    end
end

% Copyright 2024 The MathWorks, Inc.