function examples = getExamplesBySupportingFile(examplesXml,supportingFile)
%

%   Copyright 2020-2021 The MathWorks, Inc.
        
	expression = "/demos/demoitem[file/text()='" + supportingFile + "' or dir/text()='" + supportingFile + "']/source/text()";
    nodeList = evaluate(matlab.io.xml.xpath.Evaluator, expression, examplesXml, matlab.io.xml.xpath.EvalResultType.NodeSet);
    
    L = length(nodeList);
    examples = cell(L,1);
    if L == 0        
        return;
    end
    for n = 1:L
        examples{n,1} = nodeList(n).getTextContent;
    end
end
