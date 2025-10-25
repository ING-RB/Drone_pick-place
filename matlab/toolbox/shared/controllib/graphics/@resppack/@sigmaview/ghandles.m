function h = ghandles(this)
% Returns a 3-D array of handles of graphical objects associated
% with a sigmaview object.

%  Copyright 1986-2021 The MathWorks, Inc.
h = cat(1,this.Curves,this.PosArrows,this.NegArrows,this.NyquistLine);
h = reshape(h,[1 1 numel(h)]);
