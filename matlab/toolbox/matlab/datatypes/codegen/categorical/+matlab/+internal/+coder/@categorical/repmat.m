function c = repmat(this,varargin)  %#codegen
% REPMAT

% Copyright 2020 The MathWorks, Inc.
c = matlab.internal.coder.categorical(matlab.internal.coder.datatypes.uninitialized);
c.categoryNames = this.categoryNames;        
c.isProtected = this.isProtected;
c.isOrdinal = this.isOrdinal;
c.numCategoriesUpperBound = this.numCategoriesUpperBound;
c.codes = repmat(this.codes,varargin{:});