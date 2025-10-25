function varargout = xslt(varargin)
    import matlab.io.xml.internal.legacy.useLegacyXslt
    import matlab.io.xml.internal.legacy.verifyJavaEnabled
    import matlab.io.xml.internal.legacy.verifyXsltDestInputType
    import matlab.io.xml.internal.legacy.verifyXsltSourceInputType
    import matlab.io.xml.internal.legacy.verifyXsltStyleInputType
    import matlab.io.xml.internal.xslt.transform
    import matlab.io.xml.internal.xslt.parseArgs

    nargoutchk(0, 2);
    narginchk(2, 6);

    parsed = parseArgs(varargin{:});

    useLegacy = useLegacyXslt({parsed.source, parsed.style, parsed.dest}, parsed.XMLEngine);

    if useLegacy

        verifyJavaEnabled();

        verifyXsltSourceInputType(parsed.source);
        verifyXsltStyleInputType(parsed.style);

        args = {parsed.source parsed.style};

        if ~isequal(parsed.dest, "")
            verifyXsltDestInputType(parsed.dest)
            args{end + 1} = parsed.dest;
        end

        if parsed.displayWeb
            args{end + 1} = "-web";
        end

        [output, transformer] = matlab.io.xml.internal.legacy.xslt(args{:});
        varargout = {output transformer};
    elseif nargout == 2
        error(message("MATLAB:xslt:TransformerOutputNotSupported"));
    else
        output = transform(parsed.source, parsed.style, parsed.dest, parsed.displayWeb);
        varargout{1} = output;
    end
end

%   Copyright 1984-2024 The MathWorks, Inc.
