function res = targetLang(lang)
%#codegen

%   Copyright 2020-2022 The MathWorks, Inc.

%   CODER.INTERNAL.TARGETLANG(LANG) function returns true/false during code generation 
%   based on ''TargetLang'' and ''Enabled'' properties in config object
%   used for code generation.
%
%   This function at the time of code generation, helps to differentiate 
%   between regions targeted for language-specific code generation.
% 
%   CODER.INTERNAL.TARGETLANG(LANG) returns true in the following cases:
%   1. LANG = 'GPU' and GPU Codegen is enabled.
%   2. LANG = 'CUDA' and GPU Codegen is enabled and it is generating CUDA
%   code.
%   3. LANG = 'OpenCL' and GPU Codegen is enabled and it is generating
%   OpenCL code.
%   4. LANG = 'C++' or 'C' and GPU Codegen is disabled and TargetLang in 
%   cfg object = 'C++' or 'C' respectively.
%
%   This function returns false for all other cases.

narginchk(1,1);
res = false;

if coder.target('MATLAB')
    return;
end
    
coder.allowpcode('plain');
coder.inline('always');
coder.internal.prefer_const(lang);
coder.extrinsic('coder.internal.isCUDACodegen');
coder.extrinsic('coder.internal.isOpenCLCodegen');

lchar = coder.const(convertLangStrToChar(lang));
coder.internal.assert(lchar ~= 'u', 'Coder:common:InvalidTargetLanguage');
ctx = coder.internal.get_eml_option('CodegenBuildContext');

switch lchar
  case 'g'
    res = coder.internal.get_eml_option('EnableGPU');
  case 'c'
    res = coder.const(@coder.internal.isCUDACodegen, ctx);
  case 'o'
    res = coder.const(@coder.internal.isOpenCLCodegen, ctx);
  case {'a', 'b'}
      % TargetLang is not C/C++ if GPU is enabled.
    if coder.const(~isempty(ctx)) && ~coder.internal.get_eml_option('EnableGPU')
        cfgLang = coder.const(feval('getTargetLang', ctx));
        cfgChar = coder.const(convertLangStrToChar(cfgLang));
        if cfgChar == lchar
            res = true;
        end
    end
  otherwise
    coder.internal.error('Coder:common:InvalidTargetLanguage');
end

end

function lchar = convertLangStrToChar(lang)

coder.inline('always');
coder.internal.prefer_const(lang);

GPU = 'g';
CUDA = 'c';
OPENCL = 'o';
C = 'a';
CPP = 'b';
UNKNOWN = 'u';

if strcmpi(lang, 'gpu')
    lchar = GPU;
elseif strcmpi(lang, 'cuda')
    lchar = CUDA;
elseif strcmpi(lang, 'opencl')
    lchar = OPENCL;
elseif strcmpi(lang, 'c')
    lchar = C;
elseif strcmpi(lang, 'c++')
    lchar = CPP;
else
    lchar = UNKNOWN;
end

end
