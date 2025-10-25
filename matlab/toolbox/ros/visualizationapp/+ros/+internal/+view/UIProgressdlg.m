classdef UIProgressdlg < handle
% Class wrapper for uiprogressdlg dialog

%   Copyright 2022 The MathWorks, Inc.

    methods
        function handle = run(~, varargin)
             handle = uiprogressdlg(varargin{:}, 'Indeterminate', 'on');
        end
    end
end