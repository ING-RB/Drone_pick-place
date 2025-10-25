classdef MatchState < int8
    %

    % Copyright 2018 The MathWorks, Inc.
    
    enumeration
        NonCandidate (-1)
        
        NonMatch (0)
        Match (1)
        
        CandidateByPriorMatch (2)
        Candidate (3)
    end
end