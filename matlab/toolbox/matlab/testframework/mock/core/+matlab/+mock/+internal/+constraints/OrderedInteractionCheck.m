classdef OrderedInteractionCheck < matlab.mock.internal.constraints.InteractionCheck
    % This class is undocumented and may change in a future release.
    
    % Algorithm: consider the matrix describing the relationship between each
    % recorded history element and each behavior specification element, where a
    % 1 indicates that the behavior describes the recorded interaction and 0
    % indicates that it does not. For example:
    %
    %        INTERACTION HISTORY
    %
    %   B    1* 1* 0  0  1  1  1
    %   E    1* 0  0  0  1  1  0
    %   H    1* 1* 0  0  1  0  0
    %   A    1* 0  0  0  1  1  1
    %   V    1* 1* 0  1* 1* 0  1
    %   I    0  1* 0  0  1* 0  0
    %   O    1  1* 0  1* 1* 1  0
    %   R    0  0  0  0  0  1* 1*
    %
    % The order criterion is satisfied if there is a connected path of 1's from
    % the top left of the matrix to bottom right, moving to the right and down
    % (including diagonally (i.e., from (n,m) to (n+1,m+1) )). Columns of zeros
    % are OK; these are extra, irrelevant interactions.
    %
    % As each recorded interaction is processed in turn, keep track of all
    % candidate paths of matching interactions (marked with *'s above).
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess=private)
        RequiredInteractions matlab.mock.InteractionBehavior;
        ActualInteractionOrder (1,:) matlab.mock.InteractionHistory;
    end
    
    properties (Access=private)
        Matches (1,:) matlab.mock.internal.constraints.MatchState;
        Exhaustive (1,1) logical = false;
        HadOutOfOrderInteraction (1,1) logical = false;
    end
    
    methods (Static)
        function check = forMinimalQualification(requiredInteractions)
            import matlab.mock.internal.constraints.OrderedInteractionCheck;
            check = OrderedInteractionCheck(requiredInteractions);
        end
        
        function check = forExhaustiveAnalysis(requiredInteractions)
            import matlab.mock.internal.constraints.OrderedInteractionCheck;
            check = OrderedInteractionCheck(requiredInteractions);
            check.Exhaustive = true;
        end
    end
    
    methods
        function check(interactionCheck, actualInteraction)
            required = interactionCheck.RequiredInteractions;
            status = interactionCheck.Matches;
            
            for idx = 1:numel(status)
                if status(idx) ~= "NonCandidate" || (idx ~= 1 && status(idx-1) == "Match")
                    status(idx) = actualInteraction.describedBy(required(idx));
                end
            end
            
            if any(status == "Match")
                interactionCheck.ActualInteractionOrder(end+1) = actualInteraction;
                status([false, status(2:end) == "NonMatch" & status(1:end-1) == "Match"]) = "CandidateByPriorMatch";
                status(status == "NonMatch") = "NonCandidate";
                status(status == "Match") = "Candidate";
                interactionCheck.Matches = status;
                return;
            end
            
            for idx = 1:numel(status)
                if status(idx) ~= "NonMatch" && actualInteraction.describedBy(required(idx))
                    interactionCheck.ActualInteractionOrder(end+1) = actualInteraction;
                    interactionCheck.HadOutOfOrderInteraction = true;
                    return;
                end
            end
        end
        
        function bool = isDone(interactionCheck)
            bool = ~interactionCheck.Exhaustive && interactionCheck.HadOutOfOrderInteraction;
        end
        
        function bool = isSatisfied(interactionCheck)
            bool = ~interactionCheck.HadOutOfOrderInteraction && ...
                interactionCheck.Matches(end) == "Candidate";
        end
    end
    
    methods (Access=private)
        function check = OrderedInteractionCheck(requiredInteractions)
            check.RequiredInteractions = requiredInteractions;
            check.Matches = repmat("NonCandidate", 1, numel(requiredInteractions));
            check.Matches(1) = "CandidateByPriorMatch";
        end
    end
end
