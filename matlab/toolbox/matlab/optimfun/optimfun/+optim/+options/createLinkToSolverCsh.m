function [docFileTagStart, docFileTagEnd] = createLinkToSolverCsh(solverName)
%CREATELINKTOSOLVERCSH Create hyperlink tags to a solver doc page
%
%   [DOCFILETAGSTART, DOCFILETAGEND] = CREATELINKTOSOLVERCSH(SOLVERNAME)
%   creates hyperlink tags to the options section of the function reference
%   documentation page for the named solver. For example, for fmincon
%
%   docFileTagStart = <a href = "matlab: helpview('<DOCROOT>/toolbox/optim/helptargets.map','fmincon_opts')">
%   docFileTagEnd = </a>
%
%   If links are not enabled in the MATLAB session, then the start and end
%   tags are empty strings.

%   Copyright 2017-2023 The MathWorks, Inc.

% Determine toolbox
if ~contains(getfield(functions(str2func(solverName)),'file'),'globaloptim')
    toolboxName = 'optim';
else
    toolboxName = 'gads';
end

[~,docFileTagStart, docFileTagEnd] = matlab.internal.optimfun.utils.addLink('',toolboxName, ...
                                             sprintf('%s_opts',solverName),false);


