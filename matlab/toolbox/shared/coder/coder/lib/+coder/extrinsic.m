function extrinsic(varargin)
%CODER.EXTRINSIC Call the function in MATLAB rather than generating
%code for it.
% 
%   CODER.EXTRINSIC('FCN') Declares the function FCN to be extrinsic.
% 
%   CODER.EXTRINSIC('FCN1',...,'FCNn') Declares the functions FCN1
%   through FCNn to be extrinsic.
% 
%   CODER.EXTRINSIC('-sync:on', 'FCN1',...,'FCNn') causes all global
%   variables to be synchronized with the MATLAB global workspace whenever
%   extrinsic functions FCN1 .. FCNn are called.
% 
%   CODER.EXTRINSIC('-sync:off', 'FCN1',...,'FCNn') disables global
%   variable synchronization for functions, FCN1 ... FCNn.
% 
%   When running generated code in the MATLAB environment, calls to
%   extrinsic functions transfer control from the generated code to MATLAB.
%
%   When generating standalone code, extrinsic function calls are ignored.
%
%   This is a code generation function.  It has no effect in MATLAB.

%   Copyright 2006-2019 The MathWorks, Inc.

