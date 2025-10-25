function setposition(this,varargin)
%SETPOSITION   Sets axes group position.

%   Author(s): P. Gahinet
%   Copyright 1986-2009 The MathWorks, Inc.

% Default implementation: delegate to @plotarray object
this.Axes.setposition(this.Position);
messagepanepos(this)