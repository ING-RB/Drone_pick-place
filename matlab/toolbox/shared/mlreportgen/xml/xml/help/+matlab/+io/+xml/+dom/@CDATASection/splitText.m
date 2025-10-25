%splitText Splits this CDATA section into two sections
%    newNode = splitText(thisCDATASection,index) splits this CDATASection
%    into two sections at the specified zero-based index and returns the
%    new section node. After the split, the original section contains the
%    original text up to the index. The new section contains the original
%    text from the index. If the index equals the length of the original
%    section, the new section is empty. If this section has a parent, the
%    new section is inserted in the parent after this section.
%
%    See also matlab.io.xml.dom.CDATASection.setData

%    Copyright 2021 MathWorks, Inc.
%    Built-in function.