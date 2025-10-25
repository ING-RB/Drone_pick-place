function cinclude(varargin)
%CODER.CINCLUDE Include a specified header file in generated code.
%
%  coder.cinclude('HDR') includes the C header HDR in generated code. The 
%  #include statement uses double quotes and appears only in the C/C++ file
%  generated for the MATLAB code that contains the coder.cinclude call.
%
%  coder.cinclude('<HDR>') includes the C header HDR in generated code. The
%  #include statement uses angle brackets and appears only in the C/C++ file
%  generated for the MATLAB code that contains the coder.cinclude call.
%
%  coder.cinclude('HDR', 'InAllSourceFiles', true) includes the C header 
%  HDR in generated code. The #include statement uses double quotes and 
%  appears once in every C/C++ file generated from the MATLAB source code.
%
%  coder.cinclude('<HDR>', 'InAllSourceFiles', true) includes the C header 
%  HDR in generated code. The #include statement uses angle brackets and 
%  appears once in every C/C++ file generated from the MATLAB source code.
%
%  For example, to include the header file myhdr.h in the generated code:
%
%    coder.cinclude('myhdr.h');
%  or
%    coder.cinclude('myhdr.h','InAllSourceFiles', true);
%
%  See also coder.ceval, coder.target.
%
%  This is a code generation function. In MATLAB, it is ignored.

%   Copyright 2006-2019 The MathWorks, Inc.
