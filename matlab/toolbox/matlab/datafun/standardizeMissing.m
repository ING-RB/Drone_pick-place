function B = standardizeMissing(A,indicators,varargin)
% Syntax:
%     B = standardizeMissing(A,INDICATORS)
%     B = standardizeMissing(A,INDICATORS,Name=Value)
%
%     Name-Value Arguments:
%         DataVariables
%         ReplaceValues
%
% For more information, see documentation

%   Copyright 2012-2023 The MathWorks, Inc.

if nargin <= 2
    B = matlab.internal.math.ismissingKernel(A,indicators,true);
else
    if ~istabular(A)
        error(message('MATLAB:standardizeMissing:DataVariablesArray'));
    end
    if rem(numel(varargin),2) ~= 0
        error(message('MATLAB:standardizeMissing:NameValuePairs'));
    end
    replace = true;
    dataVars = 1:width(A);
    for i = 1:2:numel(varargin)
        NVidx = matlab.internal.math.checkInputName(varargin{i},{'DataVariables','ReplaceValues'});
        if NVidx(1)
            dataVars = matlab.internal.math.checkDataVariables(A,varargin{i+1},'standardizeMissing');
        elseif NVidx(2)
            replace = matlab.internal.datatypes.validateLogical(varargin{i+1},'ReplaceValues');
        else
            error(message('MATLAB:standardizeMissing:NameValueNames'));
        end
    end
    if replace
        B = matlab.internal.math.ismissingKernel(A,indicators,true,dataVars);
    else
        B = A(:,dataVars);
        dataVars = 1:width(B);
        B = matlab.internal.math.ismissingKernel(B,indicators,true,dataVars);
        B = matlab.internal.math.appendDataVariables(A,B,"standardized");
    end
end