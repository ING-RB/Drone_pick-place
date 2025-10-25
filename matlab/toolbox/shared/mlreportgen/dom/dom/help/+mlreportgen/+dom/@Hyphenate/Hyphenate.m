%mlreportgen.dom.Hyphenate Hyphenate
%   hyph = Hyphenate() enables hyphenation.
%   hyph = Hyphenate(true) enables hyphenation.
%   hyph = Hyphenate(false) disables hyphenation.
%
%   Hyphenate properties:
%       Id    - Id of this object
%       Tag   - Tag of this object
%       Value - Hyphenation status
%
%   Hyphenation is supported for PDF and HTML documents. However, only 
%   Mozilla Firefox is capable of rendering hyphenated documents. See:
%
%   https://developer.mozilla.org/en-US/docs/Web/CSS/hyphens
%
%   Example:
%
%   import mlreportgen.dom.*
%   d = Document('hyph_example','pdf');
%   open(d);
% 
%   h1 = Paragraph('Hyphenate on');
%   h1.Bold = true;
%   append(d,h1);
%   p1 = Paragraph(['pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis ']);
%   p1.Style = [p1.Style {Hyphenate(true)}];
%   append(d,p1);
% 
%   h2 = Paragraph('Hyphenate off');
%   h2.Bold = true;
%   append(d,h2);
%   p2 = Paragraph(['pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis '...
%       'pneumonoultramicroscopicsilicovolcanoconiosis ']);
%   p2.Style = [p2.Style {Hyphenate(false)}];
%   append(d,p2);
% 
%   close(d);
%   rptview(d);
%
%   See also mlreportgen.dom.HAlign

%   Copyright 2020 Mathworks, Inc.
%   Built-in class

%{
properties
     %Value Hyphenation status
     %    True to enable hyphenation.  False to disable hyphenation.
     Value;
end
%}

