function uot = unitOfTimeChoices(kind)
% A list of valid values for timeranges UnitOfTime parameter

%   Copyright 2018-2020 The MathWorks, Inc.
switch lower(kind)
case 'yqmwdt'
    uot = {'year','quarter','month','week','day','time'};
case 'yqmwdt_plural'
    uot = {'years','quarters','months','weeks','days','time'};
case 'yqmwdhms'
    uot = {'year','quarter','month','week','day','hour','minute','second'};
case 'yqmwdhms_plural'
    uot = {'years','quarters','months','weeks','days','hours','minutes','seconds'};
case 'yqmwdhms_ad' % adjective or adverb
    uot = {'yearly','quarterly','monthly','weekly','daily','hourly','minutely','secondly'};
case 'ydhms'
    uot = {'year','day','hour','minute','second'};
case 'ydhms_plural'
    uot = {'years','days','hours','minutes','seconds'};
case 'cdyqmwdhms'
    uot = {'century','decade','year','quarter','month','week','day','hour','minute','second'};
otherwise
    assert(false);
end
