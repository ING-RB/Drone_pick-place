%replace Replace placeholder content
%     contentObj = replace(contentPlaceholderObj,content) replaces the
%     content of the contentPlaceholderObj or replaces the
%     contentPlaceholderObj. If the content is a character vector, a string
%     scalar, or a mlreportgen.ppt.Paragraph, it replaces the placeholder
%     content. If the content is a mlreportgen.ppt.Table or a
%     mlreportgen.ppt.Picture object, it replaces the placeholder object.
%
%     replace(contentPlaceholderObj,contents) replaces the placeholder
%     content with multiple pieces of text. The replacement text can be
%     specified as a cell array of character vectors, string scalars,
%     mlreportgen.ppt.Paragraph objects, or any combination of these types.
%
%    See also mlreportgen.ppt.Paragraph, mlreportgen.ppt.Table,
%    mlreportgen.ppt.Picture

%    Copyright 2020 The MathWorks, Inc.
%    Built-in function