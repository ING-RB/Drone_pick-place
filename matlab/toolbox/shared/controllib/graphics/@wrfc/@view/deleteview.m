function deleteview(this)
%DELETEVIEW  Deletes @view and associated g-objects.

%  Copyright 1986-2004 The MathWorks, Inc.
for ct = 1:length(this)
  % Delete graphical objects
  h = ghandles(this(ct));
  delete(h(ishandle(h)))
end

% Delete views
delete(this)
