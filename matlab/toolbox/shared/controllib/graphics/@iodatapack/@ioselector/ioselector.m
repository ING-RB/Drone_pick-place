function h = ioselector(InputNames, OutputNames, varargin)
%IOSELECTOR Constructor for @ioselector class.

% Copyright 2013 The MathWorks, Inc.

h = iodatapack.ioselector;
h.InputName = InputNames;
h.OutputName = OutputNames;
h.InputSelected = true(length(InputNames),1);
h.OutputSelected = true(length(OutputNames),1);

% User-specified properties (can be any property EXCEPT Visible)
h.set(varargin{:});

% Construct GUI
build(h)

% All other listerners
addlisteners(h)
