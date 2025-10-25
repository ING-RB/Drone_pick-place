%SUPPORT Open MathWorks Technical Support Web Page.
%   SUPPORT, with no inputs, opens your Web browser to the MathWorks
%   Technical Support Web Page at http://www.mathworks.com/support.
%
%   On this page, you will find links to
%     - A solution search engine
%     - Information about installation and licensing
%     - Bug fixes and patches
%     - Other useful resources
%
%   SUPPORT will be removed in a future release. 
%
%   See also WEB.

%   Copyright 1984-2021 The MathWorks, Inc.

warning(message('MATLAB:support:FunctionToBeRemoved'))

disp(getString(message('MATLAB:support:disp_OpeningTheTechnicalSupportWebPage')))
disp(' ')

web('http://www.mathworks.com/support', '-browser');
