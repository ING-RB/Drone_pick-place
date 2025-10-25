function this = ltisource(model,varargin)
%LTISOURCE  Constructor for @ltisource class

%  Author(s): Bora Eryilmaz
%   Copyright 1986-2015 The MathWorks, Inc.

% Create class instance
this = resppack.ltisource;

% Initialize attributes

   this.Model = model;


% Initialize cache
Nresp = getNumResp(this);
this.Cache = struct(...
   'Stable',cell(Nresp,1),...
   'MStable',cell(Nresp,1),...
   'DCGain',cell(Nresp,1),...
   'Margins',cell(Nresp,1));

% Add listeners
addlisteners(this)

% Set additional parameters in varargin
if ~isempty(varargin)
   set(this,varargin{:});
end

