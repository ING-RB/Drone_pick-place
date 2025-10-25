%importHonorLineBreaksPara Create markup that honors line feeds
%  para = importHonorLineBreaksPara(doc,theString) converts the specified
%  theString content to a DocBook para element if the content is empty or
%  does not contain line feeds. Otherwise, it converts theString to DocBook
%  simplelist element.
%
%   See also
%   mlreportgen.re.internal.db.StringImporter.importHonorLineBreaks,
%   https://tdg.docbook.org/tdg/4.5/para.html

% Copyright 2021 MathWorks, Inc.