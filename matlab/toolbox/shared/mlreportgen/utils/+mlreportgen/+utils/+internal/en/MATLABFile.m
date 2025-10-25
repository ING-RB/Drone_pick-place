% MATLABFile Convert MATLAB file to a syntax-colored DOM object.
% domObj = MATLABFile(filePath) converts the MATLAB file at filePath to
% a syntax-colored DOM object that you can add to a DOM document or
% document part.
%
% Example
%
% % file: gensyntaxcolor.m
% import mlreportgen.dom.*;
% % Create document
% d = Document('SyntaxColor','docx');
% coloredCode = mlreportgen.utils.internal.MATLABFile(which('gensyntaxcolor.m'));
% append(d,coloredCode);
% close(d);
% rptview(d.OutputPath);

 
%   Copyright 2018-2020 MathWorks, Inc.

