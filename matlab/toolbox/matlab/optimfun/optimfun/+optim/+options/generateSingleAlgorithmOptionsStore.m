function OS = generateSingleAlgorithmOptionsStore(OS)
%

%GENERATESINGLEALGORITHMOPTIONSSTORE Complete an OptionsStore structure for
%                                   a SingleAlgorithm options object
%
%   OS = GENERATESINGLEALGORITHMOPTIONSSTORE(OSIN) generates the fields of
%   an OptionsStore structure that can be automatically generated. OSIN
%   must contain the following field:-
%
%   Defaults   : Structure containing the default option values.
%
%   GENERATESINGLEALGORITHMOPTIONSSTORE creates the following fields from
%   the above information:-
%
%   SetByUser  : Structure. Indicate whether the user has set the 
%                option (true) or not (false).
%   Options    : Options structure.

%   Copyright 2012 The MathWorks, Inc.

% Create a list of all options
fnames = fieldnames(OS.Defaults);

% Create the SetByUser structure
for i = 1:length(fnames)
    % SetByUser structure
    OS.SetByUser.(fnames{i}) = false;
end

% Create the options structure
OS.Options = OS.Defaults;



