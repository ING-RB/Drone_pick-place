%importHonorLineBreaks Create markup that honors line feeds
%  node = importHonorLineBreaks(doc,theString) converts theString into a
%  DocBook node that honors line feeds. The doc argument is an instance of
%  matlab.io.xml.dom.Document class. The theString argument specifies the
%  content that needs to be converted. It can be specified as a character
%  vector or string scalar. If theString contains line feeds, this method
%  returns a DocBook simplelist where each item is a token in the input
%  string. If theString argument is not empty and does not contain line
%  feeds, this method returns a Text node containing the content. If
%  theString is empty, this method returns an empty DocumentFragment node.
%
%   See also matlab.io.xml.dom.Document, matlab.io.xml.dom.Text,
%   matlab.io.xml.dom.DocumentFragment,
%   https://tdg.docbook.org/tdg/4.5/simplelist.html

% Copyright 2021 MathWorks, Inc.