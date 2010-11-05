function [fig,ax] = XYscatter(varargin)
% XYscatter is custom plotting program based on MATLAB plot function.
%
% SYNTAX:
%   XYscatter(X,Y)
%   XYscatter(X1,Y1,X2,Y2,...,Xn,Yn)
%   XYscatter(fX1,Y1,X2,Y2,...,Xn,Yng)
%   XYscatter(...,'PropertyName', propertyvalue,...)
%   [fig,ax] = XYscatter(...)
%
% DESCRIPTION:
% XYscatter(X,Y) creates a standard figure the same as the MATLAB func-
%   tion plot for the numeric data provided in the X and Y variables. Ad-
%   ditionally, XYscatter will prompt to input x- and y-axis labels, title,
%   and legend entries.
% XYscatter(X1,Y1,X2,Y2,...,Xn,Yn) operates as above but allows the user
%   to input pairs of X and Y variables as in the the MATLAB function plot.
% XYscatter(fX1,Y1,X2,Y2,...,Xn,Yng) operates as exactly as the previous
%   example; however, the input is contained in a cell array.
% XYscatter(...,'PropertyName', propertyvalue,...) operates as above,
%   but allows for the control of the plot using property modifers similar
%   to the standard figgure and axes properties built into MATLAB.
% [fig,ax] = XYscatter(...) operates exactly asdescribed but returns the
%   figure and axes handles that are generated.
%
% PROGRAM OUTLINE:
% 1 - INITILIZE PARAMETERS
% 2 - SEPERATES DATA FROM OPTIONS
% 3 - SEPERATE THE PROPERTY MODIFIERS AND SECONDARY AXIS DATA
% 4 - PREPARE DATA FOR PLOTTING
% 5 - PLOT DATA
% 6 - BUILD SLIDERS, LIMITBOXES, AND CONTEXT MENUS
% 7 - APPLY SETTINGS AND PLOT LIMITS
% 8 - STORE ABSOLULTE LIMITS OF DATA
% SUBFUNCTION: subfunction_options
% SUBFUNCTION/CALLBACK: setup
%   SETUP >> SUBFUNCTION: annotatefigure
%   SETUP >> SUBFUNCTION: linespec
%       SETUP >> LINESPEC >> SUBFUNCTION: findvalue
%   SETUP >> SUBFUNCTION: addlegend
%   SETUP >> SUBFUNCTION: getaxislabels
%   SETUP >> SUBFUNCTION: toggle
% SUBFUNCTION: subfunction_preparedata
%   SUBFUNCTION_PREPAREDATA >> SUBFUNCTION: trimdata
% SUBFUNCTION: subfunction_plotdata
%   SUBFUNCTION: subfunction_plotdata >> plotcontour
% SUBFUNCTION: subfunction_appenddata
% SUBFUNCTION: subfunction_plotci
% SUBFUNCTION: subfunction_builduicontrols
% SUBFUNCTION: subfuction_figuremenu
% SUBFUNCTION: subfunction_linemenu
% SUBFUNCTION: subfunction_textmenu 
% SUBFUNCTION: slider_control 
% SUBFUNCTION: limit_control 
% SUBFUNCTION: subfunction_limits
%   SUBFUNCTION_LIMITS >> SUBFUNCTION: set_axis
% SUBFUNCTION: subfunction_sliderlimits
% CALLBACK: callback_editline
% CALLBACK: callback_editlinecolor
% CALLBACK: callback_deleteline
% CALLBACK: callback_export
% CALLBACK: callback_limitbox
% CALLBACK: callback_slider
% CALLBACK: callback_scroll
% CALLBACK: callback_stepsize
% CALLBACK: callback_zoom
% CALLBACK: callback_movetext
% CALLBACK: callback_movecursor
% CALLBACK: callback_contoursection
%__________________________________________________________________________

% 1 - INITILIZE PARAMETERS
    opt = {};    % User supplied property modifier options

% 2 - SEPERATES DATA FROM OPTIONS
    % 2.1 - When input data is a cell array, all remaining inputs are
    %   considered property modifier inputs
        if iscell(varargin{1});
            C1 = varargin{1};    
            if nargin > 1;    opt = varargin(2:nargin); end

    % 2.2 - When input data is X1,Y1,X2,Y2,..., searches all inputs and
    %   when a non-numerical is encountered all remaining input is
    %   considered a property modifer inputs
        else
            for i = 1:nargin; n(i) = isnumeric(varargin{i}); end
            idx = find(n==0,1);
            if isempty(idx); C1 = varargin; 
            else      C1 = varargin(1:idx-1); opt = varargin(idx:nargin);
            end
        end

% 3 - SEPERATE THE PROPERTY MODIFIERS AND SECONDARY AXIS DATA
    [a,C2] = subfunction_options(opt);

% 4 - PREPARE DATA FOR PLOTTING
    [X1,Y1] = subfunction_preparedata(C1,a);
    [X2,Y2] = subfunction_preparedata(C2,a,'secondary');

% 5 - PLOT DATA
    % 5.1 - Create new plots
    if isempty(a.append) || ~ishandle(a.append);
        [fig,ax] = subfunction_plotdata(X1,Y1,X2,Y2,a); 

    % 5.2 - Append data to existing data
    else
        [fig,ax] = subfunction_appenddata(X1,Y1,X2,Y2,a); 
    end

% 6 - BUILD SLIDERS, LIMITBOXES, AND CONTEXT MENUS
    % 6.1 - Build controls and figure menu (don't build when appending)
        if isempty(a.append) || ~ishandle(a.append);
            subfunction_builduicontrols(fig,ax)
            subfunction_figuremenu(fig);
        end

    % 6.2 - Build line context menus
        subfunction_linemenu(findobj(fig,'Type','line'));

% 7 - APPLY SETTINGS AND PLOT LIMITS
    % 7.1 - Place figure settings in guidata for figure
    %    a = guidata(gcf); % Collect latest guidata
        a.figure = fig;   % Add the figure handle
        guidata(fig,a);   % Update guidata

    % 7.2 - Build list of items to intilize
        A = {'xlimit','ylimit','y2limit','xzoom','yzoom','colormap',...
                'y2zoom','xstepbox','ystepbox','y2stepbox',...
                'xgrid','ygrid','y2grid','xdir','ydir','y2dir',...
                'intlab','legend','legend2','editfont','interpreter',...
                'genericline','linespec','linespec2','facecolor',...
                'units','size','windowstyle','annotation',...
                'yci','xci','y2ci','x2ci','menubar','xminorgrid',...
                'yminorgrid','xminortick','yminortick','resizelegend',...
                'tight'};

    % 7.3 - Apply axis limits
        subfunction_limits;

    % 7.4 - Set absolulte limits of data
        subfunction_sliderlimits;
      
    % 7.5 - Apply setup function to setup figure
        for i = 1:length(A); setup(fig,'initilize',A{i}); end
        
    % 7.6 - Export figure if desired;
        if ~isempty(a.exportfile); callback_export(fig,[]); end
        
%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_options
function [a,C2] = subfunction_options(in)
% SUBFUNCTION_OPTIONS seperates user inputed property modifiers

n = length(in);
% 1 - SET THE DEFAULT SETTINGS       
    a.advanced = struct([]);
    a.addto = 1;  
    a.annotation = '';
    a.annotationbackground = 'none';
    a.annotationbox = 'k';
    a.annotationcoord = [];
    a.annotationlabel = '';
    a.append = [];  
    a.area = 'off';
    a.axescolor = [0.94,0.94,0.94];
    a.caxis = [];
    a.colorbar = 'off';
    a.colorbarlabel = '';
    a.colormap = 'gray';
    a.colororder = lines(10);
    a.contour = 'off';
    a.contourfill = 'on';
    a.contourlinecolor = 'none';
    a.contourxunits = 1;
    a.contouryunits = 1;
    a.dateform = 'mm/dd/yy HH:MM';
    a.interpreter = 'none';
    a.exportfile = ''; a.exportpath = cd;
    a.facecolor = '';
    a.fontname = 'Arial'; a.fontweight = 'normal'; 
    a.fontsize = 10; a.fontunits = 'points'; a.fontangle = 'normal';
    a.legend = NaN; a.legend2 = NaN;
    a.linespec = {}; a.linespec2 = {};
    a.linestyle = '-'; a.linestyle2 = '--';
    a.linewidth = 1; a.linewidth2 = 1;
    a.linestyleorder = '';
    a.load = [];
    a.logx = 'off'; a.logy = 'off';
    a.location = 'NorthWest'; a.location2 = 'NorthEast';
    a.menubar = 'figure';
    a.marker = 'none'; a.marker2 = 'none';
    a.markersize = 2; a.markersize2 = 2;
    a.name = '';
    a.prompt = 'on';
    a.resizelegend = 'off';
    a.save = [];
    a.secondary = {};
    a.size = [7,5];
    a.tight = 'off';
    a.title = '';
    a.units = 'inches';
    a.windowstyle = 'normal';
    a.xci = []; a.yci = []; a.x2ci = []; a.y2ci = [];
    a.xcicolor = {}; a.ycicolor = {}; a.x2cicolor = {}; a.y2cicolor = {};
    a.xciwidth = 0.01; a.yciwidth = 0.01;
    a.xdatetick = 'off'; a.ydatetick = 'off'; a.y2datetick = 'off';
    a.xdir = 'normal'; a.ydir = 'normal'; a.y2dir = 'normal';
    a.xgrid = 'on'; a.ygrid = 'on'; a.y2grid = 'off';
    a.xlabel = NaN; a.ylabel = NaN; a.y2label = NaN;
    a.xlim = []; a.ylim = []; a.y2lim = [];
    a.xlimit = 'off'; a.ylimit = 'off'; a.y2limit = 'off';
    a.xminorgrid = 'off'; a.yminorgrid = 'off'; a.y2minorgrid = 'off';
    a.xminortick = 'off'; a.yminortick = 'off'; a.y2minortick = 'off';
    a.xstep = []; a.ystep = []; a.y2step = [];
    a.xstepbox = 'off'; a.ystepbox = 'off'; a.y2stepbox = 'off';
    a.xtick = []; a.ytick = []; a.y2tick = [];
    a.xticklabel = {}; a.yticklabel = {}; a.y2ticklabel = {};
    a.xtrim = []; a.ytrim = []; a.y2trim = [];
    a.xzoom = 'off'; a.yzoom = 'off'; a.y2zoom = 'off';

% 2 - CHECK FOR APPEND OPTION (uses current plot structure for defaults)
    idx = 1:2:length(in);
    i = strmatch('append',lower(in(idx)));
    if i ~= 0;
        handle = in{idx(1)+1}; 
        a = guidata(handle);
        a.secondary = {}; a.advanced = struct([]);
    end

% 3 - APPLY/LOAD DEFAULT SETTINGS
    if ~ispref('xyscatter','default');
        addpref('xyscatter','default',a);
    else
        A = getpref('xyscatter','default');
        a = checkpref(A,a);
    end

% 4 - SEPERATE THE DATA FROM OPTIONS
list = fieldnames(a); k = 1;
while k < n
    % 4.1 - Get modifier tag, associated data, and initilize for next loop
        opt = in{k}; value = in{k+1}; match = '';  k = k + 2;
      
    % 4.2 - Apply the advanced option    
        if strcmpi(opt,'advanced');
            b = value; fname = fieldnames(b);
            for i = 1:length(fname); a.(fname{i}) = b.(fname{i}); end
        end
        
    % 4.3 - Load stored settings
        if strcmpi(opt,'load');
            if ~ispref('xyscatter',value);
                warning('MATLAB:XYscatter:subfunction_options',...
                    'Desired settings do not exists, using default.');
            else
                A = getpref('xyscatter',value);
                a = checkpref(A,a); 
            end
        end
        
    % 4.4 - Compare modifier tag with available options
        if ischar(opt); 
            match = strmatch(lower(opt),lower(list),'exact'); 
            if ~isempty(match); a.(list{match}) = value; end
        end

    % 4.5 - Produce an error message if modifier is not found
        if isempty(match);
            mes = ['The property modifier, ',opt,', was not recoignized.'];
            disp(mes);
        end
end

% 5 - RETURN SECONDARY AXIS DATA
    C2 = a.secondary;
    
% 6 - SAVE SETTINGS, IF DESIRED
    if ~isempty(a.save);
        apply = a.save; a.save = []; a.secondary = [];
        if ~ispref('xyscatter',apply);
            addpref('xyscatter',apply,a);
        else
            ques = ['The settings, ',apply,' already exist, do you ',...
                'want to overwrite?'];
            q = questdlg(ques,'Overwrite?','Yes');
            if strcmpi(q,'yes'); setpref('xyscatter',apply,a); end
        end
    end
    
%--------------------------------------------------------------------------
% SUBFUNCTION: options >> checkpref
function A = checkpref(A,a)
% CHECKPREF checks that loaded pref's have the needed fields

fn = fieldnames(a);
for i = 1:length(fn);
    if ~isfield(A,fn{i}); A.(fn{i}) = a.(fn{i}); end
end

%--------------------------------------------------------------------------
% SUBFUNCTION/CALLBACK: setup
function setup(hObject,eventdata,varargin)
% SETUP applies user figure settings

% 1 - SET INTILIZATION CASE (trig == 1 if initilizing the figure)
    trig = 0;
    if ischar(eventdata) && strcmpi(eventdata,'initilize'); trig = 1; end

% 2 - COLLECT FIGURE WINDOW HANDLES AND SETTINGS
    a = guidata(hObject);
    h = guihandles(hObject);
    
% 3 - FIND AXIS HANDLES, CORRECTING FOR EXISTANCE OF A LEGEND
    ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend',...
        '-not','tag','resizelegend');
    ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend',...
        '-not','tag','resizelegend');

% 4 - SET VISIBILITY OF SECONDARY Y-AXIS MENU
    if isempty(ax2); 
        set(h.y2menu,'visible','off'); 
        set(h.y2stepbox_tool,'visible','off');
        set(h.y2limit_tool,'visible','off');  
    else
        set(h.y2menu,'visible','on'); 
        set(h.y2stepbox_tool,'visible','on');
        set(h.y2limit_tool,'visible','on');
    end

item = varargin{1};
switch lower(item)
% 5 - SET WINDOWSTYLE OPTION
case {'windowstyle'}; set(gcf,'WindowStyle',a.windowstyle);

% 6 - SET VISIBILITY OF BOXES AND SLIDERS
case {'xlimit','ylimit','y2limit','xzoom','yzoom','y2zoom',...
        'xstepbox','ystepbox','y2stepbox'}
   % 6.1 - Change the checkbox status
        a.(item) = toggle(h.(item),a.(item),trig);

    % 6.2 - Set visibility of associated objects
        user = get(h.(item),'UserData');
        for i = 1:length(user); 
            set(h.(user{i}),'Visible',a.(item)); 
        end

% 7 - TOGGLE GRID LINES ON/OFF
% 7.1 - Major grid lines
 case {'xgrid','ygrid','y2grid'};
    % 7.1.1 - Change the checkbox status 
         a.(item) = toggle(h.(item),a.(item),trig);

    % 7.1.2 - Set the status of the grid
        set(ax1,'XGrid',a.xgrid); 
        set(ax1,'YGrid',a.ygrid);
        if ~isempty(ax2); set(ax2,'YGrid',a.y2grid); end
        
% 7.2 - Minor grid lines
case {'xminorgrid','yminorgrid','y2minorgrid'}
    a.(item) = toggle(h.(item),a.(item),trig);
    set(ax1,'XMinorGrid',a.xminorgrid);
    set(ax1,'YMinorGrid',a.yminorgrid);
    if ~isempty(ax2); set(ax2,'YMinorGrid',a.y2minorgrid); end   

% 7.3 - Minor tick marks
case {'xminortick','yminortick','y2minortick'}
    a.(item) = toggle(h.(item),a.(item),trig);
    set(ax1,'XMinorTick',a.xminortick);
    set(ax1,'YMinorTick',a.yminortick);
    if ~isempty(ax2); set(ax2,'YMinorTick',a.y2minortick); end        

% 8 - TOGGLE THE AXIS DIRECTION
case {'xdir','ydir','y2dir'}
    % 8.1 - Change the checkbox status 
        if trig == 0; 
            new = toggle(h.(item),get(h.(item),'Checked'),trig);
        else
            if strcmpi(a.(item),'reverse');
                set(h.(item),'Checked','on'); 
                new = 'on';
            else new = 'off';
            end
        end

    % 8.2 - Extablish axis and limit boxes to operate on
        switch item
            case 'xdir';  oper = 'XDir'; ax = ax1; 
            case 'ydir';  oper = 'YDir'; ax = ax1; 
            case 'y2dir'; oper = 'YDir'; ax = ax2; 
        end

    % 8.3 - Reverse axis and limit box tags
        switch new
            case 'on';  set(ax,oper,'reverse');  a.(item) = 'reverse';
            case 'off'; set(ax,oper,'normal');   a.(item) = 'normal';
        end

% 9 - INSERT AXIS LABELS
case {'setlabels','intlab'}
    % 9.1 - Update the axis labels
        a = getaxislabels(a,ax1,ax2,item);

    % 9.2 - Set primary axis labels
        xlabel(ax1,a.xlabel); ylabel(ax1,a.ylabel); 
        title(ax1,a.title); set(gcf,'Name',a.name);

    % 9.3 - Set secondary axis labels
        if ishandle(ax2);  ylabel(ax2,a.y2label); end

    % 9.4 - Add menu items for editing individual test items
        htxt = unique(findall(gcf,'Type','Text'));
        subfunction_textmenu(htxt);

% 10 - INSERT PRIMARY AXIS LEGEND
case {'legend'}
    if isempty(a.legend); legend(ax1,'off'); return;
%     elseif  trig == 0;   
%         a.legend = addlegend(ax1,NaN,'Y-axis',a.location);    
    else            
        a.legend = addlegend(ax1,a.legend,'Y-axis',a.location); 
    end

% 11 - INSERT SECONDARY AXIS LEGEND
case {'legend2'}
    if isempty(a.legend2); legend(ax2,'off'); return;
    elseif isempty(a.secondary); return;
%     elseif  trig == 0;  
%         a.legend2 = addlegend(ax2,NaN,'Y2-axis',a.location2);    
    else            
        a.legend2 = addlegend(ax2,a.legend2,'Y2-axis',a.location2); 
    end

% 12 - ADJUST UNITS/LATEX SUB-MENU TOGGLES
case {'interpreter'}
    % 12.1 - Update check mark and selection
        item = a.interpreter;

        % 12.1.1 - Case when intilizing
        if trig == 1; set(h.(item),'Checked','on'); item = 'tex';
       
        % 12.1.2 - Case when selected from menu
        else
            c = get(get(h.(item),'Parent'),'Children');
            set(c,'Checked','off'); 
            set(hObject,'Checked','on');
            a.interpreter = get(hObject,'tag');
        end

    % 12.2 - Apply settings
        h1 = findobj(gcf,'-property','Interpreter');
        h2 = findall(gcf,'Interpreter',item);
        set([h1;h2],'Interpreter',a.interpreter);

% 13 - CHANGE FONT ATTRIBUTES
case {'editfont'}
    % 13.1 - Case when not-initializing
        if trig == 0;
            s = uisetfont(a); 
            if isstruct(s); fn = fieldnames(s);
                for i = 1:length(fn); a.(lower(fn{i})) = s.(fn{i}); end
        end,end

    % 13.2 - Get handles of figure properties
        if length(varargin) == 2 && ishandle(varargin{2});
            handles = varargin{2};           
        else
            h1 = findobj(gcf,'-property','fontsize','-not',...
                                'Type','uicontrol');  
            h2 = findall(gcf,'Type','Text');
            handles = [h1;h2];
        end
 
    % 13.3 - Set the font properties
        set(handles,'FontName',a.fontname,'FontWeight',a.fontweight,...
                'FontSize',a.fontsize,'FontUnits',a.fontunits,...
                'FontAngle',a.fontangle);

% 14- CHANGE/SET AXIS COLOR
case {'axescolor'}
    % 14.1 - Prompt user for color if called from menu
        if trig == 0; c = colorui;
        else          c = a.axescolor;
        end

    % 14.2 - Set axis color
        set(ax1,'Color',c);
 
% 15 - TOGGLE UNITS
case {'units'}
    % 15.1 - Case when figure is being initilized
    if trig == 1; 
        set(h.(lower(a.units)),'Checked','on'); 

    % 15.2 - Case when called from figure context meun
    else
        h1 = get(h.resize,'Children'); 
        set(h1,'Checked','off');
        toggle(hObject,'off',trig);
        a.units = get(hObject,'tag');
    end

% 16 - SET FIGURE SIZE
case {'size'}
    % 16.1 - Prompt user for new figure size
    if trig == 0;
        mes = {'Enter figure width:';'Enter figure height:'};
        s = inputdlg(mes,'Figure size...',1,...
            {num2str(a.size(1)),num2str(a.size(2))});
        if isempty(s); return; end
        a.size(1) = str2double(s{1}); a.size(2) = str2double(s{2});
    end

    % 16.2 - Set figure size
        set(gcf,'Units',a.units)
        P = get(gcf,'Position');
        set(gcf,'Position',[P(1:2),a.size]);
        set(gcf,'Units','Normalized');

% 17 - SET THE AXIS TO FIT TIGHT
case {'tight'}
    % 17.1 - Check that status is on (case when intilizing figure)
        if trig == 1 && strcmpi(a.tight,'off'); end

    % 17.2 - Toggle off any text interpretation
        h1 = findobj(gcf,'-property','Interpreter');
        h2 = findall(gcf,'Interpreter',a.interpreter);
        set([h1;h2],'Interpreter','none');
        set(h.tight,'Checked','on');

    % 17.3 - Gather axis information
        tight = get(ax1,'TightInset');
        tight2 = [0,0,0,0];   

    % 17.4 -  Determine new axis limits
        if ishandle(ax2); tight2 = get(ax2,'TightInset'); end
        width = tight(3)+tight(1)+tight2(3)-tight2(1);
        new = [tight(1),tight(2),1-width,1-tight(4)-tight(2)];

    % 17.5 - Set new axis limits
        set(ax1,'Position',new);
        if ishandle(ax2); set(ax2,'Position',new); end

    % 17.5 - Return the intepreter
        set([h1;h2],'Interpreter',a.interpreter);
 
% 18 - SET THE LINESPEC OF PRIMARY AXIS
case {'linespec'}
    if ishandle(ax1) && ~isempty(a.linespec)
        p = flipdim(findobj(ax1,'Type','Line'),1);
        if ~iscell(a.linespec); a.linespec = {a.linespec}; end
        for i = 1:length(a.linespec); linespec(p(i),a.linespec{i}); end
    end
        
% 19 - SET THE LINESPEC OF SECONDARY AXIS
case {'linespec2'}
    if ishandle(ax2) & ~isempty(a.linespec2)
        if ~iscell(a.linespec2); a.linespec2 = {a.linespec2}; end
        p = flipdim(findobj(ax2,'Type','Line'),1); 
        if length(p) > 1; p = flipdim(p); end
        for i = 1:length(a.linespec2); linespec(p(i),a.linespec2{i}); end
    end
        
% 20 - SET THE COMPLETE GENERIC LINE PROPERTIES
case {'genericline'}   
    % 20.1 - Gather priarmy/secondary line handles
        p1 = findobj(ax1,'Type','Line');
        p2 = findobj(ax2,'Type','Line');

    % 20.2 - Set appearance of primary and secondary lines, with the usage
    % of LineStyleOrder option
    if ~isempty(a.linestyleorder);
        for i = 1:length(p1);
            set(p1(i),'LineWidth',a.linewidth,...
            'Marker',a.marker,'MarkerSize',a.markersize);
        end
        for i = 1:length(p2);
            set(p2(i),'LineWidth',a.linewidth2,...
            'Marker',a.marker2,'MarkerSize',a.markersize2);
        end
    end
        
    % 20.3 - Set appearance of primary and secondary lines, with out usage
    % of LineStyleOrder option
    if isempty(a.linestyleorder);
        for i = 1:length(p1);
            set(p1(i),'LineWidth',a.linewidth,'LineStyle',a.linestyle,...
            'Marker',a.marker,'MarkerSize',a.markersize);
        end
        for i = 1:length(p2);
            set(p2(i),'LineWidth',a.linewidth2,'LineStyle',a.linestyle,...
            'Marker',a.marker2,'MarkerSize',a.markersize2);
        end
    end

% 21 - ADD TEXTARROW ANNOTATION
case {'annotation'}
    if trig == 1 && isempty(a.annotation); return; end
    annotatefigure([],[],a.annotation);
    a.annotation = ''; a.annotationcoord = []; a.annotationlabel = '';
    guidata(gcf,a);

% 22 - CHANGE THE COLORMAP
case 'colormap';
    colormap(a.colormap);

% 23 - SET FACECOLOR FOR STACKED AREA PLOT
case 'facecolor';
    if ~isempty(a.facecolor);
        % 23.1 - Gather area hobjects
            hobj = findobj(ax1,'Type','hggroup');

        % 23.2 - Set the color of the objects
        for i = 1:length(hobj); 
            set(hobj(i),'FaceColor',a.facecolor{i}); 
        end
    end

% 24 - PLOT THE CONIFIDENCE LEVEL INTERVALS
case {'xci','yci'};
    if ~isempty(a.(item)); subfunction_plotci(item); end
    
% 25 - SET FIGURE MENU VALUE
case 'menubar'
    set(gcf,'MenuBar',a.menubar);
    
% 26 - RESIZE LEGEND
case 'resizelegend'
    if trig == 1 && strcmpi(a.(item),'off'); return; end
    resizelegend(gcf);
    
end
% UPDATE THE FIGURE GUIDATA
    guidata(gcf,a);

%-------------------------------------------------------------------------
% SETUP >> SUBFUNCTION: annotatefigure
function annotatefigure(~,~,type)
% ANNOTATEFIGURE adds a text, line, etc. annotation to the figure

% 1 - CHECK FOR INITILIZATION CONDITIONS
    % 1.1 - Gather axis and figure informaion
        ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
        set(gcf,'CurrentAxes',ax1);
        a = guidata(gcf);

    % 1.2 - If a single value is entered convert to a cell
        if ~iscell(type);
            type  = {type}; 
            coord = {a.annotationcoord}; text  = {a.annotationlabel};
        elseif iscell(type);
            coord = a.annotationcoord; text  = a.annotationlabel; 
        end

% 2 - DETERMINE THE TYPE OF ANNOTATION BEING ADDED
for i = 1:length(type); % Loops through mulitiple annotation entries

    switch lower(type{i})
        case {'textarrow'}
            mes = ['(1) select the location of the text box, ',...
                'then (2) the location for placing arrow.']; 
            opt = {'TextBackgroundColor','TextEdgeColor'};
            txt    = 'on'; C = 2;
        case {'line','arrow','doublearrow'}
            mes = ['(1) select the start location of the line, ',...
                'then (2) the location for placing arrow.'];
            txt = 'off';   C = 2;
        case {'textbox','ellipse','rectangle'}
            mes = ['Select the lower-left location of the text.  ']; 
            opt = {'BackgroundColor','EdgeColor'};
            txt    = 'on'; C = 1;
    end

% 3 - DETERMINE LOCATIONS
    % 3.1 - Prompt user if not coordinates exist
        if isempty(coord{i})
            m = msgbox(mes,'Add text label...','Help','Modal');
            uiwait(m); str = '';
            [x,y] = ginput(C);          % x- and y- coordinate of clicks
    
    % 3.2 - Use user supplied input
        else
            str  = text{i};  x = coord{i}(:,1);   y = coord{i}(:,2);
        end

% 4 - CALCULATE THE LOCATION, NORMALIZED TO FIGURE SIZE OF ARROW 
    % 4.1 - Get axis limits
        X = get(gca,'XLim');        % x-axis limits
        Y = get(gca,'YLim');        % y-axis limits
        p = get(gca,'Position');    % Axis position (normalized)

    % 4.2 - Normlize the given inputs
        x = p(1) + ((x-X(1))./(X(2)-X(1))).*p(3); % x-coordinate
        y = p(2) + ((y-Y(1))./(Y(2)-Y(1))).*p(4); % y-coordinate

    % 4.3 - Build proper input
        if     C == 2;    input = {x,y};   
        elseif C == 1;    input = {[x,y,0,0]};
        end

% 5 - PROMPT USER FOR TEXT STRING (IF NOT INPUTED)
    if isempty(str) && strcmpi(txt,'on');
        str = inputdlg('Enter text for current label:','Add text...');
        if isempty(str); return; end
        str = str{1};
    end

% 6 - PLACE TEXTARROW ANNOTATION ON FIGURE
    ha = annotation(type{i},input{:});
    if strcmpi(txt,'on');
        set(ha,'String',str,opt{1},a.annotationbackground,...
                opt{2},a.annotationbox);
        setup(gcf,'initilize','editfont');
        setup(gcf,'initilize','interpreter');
        subfunction_textmenu(ha);
    end

% Ends loop for mulitple inputs (Sec.2)
end 

%--------------------------------------------------------------------------
% SUBFUNCTION: setup >> linespec
function linespec(handle,spec)
% LINESPEC sets the linesytle, marker, and color of a line

% 1 - SET POSSIBLE OPTIONS
    A{1} = {'-',':','--','-.'};
    A{2} = {'+','o','*','.','x','s','d','^','v','>','<','p','h'};
    A{3} = {'r','g','b','c','m','y','k','w'};

% 2 - FIND MATCHING VALUES
    for i = 1:length(A); [m{i},spec] = findvalue(A{i},spec); end

% 3 - APPLY THE SETTINGS
    set(handle,'LineStyle',m{1});
    set(handle,'Marker',m{2});
    if ~strcmpi(m{3},'none'); set(handle,'Color',m{3}); end

%--------------------------------------------------------------------------
% SUBFUNCTION: setup >> linespec >> findvalue
function [match,spec] = findvalue(test,spec)
% FINDVALUE searchs a linespec string and returns the matched paramter
match = 'none';
for i = 1:length(test);
    [~,~,~,mat] = regexp(spec,test{i});
    if ~isempty(mat) && strcmpi(mat{1},test{i}); match = mat{1}; end
end
spec = regexprep(spec,match,'');

%--------------------------------------------------------------------------
% SETUP >> SUBFUNCTION: addlegend
function leg = addlegend(ax,leg,Lab,loc)
% ADDLEGEND places a legend on the current figure and prompts if needed

% 1 - GATHER LINE INFORMATION 
    % 1.1 - Determine the type for gathering legend names
        a = guidata(gcf); type = 'line';
        if strcmpi(a.area,'on'); type = 'hggroup'; end

    % 1.2 - Get line info and exit if it does not exist
        hline = flipdim(findobj(ax,'Type',type),1);
        if isempty(hline); return; end
        name = cellstr(get(hline,'DisplayName'));       

% 2 - IF NaN IS USED PROMPT THE USER
    if isnumeric(leg)
        for i = 1:length(name);
            new{i} = ['Data ',num2str(i)];
            prompt{i} = ['Enter name for line #',num2str(i),':'];
        end
        
        if ~strcmpi(a.prompt,'off'); 
            new = inputdlg(prompt,[Lab,'...'],1,name);
        end
        if isempty(new); leg = name; else leg = new; end
    end

% 3 - BUILD LEGEND
    % 3.1 - Check that "leg" is a cell array
        if ischar(leg); leg = {leg}; end

    % 3.2 - Check that "leg" is oriented vertically
        if size(leg,1) == 1; leg = leg'; end

    % 3.3 - Append legend entries 
        if length(hline) > length(leg); 
            n = length(name); m = length(leg);
            leg = [name(1:n-m);leg];
        end

    % 3.4 - Build legend
        if length(leg) > length(hline); 
            disp('Extra legend entries omitted.');
            leg = leg(1:length(hline));
        end
        set(hline,{'DisplayName'},leg); 
        legend(ax,leg,'Location',loc);
        
%--------------------------------------------------------------------------
% SETUP >> SUBFUNCTION: getaxislabels
function a = getaxislabels(a,ax1,ax2,item)
% GETAXISLABELS prompts user for axis and figure labels

% 1 - SEARCH FOR EXISTING LABELS
    % 1.1 - Search primary axis labels and title
        M = {'xlabel','ylabel','Title'};       
        for i = 1:length(M); 
            e = get(get(ax1,M{i}),'String');
            if ~isempty(e); a.(M{i}) = e; end
        end

    % 1.2 - Search secondary axis labels
        if ishandle(ax2);
            e = get(get(ax2,'YLabel'),'String');
            if ~isempty(e); a.y2label = e; end
        end

% 2 - DETERMINE THE PROMPT STATUS
    % Based on default NaN values if the value is a numeric set that will 
    % trigger prompting and also set the default string to a blank value 
    % for use when prompting or use the input value
        N = {a.xlabel,a.ylabel,a.y2label,a.title,a.name};
        for i = 1:length(N); 
            val(i) = isnumeric(N{i}); 
            if val(i) == 1; def{i} = ''; else def{i} = N{i}; end
        end

% 3 - SET A TRIGGER FOR PROMPTING USER TO ENTER INFORMATION
        t = '';
        if strcmpi(item,'setlabels');               t = 'prompt';
        elseif ishandle(ax2) & sum(val(1:3)) > 0;   t = 'prompt'; 
        elseif sum(val(1:2)) > 0;                   t = 'prompt';
        end

% 4 - EXIT IF THE USER IS NOT TO BE PROMPTED
    if strcmpi(a.prompt,'off'); return; end
    if ~strcmpi(t,'prompt'); return; end

% 5 - BUILD THE PROMPT LIST
        list = {'Enter the X-axis label:',...
                'Enter the primary Y-axis label:',...
                'Enter the plot title:',...
                'Enter figure window name:'};
        defstr = {def{1},def{2},def{4},def{5}};
        if ishandle(ax2);
            new = 'Enter the secondary Y-axis label:';
            list = [list(1:2),new,list(3:4)]; defstr = def;
        end

% 6 - PROMPT USER TO ENTER LABEL ITEMS
    c = inputdlg(list,'Enter labels...',1,defstr);
    if isempty(c) && ~strcmpi('setlabels',item); 
            for i = 1:length(list); c{i} = ''; end; 
    elseif isempty(c); return;
    end

% 7 - ENTER USER INPUTED STRINGS INTO DATA STORAGE ARRAY
    if length(list) == 4;
        a.xlabel = c{1}; a.ylabel = c{2}; a.title = c{3}; a.name = c{4};
    elseif length(list) == 5;
        a.xlabel = c{1};    a.ylabel = c{2}; 
        a.y2label = c{3};   a.title = c{4}; a.name = c{5};
    end

%--------------------------------------------------------------------------
% SETUP >> SUBFUNCTION: toggle
function chk = toggle(h,chk,trig,varargin)
% TOGGLE changes the checked status of a menu item
    if trig == 0;      
        switch chk;
            case 'on';  chk = 'off';
            case 'off'; chk  = 'on';
        end
    end
    set(h,'Checked',chk);
   
%--------------------------------------------------------------------------
% SUBFUNCTION: rebuildlegend
function callback_restorelegend(hObject,~) 

    h = findobj('Tag','resizelegend'); 
    delete(h);
    setup(hObject,[],'legend');
    setup(hObject,[],'legend2');

%--------------------------------------------------------------------------
% SUBFUNCTION: resizelegend
function resizelegend(fig)
% RESIZELEGEND creates a resizeable legend

% 1 - GATHER HANDLES FOR LEGENDS
    h = findall(fig,'Tag','legend');

% 2 - BUILD THE NEW LEGENDS     
for i = 1:length(h);  
    
    % 2.1 - Gather the legend information
    U = get(h(i),'UserData'); 
    
    % 2.2 - Create a new legend axis
    p = get(h(i),'Position');
    new = axes('parent',fig,'box','on','xtick',[],'ytick',[],'XColor','w',...
        'YColor','w','color',[1,1,1],'Position',p,'XLimMode','manual',...
        'YLimMode','manual','HandleVisibility','callback',...
        'tag','resizelegend'); 
    
    % 2.3 - Seperate the legend information for each entry
    N = length(U.handles); k = 1;
    LHtext = U.LabelHandles(1:N);
    LHline = U.LabelHandles(N+1:2:end); 

    for j = 1:N;
        C(j).LabelHandles = [LHline(j),LHtext(j)]; k = k + 3; 
        C(j).lstrings = U.lstrings{j};
        C(j).handles = U.handles(j);
    end
      
    % 2.4 - Construct the new legend
    N = length(C);
    for j = 1:N;
        W(j) = buildline(C(j),new);
    end

    % 2.5 - Resize and remove the new legend
    P = get(new,'Position');
    P(3) = P(3)*max(W);
    set(new,'Position',P);
   
    % 2.6 - Store legend information in the lines userdata
    user = get(U.handles(i),'UserData');
    user.legend = C(i);
    set(U.handles(i),'UserData',user);
    
    % 2.7 - Add a box
    x = [0,1,1,0,0];
    y = [0,0,1,1,0];
    hold on; 
    plot(new,x,y,'-k');
    
end
delete(h); 
 
%--------------------------------------------------------------------------
% RESIZELEGEND >> SUBFUNCTION: buildline
function W = buildline(C,new)
% BUILDLINE creates a new legend entry           

% 1 - GATHER INFORMATION ABOUT THE CURRENT LEGEND ENTRY
    hline = C.LabelHandles(1);
    txt = C.LabelHandles(2);
    x = get(hline,'Xdata');
    y = get(hline,'Ydata');
    e = get(txt,'Extent'); 
    p = get(txt,'Position');
    
 % 2 - DEFINE THE NEW POSITIONS FOR THE ENTRY  
    sep = 0.05;  
%     len = (x(2) - x(1))*0.75;
%     x = [sep,len];
%     p(1) = x(2);
    W = p(1) + e(3)-2*sep;

 % 3 - ASSIGN THE ENTRY TO THE NEW LEGEND   
    set(hline,'Parent',new,'Xdata',x,'Ydata',y);   
    set(txt,'Parent',new,'Position',p,'VerticalAlignment','Middle',...
        'HorizontalAlignment','left','HitTest','off');
        
%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_preparedata
function [X,Y] = subfunction_preparedata(c,a,varargin)
% SUBFUNCTION_PREPAREDATA organizes and trims inputed data for plotting.
%   This function changes a cell array input into X,Y matrices for plotting
%   c = {X1,Y1,X2,Y2,...,Xn,Yn} pairs just as in MATLAB's plot.  The input
%   arrays are filled with NaN so that X = [X1,X2,...,Xn] is a valid
%   operatation and similarly for Y.  
%       - The data MUST be organized in columns.
%       - Is able to handle X,Y1,Y2,Y3
%
%   This function also trims the data according to user specified property
%   modifier.
%__________________________________________________________________________

% 0 - RETURN IN INPUT IS EMPTY
    if isempty(c); X = []; Y = []; return; end

% 1 - DETERMINE THE LARGEST MATRIX
    for i = 1:length(c); n(i) = size(c{i},1); end

% 2 - FILL MATRICES WITH NaN
    N = max(n);             % Maximum length of any data column
	X = []; Y = [];         % Initilize output
    for i = 2:2:length(c);  % Loop through each data pair
 
        % 2.1 - Seperates the data pairs
            x = c{i-1};     % Seperate x-data
            y = c{i};       % Seperate y-data

        % 2.2 - Copies single columns for data column available, i.e. the
        % case when x = 1 column and y = mulitple columns.  The x data must
        % be reproduced for every y column so when the ouput is constructed
        % in 2.4 the pairs will be of equal size.
            wx = size(x,2); wy = size(y,2);
            if wx ~= wy
                if     wx == 1; 
                    for j = 1:wy; x(:,j) = x(:,1); end
                elseif wy == 1; 
                    for j = 1:wx; y(:,j) = y(:,1); end
                else
                    disp(['Dimension mismatch with x,y inputs ',...
                    '(convertmat), check that input is vertially oreiented.']);
        end,end

        % 2.3 - Fill empty portion with NaN
            if size(x,1) < N
                x(length(x)+1:N,:) = NaN;
                y(length(y)+1:N,:) = NaN;
            end

        % 2.4 - Construct output
            X = [X,x]; Y = [Y,y];
    end

% 3 - TRIM THE DATA IF DESIRED
    % 3.1 - Set tag for current axis
        if ~isempty(varargin); tag = 'y2trim'; else tag = 'ytrim'; end

    % 3.2 - Trim X-Data
        if ~isempty(a.xtrim); [X,Y] = trimdata(X,Y,a.xtrim); end
        if ~isempty(a.(tag)); [Y,X] = trimdata(Y,X,a.(tag)); end

%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_preparedata >> trimdata
function [X,Y] = trimdata(X,Y,rng)
% TRIMDATA removed data between the numbers in rng comparing X data

    col = size(X,2);
    for i = 1:col
        idx = X(:,i) < rng(1) | X(:,i) > rng(2);
        X(idx,i) = NaN; Y(idx,i) = NaN;
    end

%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_plotdata
function [fig,ax] = subfunction_plotdata(X1,Y1,X2,Y2,a)
% SUBFUNCTION_PLOTDATA plots x-y data onto one or two axes
   
% 1 - ESTABLISH THE FIGURE
    fig = figure('Color',[1,1,1],'Units','Normalized',....
                    'Position',[0.25,0.25,0.5,0.5]);

% 2 - PLOT DATA ON ONLY THE PRIMARY AXIS
    if isempty(X2);
        
    % 2.1 - Set necessary figure properties
        ax = axes('Parent',fig,'HitTest','off','nextplot','add',...
            'ColorOrder',a.colororder);
        if ~isempty(a.linestyleorder);
            set(ax,'LineStyleOrder',a.linestyleorder);
        end

    % 2.2 - Plot the area graph if desired    
        if strcmpi(a.area,'on'); 
            area(ax,X1,Y1);% Plot as stacked area
   
    % 2.3 - Plot as contour plot if desired    
        elseif strcmpi(a.contour,'on');  
            plotcontour(ax,a,X1,unique(Y1));

    % 2.4 - Plot traditional line graph
        else
            plot(X1,Y1);
        end

% 3 - PLOT DATA ON BOTH PRIMARY AND SECONDARY AXIS
    else
        ax = plotyy(X1,Y1,X2,Y2); 
        set(ax,'HitTest','off','nextplot','add');
    end

% 4 - SET A BOUNDING BOX AROUND PLOT AND ALLOW FOR PLOTS TO BE APPEND
    set(ax,'YColor','k');
    box('on'); hold all; 
    
%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_plotdata >> plotcontour
function plotcontour(ax,a,data,n)

% 1 - BUILD X,Y ARRAYS, see "help contour"
    y = (0:size(data,1)-1)*a.contouryunits;
    x = (0:size(data,2)-1)'*a.contourxunits;
    for i = 1:size(data,2); Y(:,i) = y; end
    for i = 1:size(data,1); X(i,:) = x; end

% 2 - BUILD CONTOUR PLOT    
    [C,h] = contourf(X,Y,data,n,'fill',a.contourfill,'linecolor',...
        a.contourlinecolor);
    
    if strcmpi(a.colorbar,'on'); 
        cbar = colorbar;
        set(get(cbar,'ylabel'),'String',a.colorbarlabel);
        set(cbar,'HandleVisibility','off'); 
    end

    if ~isempty(a.caxis); caxis(ax,a.caxis); end
    
% 3 - BUILD CONTEXTMENU ITEM
    cmenu = uicontextmenu;
    set(h,'UIContextMenu',cmenu);
    uimenu(cmenu,'Label','Vertical Section','callback',...
        {@callback_contoursection,h,'x'});
    uimenu(cmenu,'Label','Horizontal Section','callback',...
        {@callback_contoursection,h,'y'});
    
%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_appenddata
function [fig,ax] = subfunction_appenddata(X1,Y1,X2,Y2,a)
% SUBFUNCTION_APPENDDATA adds data to an existing plot

% 1 - SET FIGURE HANDLE
    % 1.1 - Return an error if a.append is not a figure handle
        if ~ishandle(a.append); 
            disp('Append input must be a figure or axis handle.'); 
            fig = []; ax = []; return;
    
    % 1.2 - Set fig output and determine the primary axis handle
        else
            fig = a.append; figure(fig);
            ax = findobj(fig,'YAxisLocation','left','-not','Tag','legend');
            ax(1) = ax(length(ax));
        end

% 2 - ADJUST FOR USAGE OF ADDTO OPTION
    if a.addto == 2; X2 = X1; Y2 = Y1; X1 = []; end

% 3 - PLOT PRIMARY AXIS
    if ~isempty(X1); plot(ax(1),X1,Y1); set(ax(1),'HitTest','off'); end

% 4 - PLOT SECONDARY AXIS
    if ~isempty(X2);

    % 4.1 - Find/create the secondary axis
        try 
            ax(2) = findobj(fig,'YAxisLocation','right',...
                        '-not','Tag','legend');
        catch
            pos = get(ax(1),'Position');
            ax(2) = axes('Parent',fig,'Position',pos,'HitTest','off',...
                'NextPlot','add');
        end

    % 4.2 - Plot the data and setup the axis properties
        plot(ax(2),X2,Y2);
        set(ax(2),'Xtick',[],'YAxisLocation','right','Color','none',...
                        'HitTest','off','NextPlot','add');
    end
    
%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_plotci
function subfunction_plotci(item)
% SUBFUNCTION_PLOTCI place confidence level intevals on each data point

% 1 - DETERMINE THE AXES HANDLE AND EXTRACT DATA
    % 1.1 - Gather data and axis information
        a = guidata(gcf); AX = item(1:length(item)-2); ci = a.(item);
        
    % 1.2 - Determine the handle based on input type    
        switch AX
            case {'x','y'}; loc = 'left';
            case 'x2'; loc = 'right'; AX = 'x';
            case 'y2'; loc = 'right'; AX = 'y';
        end
        ax = findobj(gcf,'YAxisLocation',loc,'-not','tag','legend');
        
    % 1.3 - Get the opposing axis direction
        OP = 'x'; if strcmpi(AX,'x'); OP = 'y'; end
        
    % 1.4 - Extract the x/y data
        hline = flipdim(findobj(ax,'Type','line'),1);
        for j = 1:length(hline);
            data(:,j) = get(hline(j),[AX,'data']);
            OPdata(:,j) = get(hline(j),[OP,'data']); 
            clr{j} = get(hline(j),'Color');
        end
        
    % 1.5 - Overwrite color if the user supplied data
        if ~isempty(a.([item,'color']));
            clr = a.([item,'color']); 
            if ~iscell(clr); clr = {clr}; end
        end

% 2 - BUILD/EXTRACT CONFIDENCE LEVEL INTERVAL DATA
    % 2.1 - Apply simple percentage scaler limits
        if isscalar(ci)
            lo = data - data * ci;
            hi = data + data * ci;
            
    % 2.2 - Apply the user supplied upper and lower bounds
        else
            
            % 2.2.1 - Check that input cell array is correct
            if ~iscell(ci) || length(ci) ~=2 
                mes = ['Confidence level input not correctly formatted',...
                    ' as a cell array as {lo,hi}!'];
                errordlg(mes,'ERROR: subfunction_plotci');
            end
            
            % 2.2.2 - Extract upper/lower data and check dimensions
            lo = ci{1}; hi = ci{2};
            if size(lo) ~= size(data) | size(hi) ~= size(data);
                mes = ['Confidence level interval dimensions do not',...
                     'match the data!'];
                errordlg(mes,'ERROR: subfunction_plotci');
            end
        end
        
% 3 - PLOT THE CONFIDENCE LEVEL INTERVALS
    % 3.1 - Define the width of the error bars
        spread = a.([AX,'ciwidth']) * (max(OPdata) - min(OPdata));
        P1 = OPdata - spread;
        P2 = OPdata + spread;

    % 3.2 - Plot the error bars
    for i = 1:size(data,1);
        for j = size(data,2);
            switch AX
            % 3.2.1 - Plot the bars and connecting line
                case 'y'     
                    h(i,j,1) = plot([P1(i,j),P2(i,j)],[hi(i,j),hi(i,j)],...
                                'Color',clr{j});
                    h(i,j,2) = plot([P1(i,j),P2(i,j)],[lo(i,j),lo(i,j)],...
                                'Color',clr{j});
                    h(i,j,3) = plot([OPdata(i,j),OPdata(i,j)],...
                                [lo(i,j),hi(i,j)],'Color',clr{j});
            
                case 'x'     
                    h(i,j,1) = plot([hi(i,j),hi(i,j)],[P1(i,j),P2(i,j)],...
                                'Color',clr{j});
                    h(i,j,2) = plot([lo(i,j),lo(i,j)],[P1(i,j),P2(i,j)],...
                                'Color',clr{j});
                    h(i,j,3) = plot([lo(i,j),hi(i,j)],...
                                [OPdata(i,j),OPdata(i,j)],'Color',clr{j});
            end
        end; 
            
            % 3.2.2 - Store handles if the user did not specify color
            if ~isempty(a.([item,'color'])); 
                user = get(hline(j),'UserData');
                user.errorbar = h(:,j,:);
                set(hline(j),'UserData',user);
            end
    end;

%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_builduicontrols
function subfunction_builduicontrols(fig,ax) 
% SUBFUNCTION_BUILDUICONTRLS places limit boxes and sliders

% 1 - EXTRACT FIGURE POSITIONS
    % 1.1 - Get axis and figure positions
        set(ax(1),'Units','Centimeters');  axP  = get(ax(1),'Position');
        set(fig,'Units','Centimeters');    szF  = get(fig,'Position');
    
   % 1.2 - Restore units to allow for resizing of window
        set(ax,'Units','Normalized');
        set(fig,'Units','Normalized');

% 2 - BUILD SLIDERS
    % 2.1 - Set slider positions
        p{1} = [0.05,axP(2),0.3,axP(4)];
        p{2} = [axP(1)+0.05,axP(2)+axP(4),axP(3),0.3];
        p{3} = [szF(3)-0.35,axP(2),0.3,axP(4)];
    
    % 2.2 - Build sliders
        tag = {'Yslider','Xslider','Y2slider'}; 
        for i = 1:length(tag); slider_control(fig,p{i},tag{i}); end
        
% 3 - BUILD LIMIT BOXES
    w = 1.5; ht = 0.4;  % Box dimensions
    
    % 3.1 - Set limit box locations
        M{1} = [0.05,axP(2)+axP(4),w,ht];           % Y max limit box
        M{2} = M{1}; M{2}(2) = axP(2)-ht;           % Y min limit box
        M{3} = [szF(3)-w-0.05,axP(2)+axP(4),w,ht];  % Y2 max limit box
        M{4} = M{3}; M{4}(2) = axP(2)-ht;           % Y2 min limit box
        w = 2.4;
        M{5} = [axP(1)-w/2 + axP(3),0.05,w,ht];     % X min limit box
        M{6} = M{5}; M{6}(1) = axP(1) - w/2;        % X max limit box

    % 3.2 - Build limit controls
        tag = {'Ymax','Ymin','Y2max','Y2min','Xmax','Xmin'};
        for i = 1:length(tag); limit_control(fig,M{i},tag{i}); end

% 4 - BUILD STEP SIZE BOXES
    % 4.1 - Set step size box locations
        w = 1.5;
        P{1} =  [w/3,axP(2)+ht/4,w,ht];             % Y step size box
        P{2} =  [szF(3)-4/3*w,axP(2)+ht/4,w,ht];    % Y2 step size box
        P{3} =  [axP(1)-w/2, 0.05+5/4*ht,w,ht];      % X step size box

    % 4.2 - Build step size control boxes
        tag = {'Ystep','Y2step','Xstep'};
        for i = 1:length(tag);
            h = limit_control(fig,P{i},tag{i}); 
            set(h,'Callback',{@callback_stepsize});
        end

% 5 - SET SCROLL WHEEL CALLBACK
    set(fig,'WindowScrollWheelFcn',{@callback_scroll});

%--------------------------------------------------------------------------
% SUBFUNCTION: subfuction_figuremenu
function subfunction_figuremenu(fig)
% SUBFUNCTION_FIGUREMENU builds context menu for editting figure

% 0 - SETUP CONTEXT MENU
    h = guihandles(fig);
    if isfield(h,'XYscatterFigureContextMenu'); return; end

    %cmenu = uicontextmenu;
    %set(fig,'UIContextMenu',cmenu);
    cmenu = uimenu(gcf,'Label','Options','Separator','on');
    set(cmenu,'Tag','XYscatterFigureContextMenu');
    %set(findobj(fig,'Type','Axes'),'UIContextMenu',cmenu);

    ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
    ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend');

% 1 - GENERAL OPTIONS
    uimenu(cmenu,'Label','Add/Edit Labels',...
        'Callback',{@setup,'setlabels'});
    uimenu(cmenu,'Label','Build Re-sizeable Legend(s)',...
        'Callback',{@setup,'resizelegend'});
    uimenu(cmenu,'Label','Restore Original Legend(s)',...
        'Callback',{@callback_restorelegend});
    uimenu(cmenu,'Label','Add/Edit Labels',...
        'Callback',{@setup,'setlabels'});
    int = uimenu(cmenu,'Label','Interpreter');
        uimenu(int,'Label','none','Callback',{@setup,'interpreter'},...
            'tag','none');
        uimenu(int,'Label','TeX','Callback',{@setup,'interpreter'},...
            'tag','tex');
        uimenu(int,'Label','LaTeX','Callback',{@setup,'interpreter'},...
            'tag','latex');
    uimenu(cmenu,'Label','Edit Font','Callback',{@setup,'editfont'});
    uimenu(cmenu,'Label','Axes Color','Callback',{@setup,'axescolor'});
    an = uimenu(cmenu,'Label','Add Annotation');
        uimenu(an,'Label','Line','Callback',{@annotatefigure,'line'});
        uimenu(an,'Label','Arrow','Callback',{@annotatefigure,'arrow'});
        uimenu(an,'Label','DoubleArrorw','Callback',...
            {@annotatefigure,'doublearrow'});
        uimenu(an,'Label','TextArrow','Callback',...
            {@annotatefigure,'textarrow'});
        uimenu(an,'Label','TextBox','Callback',...
            {@annotatefigure,'textbox'});
        uimenu(an,'Label','Ellipse','Callback',...
            {@annotatefigure,'ellipse'});
        uimenu(an,'Label','Rectangle','Callback',...
            {@annotatefigure,'rectangle'});
    sz = uimenu(cmenu,'Label','Resize Figure','tag','resize');
        uimenu(sz,'Label','Change Dimensions','Callback',{@setup,'size'});
        uimenu(sz,'Label','Normalized','Callback',{@setup,'units'},...
            'tag','normalized');
        uimenu(sz,'Label','Centimeters','Callback',{@setup,'units'},...
            'tag','centimeters');
        uimenu(sz,'Label','Inches','Callback',{@setup,'units'},...
            'tag','inches');
    uimenu(cmenu,'Label','Tight Fit','Callback',{@setup,'tight'},...
            'tag','tight');  
    uimenu(cmenu,'Label','Export figure','Callback',{@callback_export},...
            'tag','export');
        
% 2 - ESTABLISH TOOLBAR ITEMS
    % 2.1 - Open icon file
        if exist('icons.ico','file');
            icon = load('icons.ico','-mat');
        else
            B = ones(16,16,3);
            icon.save = B; icon.xgrid = B; icon.ygrid = B;
            icon.xlimit = B; icon.xstep = B; icon.ystep = B;
            icon.ylimit = B; icon.y2step = B; icon.y2limit = B;
            icon.zoom = B; icon.cursor = B; icon.edit = B;
            warndlg('Icon file, icons.ico, is missing!','WARNING');
        end

    % 2.2 - Define the toolbar buttons    
        tbar = uitoolbar(fig);
        uipushtool(tbar,'Cdata',icon.save,'TooltipString',...
            'Export figure','ClickedCallback',{@callback_export});
        uitoggletool(tbar,'Cdata',icon.zoom,'TooltipString',...
            'Toggle zooming','ClickedCallback',{@callback_zoom});
        uitoggletool(tbar,'Cdata',icon.cursor,'TooltipString',...
            'Toggle data cursor','ClickedCallback','datacursormode');
%         uipushtool(tbar,'Cdata',icon.xgrid,'TooltipString',...
%             'X-grid','ClickedCallback',{@setup,'xgrid'},...
%             'separator','on');
%         uipushtool(tbar,'Cdata',icon.ygrid,'TooltipString',...
%             'Y-grid','ClickedCallback',{@setup,'ygrid'});
        uipushtool(tbar,'Cdata',icon.xlimit,'TooltipString',...
            'X limits','ClickedCallback',{@setup,'xlimit'},...
            'separator','on');       
        uipushtool(tbar,'Cdata',icon.xstep,'TooltipString',...
            'X steps size','ClickedCallback',{@setup,'xstepbox'});        
        uipushtool(tbar,'Cdata',icon.ylimit,'TooltipString',...
            'Y limits','ClickedCallback',{@setup,'ylimit'},...
            'separator','on');
        uipushtool(tbar,'Cdata',icon.ystep,'TooltipString',...
            'Y steps size','ClickedCallback',{@setup,'ystepbox'});
        uipushtool(tbar,'Cdata',icon.y2step,'TooltipString',...
            'Y2 steps size','ClickedCallback',{@setup,'y2stepbox'},...
            'separator','on','tag','y2stepbox_tool');
        uipushtool(tbar,'Cdata',icon.y2limit,'TooltipString',...
            'Y2 limits','ClickedCallback',{@setup,'y2limit'},...
            'tag','y2limit_tool');
        uitoggletool(tbar,'Cdata',icon.edit,'TooltipString',...
            'Edit Plot','ClickedCallback','plotedit',...
            'tag','plotedit');
        
% 3 - X AXIS OPTIONS
    x = uimenu(gcf,'Label','X-Axis','Separator','on');
        uimenu(x,'Label','X Ticks/Labels','Callback',{@callback_tick},...
            'userdata',{'x',ax1});
        uimenu(x,'Label','Step Size Box','Callback',{@setup,'xstepbox'},...
            'UserData',{'Xstep'},'tag','xstepbox');
        uimenu(x,'Label','Limit Boxes','Callback',{@setup,'xlimit'},...
            'UserData',{'Xmin','Xmax'},'tag','xlimit');
        uimenu(x,'Label','Zoom Slider','Callback',{@setup,'xzoom'},...
            'UserData',{'Xslider'},'tag','xzoom');
        uimenu(x,'Label','Grid','Callback',{@setup,'xgrid'},'tag','xgrid');
        uimenu(x,'Label','Minor Grid','Callback',{@setup,'xminorgrid'},...
            'tag','xminorgrid');
        uimenu(x,'Label','Minor Ticks','Callback',{@setup,'xminortick'},...
            'tag','xminortick');
        uimenu(x,'Label','Reversed','Callback',{@setup,'xdir'},...
            'tag','xdir');

% 4 - Y-AXIS OPTIONS
    y = uimenu(gcf,'Label','Y-Axis');
        uimenu(y,'Label','Y Ticks/Labels','Callback',{@callback_tick},...
            'userdata',{'y',ax1});
        uimenu(y,'Label','Step Size Box','Callback',{@setup,'ystepbox'},...
            'UserData',{'Ystep'},'tag','ystepbox');
        uimenu(y,'Label','Limit Boxes','Callback',{@setup,'ylimit'},...
            'UserData',{'Ymin','Ymax'},'tag','ylimit');
        uimenu(y,'Label','Zoom Slider','Callback',{@setup,'yzoom'},...
            'UserData',{'Yslider'},'tag','yzoom');
        uimenu(y,'Label','Grid','Callback',{@setup,'ygrid'},...
            'tag','ygrid');
        uimenu(y,'Label','Minor Grid','Callback',{@setup,'yminorgrid'},...
            'tag','yminorgrid');
        uimenu(y,'Label','Minor Ticks','Callback',{@setup,'yminortick'},...
            'tag','yminortick');
        uimenu(y,'Label','Reversed','Callback',{@setup,'ydir'},...
            'tag','ydir');
        uimenu(y,'Label','Add/Edit Legend','Callback',{@setup,'legend'},...
            'separator','on');

% 5 - BUILD SECONDARY AXIS MENU
    y2 = uimenu(gcf,'Label','Y2-Axis','tag','y2menu');
        uimenu(y2,'Label','Y2 Ticks/Labels','Callback',{@callback_tick},...
            'userdata',{'y',ax2});
        uimenu(y2,'Label','Step Size Box','Callback',...
            {@setup,'y2stepbox'},'UserData',{'Y2step'},'tag','y2stepbox');
        uimenu(y2,'Label','Limit Boxes','Callback',{@setup,'y2limit'},...
            'UserData',{'Y2min','Y2max'},'tag','y2limit');
        uimenu(y2,'Label','Zoom Slider','Callback',{@setup,'y2zoom'},...
            'UserData',{'Y2slider'},'tag','y2zoom');
        uimenu(y2,'Label','Grid','Callback',{@setup,'y2grid'},...
            'tag','y2grid');
        uimenu(y2,'Label','Reversed','Callback',{@setup,'y2label'},...
            'tag','y2dir');
        uimenu(y2,'Label','Add/Edit Legend','Callback',...
            {@setup,'legend2'},'separator','on');
     
%--------------------------------------------------------------------------   
% SUBFUNCTION: subfunction_linemenu
function subfunction_linemenu(handles)
% SUBFUNCTION_LINEMENU build context menu for line objects

% 1 - LOOP THROUGH EVERY LINE
for j = 1:length(handles)
    cmenu = uicontextmenu;
    hline = handles(j);
    set(hline,'UIcontextmenu',cmenu);
    
    % 1.1 - Set change color option for the line
    uimenu(cmenu,'Label','Line Color','Callback',...
        {@callback_editlinecolor,hline});

    % 1.2 - Option labels
        opt = {'Line Style','Line Marker','Line Wieght','Marker Size'};

    % 1.3 - Labels for each options
        L{1} = {'None','Solid','Dashed','Dotted','Dash-Dot'};
        L{2} = {'None','Plus','Circle','Asterisk','Point','Cross',...
                'Square','Diamond','Triangle(up)','Triangle(down)',...
                'Triangle(left)','Triagnle(right)','Pentagram','Hexagram'};
        L{3} = {'0.25','0.5','1','2','3','4','5','6'};
        L{4} = {'0.25','0.5','1','2','3','4','5','6','8','10','12'};

    % 1.4 - Setting associated with Section 1.2
        s{1} = {'none','-','--',':','-.'};
        s{2} ={'none','+','o','*','.','x','s','d','^','v','<','>','p','h'};    
        s{3} = str2double(L{3});
        s{4} = str2double(L{4});

    % 1.5 - Build menu items
    for jj = 1:length(opt);
        m{jj} = uimenu(cmenu,'Label',opt{jj});
        
        for jjj = 1:length(L{jj});
            uimenu(m{jj},'Label',L{jj}{jjj},'Callback',...
                {@callback_editline,hline,s{jj}(jjj)});
    end,end

% 2 - DELETE LINE COLOR OPTIONS
    uimenu(cmenu,'Label','Delete Line','Callback',...
        {@callback_deleteline,hline},'Separator','on');
    
% 3 - BUTTON DOWN LINE HIGHLIGHTING
    set(handles,'ButtonDownFcn',{@callback_linehighlight});

end

%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_textmenu
function subfunction_textmenu(handles)
% SUBFUNCTION_TEXTMENU builds context menu for text items editting

    for i = 1:length(handles)
        amenu = uicontextmenu; 
        set(handles(i),'UIContextMenu',amenu);
        uimenu(amenu,'Label','Edit Font','Callback',...
            {@callback_editfont,handles(i)});
        uimenu(amenu,'Label','Edit Label','Callback',...
            {@callback_edittext,handles(i)});
        uimenu(amenu,'Label','Move object','Callback',...
            {@callback_movetext,handles(i)});
%        set(handles(i),'ButtonDownFcn',{@callback_hittext,handles(i)});
        uimenu(amenu,'Label','Delete','separator','on',...
            'Callback',{@delete,handles(i)});
    end

%--------------------------------------------------------------------------
% SUBFUNCTION: slider_control 
function slider_control(fig,p,tag)
% CALLBACK_SLIDERCONTROL builds a slider for zooming in on an axis.
%   fig  = figure handle of plot being generated
%   p    = position matrix of control being added
%   tag  = function tag to assign to slider
    uicontrol(fig,'Style','Slider','Units','Centimeters',...
        'Position',p,'tag',tag,'Units','Normalized','Callback',...
        {@callback_slider});

%--------------------------------------------------------------------------
% SUBFUNCTION: limit_control 
function h = limit_control(fig,p,tag)
% LIMIT_CONTROL builds edit boxes for controling axis limits.
%   fig  = figure handle of plot being generated
%   p    = position matrix of control being added
%   tag  = function tag to assign to limit box
    h = uicontrol(fig,'Style','edit','Units','Centimeters',...
        'Position',p,'BackgroundColor','w','Tag',tag,'FontSize',8,...
        'Units','Normalized','Callback',{@callback_limitbox});

%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_limits
function subfunction_limits(varargin)
% SUBFUNCTION_INSERTLIMITS inserts limits from command-line input

% 1 - GATHER FIGURE AND AXIS INFORMATION AND HANDLES
    ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
    ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend');

% 2 - SET PRIMARY AXIS LIMITS
    set_axis([ax1,ax2],'x'); set_axis(ax1,'y');

% 3 - SET SECONDARY AXIS LIMITS
    if ishandle(ax2);
        set_axis(ax2,'y2','match',ax1);
    end

% -------------------------------------------------------------------------
% SUBFUNCTION: subfunction_limits >> set_axis
function set_axis(handle,ax,varargin)
% SET_AXIS changes limits of specified axis
%   handle = axis handle
%   ax     = axis indicator ('x','y', or 'y2')
%   varargin{1} = 'notick' - doesn't display tick marks (optional)

% 1 - ESTABLISH WORKING AXIS VARIABLES
    % 1.1 - Seperate the necessary data from figure structure
        a = guidata(gcf);
        lim   = a.([ax,'lim']);
        rev   = a.([ax,'dir']);
        dtick = a.([ax,'datetick']);
        step  = a.([ax,'step']);
        
    % 1.2 - Gather axis information
    switch lower(ax)
        case 'x';  AX = 'XLim'; dax = 'x'; tag= {'Xmin','Xmax','Xstep'};
        case 'y';  AX = 'YLim'; dax = 'y'; tag= {'Ymin','Ymax','Ystep'};
        case 'y2'; AX = 'YLim'; dax = 'y'; tag= {'Y2min','Y2max','Y2step'};
    end

    % 1.3 - Set tick mark property name
        daxtick = [dax,'tick']; axtick = [ax,'tick'];

% 2 - DETERMINE THE AXIS LIMITS
    % 2.1 - Auto find the limits, being sure both axis are accounted for
    % when calculating the limits for the x-axis
        if strcmpi(lim,'auto') || isempty(lim); 
            for i = 1:length(handle)
                set(handle(i),[AX,'Mode'],'auto'); 
                temp = get(handle(i),AX);
            end
            limit = [min(temp(:,1)),max(temp(:,2))];
      
    % 2.2 - User the user defined limits
        else
            limit = lim;                    
        end

% 3 - MATACH SECONDARY AND PRIMARY Y-AXIS TICK MARKS
    if isempty(step) && ~isempty(varargin) && strcmpi(varargin{1},'match');
        prim  = get(varargin{2},'YTick');       % Primary axis ticks
        ntick = length(prim) - 1;               % Number of tick marks
        step  = (limit(2) -limit(1))/ntick;     % Exact step size
        limit(2) = limit(1) + step*ntick;       % Set new maximum value
    end

% 4 - SETUP LIMIT BOX STRINGS
    % 4.1 - Reverse direction axis
        idx1 = 1; idx2 = 2;
        if strcmpi(rev,'reverse'); idx1 = 2; idx2 = 1; end

    % 4.2 - Check that labels are ordered properly
        if limit(1) > limit(2); 
            errordlg('Axis limits must be increasing!','ERROR'); 
            guidata(gcf,a); return; 
        end
  
    % 4.3 - Build labels
        lab{1} = num2str(limit(idx1)); 
        lab{2} = num2str(limit(idx2));
        lab{3} = num2str(step);

    % 4.4 - Convert labels if datetick is utlized
        if strcmpi(dtick,'on');
            lab{1} = datestr(limit(idx1),a.dateform);
            lab{2} = datestr(limit(idx2),a.dateform);
        end

% 5 - APPLY LIMITS TO AXIS 
% 5.1 - Automatic step size
    if isempty(step)
        set(handle,AX,limit,[daxtick,'mode'],'auto');
        set(handle,[daxtick,'labelmode'],'auto');

    % 5.2 - Account for specific stepsize
    else
        set(handle,AX,limit);
        tick = limit(1):step:limit(2);
        set(handle,daxtick,tick);
    end

% 6 - SET LIMIT AND STEP SIZE BOX STRINGS
    h = guihandles(handle(1));
    for i = 1:length(lab); set(h.(tag{i}),'String',lab{i}); end

% 7 - ASSIGN DATE TICK MARKS
    if strcmpi(dtick,'on'); 
        setdatetickmarks(handle,dax,limit,step); 
    end

% 8 - USE TICK AND TICKLABEL OPTIONS (these overwrite other settings)
    % 8.1 - Check that tick mark/labels are same length
        if ~isempty(a.(daxtick)) && ~isempty(a.([daxtick,'label']));
            L1 = length(a.(daxtick));
            L2 = length(a.([daxtick,'label']));
            if L1 ~= L2;
                errordlg(['WARNING! Ticks and TickLabels must ',...
                    'be same length, using auto settings!']);
                a.(axtick) = []; a.([axtick,'label']) = [];
            end
         end

    % 8.2 - Set Tick marks
        if ~isempty(a.(daxtick)); 
            L = a.(daxtick);
            set(handle,AX,[L(1),L(length(L))]); % Set limits
            set(handle,daxtick,a.(axtick));     % Set ticks
            a.(axtick) = [];                    % Reset 
        end

    % 8.3 - Set Tick mark labels
        if ~isempty(a.([daxtick,'label'])); 
            set(handle,[daxtick,'label'],a.([axtick,'label'])); 
            a.([axtick,'label']) = []; 
        end 

% 9 - RETURN DATA TO GUI
    guidata(gcf,a);

%--------------------------------------------------------------------------
% SUBFUNCTION_LIMITS >> set_axis >> setdatetickmarks
function setdatetickmarks(handle,dax,limit,inc)
% SETDATETICKMARKS assigns datetick labels to axis

% 1 - ASSIGN STEP AND LABELS
    % 1.1 - Determine increment
        if isempty(inc);
        	x = diff(limit)/10;
            a = [1,2,3,4,6,8,12,24,168,360]/24;
            inc = a(find(x<=a,1,'first'));
        end
        
    % 1.2 - Rely on existing marks for larger increments and return
        if inc < 7; 
            lab = 'HH:MM';
        else
            lab = 'mmm-dd';
        end

% 2 - DEFINE THE TICK MARKS AND LABELS
    % 2.1 - Tick marks on daily scale
        tick = limit(1):inc:limit(2);

    % 2.2 - Tick marks on monthly scale
    if inc >= 15;
        V = datevec(limit(1)); V(3) = 0; 
        tick = [datenum(V),datenum(V)+15];
        i = 2;
        while tick(i) < limit(2) && i < 100;
        	V = datevec(tick(i)+17); V(3) = 0;
            tick = [tick,datenum(V),datenum(V)+15];
            i = i + 2;
        end
    end
    label = cellstr(datestr(tick,lab))';

% 3 - INSERT THE FULL MONTH/DAY AT MIDNIGHT (small stepsize only)
    if inc < 15;
        idx = find(tick == round(tick));
        for i = 1:length(idx);
            label{idx(i)}= datestr(tick(idx(i)),'mm/dd');
        end
    end

% 4 - SET THE TICKS AND LABELS
    set(handle,[dax,'tick'],tick,[dax,'ticklabel'],label);

%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_sliderlimits
function subfunction_sliderlimits
% SUBFUNCTION_SLIDERLIMITS finds overall max and min of data for zooming

% 1 - GATHER FIGURE AND AXIS INFORMATION AND HANDLES
    ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
    ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend');

% 2 - DETERMINE THE MIN/MAX OF DATA ON PRIMARY AXIS
    % 2.1 - Determine the type for gathering legend names
        a = guidata(gcf); type = 'line';
        if strcmpi(a.area,'on') || strcmpi(a.contour,'on'); 
            type = 'hggroup'; 
        end
   
    % 2.2 - Collect the data from object
        hline = unique(findall(ax1,'Type',type));
        for i = 1:length(hline); 
            x = get(hline(i),'Xdata'); y = get(hline(i),'Ydata');
            Lx(i,:) = [min(x),max(x)];
            Ly(i,:) = [min(y),max(y)];
        end
     
    % 2.3 - Return if Lx is not constructed (area plots)
        if ~exist('Lx','var')
            Xlim('auto'); Ylim('auto'); return;
        end
% 3 - DETERMINE THE MIN/MAX OF SECONDARY AXIS
    hline2 = findobj(ax2,'Type','Line');
    n = size(Lx,1);
    for i = 1:length(hline2);
        x = get(hline2(i),'Xdata'); y = get(hline2(i),'Ydata');
        Lx(n+i,:) = [min(x),max(x)];
        Ly2(i,:) = [min(y),max(y)];
    end

% 4 - DETERMINE THE OVERALL MAX/MIN AND STORE IN SLIDER'S USERDATA
    h = guihandles(gcf);
    X = [min(Lx(:,1)),max(Lx(:,2))];    set(h.Xslider,'UserData',X);
    Y = [min(Ly(:,1)),max(Ly(:,2))];    set(h.Yslider,'UserData',Y);
    if ~isempty(hline2);
        Y2 = [min(Ly2(:,1)),max(Ly2(:,2))]; set(h.Y2slider,'UserData',Y2);
    end
    
%--------------------------------------------------------------------------
% SUBFUNCTION: subfunction_refreshlegend
function subfunction_refreshlegend(hline)
% SUBFUNCTION_REFRESHLEGEND updates the resized legend entries

user = get(hline,'UserData'); C = user.legend;
hleg = C.LabelHandles(1);
itm = {'LineStyle','Marker','LineWidth','Markersize','Color'};
if ishandle(hleg);
    for i = 1:length(itm);
        set(hleg,itm{i},get(hline,itm{i}));
    end
end

%--------------------------------------------------------------------------
% CALLBACK: callback_editline
function callback_editline(hObject,eventdata,hline,setting)
% CALLBACK_EDITLINE changes the appearance of a line object
    parent = get(hObject,'Parent');
    switch get(parent,'Label');
        case 'Line Style';  set(hline,'LineStyle',setting{1});
        case 'Line Marker'; set(hline,'Marker',setting{1}); 
        case 'Line Wieght'; set(hline,'LineWidth',setting);    
        case 'Marker Size'; set(hline,'MarkerSize',setting);
    end
    subfunction_refreshlegend(hline); % Refresh the resize legend  
    
%--------------------------------------------------------------------------
% CALLBACK: callback_edittext
function callback_edittext(hObject,eventdata,textobj)
% CALLBACK_EDITTEXT allows user to edit the text object

current = get(textobj,'String'); % Current text
if ischar(current); current = {current}; end % Convert to cell array
new = inputdlg('Enter new text:','Edit',1,current); % Get new text
set(textobj,'String',new); % Apply new text

%--------------------------------------------------------------------------
% CALLBACK: callback_editfont
function callback_editfont(hObject,eventdata,textobj)
% CALLBACK_edittext allows user to edit the text object
    s = uisetfont(textobj,'Edit font...');
    if isstruct(s); set(textobj,s); end

%--------------------------------------------------------------------------
% CALLBACK: callback_editlinecolor
function callback_editlinecolor(hObject,eventdata,hline)
% CALLBACK_EDITLINECOLOR changes the selected lines color

% 1 - CHANGE COLOR OF LINE
    c = colorui; if  length(c) == 1; return; end
    set(hline,'Color',c)
    
% 2 - CHANGE COLOR OF ERROR BARS    
    h = get(hline,'UserData');
    if ~isstruct && isfield(h,'errorbar'); set(h.errorbar,'Color',c); end
    
% 3 - REFRESH THE RESIZED LEGEND
    subfunction_refreshlegend(hline);

%--------------------------------------------------------------------------
% CALLBACK: callback_deleteline
function callback_deleteline(hObject,eventdata,hline)
% CALLBACK_DELETELINE removes a line from the plot (context menu option)  

% 1 - DELETE LINE
    ax = get(hline,'Parent');   % Determine axis
    delete(hline);              % Remove line

% 2 - UPDATE LEGEND
    [L,~,P,T] = legend(ax);

    % 2.1 - If a legend exists
    if ~isempty(T);
        
        % 2.1.1 - Build new legend entries
            update = ishandle(P); new = T(update);       
 
        % 2.2.2 - If new is empty delete the axis information
        if isempty(new)
            xlabel(ax,'');  ylabel(ax,''); 
            set(ax,'XTick',[],'YTick',[]); delete(L);

        % 2.2.3 - Update legend if lines still exist
        else
            form = get(L,'Interpreter'); pos  = get(L,'Location');
            legend(ax,new,'Interpreter',form,'Color','w','Location',pos);               
        end

    % 2.2 - Case when no legend exits: delete axis information if no plots
    % remain on the axis
    else
        child = get(ax,'Children');
        if isempty(child);
            xlabel(ax,''); ylabel(ax,''); 
            set(ax,'XTick',[],'YTick',[]);
        end   
    end

%--------------------------------------------------------------------------
% CALLBACK: callback_export
function callback_export(hObject,eventdata)
% CALLBACK_EXPORT saves the file to a PDF of JPEG

% 1 - DETERMINE THE FILENAME TO CREATE
    a = guidata(gcf);
	if isempty(a.exportfile);
        filterspec = {'*.pdf','PDF vector (*.pdf)';...
        '*.jpg','JPEG bitmap (*.jpg)';...
        '*.png','Portable Network Graphics (*.png)';...
        '*.emf','Enhanced metafile (*.emf)';...
        '*.ill','Adobe Illustrator (*.ill)';...
        '*.tiff','Tagged Image File Format (*.tiff)'};
        [name,pth] = uiputfile(filterspec,'Save file as...',a.exportpath);
        if name == 0; return; end
        filename = [pth,name]; 
    else
        pth = a.exportpath;
        filename = fullfile(a.exportpath,a.exportfile);
    end
    cmd = {'-dpdf','-djpeg','-dpng','-dmeta','-dill','-tiff'};  
    for j = 1:length(filterspec); ext{j} = filterspec{j,1}(2:end); end
    
% 2 - SET THE PAPERSIZE FOR PRINTING
    set(gcf,'Units','inches');
    set(gcf,'PaperUnits','Inches','PaperPositionMode','auto');
    P = get(gcf,'Position');
    set(gcf,'PaperSize', [P(3),P(4)]);
    axis fill

% 3 - PRINT THE FILE
    [p,f,e] = fileparts(filename);
    if ~exist(p,'dir'); mkdir(p); end
    try
        idx = find(strcmp(e,ext),1,'first');
        fhandle = ['-f',num2str(gcf)];
        print(cmd{idx},'-r1200','-noui','-painters',fhandle,filename);
    catch err
        disp('Failed to write file, make sure the file is not open.');
        rethrow(err);
    end

% 4 - SET THE STARTING PATH
    a.exportpath = pth;
    guidata(gcf,a);

%--------------------------------------------------------------------------
% CALLBACK: callback_limitbox
function callback_limitbox(hObject,eventdata)
% CALLBACK_LIMITBOX executes when a limit box is used

% 1 - GATHER INFORMATION ABOUT AXES
    % 1.1 - Get data structure and figure handles
        a = guidata(gcf);
        h = guihandles(hObject);

    % 1.2 - Find the primary and secondary axis handles
        ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
        ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend');

% 2 - SET INFORMATION FOR ASSOCIATED AXIS
    % 2.1 - Set limit box tags, axis property strings, and handles
    switch get(hObject,'tag');
        case {'Ymax','Ymin'};   
            tag = {'Ymin','Ymax'}; ax = 'y'; AX = 'Ylim'; handle = ax1;
        case {'Xmin','Xmax'};
            tag = {'Xmin','Xmax'}; ax = 'x'; AX = 'Xlim'; handle=[ax1,ax2];
        case {'Y2min','Y2max'};
            tag = {'Y2min','Y2max'}; ax = 'y2'; AX = 'Ylim'; handle = ax2;
    end

    % 2.2 - Set data structure field names for collecting data
        rev = [ax,'dir']; lim = [ax,'lim']; dtk = [ax,'datetick'];

% 3 - COLLECT THE AUTO MATLAB FIT LIMITS - being sure to adjust for the
% existance of a double axis
    for i = 1:length(handle)
        set(handle(i),[AX,'Mode'],'auto'); 
        temp = get(handle(i),AX);
    end
    auto = [min(temp(:,1)),max(temp(:,2))];

% 4 - APPLY INDEX REFERENCES FOR REVERSING AXIS/LIMIT BOXES
    idx{1} = 1; idx{2} = 2;
    if strcmpi(a.(rev),'reverse'); idx{1} = 2; idx{2} = 1; end

% 5 - COLLECT THE NEW LIMIT INFORMATION FROM THE FIGURE
for i = 1:length(tag);
     % 5.1 - Collect text from figure, adjusting for a date input
        if strcmpi(a.(dtk),'on');
            L(i) = datenum(get(h.(tag{idx{i}}),'String'),a.dateform);
        else
            L(i) = str2double(get(h.(tag{idx{i}}),'String'));
        end

    % 5.2 - If the value is empty then use the auto limits
        if isempty(L(i)) || isnan(L(i)); L(i) = auto(i); end
end

% 6 - RETURN THE NEW LIMITS TO DATA STRUCTURE AND APPLY TO FIGURE
    a.(lim) = L;
    guidata(gcf,a);
    subfunction_limits;

%--------------------------------------------------------------------------
% CALLBACK: callback_slider
function callback_slider(hObject,eventdata)
% CALLBACK_SLIDER excutes when a zoom slider is used

% 1 - EXTRACT FIGURE AND AXIS INFORMATION
    % 1.1 - Get data structure and axis handles
        a = guidata(gcf);
        ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
        ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend');
    
    % 1.2 - Setup control parameters  
    switch get(hObject,'tag');
        case 'Xslider';  s = 'xlim';  handle = ax1; AX = 'XLim'; 
        case 'Yslider';  s = 'ylim';  handle = ax1; AX = 'YLim';
        case 'Y2slider'; s = 'y2lim'; handle = ax2; AX = 'YLim';
    end

% 2 - SET THE NEW AXIS RANGE
    % 2.1 - Find current mouse location
        lim = get(handle,AX);
        center = lim(1) + (lim(2) - lim(1))/2;

    % 2.3 - Get the slider value, adjusting for the zero end
        val = 1 - get(hObject,'Value');
        if val == 0; val = 0.001; end

    % 2.4 - Set the new xlimit range
        user = get(hObject,'UserData');
        rng = (user(2) - user(1))*val;
        lim = [center - rng/2, center + rng/2];
    
    % 2.5 - Don't allow limits to exceed data range
        if lim(1) <= user(1); lim(1) = user(1); lim(2) = lim(1) + rng; end
        if lim(2) >= user(2); lim(2) = user(2); lim(1) = lim(2) - rng; end

% 3 - SET THE NEW LIMITS
    a.(s) = lim;
    guidata(gcf,a);
    subfunction_limits;

%--------------------------------------------------------------------------
% CALLBACK: callback_scroll
function callback_scroll(hObject,eventdata)
% CALLBACK_SCROLL executes when the scroll wheel is used

% 1 - DETERMINE IF CURSOR IS IN CORRECT LOCATION FOR SCROLLING
    % 1.1 - Get figure information
        a = get(gca,'Position');       % Axis position
        c = get(gcf,'CurrentPoint');   % Current point location

    % 1.2 - Test cursor location and get slider visiblity
        testX  = c(2) < a(1);      
        testY  = c(1) < a(2);      
        testY2 = c(1) > a(1)+a(3);
    
    % 1.3 - Define the axis handles
        ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
        ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend');

    % 1.4 - Determine the the axis to modify
        if      testX   tag = 'X';  type = 'XLim'; ax = ax1;
        elseif  testY   tag = 'Y';  type = 'YLim'; ax = ax1;
        elseif  testY2  tag = 'Y2'; type = 'YLim'; ax = ax2;
        else    return
        end

% 2 - CALCULATE THE NEW POSITION
    % 2.1 - Establish scroll dirction, adjusting for reverse axis
        a = guidata(gcf);
        d = eventdata.VerticalScrollCount*(-1);
        if strcmpi(a.(lower([tag,'dir'])),'reversed'); d = d*(-1); end
    
    % 2.2 - Establish current limits and adjusments
        lim = get(ax,type);         % Current limits
        rng = (lim(2) - lim(1))/2;  % Half of the limits range
        center = lim(1) + rng;      % Center of limits

    % 2.3 - Find new limits (-1 increases, 1 decreases)
        if d == 1;
            lim(1) = center; lim(2) = lim(2) + rng;
        elseif d == -1;
            lim(2) = center; lim(1) = lim(1) - rng;
        end

    % 2.4 - Don't allow limits to exceed available data
        h = guihandles(gcf);
        user = get(h.([tag,'slider']),'UserData');

        if lim(1) <= user(1); 
            lim(1) = user(1); lim(2) = lim(1) + rng*2; end
        if lim(2) >= user(2); 
            lim(2) = user(2); lim(1) = lim(2) - rng*2; end
 
% 3 - SET THE NEW LIMITS
    a.(lower([tag,'lim'])) = lim;
    guidata(gcf,a);
    subfunction_limits;

%--------------------------------------------------------------------------
% CALLBACK: callback_stepsize
function callback_stepsize(hObject,eventdata)
% CALLBACK_STEPSIZE executes when the step size box is utlized

% 1 - GATHER STEP SIZE FROM FIGURE
    a = guidata(gcf);
    tag = lower(get(hObject,'tag'));
    num = str2double(get(hObject,'string'));
    if isnan(num); num = []; end

% 2 - INSERT STEP SIZE INTO FIGURE GUIDATA AND UPDATE LIMITS
    a.(tag) = num;
    guidata(gcf,a);
    subfunction_limits;

%--------------------------------------------------------------------------
% CALLBACK: callback_tick
function callback_tick(hObject,eventdata)
% CALLBACK_TICK allows user to define tick marks and labels

% 1 - EXTRACT USER DATA AND DETERMINE IF Y2-AXIS IS BEING USED
    user = get(hObject,'userdata'); % {axis label, axis handle}
    lab = get(hObject,'Label');     % Object label
    idx = num2str(regexp(lab,'2')); % Returns '2' if Y2, empty otherwise

% 2 - DEFINE THE MESSAGE FOR THE INPUT DIALOG
    mes{1} = ['Enter numeric values for ',upper(user{1}),...
        '-axis tick marks:'];
    mes{2} = ['Enter numeric and/or text values for ',...
        upper(user{1}),'-axis tick mark labels:'];

% 3 - GATHER THE EXISTING TICKS/LABELS
    % 3.1 - Get tick marks and labels from the figure
        D{1} = get(user{2},[user{1},'Tick']);
        D{2} = get(user{2},[user{1},'TickLabel']); 

    % 3.2 - Convert extracted data to comma seperated strings
    for j = 1:length(D);
        data = D{j};    % Current list of numbers/text

        % 3.2.1 - Accounts for char type
        if ischar(data); data = cellstr(data); end

        % 3.2.2 - Converts numeric values to a string
        if isnumeric(data);
            def{j} = num2str(data(1));
            for i = 2:length(data); 
                def{j} = [def{j},',',num2str(data(i))]; 
            end

        % 3.2.3 - Converts cell arrays to a string
        elseif iscell(data);
            def{j} = data{1};
            for i = 2:length(data); def{j} = [def{j},',',data{i}]; end
        end
    end

% 4 - PROMPT USER FOR NEW TICKS/LABELS
    in = inputdlg(mes,'Edit ticks/labels...',1,def);
    if isempty(in); return; end

% 5 - SET THE NEW TICKS AND LABELS
    % 5.1 - Define new limits
        a = guidata(gcf); % Figure data structure
        a.([user{1},idx,'tick']) = eval(['[',in{1},']']);   
        temp = textscan(in{2},'%s','delimiter',',');
        a.([user{1},idx,'ticklabel']) = temp{1};

    % 5.2 - Return gui structure and update limits
        guidata(gcf,a);
        subfunction_limits;
    
%--------------------------------------------------------------------------
% CALLBACK: callback_zoom
function callback_zoom(hObject,eventdata)
% CALLBACK_ZOOM toggles the zoom feature

% 1 - TOGGLE THE ZOOM
    zoom; z = zoom(gcf); % Zoom handle
    if strcmpi(get(z,'Enable'),'on'); return; end
    
% 2 - UPDATE THE LIMIT BOXES WHEN TURNED OFF 
    % 2.1 - Gather axes handles
        ax1 = findobj(gcf,'YAxisLocation','left','-not','tag','legend');
        ax2 = findobj(gcf,'YAxisLocation','right','-not','tag','legend');

    % 2.2 - Primary axis limits
        h = guihandles(gcf); % Figure handles
        x = xlim(ax1); y = ylim(ax1);     
        set(h.Xmin,'String',num2str(x(1)));
        set(h.Xmax,'String',num2str(x(2)));
        set(h.Ymin,'String',num2str(y(1)));
        set(h.Ymax,'String',num2str(y(2)));

    % 2.3 - Secondary axis limits
        if ishandle(ax2); 
            y2 = ylim(ax2); 
            set(h.Y2min,'String',num2str(y2(1)));
            set(h.Y2max,'String',num2str(y2(2)));
        end    
    
%--------------------------------------------------------------------------        
% CALLBACK: callback_movetext
function callback_movetext(hObject,eventedata,h)
% CALLBACK_MOVETEXT allows user to move text objects

% 1 - ASSIGN CALLBACK FOR MOVING TEXT
if ishandle(h);
    set(gcf,'WindowButtonMotionFcn',{@callback_movecursor,h});
    set(gcf,'WindowButtonDownFcn',{@callback_movetext,'stop'});  

% 2 - RE-ASSIGN CALLBACK WHEN BUTTON IS CLICKED
else
    set(gcf,'WindowButtonMotionFcn',{});
end
 
%--------------------------------------------------------------------------    
% CALLBACK: callback_movecursor
function callback_movecursor(hObject,eventdata,h)
% CALLBACK_MOVECURSOR repositions text object to cursor position
cur_pos = get(gca,'CurrentPoint');
set(h,'Position',[cur_pos(1,1),cur_pos(1,2)]);

%--------------------------------------------------------------------------    
% CALLBACK: callback_contoursection
function callback_contoursection(hObject,eventdata,h,type)
% CALLBACK_CONTOURSECTION allows user to plot cross section of contour data

% 1 - Select the location and gather figure intormation
    [x,y] = ginput(1);
    a = guidata(hObject);
    dx = a.contourxunits;
    dy = a.contouryunits;

% 2 - Determine the X and Y data
    Z = get(h,'Zdata');
    switch type
    case 'x'; 
        idx = round(x/dx); X = Z(:,idx); Y = ((1:size(Z,1))'-1)*dy;
        a.xlabel = a.colorbarlabel; a.xlim = [];
        a.name = ['X = ',num2str(x)];       
    case 'y'; 
        idx = round(y/dy); X = ((1:size(Z,2))'-1)*dx; Y = Z(idx,:)';
        a.ylabel = a.colorbarlabel; a.ylim = [];
        a.name = ['Y = ',num2str(y)];
    end

% 3 - Plot the data
    XYscatter(X,Y,'advanced',a,'contour','off','legend',{});
    
%--------------------------------------------------------------------------
% CALLBACK: callback_linehighlight
function callback_linehighlight(hObject,~)
% CALLBACK_LINEHIGHLIGHT toggles line highlihting on and off

    if ~strcmpi(get(gcf,'SelectionType'),'normal'); return; end
    user = get(hObject,'UserData');
    w = get(hObject,'LineWidth');
    m = get(hObject,'Marker');
    s = get(hObject,'MarkerSize');
    
    if w == 4.151  
        set(hObject,'LineWidth',user.linewidth,'Marker',user.marker,...
            'MarkerSize',user.markersize);
        
        if isfield(user,'handles'); % Used by optics software
            set(user.handles,'LineWidth',user.linewidth,'Marker',user.marker,...
            'MarkerSize',user.markersize);
        end
        
        if isfield(user,'patch'); % Used by optics software
            p = findobj(gcf,'Type','patch');
            set(p,'FaceAlpha',0.25);
        end
        
    else      
        user.linewidth = w; user.marker = m; user.markersize = s;
        set(hObject,'LineWidth',4.151,'UserData',user ,'Marker','o',...
            'MarkerSize',5.151);
        
        if isfield(user,'handles'); % Used by optics software
            set(user.handles,'LineWidth',4.151,'UserData',user,...
            'MarkerSize',5.151);
        end 
        
        if isfield(user,'patch'); % Used by optics software
            set(user.patch,'FaceAlpha',0.6,'Visible','on');
        end
        
    end

