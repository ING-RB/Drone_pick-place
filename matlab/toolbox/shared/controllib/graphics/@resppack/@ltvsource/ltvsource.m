function this = ltvsource(model,varargin)
%LTVSOURCE  Constructor for @ltvsource class

%   Copyright 2022 The MathWorks, Inc.
this = resppack.ltvsource;
this.Model = model;

% Add listeners
addlisteners(this)

% Set additional parameters in varargin
if ~isempty(varargin)
   set(this,varargin{:});
end

