function Text = appendMATLABCode(Text,Variable,VariableName,Comment)

% Utility function to add MATLAB Code for Code Generation
% Author(s): Suat Gumussoy 25-Mar-2014

% Copyright 2014 The MathWorks, Inc.

% TEXT is a vector of char cell array where each line is generated MATLAB code.
% VARIABLE is the data whose content will be displayed. If Variable is char,
% and the first letter is % or VariableName is empty, it is considered as
% one line comment. Otherwise char type is considered as string data.
% VARIABLENAME is char variable name where the data of VARIABLE is assigned.
% COMMENT is the char comment for the generated MATLAB code. When the data is
% longer than one line, comment is put on top by default. If it is one line
% long, comment is put next to the end of the line.

% Variable can be 'cell', 'tf', 'zpk', 'ss', 'double', 'char' and 'string'

if nargin<3
    VariableName = '';
end
if nargin<4
    Comment = {};
end

%% get data in variable
if isstring(Variable)
   Variable = char(Variable);
end
switch class(Variable)
    case 'cell'
        CellString = controllib.internal.codegen.createExpressionForCellString(Variable);
    case {'tf','zpk','ss'}
        CellString = {[controllib.internal.codegen.createExpressionForTFModel(Variable) ';']};      
    case 'double'
        CellString = {[controllib.internal.codegen.doubleToString(Variable) ';']};
    case 'logical'
        if Variable
            CellString = {['true' ';']};
        else
            CellString = {['false' ';']};
        end
    case 'char'
        if Variable(1)=='%' || isempty(VariableName) % Variable is one-line comment or string as is (without assignment)
           CellString = {Variable}; 
        else
            CellString = {['''' Variable '''' ';']};
        end
end

%% assign the data to variable with variablename
CellString = controllib.internal.codegen.createExpressionWithVariableName(CellString,VariableName);

%% add comment
if ~isempty(Comment)
    if length(CellString)>1 % comment on top
        Comment =  ['% ' Comment];
        CellString = [{Comment};CellString];
    else % comment on side in one line
        Comment = [' % ' Comment];
        CellString = {[CellString{1} Comment]};
    end
end

%% append to the text
Text = [Text;CellString];