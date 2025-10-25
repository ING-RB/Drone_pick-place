function B = isbetween(A,LB,UB,varargin)
% Syntax:
%     TF = isbetween(A,LB,UB)
%     TF = isbetween(A,LB,UB,intervalType)
%     TF = isbetween(___,Name=Value)
%
%     Name-Value Arguments for tabular inputs:
%         DataVariables
%         OutputFormat
%
% For more information, see documentation

%   Copyright 2024 The MathWorks, Inc.

outputFormatAllowed = true;
[convertedA,LB,UB,datavariables,AisTabular,tabularBounds,intervalType,outputIsLogical] = matlab.internal.math.parseIsBetweenInput(A,LB,UB,outputFormatAllowed,varargin{:});
B = matlab.internal.math.isbetweenInternal(A,convertedA,LB,UB,datavariables,AisTabular,tabularBounds,intervalType,outputIsLogical,outputFormatAllowed);




