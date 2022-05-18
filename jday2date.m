%  [day,month] = JDAY2DATE(julianDay,year)
%
%  DESCRIPTION
%  Extracts the DAY and MONTH in the Gregorian calendar from the specified 
%  YEAR and Julian day of the year (JULIANDAY).
%
%  INPUT VARIABLES
%  - julianDay: vector of Julian days. Numbers 1-365 correspond to non-leap 
%    years (Julian calendar) and 1-366 to leap-years.
%  - year: number indicating the year for the specified Julian day.
%
%  OUTPUT VARIABLES
%  - day: day in the Gregorian calendar, corresponding to the specified
%    Julian day and year
%  - month: month in the Gregorian calendar, corresponding to the specified 
%    Julian day and year
%
%  INTERNALLY CALLED FUNCTIONS
%  - None
%
%  FUNCTION CALLS
%  [day,month] = jday2date(julianDay,year)
%
%  See also READP190

%  VERSION 2.0
%  Date: N/A
%  Author: Guillermo Jimenez Arranz
%  - JULIANDAY can contain more than one value.
%  - The functionality of ISLEAPJYEARis included in JDAY2DATE.
%
%  VERSION 1.0
%  Guillermo Jimenez Arranz
%  email: gjarranz@gmail.com
%  9 Dec 2014

function [day,month] = jday2date(jday,year)

isleapjyear = ~rem(year,4);
if ~isleapjyear
    firstDay = [1 32 60 91 121 152 182 213 244 274 305 335];
else
    firstDay = [1 32 61 92 122 153 183 214 245 275 306 336];
end

q = jday - firstDay + 1;
month = sum(q>0,2)';
day = q(sub2ind(size(q),1:size(q,1),month));
