function this = idnlmodelsource(model,varargin)
%LTISOURCE  Constructor for @ltisource class

%  Author(s): Rajiv Singh
%   Copyright 2010 The MathWorks, Inc.

% Create class instance
this = resppack.idnlmodelsource;

% Initialize attributes
this.Model = model;

%{
% Initialize cache
Nresp = getsize(this,3);
this.Cache = struct(...
   'Stable',cell(Nresp,1),...
   'MStable',cell(Nresp,1),...
   'DCGain',cell(Nresp,1),...
   'Margins',cell(Nresp,1));
%}

% Add listeners
addlisteners(this)

% Set additional parameters in varargin
if ~isempty(varargin)
   set(this,varargin{:});
end
