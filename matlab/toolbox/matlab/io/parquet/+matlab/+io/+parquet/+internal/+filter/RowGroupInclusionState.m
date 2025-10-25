classdef RowGroupInclusionState
%RowGroupInclusionState   Expresses the result of filtering as a tri-state
%   parameter. This is because the binary true/false isn't sufficient to
%   communicate whether a RowGroup should be fully excluded or just
%   partially excluded on application of the negation operator.
%
%   See also: rowfilter

%   Copyright 2021-2022 The MathWorks, Inc.

    enumeration
        FullyIncluded,
        PartiallyIncluded,
        FullyExcluded
    end

    % Override and, or, not operators based on a consistent truth table.
    methods
        function rs = not(rs)
            rs = arrayfun(@scalarNot, rs, UniformOutput=true);
        end

        function rs = and(lhs, rhs)
            rs = arrayfun(@scalarAnd, lhs, rhs, UniformOutput=true);
        end

        function rs = or(lhs, rhs)
            rs = arrayfun(@scalarOr, lhs, rhs, UniformOutput=true);
        end

        function rs = scalarNot(rs)
            arguments
                rs (1, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
            end
            % FullyIncluded -> FullyExcluded
            % FullyExcluded -> FullyIncluded
            % PartiallyIncluded unchanged.

            import matlab.io.parquet.internal.filter.RowGroupInclusionState;

            if rs == RowGroupInclusionState.FullyIncluded
                rs = RowGroupInclusionState.FullyExcluded;
            elseif rs == RowGroupInclusionState.FullyExcluded
                rs = RowGroupInclusionState.FullyIncluded;
            end

            % Intentional fall-through for PartiallyIncluded.
        end

        function result = scalarAnd(lhs, rhs)
            %AND   Propagate exclusion (falsy-ness)
            %
            %                  LHS
            %           | FI | PI | FE |
            %       ----+----+----+-----
            %        FI | FI   PI   FE |
            %   RHS  PI | PI   PI   FE |
            %        FE | FE   FE   FE |
            %
            % Basically: FullyExcluded wins where it shows up.
            %            and PartiallyIncluded wins over FullyIncluded.
            %
            % LHS and RHS must have equivalent dimensions.

            arguments
                lhs (1, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
                rhs (1, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
            end

            import matlab.io.parquet.internal.filter.RowGroupInclusionState;

            args = [lhs rhs];

            isAnyFullyExcluded     = any(args == RowGroupInclusionState.FullyExcluded, "all");
            isAnyPartiallyIncluded = any(args == RowGroupInclusionState.PartiallyIncluded, "all");

            % If either LHS or RHS are fully excluded, then return
            % early since the combination must be fully excluded.
            if isAnyFullyExcluded
                result =  RowGroupInclusionState.FullyExcluded;
                return;
            end

            % The only cases left are either LHS or RHS have
            % PartiallyIncluded, or they are both FullyIncluded.
            % Handle the partial inclusion cases first.
            if isAnyPartiallyIncluded
                result =  RowGroupInclusionState.PartiallyIncluded;
                return;
            end

            % Finally, AND only returns FullyIncluded if both LHS
            % and RHS are both Fully Included.
            result = RowGroupInclusionState.FullyIncluded;
        end

        function result = scalarOr(lhs, rhs)
            %OR   Propagate inclusion (truthy-ness)
            %
            %                  LHS
            %           | FI | PI | FE |
            %       ----+----+----+-----
            %        FI | FI   FI   FI |
            %   RHS  PI | FI   PI   PI |
            %        FE | FI   PI   FE |
            %
            % Basically: FullyIncluded wins where it shows up.
            %            and PartiallyIncluded wins over FullyExcluded.
            %
            % LHS and RHS must have equivalent dimensions.

            arguments
                lhs (1, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
                rhs (1, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
            end

            import matlab.io.parquet.internal.filter.RowGroupInclusionState;

            args = [lhs rhs];

            isAnyFullyIncluded     = any(args == RowGroupInclusionState.FullyIncluded, "all");
            isAnyPartiallyIncluded = any(args == RowGroupInclusionState.PartiallyIncluded, "all");

            % If either LHS or RHS are fully included, then return
            % early since the combination must be fully included.
            if isAnyFullyIncluded
                result =  RowGroupInclusionState.FullyIncluded;
                return;
            end

            % The only cases left are either LHS or RHS have
            % PartiallyIncluded, or they are both FullyExcluded.
            % Handle the partial inclusion cases first.
            if isAnyPartiallyIncluded
                result =  RowGroupInclusionState.PartiallyIncluded;
                return;
            end

            % Finally, OR only returns FullyExcluded if both LHS
            % and RHS are both Fully Excluded.
            result = RowGroupInclusionState.FullyExcluded;
        end
    end
end
