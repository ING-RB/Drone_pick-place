%insertBefore Insert a node into this element
%    node = insertBefore(thisElem,newChild,refChild) inserts newChild
%    before refChild in this element. If refChild is empty, tbis method
%    inserts newChild at the end of the list of this element's children. If
%    newChild is a DocumentFragment node, the fragment's children are
%    inserted before the reference node in the same order as they appear in
%    the fragment. If newChild already exists in the document tree, it is
%    removed before being reinserted.
%
%    Note: if refChild is a node that has never been appended or inserted
%    into the the document tree, it is treated as an empty object, causing
%    newChild to be inserted at the end of this node's list of children.
%
%    See also matlab.io.xml.dom.Element.appendChild, 
%    matlab.io.xml.dom.Element.removeChild

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.