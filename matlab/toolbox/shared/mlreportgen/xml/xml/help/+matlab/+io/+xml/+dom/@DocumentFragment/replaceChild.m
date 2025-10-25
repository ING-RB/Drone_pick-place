%replaceChild Replace a fragment child
%    child = replaceChild(thisFragment,newChild,oldChild) replaces oldChild
%    with newChild in this fragment and returns newChild. If newChild is a
%    DocumentFragment object, oldChild is replaced by all of the
%    DocumentFragment object's children, which are inserted in the same
%    order. If the newChild is already in the fragment, it is first removed
%    from the document.
%
%    See also matlab.io.xml.dom.DocumentFragment.appendChild, 
%    matlab.io.xml.dom.DocumentFragment.removeChild

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.