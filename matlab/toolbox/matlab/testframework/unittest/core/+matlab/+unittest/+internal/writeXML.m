function writeXML(fileName,documentNode)
% MUTF internal API for writing to .XML files.
    
% Copyright 2020 The MathWorks, Inc.

writer = matlab.io.xml.dom.DOMWriter;
writer.Configuration.FormatPrettyPrint = true;
writeToURI(writer,documentNode,fileName);
end

