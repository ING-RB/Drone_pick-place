function exampleDom = getExampleDom(metadataNumber, examplesXml)
%

%   Copyright 2019-2023 The MathWorks, Inc.

	exampleDom = matlab.io.xml.dom.Document();

    expression = "/demos/demoitem[metadata/text()='" + metadataNumber + "']/metadata/text()";
    nodeList = evaluate(matlab.io.xml.xpath.Evaluator, expression, examplesXml, matlab.io.xml.xpath.EvalResultType.NodeSet);
    
    if length(nodeList) == 1
        parentNode = nodeList(1).getParentNode().getParentNode();
        copy = exampleDom.importNode(parentNode, true);
        exampleDom.appendChild(copy);
    else 
        error(message("MATLAB:examples:ExampleNotFound",metadataNumber,examplesXml))
    end
end
