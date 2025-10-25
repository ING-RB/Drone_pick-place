%mlreportgen.re.internal.db.StringImporter Create a DocBook simplelist element
%    This class comprises static methods that convert a character vector or
%    string scalar into a DocBook node that honors line feeds.
%
%    StringImporter methods:
%      importHonorLineBreaks        - Create simplelist from textual content
%      importHonorLineBreaksNull    - Return [] from empty textual content
%      importHonorLineBreaksPara    - Return empty para from empty textual content
%
%    See also mlreportgen.re.internal.db.GraphicMaker

% Copyright 2021 MathWorks, Inc.