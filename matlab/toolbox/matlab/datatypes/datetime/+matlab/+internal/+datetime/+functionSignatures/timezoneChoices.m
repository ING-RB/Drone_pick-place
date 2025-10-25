function choices = timezoneChoices()
% TIMEZONECHOICES List timezones for use in DATETIME function signatures

%   Copyright 2017 The MathWorks, Inc.

t = timezones();
choices = [{'local', 'UTC', 'UTCLeapSeconds'}, t.Name(:)'];
