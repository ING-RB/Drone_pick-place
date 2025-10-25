function output = transform(source, style, destination, displayWeb)
    arguments
        source(1, 1) string 
        style(1, 1) string
        destination(1, 1) string {mustBeNonmissing}
        displayWeb(1, 1) logical = false
    end

    errorIfMissingOrZeroLengthText(source, "source");
    errorIfMissingOrZeroLengthText(style, "style")

    sourceLocalFile = matlab.io.xml.internal.xslt.makeLocalFile(source);
    styleLocalFile = matlab.io.xml.internal.xslt.makeLocalFile(style);

    sourceObj = matlab.io.xml.transform.SourceFile(sourceLocalFile.LocalName);
    styleObj = matlab.io.xml.transform.StylesheetSourceFile(styleLocalFile.LocalName);
    resultObj = matlab.io.xml.internal.xslt.createTransformResult(destination);

    transformer = matlab.io.xml.transform.Transformer();
    transform(transformer, sourceObj, styleObj, resultObj.Result);

    if displayWeb
        web(resultObj.URL);
    end

    output = char(resultObj.Output);
end

function errorIfMissingOrZeroLengthText(value, argument)
    if ismissing(value) || strlength(value) == 0
        msg = message("MATLAB:io:common:arguments:ZeroLengthText", argument);
        errid = "MATLAB:xmlstringinput:EmptyFilename";
        exception = MException(errid, msg.string());
        throw(exception);
    end
end

% Copyright 2024 The MathWorks, Inc.
