% MATLABCode Convert MATLAB code string to a syntax-colored DOM object.
% domObj = MATLABCode(code) converts the MATLAB code string to a
% syntax-colored DOM object that you can add to a DOM document or document
% part.
%
% Example
%
%   % file: gensyntaxcolor.m
%   import mlreportgen.dom.*;
%   % Create document
%   d = Document('SyntaxColor','docx');
%   code = fileread(which('gensyntaxcolor.m'));
%   coloredCode = mlreportgen.utils.internal.MATLABCode(code);
%   append(d,coloredCode);
%   close(d);
%   rptview(d.OutputPath);

 
    %   Copyright 2018-2023 MathWorks, Inc.

