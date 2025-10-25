%replaceChild Replace a child of a node
%    child = replaceChild(thisNode,oldChild,newChild) replaces oldChild with 
%    newChild in thisNode and returns newChild. If newChild is a 
%    DocumentFragment object, oldChild is replaced by all of the 
%    DocumentFragment object's children, which are inserted in the
%    same order. If the newChild is already in the document tree, it is 
%    first removed from the document.
%
%    See also matlab.io.xml.dom.Node.appendChild, 
%    matlab.io.xml.dom.Node.removeChild

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.