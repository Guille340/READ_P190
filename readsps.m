%  source = READSPS()
%
%  DESCRIPTION
%  Reads a SPS file and exports time and location of the source. SPS is one 
%  of the available formats used in seismic surveys to log position and field 
%  data. It uses a header, for general information and format specification, 
%  and a main body for real time data storing (line ID, geographic/projected 
%  coordinates, time, and various other parameters for every shot of the 
%  seismic source).
%  
%  "NOTE This function extracts the time and position (geographic coordinates 
%  only) omitting the header. DMS position data is assumed (Degrees-Minutes-
%  Seconds). It is important to check the header to know any relevant 
%  information that can affect to the time and position data of the vessel 
%  and the source (like position units or Datum and Reference Ellipsoid). 
%  Future versions of this function migth perform a complete analysis of the 
%  SPS file, included header and additional parameters"
%
%  OUTPUT VARIABLES
%  - source: array [M,8] where each lines contains time and position 
%    information of the source, with format [day month year hour minute 
%    second latitude longitude]
%
%  INTERNALLY CALLED FUNCTIONS
%  - jday2date
%
%  CONSIDERATIONS & LIMITATIONS
%  - The function needs to be finished!
%
%  REFERENCES
%  - Shell Internationale Petroleum, "Shell processing support format for 
%    3D surveys, as adopted by the SEG in 1993", revision 2.1, Jan 2006
%
%  See also JDAY2DATE

%  VERSION 1.0
%  Guillermo Jimenez Arranz
%  email: gjarranz@gmail.com
%  4 Jun 2014

function source = readsps()

year = 2014;

% OPEN FILE
[file,path] = uigetfile({'*.txt','Text File (*.txt)';'*.sps','SPS File (*.sps)'},'Select SPS file');
f_ori = strcat(path,file);
fid_R = fopen(f_ori,'r');
% f_mod = strcat(path,file(1:end-4),'_MOD.txt');
% fid_W = fopen(f_mod,'w');

% SKIP HEADER
lin = fgets(fid_R);
while strcmp(lin(1),'H')
lin = fgets(fid_R);
end

% READ FILE
year = julianYear;
v = 0;
s = 0;
while lin~=-1

    ID = lin(1); % recorded identifier
    
    latDeg = str2num(lin(26:27)); % degrees of latitude
    latMin = str2num(lin(28:29)); % minutes of latitude
    latSec = str2num(lin(30:34)); % seconds of latitude
    if strcmp(lin(35),'N'), latNS = 1; else latNS = -1; end % sign of latitude
    lonDeg = str2num(lin(36:38)); % degrees of longitude
    lonMin = str2num(lin(39:40)); % minutes of longitude
    lonSec = str2num(lin(41:45)); % seconds of longitude
    if strcmp(lin(46),'E'), lonEW = 1; else lonEW = -1; end % sign of longitude
    lat = latNS*(latDeg + latMin/60 + latSec/3600); % latitude [deg]
    lon = lonEW*(lonDeg + lonMin/60 + lonSec/3600); % longitude [deg]
    
    julianDay = str2num(lin(71:73)); % Julian Day of the year
    hour = str2num(lin(74:75)); % time [hours]
    min = str2num(lin(76:77)); % time [minutes]
    sec = str2num(lin(78:79)); % time [seconds]
    [day,month] = jday2date(julianDay,year);

    row = [day month year hour min sec lat lon];
    
    if strcmp(ID,'S'), s = s+1; source(s,:) = row; end

%     DATE = sprintf('%0.2d-%0.2d-%0.4d',day,month,julianYear);
%     LAT = sprintf('%2.8f',lat);
%     LON = sprintf('%3.8f',lon);
%     LIN = [ID ',' DATE ',' LAT ',' LON sprintf('\r\n')];
%     fwrite(fid_W,LIN);
   
    lin = fgetl(fid_R);

end

fclose(fid_R);
% fclose(fid_W);


