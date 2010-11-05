function callback_recent(hObject,eventdata,varargin)
% CALLBACK_RECENT builds and maintains the open recent list in file menu
%__________________________________________________________________________
% USAGE: callback_recent(hObject,eventdata,varargin)
%
% INPUT: hObject = calling objects handle (within Program Control)
%        eventdata = not used, MATLAB required
%        varargin = filename of item being added or excluded when used as
%           handle to the filemenu (i.e. building the menu)
%
% PROGRAM OUTLINE:
% 1 - PREPARE THE GUI
% 2 - BUILD THE LIST OF RECENT FILES
% 3 - REMOVE LIST ITEMS THAT DO NOT EXIST
% 4 - REMOVE OPEN RECENT MENU IF NO FILES EXISTS
% 5 - BUILD CALLBACKS FOR EACH FILE IN LIST
% 6 - APPEND LIST WITH A NEW FILE
% 7 - OVERWRITE CURRENT FILE WITH THE UPDATED LIST
%__________________________________________________________________________

% 1 - PREPARE THE GUI
    h = guihandles(hObject);            % Program Control handles
    delete(get(h.recent,'Children'));   % Remove any existing menus
    set(h.recent,'Visible','on');       % Make list visible

% 2 - BUILD THE LIST OF RECENT FILES
    % 2.1 - Case when no file list exists
    if ~exist([cd,'\recent.txt'],'file'); list = {}; 

    % 2.2 - Case when using an existing list
    else
        fid = fopen('recent.txt');                   % Opens file
        list = textscan(fid,'%s','delimiter','\n');  % Reads strings
        fclose(fid);                                 % Closes files
        list = unique(list{1});                      % Removes duplicates
    end

    % 2.3 - Remove default.mat file from list
        name = {};
        for i = 1:length(list); [p,name{i}] = fileparts(list{i}); end
        idx = strmatch('default',name); list(idx) = [];

    % 2.4 - Remove duplicate entries
        if length(list) > 10; list = list(1:10); end % Allow 10 entrys
        
% 3 - REMOVE LIST ITEMS THAT DO NOT EXIST
    idx = zeros(length(list),1);
    for i = 1:length(list);
        if exist(list{i},'file'); idx(i) = 1; end
    end
    list = list(logical(idx));
        
% 4 - REMOVE OPEN RECENT MENU IF NO FILES EXISTS
    if isempty(list); set(h.recent,'Visible','off');end

% 5 - BUILD CALLBACKS FOR EACH FILE IN LIST
if isempty(varargin);
    for i = 1:length(list);
        [p,nm,ext] = fileparts(list{i});
        uimenu(h.recent,'Label',[nm,ext],'Callback',...
            {'callback_readWS',list{i}});
    end

% 6 - APPEND LIST WITH A NEW FILE
else
    list = [varargin{1};list];
end

% 7 - OVERWRITE CURRENT FILE WITH THE UPDATED LIST
    fid = fopen([cd,'\recent.txt'],'w');
    for j = 1:length(list); fprintf(fid,'%s\n',list{j}); end
    fclose(fid);
