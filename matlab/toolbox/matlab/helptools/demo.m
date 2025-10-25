function demo(action,categoryArg) 
% DEMO Access examples via Help browser. 
%
%   DEMO displays a list of featured MATLAB and Simulink examples in the 
%   Help browser.
%
%   DEMO TYPE NAME displays the examples for the product matching NAME and
%   TYPE, as defined in that product's info.xml or demos.xml file.
%   
%   Examples:
%       demo 'matlab'
%       demo 'toolbox' 'signal'
%
%   See also DOC.

%   Copyright 1984-2024 The MathWorks, Inc.

if nargin < 1
    web(fullfile(docroot, 'examples.html'))
elseif nargin == 1
    action = char(action);
    web(fullfile(docroot, action, 'examples.html'))
elseif nargin == 2
    categoryArg = char(categoryArg);
    web(fullfile(docroot, categoryArg, 'examples.html'))
end
