function htmlOut = mlintrpt(~,~,~)
%MLINTRPT mlint has been removed. Use codeAnalyzer instead.

%   Copyright 1984-2024 The MathWorks, Inc.

htmlOut = getString(message('MATLAB:codetools:reports:Error'));
errorStruct = {};
errorStruct.message = htmlOut;
errorStruct.identifier = "MATLAB:mlintrpt:Error";
error(errorStruct)