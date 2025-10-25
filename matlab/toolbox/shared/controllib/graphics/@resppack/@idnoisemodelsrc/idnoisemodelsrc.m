function this = idnoisemodelsrc(model,varargin)
%LTISOURCE  Constructor for @idnoisemodelsrc class

%   Copyright 1986-2011 The MathWorks, Inc.

% Create class instance
this = resppack.idnoisemodelsrc;

% Initialize attributes
this.Model = model;

% Add listeners
addlisteners(this)

% Set additional parameters in varargin
if ~isempty(varargin)
   set(this,varargin{:});
end

