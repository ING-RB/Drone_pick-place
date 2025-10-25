function documentNode = readXML(filename)
% MUTF internal API for reading .XML files.
    
% Copyright 2020 The MathWorks, Inc.
documentNode = parseFile(matlab.io.xml.dom.Parser, filename);
end

