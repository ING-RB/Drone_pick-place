%insertBefore Insert a node into another node
%    node = insertBefore(thisNode,newChild,refChild) inserts newChild
%    before refChild. If refChild is empty, insert newChild at the end
%    of the list of this node's children. If newChild is a DocumentFragment
%    node, the fragment's children are inserted before the reference node
%    in the same order as they appear in the fragment. If newNode already
%    exists in the document tree, it is removed before being reinserted.
%
%    Note: if refNode is a node that has never been appended or inserted
%    into the the document tree, it is treated as an empty object, causing
%    newNode to be inserted at the end of this node's list of children.
%
%    See also matlab.io.xml.dom.Node.appendChild, 
%    matlab.io.xml.dom.Node.removeChild

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.