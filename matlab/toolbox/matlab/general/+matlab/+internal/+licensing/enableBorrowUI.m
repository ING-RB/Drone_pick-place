function enableBorrowUI(option)
%Enable or Disable the License Borrow UI option in menu the next time MATLAB starts.
%   enableBorrowUI(true) enables License Borrow UI option in the menu.
%   enableBorrowUI(false) disables License Borrow UI option in the menu.

%   Copyright 2013-2020 The MathWorks, Inc.


% Arg checking
narginchk(1, 1);
nargoutchk(0, 0);

% Check argument datatype
if (~islogical(option))
    error('Input must be boolean - true or false');
end

s = settings;
s.matlab.licensing.BorrowUIEnabled.PersonalValue = option;


