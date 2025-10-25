function boo = isvisible(this)
%ISVISIBLE  Determines effective visibility of @view object.

%  Copyright 1986-2004 The MathWorks, Inc.
boo = strcmp(get(this,'Visible'),'on');
if ~isempty(this(1).Parent)
   boo = boo & isvisible(this(1).Parent);
end