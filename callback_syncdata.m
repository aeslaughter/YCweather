function callback_syncdata(hObject,eventdata,varargin)
% CALLBACK_SYNCDATA syncs all weather and daily log data from server
%__________________________________________________________________________
%
% SYNTAX: 
%   callback_syncdata(hObject)
%   callback_syncdata(hObject,[],'menu')
%
% DESCRIPTION: 
%   callback_syncdata(hObject,'current') syncs all data and daily logs 
%       from the current season
%   callback_syncdata(hObject,[]) syncs all weather data and daily logs 
%       from the season selected in the GUI
%__________________________________________________________________________

try
% 1 - DEFINE DIRECTORY NAMES AND DESIRED FOLDER
    % 1.1 - Local database directory
        GUI = guidata(hObject);
        database = GUI.settings.paths.database;
        if ~exist(database,'dir'); mkdir(database); end
        
    % 1.2 - Remote/local database directories to sync 
        if strcmpi(eventdata,'current'); 
            fldr = getfolder;
        else fldr = GUI.season;
        end
        remote = ['/pub/snow/db/',fldr,'/'];
        local = [database,fldr];
            
% 2 - SYNC WEATHER DATA FROM CURRENT SEASON 
    if ~exist(local,'dir'); mkdir(local); end
    syncdata(local,remote);
    
% % 3 - UPDATE GUI (Only calls with 'menu' option)
    if ~isempty(varargin) && strcmpi(varargin{1},'menu'); % 
        callback_season(hObject,[]);
    end

% 4 - ERROR CATCHING    
catch
    mes = ['Error with data sync to database (callback_syncdata.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);    
end

%--------------------------------------------------------------------------
% SUBFUNCTION: folder
function fldr = getfolder

% Get the current time
c = clock;

% Determine the current folder based on water-year
if c(2) < 10; 
    yr2 = num2str(c(1));
    yr1 = num2str(c(1)-1);
    fldr = [yr1(3:4),'-',yr2(3:4)];
else
    yr1 = num2str(c(1));
    yr2 = num2str(c(1)+1);
    fldr = [yr1(3:4),'-',yr2(3:4)];
end