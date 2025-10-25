% This pragma is used to specify that some aggregate data (i.e. cell array or structure) is to be
% exploded in the generated code. Explosion of an aggregate means to separate the members of the
% aggregate into independent, standalone memory locations. For instance, given a struct variable 'S'
% with members 'x' and 'y', explosion of 'S' will produce two new variables 'S_x' and 'S_y'.
%
% A situation of when to use this pragma would be if the generated code contains avoidable memory
% copies introduced by the packaging of data into aggregate data types.
%
% The input to the pragma can be a variable (most common case) or any addressable expression (e.g. a
% member of a larger aggregate value).
% 
% If the explosion cannot be performed for some reason, the pragma will be ignored.
%
% Limitations:
%
%   1. When the input to the pragma is a cell array, any subscript into the array must be constant
%   (i.e. constant foldable by inference).
%
%   2. The data passed to the pragma may not be a LHS or RHS of an assignment operation, except for
%   the case when the data is the LHS of a call expression assignment.
%
%   3. If the input references a member of another aggregate expression 'A', the input will not be
%   exploded unless 'A' is also specified to be exploded.
%
% Usage tips:
%
%   1. When creating a cell array to be exploded, use the 'cell' function instead of using braces
%   (i.e. {}). This is because braces can introduce special nodes in the IR that the explosion
%   transform currently does not know how to process.
%
%   2. Place this pragma as close as possible to where the aggregate data is defined. For instance,
%   if the aggregate data is created using the 'cell' function, the pragma should be placed in the
%   same function that calls 'cell'. If the explodable data is an input or output, the explosion
%   transform will ensure that the data gets exploded further up and down the call tree.

%   Copyright 2022-2023 The MathWorks, Inc.
function explodeAggregate(~)
end
