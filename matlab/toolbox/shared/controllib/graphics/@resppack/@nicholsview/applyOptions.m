function applyOptions(this, Options)
% APPLYOPTIONS  nicholsview options

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2005 The MathWorks, Inc.

cOpts = get(this(1), 'UnwrapPhase');

% Set new preferences
if isfield(Options, 'UnwrapPhase') && ~strcmp(Options.UnwrapPhase,cOpts)
  set(this, 'UnwrapPhase', Options.UnwrapPhase);
end

cOpts = get(this(1), 'PhaseWrappingBranch');

% Set new preferences
if isfield(Options, 'PhaseWrappingBranch') && ~strcmp(Options.PhaseWrappingBranch,cOpts)
  set(this, 'PhaseWrappingBranch', Options.PhaseWrappingBranch);
end

cOpts = get(this(1), 'ComparePhase');

% Set new preferences
if isfield(Options, 'ComparePhase') && ...
        (~strcmp(Options.ComparePhase.Enable,cOpts.Enable) || ...
        (Options.ComparePhase.Freq ~= cOpts.Freq) || ...
        (Options.ComparePhase.Phase ~= cOpts.Phase))
    set(this, 'ComparePhase', Options.ComparePhase);
end