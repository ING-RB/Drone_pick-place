function metadata = findExample(arg)

% Copyright 2017-2023 The MathWorks, Inc.

% By component/main or component-main.
match = regexp(arg,'^(\w+)[/-](\w+)$','tokens','once');
if isempty(match)
    error("MATLAB:examples:InvalidArgument", "Invalid argument - " + arg)
end

component = match{1};
source = match{2};

examplesXml = matlab.internal.examples.findExamplesXml(component,arg);

expression = "/demos/demoitem[source/text()='" + source + "']/metadata/text()";
nodeList = evaluate(matlab.io.xml.xpath.Evaluator, expression, examplesXml, matlab.io.xml.xpath.EvalResultType.NodeSet);

if length(nodeList) <1
    error(message("MATLAB:examples:InvalidExample",arg));
end

metadata = nodeList(1).getTextContent;
id = [component '-' metadata];
metadata = matlab.internal.examples.readMetadata(id, examplesXml);
metadata.foundBy = convertStringsToChars(arg);

end

