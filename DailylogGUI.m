function varargout = DailylogGUI(varargin)
% DAILYLOGGUI M-file for DailylogGUI.fig
%__________________________________________________________________________
% USAGE: h = DailylogGUI;
%
% INPUT: none
% 
% OUTPUT: h - handle of created viewer window
%
% NOTES: This m-file was constructed with MATLAB's guide and then modified
%__________________________________________________________________________

% 1 - BEGIN INITIALIZATION CODE - DO NOT EDIT
    gui_Singleton = 0;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @DailylogGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @DailylogGUI_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT

% 2 - EXECUTES JUST BEFORE DAILYLOGGUI IS MADE VISIBLE.
function DailylogGUI_OpeningFcn(hObject, eventdata, h, varargin)

    % 2.1 - MATLAB instituted code, do not edit
        handles.output = hObject;   % Command-line output
        guidata(hObject, handles);  % Update handles structure

    % 2.2 - Set Callbacks for popup menu of dailylogs
        set(h.popup,'Callback',{@callback_log});       

    % 2.3 - Set the popup menu and back/forward callbacks
        set(h.forward,'Callback',{@callback_buttons});
        set(h.back,'Callback',{@callback_buttons});

    % 2.4 - Set the menu options callbacks
        set(h.exit,'Callback',{@exit});
        set(h.save,'Callback',{@savedailylog});
        set(h.openwindows,'Callback',{@openwindows});
        set(h.openimages,'Callback',{@openimages});

%--------------------------------------------------------------------------
% OUTPUTS FROM THIS FUNCTION ARE RETURNED TO THE COMMAND LINE.
function varargout = DailylogGUI_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

%--------------------------------------------------------------------------
% CALLBACK: callback_log
function callback_log(hObject,eventdata)

% Determine the filename to open
    user = get(hObject,'UserData');
    str  = get(hObject,'String');
    idx  = get(hObject,'Value');
    name = str{idx};

% Insert the daily log into the GUI
    filename = [user{1},name];
    insertdailylog(filename,hObject);

% Change log appearence to general if desired
    GUI = guidata(user{2});
    if GUI.settings.pref.log == 2; generalLOG(hObject); end

% Set current filename to open windows  and save user data and locaton
    h = guihandles(hObject);
    set(h.openwindows,'UserData',filename);
    set(h.save,'UserData',filename);
    set(h.openimages,'UserData',{user{3}(idx),user{2}});

%--------------------------------------------------------------------------
% CALLBACK: callback_buttons
function callback_buttons(hObject,~)
% CALLBACK_BUTTONS cycles forward and back for associated button and list

% Determine the button that was pushed and assign handle and movement
    h = guihandles(hObject);
    switch get(hObject,'Tag');
        case 'forward';    handle = h.popup; move = 1;
        case 'back';       handle = h.popup; move = -1;
    end

% Determine the new list location
    N = length(get(handle,'String'));
    current = get(handle,'Value');
    new     = current + move;
    if new > N; new = 1; end;
    if new < 1; new = N; end;

% Set tne new list location value
    if new >= 1 && new <= N;
        set(handle,'Value',new);
        fcall = get(handle,'Callback');
        fcall(handle,1);
    end

%--------------------------------------------------------------------------
% CALLBACK: openimages
function openimages(hObject,~)
    
% Extract user data from open images file menu
    user = get(hObject,'UserData');

% Set time of guidata to correspond to that from the daily log viewer
    gui = user{2};
    GUI = guidata(gui);
    GUInew = GUI;
    GUInew.time(1) = user{1};
    guidata(gui,GUInew);

% Open the image viewer
    callback_openimage(gui,1);

% Reset time data on GUI
    guidata(gui,GUI);
   
%--------------------------------------------------------------------------
% CALLBACK: savedailylog
function savedailylog(hObject,~)
% SAVEDAILYLOG saves daily log information
%__________________________________________________________________________
% USAGE: savedailylog(hObject,eventdata,main,loc)
%
% INPUT: hObject - handle to save menu item, contains filename to save
%        eventdata - not used, MATLAB required   
%
% PROGRAM OUTLINE:
% 1 - OPEN THE FILE FOR WRITING  
% 2 - PRINT INFORMATION TO THE FILE
% 3 - CLOSES THE FILE AND WINDOW IF DESIRED
%__________________________________________________________________________

% 1 - OPEN THE FILE FOR WRITING
    h = guihandles(hObject);   % Handles of dailylog form
    filename = get(hObject,'UserData');

    % 1.1 - Ask to overwrite if file exists
    if exist(filename,'file');
        q = questdlg('File already exists, would you like to overwrite?',...
            'Overwrite?','Overwrite','Cancel','Overwrite');
        
        if strcmpi(q,'Cancel'); return; end
    end

    % 1.2 - Check that daily log directory exists
        pathstr = fileparts(filename);
        if ~exist(pathstr,'dir'); mkdir(pathstr); end

    % 1.2 - Open the file for writing
        fid = fopen(filename,'w');
    
% 2 - PRINT INFORMATION TO THE FILE    
    name = {'name','station','date','time','thermo','keywords',...
        'layer1','layer2','layer3','layer4','layer5','layer6'};

    n = length(name); 

    % Prints the strings of each field except for comment field, which 
    % may contain multiple lines so is handled seperatly
    for i = 1:n
        type = get(h.(name{i}),'Style');   
        if strcmpi(type,'popupmenu')
            str = num2str(get(h.(name{i}),'Value')-1);
        else
            str = get(h.(name{i}),'String');
        end

        if strcmpi(str,''); str = 'none'; end
        fprintf(fid,'%s\n',str); 
    end

    % Prints the comments window into a series of strings
    com = get(h.comment,'String');
    for i = 1:size(com,1)
        fprintf(fid,'%s\n',com(i,:));
    end

% 3 - CLOSES THE FILE AND WINDOW IF A LOG IS BEING ADDED
    fclose(fid);
    if strcmpi(get(h.openmenu,'Visible'),'off');
        close(h.figure1);
    end

%--------------------------------------------------------------------------
% CALLBACK: openwindows
function openwindows(hObject,~)
    name = get(hObject,'UserData'); % Current filename
    winopen(name);
    
%--------------------------------------------------------------------------
% CALLBACK: EXIT
function exit(hObject,~) 
    h = guihandles(hObject); close(h.figure1);
    
%--------------------------------------------------------------------------
% SUBFUNCTION: insertdailylog
function insertdailylog(name,h)
% INSERTDAILYLOG inserts the data read from the text file in "name" into
% the panel in handle "h".
%__________________________________________________________________________
% USAGE: insertdailylog(name,h)
%
% INPUT: name = text file name where the daily log data is stored
%        h = handle of current panel where data will be inserted
% 
% OUTPUT: none
%
% PROGRAM OUTLINE:
% 1 - OPEN FILE AND EXTRACT EACH LINE OF TEXT
% 2 - INSERT TEXT INTO GUI    
%__________________________________________________________________________

% 1 - OPEN FILE AND EXTRACT EACH LINE OF TEXT
    fid = fopen(name,'r');                  % Opens file
    txt = textscan(fid,'%s','delimiter','\n'); txt = txt{:}; % Reads text
    fclose(fid);                            % Close file

% 2 - INSERT TEXT INTO GUI    
    n = guihandles(h);  % Handles to each field
    N = length(txt);    % Number of fields (rows of text in file)

    % Tags where the data shall be inserted
    L = {'name','station','date','time','thermo','keywords','layer1',...
        'layer2','layer3','layer4','layer5','layer6'};

    % Loop through each tag and insert the text
    for i = 1:length(L);
        set(n.(L{i}),'String',txt{i},'Style','edit');
    end

    % Handles the Additional Comments section, which may contain mulitple
    % lines
    if N > length(L)
         comment = txt{length(L) + 1};  % First line of comment section

         % Additional comment lines
         for i = length(L)+2:N; comment = char(comment,txt{i}); end

         % Set comment to figure
         set(n.comment,'String',comment);
    end

%--------------------------------------------------------------------------
% SUBFUNCTION: generalLOG
function generalLOG(main)
% GENERALLOG changes the daily log form to only include a window for
% entering text; all of the fields exists but are simply made invisible so
% that the user may not change these options.  The saving of the log
% does not change
%__________________________________________________________________________
% USAGE:generalLOG(main)
%
% INPUT: main = handle of the daily log window as output from DailylogGUI
%
% OUTPUT: none
%__________________________________________________________________________

% Gather handles of daily log form
    h = guihandles(main);
    L = {'name','station','date','time','thermo','keywords','layer1',...
        'layer2','layer3','layer4','layer5','layer6'};
% Make all objects invisibile
    for i = 1:length(L); set(h.(L{i}),'visible','off'); end

% Show the popupmenu and back forward buttons
    set(h.popup,'visible','on');%,'units','normalize',...
      %  'position',[0.75,0.88,0.24,0.1]);
    set(h.back,'visible','on');
    set(h.forward,'visible','on');
    
% Show the menu items
    set(h.filemenu,'visible','on'); set(h.openmenu,'visible','on');
    set(h.save,'visible','on');     set(h.openwindows,'visible','on');
    set(h.exit,'visible','on');     set(h.openimages,'visible','on');

% Show the figure and panel
    set(h.figure1,'Visible','on');  
    set(h.panel,'visible','on','BorderType','None');

% Show the panel and comment window and resize to fit the figure window
    set(h.comment,'visible','on','Units','Normalized',...
        'Position',[0,0,1,1]);