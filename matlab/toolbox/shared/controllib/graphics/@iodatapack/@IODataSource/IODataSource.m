function this = IODataSource(data,varargin)
%IODATASOURCE  Constructor for @IODataSource class

%  Copyright 2013 The MathWorks, Inc.

% Create class instance
this = iodatapack.IODataSource;

% Initialize attributes
this.IOData = data;

% Add listeners
addlisteners(this)

% Set additional parameters in varargin
if ~isempty(varargin)
   set(this,varargin{:});
end
