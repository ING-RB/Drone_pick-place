classdef turnrep
%

%   Copyright 2023 The MathWorks, Inc.

    %#codegen

    % polygon in turning rep
    properties
        total_len
        legs
    end
    methods
        function turnrepObj = turnrep(n)
            % single leg of a turning rep polygon
            leg = struct('theta', 0, ... % heading of the leg
                'len', 0, ... % length in original coordinates
                's', 0); % cumulative arc length in [0,1] of start
            turnrepObj.legs = repmat(leg, [1 n]);
            turnrepObj.total_len = 0;
        end
        function num = n(turnrepObj)
            num = coder.internal.indexInt(numel(turnrepObj.legs));
        end
        function m = mod(turnrepObj, i)
            coder.inline('always');
            nt = turnrepObj.n();
            if i < nt
                m = i + 1;
            else
                m = mod(i, nt);
                m = m + 1;
            end
        end
    end
end
