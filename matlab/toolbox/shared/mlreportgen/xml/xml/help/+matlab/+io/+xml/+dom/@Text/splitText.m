%splitText Splits this text node in two
%    newNode = splitText(thisText,index) splits this text into two text nodes
%    at the specified zero-based index and returns the new node. After
%    the split, this node contains the original text up to the index. The
%    new node contains the original text from the index. If the index
%    equals the length of the original text, the new node is empty. If
%    this node has a parent, the new node is inserted in the parent
%    following this node.
%
%    See also matlab.io.xml.dom.Text.setData

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.