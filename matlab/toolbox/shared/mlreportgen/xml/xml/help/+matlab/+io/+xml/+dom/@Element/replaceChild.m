%replaceChild Replace a child of this element
%    child = replaceChild(thisElem,newChild,oldChild) replaces oldChild
%    with newChild in thisElem and returns newChild. If newChild is a
%    DocumentFragment object, oldChild is replaced by all of the
%    DocumentFragment object's children, which are inserted in the same
%    order. If the newChild is already in the document tree, it is first
%    removed from the document.
%
%    See also matlab.io.xml.dom.Element.appendChild, 
%    matlab.io.xml.dom.Element.removeChild

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.