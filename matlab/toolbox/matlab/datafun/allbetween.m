function tf = allbetween(A,LB,UB,varargin)
% Syntax:
%     TF = allbetween(A,LB,UB)
%     TF = allbetween(A,LB,UB,intervalType)
%     TF = allbetween(___,Name=Value)
%
%     Name-Value Arguments for tabular inputs:
%         DataVariables
%
% For more information, see documentation

%   Copyright 2024 The MathWorks, Inc.

outputFormatAllowed = false;
[convertedA,LB,UB,datavariables,AisTabular,tabularBounds,intervalType,outputIsLogical] = matlab.internal.math.parseIsBetweenInput(A,LB,UB,outputFormatAllowed,varargin{:});
if isduration(A) || isduration(LB) || isduration(UB) || isdatetime(A) || isdatetime(LB) || isdatetime(UB) 
    tf = all(isbetween(A,LB,UB,varargin{:}),'all');
else
    tf = all(matlab.internal.math.isbetweenInternal(A,convertedA,LB,UB,datavariables,AisTabular,tabularBounds,intervalType,outputIsLogical,outputFormatAllowed),'all');
end
