function cyc = hascycles(G)
% HASCYCLES Determine whether a digraph has cycles.
%   HASCYCLES(G) returns logical 1 (true) if digraph G contains one or more
%   cycles, and logical 0 (false) otherwise. A cycle exists when there is a
%   nonempty path through the graph in which only the first and last nodes
%   are repeated. An example of a cycle is: (node1 -> node2 -> node3 ->
%   node1).
%
%   See also ALLCYCLES, CYCLEBASIS, ISDAG

%   Copyright 2020 The MathWorks, Inc.

cyc = ~isdag(G);
