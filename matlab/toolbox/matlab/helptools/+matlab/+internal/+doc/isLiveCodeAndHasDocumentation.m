function b = isLiveCodeAndHasDocumentation(topic)
%isLiveCode Checks if the live file contains documentation.
%   isLiveCode(topic) Checks using topic as file path.

%   Copyright 2017-2020 The MathWorks, Inc.
      docXML = matlab.internal.doc.getDocumentationXML(topic);
      b = ~isempty(char(docXML)); 
end
 
