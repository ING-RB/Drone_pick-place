function ValidBlackboxRuntime = getValidBlackboxRuntime(aCandidateRuntime)
%

%   Copyright 2019 The MathWorks, Inc.

    switch(aCandidateRuntime)
        %hardcodedsfxruntime
        case {'R2019a','R2019b','R2020a'}%older sfx runtime list
            ValidBlackboxRuntime = aCandidateRuntime;
        otherwise
            ValidBlackboxRuntime = 'R2020b';
    end
end
