function Cellstr = createExpressionWithVariableName(Cellstr,VariableName)
% Utility function to add variable name and equals to the left of the
% expresssion and indents it. It assumes Cellstr is a vector string cell
% array and variable name is added to the first one.

% Copyright 2014 The MathWorks, Inc.

% If CellStrVar is 
% {'a1'; ...
% 'a2'};
% and VariableName is 'A'

% The function makes
% A = {'a1'; ...
%      'a2'};

if ~isempty(VariableName) % add variable name to the first line    
    Cellstr{1,1} = sprintf('%s = %s',VariableName,Cellstr{1,1});  
    Cellstr = controllib.internal.codegen.createExpressionWithIndentation(Cellstr);
end