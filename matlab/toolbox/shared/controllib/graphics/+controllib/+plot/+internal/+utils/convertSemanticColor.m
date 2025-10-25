function newSemanticColor = convertSemanticColor(semanticColor,state)
arguments
    semanticColor string
    state (1,:) string = "primary"
end

p = digitsPattern(1,2);
colorOrder = double(extract(semanticColor,digitsPattern));
newSemanticColor = controllib.plot.internal.utils.GraphicsColor(colorOrder,state).SemanticName;
end