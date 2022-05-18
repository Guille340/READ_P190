%  P190Data = READP190(filePath,varargin)
%
%  DESCRIPTION
%  Reads a P1-90 file and returns a structure P190Data containing the time, 
%  location and operational information from the source and the seismic 
%  vessel.
%
%  P1-90 is a format used in seismic surveys for logging position and field 
%  data. It comprises a header, for general information and format specs, and 
%  a main body, for real time data (line id, geographic/projected coordinates, 
%  time and various other parameters for every pulse emitted by the seismic 
%  source).
%
%  INPUT VARIABLES
%  - filePath: absolute path of the p190 file.
%  - year (varargin{1}): year when the navigation data was recorded. The
%    date of the recorded data is included in the H0201 header (Tape Date),
%    but date format is not standard. Setting the correct year when the
%    data was stored is necessary to perform the conversion from Julian to
%    Gregorian days and thus generate the correct timestamps. The data in
%    the p190 file must refer to the specified year (split the file if
%    necessary). If YEAR is not set, the year of the recording is taken
%    from the date when the file was last modified.
%
%  OUTPUT VARIABLES
%  - P190Data: structure containing the P190 information from the source
%    and seismic vessel.
%    ¬ recid: record identifier ('V' for vessel, 'S' for source)
%    ¬ vesid: identifier of the vessel towing the source (1-9)
%    ¬ souid: source identifier (1-9)
%    ¬ line: seismic line identifier (number)
%    ¬ point: shot identifier (number)
%    ¬ utctick: utc tick [s]
%    ¬ lat: latitude of the source [deg]
%    ¬ lon: longitude of the source [deg]
%
%  INTERNALLY CALLED FUNCTIONS
%  - jday2date
%
%  CONSIDERATIONS AND LIMITATIONS
%  - This function extracts the time and position (geographic coordinates
%    only) omitting the header.
%  - DMS position data is assumed (Degrees-Minutes-Seconds)
%  - It is important to check the header to know any relevant information
%    that can affect the time and position data of the vessel and the source
%    (like position in [deg] or Datum and Reference Ellipsoid).
%
%  REFERENCES
%  - Positioning and Surveying Commitee, "U.K.O.O.A. P1-90 post plot data
%    exchange tape. 1990 format", June 1990
%
%  See also JDAY2DATE

%  VERSION 3.1
%  Date: 19 Apr 2022
%  Author: Guillermo Jimenez Arranz
%  - Small update on the help to reflect the changes previously made to the
%    output argument (VESSEL and SOURCE now merged into P190DATA).
%
%  VERSION 3.0
%  Date: 15 Apr 2018
%  Author: Guillermo Jimenez Arranz
%  - In this new revision all the p190 sentences are returned in one
%    structure (i.e. there are no separate structures for source and
%    vessel sentences).
%  - More than one p190 file can be selected.
%
%  VERSION 2.0
%  Date: 08 Oct 2016
%  Author: Guillermo Jimenez Arranz
%  - READP190 now returns two structures containing the information
%    related to the source and the seismic vessel. In the previous version
%    ¦vessel¦ and ¦source¦ were 8 column arrays with format with format
%    [day month year hour minute second latitude longitude].
%
%  VERSION 1.0
%  Guillermo Jimenez Arranz
%  email: gjarranz@gmail.com
%  4 Jun 2014

function P190Data = readp190(filePath,varargin)

% Error Control: Number of Input Arguments
narginchk(1,2)

% Number of Selected Files
if iscell(filePath)
    K = numel(filePath);
end

if ischar(filePath)
    filePath = {filePath};
    K = 1;
end

% Error Control: File Extension
fext = cell(1,K);
for k = 1:K
    [~,~,fext{k}] = fileparts(filePath{k});
end
isp190 = strcmp(fext,'.p190');

if any(~isp190)
    error('One or more selected files have an unrecognised extension')
end

i1 = 1;
for k = 1:K
    % Read data from p190 file
    fid = fopen(filePath{k},'r');
    datatemp = textscan(fid,'%s','Delimiter','\n');
    fclose(fid);
    i2 = i1 + numel(datatemp{1}) - 1;
    data(i1:i2) = datatemp{1};
    i1 = i2 + 1;
end

clear datatemp

% Error Control: Year of Acquisition
year = zeros(1,K);
for k = 1:K
    p190file = dir(filePath{k});
    if nargin == 1 % from "Last Modified" file date
        year(k) = str2num(datestr(p190file.datenum,'yyyy'));
    else % from variable input argument
        year(k) = varargin{1};
    end
end
year = unique(year);
if length(year) > 1
    error('The year of acquisition must be the same for all selected P190 files');
end

% Remove corrupt sentences (no. characters > 80)
M = numel(data); % total number of p190 sentences in ¦data¦ structure
ncha = zeros(1,M);
for m = 1:M
    ncha(m) = length(data{m});
end
data(ncha ~= 80) = [];

% Remove repeated sentences
data = unique(data,'stable');

% Convert cell vector to char array
datatxt = char(data);
clear data

% Remove P190 sentences other than 'V' and 'S'
recid = datatxt(:,1);
ives = recid == 'V';
isou = recid == 'S';
ival = ives | isou;
datatxt(~ival,:) = [];

% Remove non-paired sentences
timenum = str2num(datatxt(:,71:79));
utime = unique(timenum);
edges = [(utime(1) - 1) ; utime] + 0.5;
counts = histcounts(timenum,edges);
datatxt(ismember(timenum,utime(counts == 1)),:) = [];
M = size(datatxt,1);

% Retrieve survey parameters
recid = datatxt(:,1);
vesid = str2double(cellstr(datatxt(:,17)));
souid = str2double(cellstr(datatxt(:,18)));
line = str2num(datatxt(:,2:13));
point = str2num(datatxt(:,20:25));

% Retrieve position
latdeg = str2num(datatxt(:,26:27)); % degrees of latitude in DMS format
latmin = str2num(datatxt(:,28:29)); % minutes of latitude in DMS format
latsec = str2num(datatxt(:,30:34)); % seconds of latitude in DMS format
latsig = (datatxt(:,35) == 'N')*2 - 1; % sign of latitude (E = +1, S = -1)
londeg = str2num(datatxt(:,36:38)); % degrees of longitude
lonmin = str2num(datatxt(:,39:40)); % minutes of longitude
lonsec = str2num(datatxt(:,41:45)); % seconds of longitude
lonsig = (datatxt(:,46) == 'E')*2 - 1; % sign of latitude (N = +1, W = -1)
lat = latsig.*((latsec/60 + latmin)/60 + latdeg); % latitude [deg]
lon = lonsig.*((lonsec/60 + lonmin)/60 + londeg); % longitude [deg]

% Retrieve date and time
jday = str2num(datatxt(:,71:73)); % Julian day of the year
hou = str2num(datatxt(:,74:75)); % time [hours]
mnt = str2num(datatxt(:,76:77)); % time [minutes]
sec = str2num(datatxt(:,78:79)); % time [seconds]
[day,month] = jday2date(jday,year);
datestring = strsplit(sprintf('%0.2d/%0.2d/%0.4d %0.2d:%0.2d:%0.2d\n',...
    reshape([day' month' repmat(year,M,1) hou mnt sec]',6*M,1)),'\n');
utctick = datenum(datestring(1:end-1),'dd/mm/yyyy HH:MM:SS')*86400;

% Generate structure
P190Data.recid = recid;
P190Data.vesid = vesid;
P190Data.souid = souid;
P190Data.line = line;
P190Data.point = point;
P190Data.utctick = utctick;
P190Data.lat = lat;
P190Data.lon = lon;

% Sort Data by Time
[~,isort] = sort(P190Data.utctick);
P190Data.recid = P190Data.recid(isort);
P190Data.vesid = P190Data.vesid(isort);
P190Data.souid  = P190Data.souid(isort);
P190Data.line = P190Data.line(isort);
P190Data.point = P190Data.point(isort);
P190Data.utctick = P190Data.utctick(isort);
P190Data.lat = P190Data.lat(isort);
P190Data.lon = P190Data.lon(isort);
