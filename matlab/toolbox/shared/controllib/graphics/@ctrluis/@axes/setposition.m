function setposition(this,varargin)
%SETPOSITION   Sets axes group position.

%   Copyright 1986-2009 The MathWorks, Inc.
set(this.Axes2d,'Position',this.Position)
messagepanepos(this)
