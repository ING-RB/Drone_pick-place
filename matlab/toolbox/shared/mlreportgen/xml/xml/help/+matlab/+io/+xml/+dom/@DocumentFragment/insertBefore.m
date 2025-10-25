%insertBefore Insert a node into a fragment
%    node = insertBefore(thisFragment,newChild,refChild) inserts newChild
%    before refChild. If refChild is empty, insert newChild at the end
%    of the list of this fragment's children. If newChild is a DocumentFragment
%    node, the fragment's children are inserted before the reference node
%    in the same order as they appear in the fragment. If newChild already
%    exists in the fragment, it is removed before being reinserted.
%
%    Note: if refChild is a node that has never been appended or inserted
%    into the fragment, it is treated as an empty object, causing
%    newChild to be inserted at the end of this fragment's list of children.
%
%    See also matlab.io.xml.dom.DocumentFragment.appendChild, 
%    matlab.io.xml.dom.DocumentFragment.removeChild

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.