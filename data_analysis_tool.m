function data_analysis_tool(batches,currentBatchPath,curMovieIndex,pixelSize)


%Tool to analyze TrackIt batch files for a multitude of paramaters
%including diffusion analysis, bound fractions, track lengths etc.). Can be
%started either from within TrackIt via "Analysis" -> "Tracking data
%analysis" or by directly executing the data_analysis_tool function.
%
%
%Usage:
%data_analysis_tool(batches,currentBatchPath,curMovieIndex,pixelSize) or data_analysis_tool()
%
%
% Input: (function can also be called without inputs)
%     batches           -   initialize cell array of batches with the current
%                           batch analyzed in TrackIt
%     currentBatchPath  -   opening path for the "load batch file" dialog
%     curMovieIndex     -   Number of the movie currently visible in TrackIt main window
%     pixelSize         -   pixelsize in microns per pixel
%                   


%Create user interface
ui = CreateHistogramUI();

%Check if tool is called directly within Matlab or from the Main UI
if nargin == 4 && ~isempty(batches{1}(1).movieInfo.fileName)
    %Tracking data analysis tool was called from inside TrackIt

    if pixelSize == 0
        pixelSize = 1;
    end

    %Get list of frame cycle times of each movie of the current batch
    frameCycleTimeMovieList = {zeros(length(batches{1}),1)};

    for cMovieIdx = 1:length(batches{1})
        frameCycleTimeMovieList{1}(cMovieIdx) = batches{1}(cMovieIdx).movieInfo.frameCycleTime;
    end

    %Get list of unique frame cycle times of the curernt batch
    frameCycleTimesList = {unique(frameCycleTimeMovieList{1})};


    %Set name of TrackIt batch in the batch file list
    ui.popBatchSel.String = {'1: Current batch'};

    %Fill edit fields for pixel size and movie index with values from TrackIt main UI
    ui.editPixelsize.String = pixelSize;
    ui.editMovie.String = curMovieIndex;


else
    %Tracking data analysis tool was opended without TrackIt
    pixelSize = 1;

    %Add all subfolders to the matlab path
    mainFolder = fileparts(which(mfilename));
    addpath(genpath(mainFolder));

    %Opening path for the "load batch file" dialog e.g. currentBatchPath = 'D:\Data\CDX2'
    currentBatchPath = '';

    curMovieIndex = 1; %Initialize index of movie currently analyzed
    
    frameCycleTimeMovieList = {}; %Initialize list of frame cycle times of all movies
    frameCycleTimesList = {}; %Initialize list of unique frame cycle times
    batches = {}; %Initialize cell array of batch files
end


%Initialize results structure
results = InitResults();

%Initialize structure containing values plotted in central graph
currentPlotValues = struct;

%Create results
BatchSelectionCB()

%Initialize plotStyle
plotStyle = 'Histogram';

%Initialize results and user interface

    function results = InitResults()
        %Initialzize results structure
        
        results.batchName = '';         %Name of the batch file
        results.posInBatchList = '';         %Name of the batch file
        results.movieNames = '';        %Names of movies in the current batch
        results.movieNumbers = -1;      %Movie numbers of the movies with selected frame cycle time
        results.frameCycleTimes = -1;   %List of frame cycle times of the movies in the current batch
        results.trackingRadii = -1;     %List of the tracking radii used in each movie of the current batch
         
        results.trackLengths = -1;      %Array containing the duration of all tracks in all movies of the current batch
        results.meanTrackLength = -1;   %Array containing the average track duration of all tracks in all movies of the current batch
        
        results.angles = -1;            %Array containing the angles between jumps within all tracks in all movies of the current batch
        results.anglesMeanDisp = -1;    %Array containing the angles between jumps within all tracks in all movies of the current batch
        results.nAngles = -1;           %Array containing the number of angles
        results.jumpDistances = -1;     %Array containing the distances between jumps within all tracks in all movies of the current batch
        results.meanJumpDists = -1;     %Array containing the average jump distance of each track in all movies of the current batch
        results.meanJumpDistMoviewise = -1;%Array containing the average jump distance of each movie of the current batch
        results.nJumps = -1;           %Array containing the number of jumps in each movie of the current batch
        
        results.roiSize = -1;           %Array containing the sizes of the region of interest in all movies of the current batch
        results.meanTracksPerFrame = -1;%Array containing the average number of tracks per frame for each movie of the current batch
        results.meanSpotsPerFrame = -1; %Array containing the average number of spots per frame for each movie of the current batch
        results.nSpots = -1;            %Array containing the total number of spots in each movie of the current batch
        
        results.alphaValues = -1;       %Array containing the alpha values from the msd fit of all tracks of all movies of the current batch
        results.msdDiffConst = -1;      %Array containing the diffusion coefficient calculated from the msd fit of all tracks of all movies of the current batch
        results.confRad = -1;           %Array containing the confinement radius calculated from the msd fit of all tracks of all movies of the current batch
        results.meanJumpDistConfRad = -1;%Array containing the mean jump distance of the tracks where a confinement radius was calculated. Used to plot confinement radius vs. mean jump distance
                
        results.nTracks = -1;           %Array containing the number of tracks in each movie of the current batch
        results.nShort = -1;            %Array containing the number of short tracks in each movie of the current batch (threshold is defined in ui)
        results.nLong = -1;             %Array containing the number of long tracks in each movie of the current batch (threshold is defined in ui)
        results.nNonLinkedSpots = -1;   %Array containing the number of non-linked spots each movie of the current batch
        results.nAllEvents = -1;        %Array containing the number of all events in each movie of the current batch (nTracks + nNonLinkedSpots)
        results.trackedFractions = struct;%Structure array containing the results of tracked fractions
        
        results.distToRoiBorder = -1;   %Array containing the minimum distance of the average track position from the region of interest
    end

    function ui = CreateHistogramUI()
        %% Figure and axes
        fontSizeLarge = 10;
        fontSizeListbox = 9;
        fontSizeButton = 8;
        fontSizeCheckbox = 8.5;
        fontSizeEdit = 9;
        fontSizeText = 8.5;
        fontSizeRadBtn = 8;
        fontSizeMenu = 8;
        fontSizeTable = 8;

        %Create figure
        ui.f   = figure('Units','normalized',...
            'Position',[0.05 0.05 .82 .82],...
            'Name','Tracking data analysis',...
            'DefaultAxesFontSize',12,...
            'MenuBar','None',...
            'toolBar','Figure',...
            'CloseRequestFcn',@(~,~)CloseHistogram);

        %Create polar axis for angles display
        ui.pax  = polaraxes(ui.f,...
            'Units','normalized',...
            'visible','off',...
            'Position',[0.31 0.1 0.495 0.85]);
        
        %Create axis
        ui.ax  = axes(ui.f,...
            'Units','normalized',...
            'Position',[0.315 0.1 0.485 0.85]);


        % Create a context menu
        contextMenu = uicontextmenu;

        % Add a menu item to the context menu for setting axis font size
        menuLabel = 'Adjust axis, label and legend font size';
        uimenu(contextMenu, 'Label', menuLabel, 'Callback', @AdjustAxisFontSizeCB);

        % Set the context menu for the UI axis, X-axis label, and Y-axis label
        set(ui.ax, 'UIContextMenu', contextMenu);
        set(ui.pax, 'UIContextMenu', contextMenu);

        % Initialize a graphics object for storing histogram data
        ui.hist = gobjects(1);

        % Create a 'Export' menu in the main UI menu bar
        ui.menuFile = uimenu(ui.f, 'Label', 'Export');

        % Add a sub-menu item for exporting results to the Matlab workspace
        uimenu(ui.menuFile, 'Label', 'Export results to Matlab workspace', 'Callback', @CopyToWorkspaceCB);

        % Create a 'Help' menu in the main UI menu bar
        ui.menuHelp = uimenu(ui.f, 'Label', 'Help');

        % Add a sub-menu item for opening the manual
        uimenu(ui.menuHelp, 'Label', 'Open manual', 'Callback', @OpenManualCB);

        % Find all push tools, toggle split tools, and toggle tools in the main UI
        hTools1 = findall(ui.f, 'Type', 'uipushtool');
        hTools2 = findall(ui.f, 'Type', 'uitogglesplittool');
        hTools3 = findall(ui.f, 'Type', 'uitoggletool');

        % Delete push tools and toggle split tools
        delete(hTools1);
        delete(hTools2);

        % Iterate through toggle tools and delete those not related to exploration
        for c = 1:length(hTools3)
            if ~strcmp(hTools3(c).Tag, 'Exploration.DataCursor') && ...
                    ~strcmp(hTools3(c).Tag, 'Exploration.ZoomIn') && ...
                    ~strcmp(hTools3(c).Tag, 'Exploration.ZoomOut') && ...
                    ~strcmp(hTools3(c).Tag, 'Exploration.Pan')
                delete(hTools3(c));
            end
        end

        
        %% Batch selection

        %Create panel on left side of movie
        ui.panSel = uipanel(ui.f,'Position',[0.005 0.01 0.25 0.98]);
        
        %Button to load batch files
        ui.btnLoadBatchFiles  = uicontrol('Parent',ui.panSel,...
            'Units','normalized',...
            'FontSize',fontSizeButton,...
            'Position',[0.02 0.94 .32 0.04],...
            'String','Load batch .mat file(s)',... <html><br>
            'Callback',@LoadBatchFilesCB);

        %Button to rename loaded batch files
        ui.btnRenameBatchFiles  = uicontrol('Parent',ui.panSel,...
            'Units','normalized',...
            'FontSize',fontSizeButton,...
            'Position',[0.36 0.94 .3 0.04],...
            'String','Rename',... <html><br>
            'Callback',@RenameBatchFilesCB);
        
        %Button to remove batch files
        ui.btnRemoveBatchFiles  = uicontrol('Parent',ui.panSel,...
            'Units','normalized',...
            'FontSize',fontSizeButton,...
            'Position',[0.68 0.94 .3 0.04],...
            'String','Remove',... <html><br>
            'Callback',@RemoveBatchFilesCB);

        %Listbox that displays loaded batch files
        ui.popBatchSel = uicontrol('Parent',ui.panSel,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.02 0.685 0.96 0.25],...
            'Max',2,'Min',0,...
            'Callback',@(~,~)BatchSelectionCB);
        
        %Timelapse selection listbox
        ui.popTlSel = uicontrol('Parent',ui.panSel,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.02 0.48 0.45 0.18],...
            'String', {'Single movie', 'All movies'},...
            'Max',2,'Min',0,...
            'Callback',@(~,~)TlSelectionCB);
                
         % Movie Selection panel
        ui.panelMovieSel = uipanel(ui.panSel,...
            'Position',[0.52 0.58 0.45 0.09],'Title','Movie number'); %'BorderType','none'
        

        ui.btnNextMovie = uicontrol(ui.panelMovieSel,...
            'Units','normalized',...
            'FontSize',fontSizeButton,...
            'Position', [.52  .45   .45 .5],...
            'String','Next',...
            'Callback',@MovieNumberCB);
        
        ui.btnPreviousMovie = uicontrol(ui.panelMovieSel,...
            'Units','normalized',...
            'FontSize',fontSizeButton,...
            'Position', [.01  .45   .45 .5],...
            'String','Previous',...
            'Callback',@MovieNumberCB);
        ui.txtMovie = uicontrol(ui.panelMovieSel,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.05  .06   .3 .3],...
            'Style','Text',...
            'String','Movie',...
            'HorizontalAlignment','Left');
        ui.editMovie = uicontrol(ui.panelMovieSel,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.4  .07  .25 .3],...
            'Style','Edit',...
            'String',1,...
            'HorizontalAlignment','Right',...
            'Callback',@MovieNumberCB);
        ui.txtMovie2 = uicontrol(ui.panelMovieSel,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.69  .06  .1 .3],...
            'Style','Text',...
            'String','/',...
            'HorizontalAlignment','Left');
        ui.txtMovie3 = uicontrol(ui.panelMovieSel,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.75  .06   .3 .3],...
            'Style','Text',...
            'String',1,...
            'HorizontalAlignment','Left');
        
        %Sub-regions
        ui.popRegionSel = uicontrol('Parent',ui.panSel,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.52 0.48 0.45 0.091],...
            'String', {'All regions'},...
            'Max',2,'Min',0,...
            'Visible','on',... 
            'Callback',@(~,~)TlSelectionCB);
        
        %% Parameters selection tab group

        %Create tab group
        ui.tabGroupParam = uitabgroup('Parent',ui.panSel,...
            'Units','normalized',...
            'Position',[0.02 0.21 0.96 0.26],...
            'SelectionChangedFcn',@(~,~)PlotHistogramCB);
        
        %Create tab for jumps analysis
        ui.tabJumps = uitab(ui.tabGroupParam,...
            'Title','Jumps');
        
        %Listbox to select analysis parameter in the "jumps" tab
        ui.popJumps = uicontrol('Parent',ui.tabJumps,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.0 0.0 0.99 0.99],...
            'String', {'Jump distances', 'Cumulative jump distances',...
            'Diffusion fit results','Number of jumps','Mean jump distance per track', 'Mean jump distance per movie'},...
            'Callback',@(~,~)PlotHistogramCB);

        %Create tab for angle analysis
        ui.tabAngles = uitab(ui.tabGroupParam,...
            'Title','Angles');

        %Listbox to select analysis parameter in the "angles" tab
        ui.popAngles = uicontrol('Parent',ui.tabAngles,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.0 0.0 0.99 0.99],...
            'String', {'Jump angles', 'Jump angle anisotropy','Jump angle anisotropy vs. mean jump distance', 'Number of jump angles'},...
            'Callback',@(~,~)PlotHistogramCB);

        %Create tab for MSD analysis
        ui.tabMSD = uitab(ui.tabGroupParam,...
            'Title','MSD');

        %Listbox to select analysis parameter in the "MSD" tab
        ui.popMSD = uicontrol('Parent',ui.tabMSD,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.0 0.0 0.99 0.99],...
            'String', {'Confinement radius', 'Confinement radius vs. mean jump distance',...
            'Alpha values', 'Diffusion coefficients'},...
            'Callback',@(~,~)PlotHistogramCB);
        
        %Create tab for tracked fraction analysis
        ui.tabFractions = uitab(ui.tabGroupParam,...
            'Title','Tracked fractions');
        
        %Listbox to select analysis parameter in the "Tracked fraction" tab
        ui.popTrackedFraction = uicontrol('Parent',ui.tabFractions,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.0 0.0 0.99 0.99],...
            'String', {'Tracks vs. all events',...
            'Long tracks vs. all events',...
            'Short tracks vs. all events',...
            'Long tracks vs. long + short tracks',...
            'Number of tracks','No. of non-linked spots'...
            'Number of all events (tracks + non-linked)',...
            'Number of long tracks', 'Number of short tracks'},...
            'Callback',@(~,~)PlotHistogramCB);

        %Create tab for duration analysis
        ui.tabDurations = uitab(ui.tabGroupParam,...
            'Title','Durations');

        %Listbox to select analysis parameter in the "durations" tab
        ui.popDurations = uicontrol('Parent',ui.tabDurations,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.0 0.0 0.99 0.99],...
            'String', {'Track lengths','Survival time distribution',...
             'Average track length'},...
            'Callback',@(~,~)PlotHistogramCB);
        
        %Create tab for other analysis
        ui.tabOther = uitab(ui.tabGroupParam,...
            'Title','Other');
        
        %Listbox to select analysis parameter in the "other" tab
        ui.popOther = uicontrol('Parent',ui.tabOther,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Style','Listbox',...
            'Position',[0.0 0.0 0.99 0.99],...
            'String', {'Average number of tracks per frame',...
             'Average number of spots per frame', 'Total number of spots','ROI size',...
             'Distance to ROI border', 'Dist. to ROI border vs. mean jump dist.'},...
            'Callback',@(~,~)PlotHistogramCB);

               
        %% Statistics overview
                
        ui.txtStats  = uicontrol('Parent',ui.panSel,...
            'Style','text',...
            'Units','normalized',...
            'FontSize',fontSizeLarge,...
            'Position',[0.01 0.14 1 0.06],...
            'String','Statistics overview');
        
        
        ui.tableStatistics = uitable(ui.panSel,...
            'Units','normalized',...
            'FontSize',fontSizeTable,...
            'Position',[0.02 0.01 .96 .155],...
            'ColumnName',{''},...            
            'RowName',{},...
            'Data',{'#movies';'#tracks';'#non-linked spots';'#all events';'#jumps';'#angles'},...
            'ColumnEditable',[false,false,false,false]);
        
        %% Display settings panel
        ui.panSelStat = uipanel(ui.f,'Position',[0.82 0.005 0.18 0.99]);

               
        ui.panelDispSettings = uipanel(ui.panSelStat,...
            'Position',[0.02 0.77 0.96 0.23],...
            'Title','Display settings',...
            'Visible','on');

        vertSize = .14;

        %X-Axis
        
        ui.txtHistLimX = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeLarge,...
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position', [0.02 0.8 0.5 vertSize],...
            'String', 'x-axis limits');
        
        ui.editLimX1  = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'String','0',...
            'Position',[0.02 0.68 0.22 vertSize],...
            'Tag','x',...
            'Callback',@EditLimitsCB);

        ui.txtLimX = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position', [0.25 0.66 0.075 vertSize],...
            'String', '—');

        ui.editLimX2  = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'String','1',...
            'Position',[0.34 0.68 0.22 vertSize],...
            'Tag','x',...
            'Callback',@EditLimitsCB);
        
        ui.cboxLogX = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Position',[0.65 0.79 0.45 vertSize],...
            'String','Logarithmic',...
            'Tag','logX',...
            'Callback',@EditLimitsCB);
        
        ui.cboxAutoX = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Value',1,...
            'Position',[0.65 0.65 0.45 vertSize],...
            'String','Auto adjust',...            
            'Tag','autoX',...
            'Callback',@EditLimitsCB);
        
        %Y-Axis
       ui.txtHistLimY = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeLarge,...  
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position', [0.02 0.48 0.5 vertSize],...
            'String', 'y-axis limits');
        
        ui.editLimY1  = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'String','0',...
            'Position',[0.02 0.36 0.22 vertSize],...
            'Tag','y',...
            'Callback',@EditLimitsCB);

        ui.txtLimY = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeLarge,...
            'Style','text',...
            'Position', [0.25 0.34 0.075 vertSize],...
            'String', '—');

        ui.editLimY2  = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'String','1',...
            'Position',[0.34 0.36 0.22 vertSize],...
            'Tag','y',...
            'Callback',@EditLimitsCB);
        
        ui.cboxLogY = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Position',[0.65 0.47 0.45 vertSize],...
            'String','Logarithmic',...
            'Tag','logY',...
            'Callback',@EditLimitsCB);
        
        ui.cboxAutoY = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Value',1,...
            'Position',[0.65 0.33 0.45 vertSize],...
            'String','Auto adjust',...            
            'Tag','AutoY',...
            'Callback',@EditLimitsCB);

        %Show legend checkbox        
        ui.cboxShowLegend = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Position',[0.02 0.18 0.45 vertSize],...
            'String','Show legend',...
            'Value',1,...
            'Callback',@(~,~)AdjustAxis);
        
        
        % #bins
        ui.txtBinNum  = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...           
            'FontSize',fontSizeLarge,... 
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position',[0.02 0.01 0.4 vertSize],...
            'String','#bins');
        
        ui.editBinNum = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style', 'edit',...
            'Visible','on',...
            'Position', [0.24 0.02 0.2 vertSize],...
            'String','50',...
            'Callback',@(~,~)PlotHistogramCB);


        %Lookup-table
        ui.txtLut  = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...            
            'FontSize',fontSizeLarge,...
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position',[0.5 0.01 0.4 vertSize],...
            'String','LUT');
        
        ui.popLut = uicontrol('Parent',ui.panelDispSettings,...
            'Units','normalized',...
            'FontSize',fontSizeMenu,...
            'Style', 'popupmenu',...
            'Visible','on',...
            'Position', [0.65 0.02 0.30 vertSize],...
            'String',{'standard','winter','parula','jet','copper','gray'},...
            'Callback',@(~,~)PlotHistogramCB);
        
        %% Units panel
        
        ui.btnGroupUnits = uibuttongroup(ui.panSelStat,...
            'Units','normalized',...
            'Position', [.02  .68 .96 .09],...
            'Title','Units',...
            'SelectionChangedFcn',@btnGroupUnitsCB);
                
        %Pixels & frames radio button
        ui.btnPxFr = uicontrol(ui.btnGroupUnits,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.05  .55  .5 .4],...
            'Style','radiobutton',...
            'String','pixels & frames',...
            'HorizontalAlignment','Left');
        
        %Microns & seconds radio button
        ui.btnMiMs = uicontrol(ui.btnGroupUnits,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.55  .55  .6 .4],...
            'Style','radiobutton',...
            'String','microns & sec',...
            'HorizontalAlignment','Left');

        %Pixelsize text
        ui.txtPixelsize = uicontrol(ui.btnGroupUnits,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.05  .15  .75 .25],...
            'Visible','off',...
            'Style','text',...
            'String','Pixelsize in microns per px:',...
            'HorizontalAlignment','Left');
        
        %Pixelsize edit field                
        ui.editPixelsize = uicontrol(ui.btnGroupUnits,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.7  .12  .17 .32],...    
            'Visible','off',...
            'Style','Edit',...
            'String',1,...
            'Callback',@btnGroupUnitsCB);
        
        %% Jumps filtering options panel
        
        %Jumps to consider panel
        ui.panelJumpsToConsider = uipanel(ui.panSelStat,...
            'Position',[0.02 0.58 0.96 0.09],...
            'Title','Jumps filtering options',...
            'Visible','off'); %line/none
        
        %Jumps to consider text
        ui.txtJumpsToConsider = uicontrol('Parent',ui.panelJumpsToConsider,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position',[0.05 0.42 0.7 0.4],...
            'HorizontalAlignment','Left',...
            'Visible','on',...
            'String','Jumps to consider per track');
        
        %Jumps to consider edit field
        ui.editJumpsToConsider = uicontrol('Parent',ui.panelJumpsToConsider,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'Position',[0.75 0.47 0.2 0.4],...
            'String',Inf,...
            'Visible','on',...
            'Callback',@(~,~)CreateData);
        
        %Checkbox to remove jumps over gap frames
        ui.cboxRemoveGaps = uicontrol('Parent',ui.panelJumpsToConsider,...
            'Units','normalized',...
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Position',[0.05 0.05 0.95 0.3],...
            'HorizontalAlignment','Left',...
            'Visible','on',...
            'Value',1,...
            'String','Remove jumps over gap frames',...
            'Callback',@(~,~)CreateData);
        
        
        %% Histogram normalization and style panel
        
        %Normalize by count or probability
        ui.panelNormalization = uipanel(ui.panSelStat,...
            'Position',[0.02 0.51 0.96 0.06],...
            'Visible','off',...
            'BorderType','none'); %line/none
                
        %Button group for normalization
        ui.btnGroupNormalization = uibuttongroup(ui.panelNormalization,...
            'Units','normalized',...
            'Position', [.0  .0   .53 1],...
            'Title','Normalization',...
            'SelectionChangedFcn',@(~,~)PlotHistogramCB);
                        
        %Probability radio button
        ui.btnProbability = uicontrol(ui.btnGroupNormalization,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.45  .0   .6 .9],...
            'Style','radiobutton',...
            'String','Probability',...
            'HorizontalAlignment','Left');

        %Count radio button
        ui.btnCount = uicontrol(ui.btnGroupNormalization,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.05  .0   .4 .9],...
            'Style','radiobutton',...
            'String','Count',...
            'HorizontalAlignment','Left');
        
        %Histogram style: Bars or Stairs button group
        ui.btnGroupBarsStairs = uibuttongroup(ui.panelNormalization,...
            'Units','normalized',...
            'Position', [.55  .0 .45 1],...
            'Title','Display style',...
            'Visible','on',...
            'SelectionChangedFcn',@(~,~)PlotHistogramCB);
                
        %Bars radio button
        ui.btnBars = uicontrol(ui.btnGroupBarsStairs,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.05  .0  .5 .9],...
            'Style','radiobutton',...
            'String','Bars',...
            'HorizontalAlignment','Left');
        
        %Stairs radio button
        ui.btnStairs = uicontrol(ui.btnGroupBarsStairs,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.55  .0  .6 .9],...
            'Style','radiobutton',...
            'String','Stairs',...
            'HorizontalAlignment','Left');



        
        
        %% Panel diffusion analysis

        %Checkbox to display fit curves in the "jump distances" and
        %"cumulative jump distances" analysis
        ui.cboxShowFit1 = uicontrol('Parent',ui.panSelStat,...
            'Units','normalized',...       
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Visible','off',...
            'Position',[0.02 0.4 0.8 0.03],...
            'String','Show diffusion fit curves',...
            'Callback',@(~,~)PlotHistogramCB);


        %Create panel containing all the diffusion analysis ui elements
        ui.panelDiffParam = uipanel(ui.panSelStat,...
            'Position',[0.02 0.0 .96 0.4],...
            'Visible','off',...
            'Title','Diffusion analysis'); %line/none

        % Button group to select number of rates for diffusion fit
        ui.btnGroupFitType = uibuttongroup(ui.panelDiffParam,...
            'Position', [.02  .85   .96 .15],...
            'Title','Fit type',...
            'Visible','on',...
            'SelectionChangedFcn',@(~,~)PlotHistogramCB);
        
        ui.btnThreeRates = uicontrol(ui.btnGroupFitType,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.02  .0   .5 .9],...
            'Style','radiobutton',...
            'String','3 rates',...
            'HorizontalAlignment','Left');
        
        ui.btnTwoRates = uicontrol(ui.btnGroupFitType,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.37  .0   .5 .9],...
            'Style','radiobutton',...
            'String','2 rates',...
            'HorizontalAlignment','Left');
        
        ui.btnOneRate = uicontrol(ui.btnGroupFitType,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.7  .0   .5 .9],...
            'Style','radiobutton',...
            'String','1 rate',...
            'HorizontalAlignment','Left');

        %Warning for overlaying fit with normal histogram
        ui.txtFitWarning = uicontrol('Parent',ui.panelDiffParam,...
            'Units','normalized',...       
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position',[0.1 0.6 0.8 0.2],...
            'String','Note: displayed fit curves are a visualization of the results obtained from fitting the cumulative jump distance histogram! ',...
            'Callback',@(~,~)PlotHistogramCB);

        
        %Parameter button group for the "Diffusion fit results" 
        ui.btnGroupDisplayedParam = uibuttongroup(ui.panelDiffParam,...
            'Units','normalized',...
            'Position', [.02  .69   .96 .15],...
            'Title','Displayed parameter',...
            'Visible','off',...
            'SelectionChangedFcn',@(~,~)PlotHistogramCB);
        
        ui.btnShowD = uicontrol(ui.btnGroupDisplayedParam,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.02  .0   .3 .9],...
            'Style','radiobutton',...
            'String','D',...
            'HorizontalAlignment','Left');
        
        ui.btnShowA = uicontrol(ui.btnGroupDisplayedParam,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.3  .0   .3 .9],...
            'Style','radiobutton',...
            'String','A',...
            'HorizontalAlignment','Left');
        
        ui.btnShowEffectiveD = uicontrol(ui.btnGroupDisplayedParam,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.6  .0   .5 .9],...
            'Style','radiobutton',...
            'String','Effective D',...
            'HorizontalAlignment','Left');
                
        %Diffusion analysis resampling panel
        ui.panelDataAndError = uipanel(ui.panelDiffParam,...
            'Position',[0.02 0.43 .96 0.25],...
            'Visible','off',...
            'Title','Displayed values and error'); %line/none
        
        %Popupmenu to select displayed value and error
        ui.popError = uicontrol('Parent',ui.panelDataAndError,...
            'Units','normalized',...
            'FontSize',fontSizeMenu,...
            'Style', 'popupmenu',...
            'Visible','on',...
            'Position', [0.02 0.8 .96 0.1],...
            'String',{'Pooled data, 95% confidence interval','Mean & stand. dev. of movie-wise values','Mean & stand. dev. of respampling values'},...
            'Callback',@(~,~)PlotHistogramCB);


        %Resampling panel to select number of resamplings and percentage
        ui.panelResamplingDiff = uipanel(ui.panelDataAndError,...
            'Position',[0.00 0.05 1 0.4],...
            'Visible','off',...
            'BorderType','none'); %line/none
        
        ui.editNResamplingDiff = uicontrol('Parent',ui.panelResamplingDiff,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'Position',[0.02 0.01 0.15 0.8],...
            'String',5,...
            'Visible','on',...
            'Callback',@(~,~)PlotHistogramCB);
        
        ui.txtNResamplingDiff1 = uicontrol('Parent',ui.panelResamplingDiff,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position',[0.2 0.0 0.4 0.75],...
            'String','resamplings with',...
            'HorizontalAlignment','Left',...
            'Visible','on');
        
        ui.editPercResamplingDiff = uicontrol('Parent',ui.panelResamplingDiff,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'Position',[0.6 0.01 0.15 0.8],...
            'String',50,...
            'Visible','on',...
            'Callback',@(~,~)PlotHistogramCB);
               
        ui.txtNResamplingDiff2 = uicontrol('Parent',ui.panelResamplingDiff,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position',[0.78 0.00 0.5 0.75],...
            'HorizontalAlignment','Left',...
            'String','% data',...
            'Visible','on');
        
        %Panel to select bin size and start values for the fit

        ui.panelDiffSet = uipanel(ui.panelDiffParam,...
            'Position',[0.02 0.0 0.96 0.4],...
            'Visible','on',...
            'Title','Fit settings'); %line/none
        
        ui.txtBinSize = uicontrol('Parent',ui.panelDiffSet,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position',[0.05 0.75 0.7 0.2],...
            'HorizontalAlignment','Left',...
            'Visible','on',...
            'String','Bin width (px)');
        
        ui.editBinSize = uicontrol('Parent',ui.panelDiffSet,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'Position',[0.75 0.8 0.2 0.2],...
            'BackgroundColor', [1 1 0.6],...
            'String',0.001,...
            'Visible','on',...
            'Callback',@(~,~)PlotHistogramCB);


        ui.tableStartD = uitable(ui.panelDiffSet,...
            'Units','normalized',...
            'FontSize',fontSizeTable,...
            'Position',[0.2 0.02 0.7 0.7],...
            'ColumnName',{'','Fit start value'},...         
            'Visible','on',...
            'RowName',{},...
            'Data',{'D1',0.1;'D2',1;'D3',10;},...
            'ColumnEditable',[false,true],...
            'CellEditCallback',@(~,~)PlotHistogramCB);
         
        %% Angles: Polarplot or lineplot
        
        ui.btnGroupPolarOrLine = uibuttongroup(ui.panSelStat,...
            'Units','normalized',...
            'Position', [.02  .44 .96 .06],...
            'Title','Histogram style',...
            'Visible','off',...
            'SelectionChangedFcn',@(~,~)PlotHistogramCB);
                
        ui.btnAnglesPolarplot = uicontrol(ui.btnGroupPolarOrLine,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.05  .0  .5 .9],...
            'Style','radiobutton',...
            'String','Polarplot',...
            'HorizontalAlignment','Left');
        
        ui.btnAnglesLineplot = uicontrol(ui.btnGroupPolarOrLine,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.55  .0  .6 .9],...
            'Style','radiobutton',...
            'String','Lineplot',...
            'HorizontalAlignment','Left');
        
        %% Angles: Jump distances making up the angle
        
        ui.btnGroupAnglesJumpDist = uipanel(ui.panSelStat,...
            'Units','normalized',...
            'Position', [.02  .26 .96 .1],...
            'Title','Jumps making up the angle',...
            'Visible','off');
                
        ui.txtMinJumpDist = uicontrol(ui.btnGroupAnglesJumpDist,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.05  .65  .5 .2],...
            'Style','text',...
            'String','Min. jump distance:',...
            'HorizontalAlignment','Left');
        
        ui.editAnglesMinJumpDist = uicontrol(ui.btnGroupAnglesJumpDist,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.5  .6  .18 .3],...    
            'Style','Edit',...
            'String',0,...
            'Callback',@(~,~)CreateData);
        
        ui.txtAnglesMinJumpDist = uicontrol(ui.btnGroupAnglesJumpDist,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.7  .55  .2 .3],...    
            'Style','text',...
            'String','px');
        
        ui.txtMaxJumpDist = uicontrol(ui.btnGroupAnglesJumpDist,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.05  .15  .6 .2],...
            'Style','text',...
            'String','Max. jump distance:',...
            'HorizontalAlignment','Left');
                                
        ui.editAnglesMaxJumpDist = uicontrol(ui.btnGroupAnglesJumpDist,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.5  .1  .18 .3],...    
            'Style','Edit',...
            'String',Inf,...
            'Callback',@(~,~)CreateData);
        
        ui.txtAnglesMaxJumpDist = uicontrol(ui.btnGroupAnglesJumpDist,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.7  .05  .2 .3],...    
            'Style','text',...
            'String','px');

        %% Angle anisotropy resampling panel       

        ui.panelResamplingAnisotropy = uipanel(ui.panSelStat,...
            'Title','Resampling for error calculation',...
            'Position',[0.02 0.19 .96 0.06],...
            'Visible','off'); %line/none
        
        ui.editNResamplingAnisotropy = uicontrol('Parent',ui.panelResamplingAnisotropy,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'Position',[0.02 0.05 0.15 0.7],...
            'String',50,...
            'Visible','on',...
            'Callback',@(~,~)PlotHistogramCB);
        
        ui.txtNResampling1Anisotropy = uicontrol('Parent',ui.panelResamplingAnisotropy,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position',[0.2 0.0 0.4 0.7],...
            'String','resamplings with',...
            'HorizontalAlignment','Left',...
            'Visible','on');
        
        ui.editPercResamplingAnisotropy = uicontrol('Parent',ui.panelResamplingAnisotropy,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Style','edit',...
            'Position',[0.6 0.05 0.15 0.7],...
            'String',50,...
            'FontSize',9.5,...
            'Visible','on',...
            'Callback',@(~,~)PlotHistogramCB);
               
        ui.txtNResampling2Anisotropy = uicontrol('Parent',ui.panelResamplingAnisotropy,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'Position',[0.78 0.00 0.5 0.7],...
            'HorizontalAlignment','Left',...
            'String','% data',...
            'Visible','on');
        
       
        %% Illumination pattern panel
       
        %Button group to select between continuous and ITM illumination
        ui.btnGroupITM = uibuttongroup(ui.panSelStat,...
            'Units','normalized',...
            'Position', [0.02 0.62 0.96 0.055],...
            'Title','Illumination pattern',...
            'Visible','off',...
            'SelectionChangedFcn',@bgITMselectionCB);
                
        ui.btnContinuous = uicontrol(ui.btnGroupITM,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.05  .0   .5 .9],...
            'Style','radiobutton',...
            'String','Continuous',...
            'HorizontalAlignment','Left');
        
        ui.btnITM = uicontrol(ui.btnGroupITM,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.47  .0   .6 .9],...
            'Style','radiobutton',...
            'String','Interlaced (ITM)',...
            'HorizontalAlignment','Left');

        %Panel to enter number of survived frames to count as long track
        ui.panelLongTrack = uipanel(ui.panSelStat,...
            'Units','normalized',...
            'Position', [0.02 0.54 0.96 0.07],...
            'Title','Definition of a long track',...
            'Visible','off');

        ui.txtNDarkForLong = uicontrol(ui.panelLongTrack,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.05  .0   .7 .85],...
            'Style','text',...
            'String','Count as long track if number of survived frames is greater than:',...
            'HorizontalAlignment','Left');

        ui.editNDarkForLong = uicontrol(ui.panelLongTrack,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.8  .2  .17 .5],...    
            'Style','Edit',...
            'String',3,...
            'Callback',@(~,~)bgITMselectionCB);

        %Panel to select the number of bright frames in one ITM cycle
        %(experimental feature that is currently not used)
        ui.panelNBrightFrames = uipanel(ui.panSelStat,...
            'Units','normalized',...
            'Position', [0.02 0.35 0.96 0.06],...
            'Title','Number of bright frames between dark periods',...
            'Visible','off');

        ui.txtNBrightFrames = uicontrol(ui.panelNBrightFrames,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Position', [.05  .0   .7 .7],...
            'Visible','on',...
            'Style','text',...
            'String','#bright frames in one cycle',...
            'HorizontalAlignment','Left');

        ui.editNBrightFrames = uicontrol(ui.panelNBrightFrames,...
            'Units','normalized',...
            'FontSize',fontSizeEdit,...
            'Position', [.8  .2  .17 .5],... 
            'Visible','on',...   
            'Style','Edit',...
            'String',1,...
            'Callback',@(~,~)bgITMselectionCB);
               
        %% Group movies panel: normalize by ROI and batch or movie-wise
              
        %Button group to plot all values grouped by batch number or plotted
        %versus another value
        ui.btnGroupSwarmVsMovie = uibuttongroup(ui.panSelStat,...
            'Units','normalized',...
            'Position', [.02  .45 .96 .08],...
            'Title','X-axis',...
            'Visible','off',...
            'SelectionChangedFcn',@(~,~)PlotHistogramCB);
                
        ui.btnValueVsBatchFile = uicontrol(ui.btnGroupSwarmVsMovie,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.05  .1  .5 .9],...
            'Style','radiobutton',...
            'String','Batch file',...
            'HorizontalAlignment','Left');
        
        ui.btnValueVsParameter = uicontrol(ui.btnGroupSwarmVsMovie,...
            'Units','normalized',...
            'FontSize',fontSizeRadBtn,...
            'Position', [.4  .1  .2 .9],...
            'Style','radiobutton',...
            'HorizontalAlignment','Left');
        
        ui.popValueVsParameter = uicontrol(ui.btnGroupSwarmVsMovie,...
            'Units','normalized',...
            'FontSize',fontSizeMenu,...
            'Position', [.50  0  .45 .8],...
            'Style','popupmenu',...            
            'String',{'Movie number', 'No. of tracks', 'No. of non-linked spots', 'No. of all events',...
            'Mean jump distance', 'Avg. track length', 'Avg. no. of tracks per frame',...
            'Avg. no. of spots per frame', 'ROI size','No. of jumps'},...
            'HorizontalAlignment','Left',...
            'Callback',@(~,~)PlotHistogramCB);
                      
        %% MSD fit panel
        
        textHeight = .08;
        editWidth = 0.18;
        
        ui.panelMsdFit = uipanel(ui.panSelStat,...
            'Position',[0.02 0.02 0.95 0.45],...
            'Visible','off',...
            'BorderType','none'); %line/none
        
        %Radio button group to select between linear and power law fit
         ui.btnGroupFitFun = uibuttongroup(ui.panelMsdFit,...
            'Units','normalized',...
            'Position', [.0  .85 .99 .15],...
            'Title','Fit function',...
            'Tag','FitFun',...
            'SelectionChangedFcn',@PointsToFitBtnCB);
                
        ui.btnMSD = uicontrol(ui.btnGroupFitFun,...
            'Units','normalized',...
            'Position', [.05  .15  .5 .8],...
            'Style','radiobutton',...
            'String','Power law',...
            'Tag','MSD',...
            'HorizontalAlignment','Left');
        
        ui.btnLinear = uicontrol(ui.btnGroupFitFun,...
            'Units','normalized',...
            'Position', [.55  .15  .6 .8],...
            'Style','radiobutton',...
            'String','Linear',...            
            'Tag','Linear',...
            'HorizontalAlignment','Left');
        
        %Number of points to fit
        ui.txtPointsToFit  = uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position',[0.0 0.75 1 textHeight],...
            'String','Amount of MSD points to fit (number or percentage)');
                
        
        ui.editPointsToFit = uicontrol('Parent',ui.panelMsdFit,...
            'Style', 'edit',...
            'FontSize',fontSizeEdit,...
            'Units','normalized',...
            'Visible','on',...
            'Position', [0.0 0.7 editWidth textHeight],...
            'String','90%');
    
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.35  .7   editWidth textHeight],...
            'String','5',...
            'Tag','PointsToFit',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
        
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.55  .7   editWidth textHeight],...
            'String','60%',...
            'Tag','PointsToFit',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
                
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.75  .7   editWidth textHeight],...
            'String','90%',...
            'Tag','PointsToFit',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
        
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.35  .62   editWidth textHeight],...
            'String','10',...
            'Tag','PointsToFit',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
        
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.55  .62   editWidth textHeight],...
            'String','75%',...
            'Tag','PointsToFit',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
                
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.75  .62   editWidth textHeight],...
            'String','100%',...
            'Tag','PointsToFit',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
        
        %Offset
        
        ui.txtOffset = uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'FontSize',fontSizeText,...
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position',[0.0 0.5 0.5 textHeight],...
            'String','Max. offset');
        
        ui.editOffset = uicontrol('Parent',ui.panelMsdFit,...
            'Style', 'edit',...
            'FontSize',fontSizeEdit,...
            'Units','normalized',...
            'Visible','on',...
            'Position', [0.0 0.45 editWidth textHeight],...
            'String','0',...
            'Callback',@(~,~)PlotHistogramCB);
        
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.35  .45   editWidth textHeight],...
            'String','0',...
            'Tag','Offset',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
        
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.55  .45   editWidth textHeight],...
            'String','0.5',...
            'Tag','Offset',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
                
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.75  .45   editWidth textHeight],...
            'String','1',...
            'Tag','Offset',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
        
       %Shortest track        
        ui.txtMsdShortestTrack  = uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...            
            'FontSize',fontSizeText,...
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position',[0.0 0.3 0.5 textHeight],...
            'String','Shortest track');
        
        ui.editMsdShortestTrack = uicontrol('Parent',ui.panelMsdFit,...
            'Style', 'edit',...
            'FontSize',fontSizeEdit,...
            'Units','normalized',...
            'Visible','on',...
            'Position', [0.5 0.3 editWidth textHeight],...
            'String','10',...
            'Callback',@(~,~)PlotHistogramCB);
        
        %Alpha Treshold
        ui.txtAlphaThres  = uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...           
            'FontSize',fontSizeText,... 
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position',[0.0 0.19 0.95 textHeight],...
            'String','Show tracks with alpha values below or equal to');
        
        ui.editAlphaThres = uicontrol('Parent',ui.panelMsdFit,...
            'Style', 'edit',...
            'FontSize',fontSizeEdit,...
            'Units','normalized',...
            'Visible','on',...
            'Position', [0.0 0.13 editWidth textHeight],...
            'String','Inf',...
            'Callback',@(~,~)CreateData);
        
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.35  .13   editWidth textHeight],...
            'String','0.7',...
            'Tag','Alpha',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
        
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.55  .13   editWidth textHeight],...
            'String','1',...
            'Tag','Alpha',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);
                
        uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'Position',[.75  .13   editWidth textHeight],...
            'String','Inf',...
            'Tag','Alpha',...
            'HorizontalAlignment','Left',...
            'Callback',@PointsToFitBtnCB);

        %Button to start fit procedure
        ui.btnFitMsd = uicontrol('Parent',ui.panelMsdFit,...
            'Units','normalized',...
            'FontSize',9,...
            'Visible','on',...
            'Position',[0.1 0.0 .8 0.1],...
            'BackgroundColor', [1 1 0.8],...
            'String','Fit MSD',... <html><br>
            'Callback',@FitMsdCB);
              
        %% Normalize by ROI size
        
        ui.cboxNormalizeROI = uicontrol(ui.panSelStat,...
            'Units','normalized',...
            'FontSize',fontSizeCheckbox,...
            'Style','checkbox',...
            'Visible','off',...
            'Position',[0.05 0.28 0.8 0.04],...
            'String','Normalize by ROI-size',...
            'Callback',@(~,~)PlotHistogramCB);
        
        %% Distance from ROI
        
        ui.btnCalcDistance = uicontrol('Parent',ui.panSelStat,...
            'Units','normalized',...
            'FontSize',fontSizeListbox,...
            'Visible','off',...
            'Position',[0.1 0.05 .8 0.05],...
            'String','Calculate distances',... <html><br>
            'Callback',@CalcDistanceFromRoiCB);
                        

        %% Other
        %Initialize datacursor
        ui.dataCoursor = datacursormode(ui.f);
        set(ui.dataCoursor,'UpdateFcn',{@dataCursorCB});
        
    end

%Data creation

    function CreateData()
        %Function to create all the results (except confinement radii and Diffusion fit results)
        %Executed every time the composition of movies to show changes
        
        if isempty(batches)
            results = InitResults();
        else
            %Get amount of selected batch files
            nBatches = numel(ui.popBatchSel.Value);
            
            %Initialize results structure
            resultsInit = InitResults();
            results = repmat(resultsInit, 1, nBatches);
            
            %Initialize loop variables
            resultIdx = 1;
            nSelectedBatches = numel(ui.popBatchSel.Value);
            
            columnName = cell(nSelectedBatches,1);
            statData = cell(4,nSelectedBatches);

            %Iterate through selected batch files and create data for the
            %selected combination of batch file, frameCycleTime and
            %subRegion
            for datasetIdx = 1:nSelectedBatches
                curBatchPosInList = ui.popBatchSel.Value(datasetIdx);
                
                %Get batch file for this loop
                currentBatch = batches{curBatchPosInList};
                
                if ui.popTlSel.Value(1) == 1 
                    %User want to see results of one specific movie number
                    if length(batches{curBatchPosInList}) < curMovieIndex
                        moviesIdx = [];
                    else
                        moviesIdx = curMovieIndex;
                    end
                elseif ui.popTlSel.Value(1) == 2
                    %User want to see results of all movies
                    %Get movie indices of all movies in this batch
                    moviesIdx = 1:length(currentBatch);
                else
                    %User want to see movies with specific frameCycleTimes                 
                    %Find logical indices of movies matching these fcts
                    fctMovies = zeros(length(currentBatch),1);
                    for k = 1:numel(ui.popTlSel.Value)
                        curFct = str2double(ui.popTlSel.String{ui.popTlSel.Value(k)}(1:end-3));
                        fctMovies = or(fctMovies, frameCycleTimeMovieList{curBatchPosInList} == curFct);
                    end
                    
                    %Get indices of movies having the selected frameCycleTimes
                    moviesIdx = find(fctMovies');
                end
                
                resultsInCurBatch = [currentBatch(moviesIdx).results];

                if isempty(moviesIdx)
                    %There is no movie in this batch with the selected
                    %frame cycle time
                    results(resultIdx) = [];
                                        
                    nMovies = 0;
                    nTracks = 0;
                    nNonLinkedSpots = 0;
                    nAllEvents = 0;
                    nAllAngles = 0;
                    nAllJumps = 0;
                elseif all([resultsInCurBatch.nSpots]' == 0)
                    % none of the movies contains any spots
                    results(resultIdx) = [];
                                                   
                    nMovies = sum(moviesIdx);
                    nTracks = 0;
                    nNonLinkedSpots = 0;
                    nAllEvents = 0;
                    nAllAngles = 0;
                    nAllJumps = 0;
                else


                    %-----Get all settings from the user interface-----------------------------

                    
                    para.regionNum = ui.popRegionSel.Value-1;                                       %Get currently selected Region
                    para.nJumpsToConsider = str2double(ui.editJumpsToConsider.String);              %Number of jumps in on track that should be considered for mobility analysis
                    para.boolRemoveGaps = ui.cboxRemoveGaps.Value;                                  %Wether user wants to remove jumps and angles where gap frames are involved
                    para.alphaThres = str2double(ui.editAlphaThres.String);                         %Get alpha value threshold for msd analysis
                    para.boolPixelsAndFrames = ui.btnPxFr.Value;                                    %Check if units should be displayed in pixels or frames
                    para.nDarkForLong = str2double(ui.editNDarkForLong.String);                     %Number of frames or dark periods to count as "long track"
                    para.nBrightFrames = str2double(ui.editNBrightFrames.String);                   %Number of subsequent bright frames before a dark period (1 for continuous, >1 for ITM)
                    para.minJumpDistForAngles = str2double(ui.editAnglesMinJumpDist.String);        %Minimum jump distance of the jumps making up the jump angles
                    para.maxJumpDistForAngles = str2double(ui.editAnglesMaxJumpDist.String);        %Maximum jump distance of the jumps making up the jump angles


                    if para.boolPixelsAndFrames
                        %Results are displayed in pixels and frames
                        para.pixelsize = 1;
                    else
                        %Results are displayed in microns and seconds
                        para.pixelsize = str2double(ui.editPixelsize.String);
                    end

                    %Create results for the current batch and the given movie indices
                    curBatchResults = create_histogram_data(currentBatch,moviesIdx, para);
                    
                    %Save list of batch filenames in results structure
                    curBatchResults.batchName = ui.popBatchSel.String{curBatchPosInList};
                    curBatchResults.posInBatchList = curBatchPosInList;
                   

                    results(resultIdx) = curBatchResults;
                    
                    %Create results displayed in the statistics table (lower left)
                    nMovies = sum(results(resultIdx).roiSize(:) ~= 0);
                    nTracks = sum(vertcat(results(resultIdx).nTracks));
                    nNonLinkedSpots = sum(vertcat(results(resultIdx).nNonLinkedSpots));
                    nAllEvents = sum(vertcat(results(resultIdx).nAllEvents));
                    nAllAngles = sum(vertcat(results(resultIdx).nAngles));
                    nAllJumps = sum(vertcat(results(resultIdx).nJumps));
                    
                    
                    resultIdx = resultIdx + 1;                    
                end
                
                
                %Create statistics for the lower left corner of the ui
                statData{1,datasetIdx} = nMovies;
                statData{2,datasetIdx} = nTracks;
                statData{3,datasetIdx} = nNonLinkedSpots;
                statData{4,datasetIdx} = nAllEvents;
                statData{5,datasetIdx} = nAllJumps;
                statData{6,datasetIdx} = nAllAngles;

                columnName{datasetIdx} = ['#', num2str(curBatchPosInList)];                
            end
            
            
            if ~isempty(columnName)
                %Display statistics at the lower left corner of the ui
                ui.tableStatistics.Data = [ui.tableStatistics.Data(:,1), statData];                
                ui.tableStatistics.ColumnName = [{''}; columnName];
            else
                %No batches to display
                ui.tableStatistics.ColumnName = {''};
                ui.tableStatistics.Data = {'#movies';'#tracks';'#non-linked spots';'#all events';'#jumps';'#angles'};
            end
            
        end
        
        PlotHistogramCB()    
    end

    function FitMsdCB(src,~)
        %Executed when user presses "Fit MSD" button, fits the msd of all
        %tracks in all movies of all batches
        
        %Button turns red during execution
        src.BackgroundColor = 'r';
        
        %Get user settings for msd analysis
        shortestTrack = str2double(ui.editMsdShortestTrack.String);
        maxOffset = str2double(ui.editOffset.String);
        pointsToFit = ui.editPointsToFit.String;
        msdOrLinear = ui.btnGroupFitFun.SelectedObject.Tag;
        
        %Iterate through batches
        for batchIdx = 1:length(batches)
            %Get current batch
            curbatch = batches{batchIdx};
            %Get number of movies in current batch
            nMoviesInCurBatch = length(curbatch);
            %Iterate through movies of current batch
            
            for curMovieIdx = 1:nMoviesInCurBatch
                %Display fitting progress
                src.String = ['Fitting batch #',num2str(batchIdx), ', movie ', num2str(curMovieIdx), '/', num2str(nMoviesInCurBatch)];
                drawnow

                %Get tracks in current movie
                tracks = curbatch(curMovieIdx).results.tracks;

                %Fit msd and retrieve results
                msdResults = msd_analysis(tracks,shortestTrack,pointsToFit,maxOffset,msdOrLinear);
                
                curbatch(curMovieIdx).results.msdDiffConst = msdResults.msdDiffConst;
                curbatch(curMovieIdx).results.alphaValues = msdResults.alphaValues;
                curbatch(curMovieIdx).results.confRad = msdResults.confRad;
                curbatch(curMovieIdx).results.meanJumpDistConfRad = msdResults.meanJumpDist;
                
                nRegions = curbatch(curMovieIdx).results.nSubRegions+1;                
                trackSubRegionAssignment = curbatch(curMovieIdx).results.tracksSubRoi;
                
                
                for subRegionIdx = 1:nRegions
                    tracksInSubRegion  = subRegionIdx-1 == trackSubRegionAssignment;
                    curbatch(curMovieIdx).results.subRegionResults(subRegionIdx).msdDiffConst = msdResults.msdDiffConst(tracksInSubRegion);
                    curbatch(curMovieIdx).results.subRegionResults(subRegionIdx).alphaValues = msdResults.alphaValues(tracksInSubRegion);
                    curbatch(curMovieIdx).results.subRegionResults(subRegionIdx).confRad = msdResults.confRad(tracksInSubRegion);
                    curbatch(curMovieIdx).results.subRegionResults(subRegionIdx).meanJumpDistConfRad = msdResults.meanJumpDist(tracksInSubRegion);
                end
                
            end
            %Save fit results in batches structure
            batches{batchIdx} = curbatch;
        end
        
        %Reset button
        src.String = 'Fit MSD';
        src.BackgroundColor = [.94 .94 .94];
        
        %Update all results and plots
        CreateData()
    end

    function CalcDistanceFromRoiCB(src,~)
        %Calculate distance of a track or all the detections of a track
        %with respect to the closest ROI or subROI

        oriString = src.String;
        src.BackgroundColor = 'r';
        drawnow


        %Iterate through all batches
        for batchIdx =  1:length(batches)
            
            %Get current batch
            curbatch = batches{batchIdx};

            %Iterate through all movies
            for movieIdx = 1 : length(curbatch)
                %Display progress on the fit button
                src.String = ['Batch #',num2str(batchIdx), ', Movie #', num2str(movieIdx)];
                drawnow
                
                %Get region number of all tracks
                tracksInSubRoiIdx = curbatch(movieIdx).results.tracksSubRoi;
                
                %Get tracks
                tracks = curbatch(movieIdx).results.tracks;
                
                %Get number of tracks
                nTracks = length(tracks);
                
                %Initialize variable to save distances
                minDistCurMovie = zeros(nTracks,1);
                
                %Iterate through all tracks of current movie
                for trackIdx = 1:nTracks

                    %Check if any subROIs exist
                    if isempty(tracksInSubRoiIdx)
                        %No subROI, so roi index is 1
                        roiIdx = 1;
                    else
                        %Sub rois exist so get roi index of current track
                        roiIdx = tracksInSubRoiIdx(trackIdx)+1;
                    end
                    
                    if roiIdx == 1
                        %Region of current track is tracking region
                        subROI = curbatch(movieIdx).ROI{1};
                    else
                        %Region of current track is a subRegion
                        subROI = vertcat(curbatch(movieIdx).subROI{roiIdx-1}{1}{:});
                    end
                    
                    %Calculate mean position of track
                    P = mean(tracks{trackIdx}(:,2:3));

                    %Calculate distance from mean track position to the
                    %nearest region border
                    minDistCurMovie(trackIdx) = abs(p_poly_dist1(P(1), P(2), subROI(:,1), subROI(:,2)));
                    
                end
                
                %Save distance in current batch
                curbatch(movieIdx).results.distToRoiBorder = minDistCurMovie;
                
                %Get number of subRegions
                nRegions = curbatch(movieIdx).results.nSubRegions+1;
                
                %Iterate through all subRegions and save distance to roi
                %border in the respective subregion structure
                for subRegionIdx = 1:nRegions
                    tracksInCurSubRegion  = subRegionIdx-1 == tracksInSubRoiIdx;                    
                    curbatch(movieIdx).results.subRegionResults(subRegionIdx).distToRoiBorder = minDistCurMovie(tracksInCurSubRegion);                    
                end
                
            end
            batches{batchIdx} = curbatch;
        end
        
        CreateData()
        src.String = oriString;
        src.BackgroundColor = [0.9400    0.9400    0.9400];
    end

%Update UI and data display

    function PlotHistogramCB()


        if isempty(batches) || isempty(results)
            plot(ui.ax,1)
            return
        end

        %Get number of selected batch files
        nBatches = length(results);
        
        %Get selected LUT and create color array
        selectedColor = ui.popLut.String{ui.popLut.Value};
        batchColors = analysis_tool_colormaps(nBatches, selectedColor);

                        
        %Initialize struct array for exporting plot values to matlab
        %workspace
        currentPlotValues = repmat(struct,nBatches,1);
                      
        %Hide all ui elements on the right side because we later enable the
        %ui elements corresponding to the current parameter selection

        %Get all children of the right panel
        rightPanelChildren = ui.panSelStat.Children;

        %Set visibility of all children to 'off' except last two elements, which are 
        % "Units" and "Display settings" panels that should stay visible
        for idx = 1:numel(rightPanelChildren)-2
            rightPanelChildren(idx).Visible = 'off';
        end

        %Adjust aditional ui elements that are not direct children of the display settings panel
        ui.editBinNum.Visible = 'on';
        ui.txtBinNum.Visible = 'on';
        ui.panelDataAndError.Visible = 'off';
        ui.btnGroupDisplayedParam.Visible = 'off';
        ui.txtFitWarning .Visible = 'off';

        %Clean up polar histogram
        if strcmp(ui.pax.Visible, 'on') 
            delete(ui.polhist)
            ui.pax.Visible = 'off';
        end
        
        %Initialize x -and y labels
        xlabel1 = '';
        ylabel1 = '';

        %Find currently selected analysis Parameter, adjust the ui and
        %prepare the corresponding values from the results structure
        switch ui.tabGroupParam.SelectedTab.Title            
            case 'Jumps'
                %% Jumps tab
                switch ui.popJumps.String{ui.popJumps.Value}
                    case 'Jump distances'
                        % Jump Distance histogram
                        ui.panelJumpsToConsider.Visible = 'on';
                        ui.cboxShowFit1.Visible = 'on';


                        if ui.btnPxFr.Value
                            xlabel1 = 'Jump distance (px)';
                        else
                            xlabel1 = 'Jump distance (\mum)';
                        end

                        valuesY = cell(1,nBatches);

                        for resultsIdx = 1:nBatches
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).jumpDistances{:});
                        end


                        if ui.cboxShowFit1.Value
                            ui.btnProbability.Value = 1;
                            ui.txtFitWarning.Visible = 'on';
                        end

                        plotStyle = 'histogram';
                    case 'Cumulative jump distances'
                        % Cumulative jump Distance histogram
                        ui.panelJumpsToConsider.Visible = 'on';
                        
                        ui.cboxShowFit1.Visible = 'on';
                        ui.panelDiffParam.Visible = 'on';
                        ui.editBinNum.Visible = 'off';
                        ui.txtBinNum.Visible = 'off';
                        
                        
                        
                        if ui.btnPxFr.Value
                            xlabel1 = 'd^2/(4\cdot\Deltat)  [px^2frame^{-1}]';
                        else
                            xlabel1 = 'd^2/(4\cdot\Deltat)  [\mum^{2}s^{-1}]';
                        end
                        
                        valuesY = cell(1,nBatches);
                        
                        for resultsIdx = 1:nBatches                            
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).jumpDistances{:});
                        end
                        
                        plotStyle = 'cumulativeJumpDist';
                    case 'Diffusion fit results'
                        % Diffusion parameter
                        
                        %Diffusion parameter is a special case because we
                        %need to fit the diffusion curves first. Here we
                        %adjust the visible ui elemts and do the rest
                        %later.

                        ui.panelDiffParam.Visible = 'on';
                        ui.panelJumpsToConsider.Visible = 'on';
                        ui.editBinNum.Visible = 'off';
                        ui.txtBinNum.Visible = 'off';
                        ui.panelDataAndError.Visible = 'on';
                        ui.btnGroupDisplayedParam.Visible = 'on';
                        
                        if ui.popError.Value == 3
                            ui.panelResamplingDiff.Visible =  'on';
                        end
                        
                        plotStyle = 'Diffusion fit results';

                    case 'Number of jumps'
                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        ui.panelJumpsToConsider.Visible = 'on';
                        
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end

                        hasPooledValue = 0;
                        
                        ylabel1 = 'No. of jumps';
                        
                        valuesY = {results(:).nJumps};
                    case 'Mean jump distance per track' 
                        % Mean jump distance histogram
                        ui.panelJumpsToConsider.Visible = 'on';
                        
                        if ui.btnPxFr.Value
                            xlabel1 = 'Mean jump distance (px)';
                        else
                            xlabel1 = 'Mean jump distance  (\mum)';
                        end
                        
                        valuesY = cell(1,nBatches);
                        
                        for resultsIdx = 1:nBatches
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).meanJumpDists{:});
                        end
                        
                        plotStyle = 'histogram';

                    case 'Mean jump distance per movie'
                        % Mean jump distance per movie
                        ui.panelJumpsToConsider.Visible = 'on';
                        ui.cboxNormalizeROI.Value = 0;

                        valuesY = {results(:).meanJumpDistMoviewise};
                        hasPooledValue = 0;
                        
                        if ui.btnPxFr.Value
                            ylabel1 = 'Mean jump distance (pixel)';
                        else
                            ylabel1 = 'Mean jump distance (µm)';
                        end
                        
                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end
                        
                    
                end

            case 'Angles'
                %% Angles tab
                switch ui.popAngles.String{ui.popAngles.Value}
                    case 'Jump angles'
                        % Angles
                        ui.panelJumpsToConsider.Visible = 'on';
                        ui.btnGroupAnglesJumpDist.Visible =  'on';
                        ui.btnGroupPolarOrLine.Visible =  'on';
                        
                        valuesY = cell(1,nBatches);

                        if ui.btnAnglesPolarplot.Value
                            plotStyle = 'angular histogram';
                            for resultsIdx = 1:nBatches
                                valuesY{resultsIdx} = vertcat(results(resultsIdx).angles{:});
                            end
                        else
                            plotStyle = 'histogram';
                            xlabel1 = 'Angle (deg)';

                            for resultsIdx = 1:nBatches
                                curBatchAngles = vertcat(results(resultsIdx).angles{:});
                                curBatchAngles = curBatchAngles*180/pi;
                                curBatchAngles(curBatchAngles < 0) = curBatchAngles(curBatchAngles < 0)+360;
                                valuesY{resultsIdx} = curBatchAngles;
                            end
                        end


                        delete(ui.hist)
                        cla(ui.ax)
                        ui.ax.Visible = 'off';
                    case 'Jump angle anisotropy'
                        ui.panelJumpsToConsider.Visible = 'on';
                        ui.btnGroupAnglesJumpDist.Visible =  'on';
                        ui.panelResamplingAnisotropy .Visible = 'on';

                        plotStyle = 'swarmplot';
                        hasPooledValue = 2;

                        %Get percentage and number of resamplings
                        percResampling = str2double(ui.editPercResamplingAnisotropy.String);
                        nResamplings = str2double(ui.editNResamplingAnisotropy.String);

                        ylabel1 = 'Fold-anisotropy (180° ± 30° / 0° ± 30°)';

                        %Initialize random number generator
                        rng('default')


                        valuesY = cell(nBatches,1);
                        valuesMean = zeros(nBatches,1);
                        valuesStd = zeros(nBatches,1);
                        wholeSet = zeros(nBatches,1);
                        wholeSetErr = zeros(nBatches,1);

                        for resultsIdx = 1:nBatches

                            %---Moviewise analysis-------------

                            %Get number of movies
                            nMovies = length(results(resultsIdx).angles);
                            curBatchMoviewiseAnisotropy = zeros(nMovies,1);

                            for movieIdx = 1:nMovies
                                %Get angles in current movie and convert to degrees
                                curMovieAngles = results(resultsIdx).angles{movieIdx}*180/pi;
                                curMovieAngles(curMovieAngles < 0) = curMovieAngles(curMovieAngles < 0)+360;

                                %Get number of forward jumps
                                forward = sum((curMovieAngles > 330) | (curMovieAngles < 30));
                                %Get number of backward jumps
                                backward = sum(curMovieAngles > 150 & curMovieAngles < 210);
                                %Calculate anisotropy in current movie
                                curBatchMoviewiseAnisotropy(movieIdx) = backward/forward;
                            end

                            %Save anisotropy of current movie 
                            valuesY{resultsIdx} = curBatchMoviewiseAnisotropy;

                            %Delete Inf and NaN values to calculate mean
                            %and standard deviation for display
                            curBatchMoviewiseAnisotropy = curBatchMoviewiseAnisotropy(curBatchMoviewiseAnisotropy >= 0 & curBatchMoviewiseAnisotropy < inf);
                            
                            %Calculate mean
                            valuesMean(resultsIdx) = mean(curBatchMoviewiseAnisotropy);

                            %Calculate standard deviation 
                            valuesStd(resultsIdx) = std(curBatchMoviewiseAnisotropy)/numel(curBatchMoviewiseAnisotropy);

                            %-------Pooled analysis-----------------

                            %Catenate all angles of all movies
                            curBatchAllAngles = vertcat(results(resultsIdx).angles{:});

                            %Covnert to degree
                            curBatchAllAngles = curBatchAllAngles*180/pi;
                            curBatchAllAngles(curBatchAllAngles < 0) = curBatchAllAngles(curBatchAllAngles < 0)+360;

                            %Get number of forward jumps
                            forward = sum((curBatchAllAngles > 330) | (curBatchAllAngles < 30));
                            %Get number of backward jumps
                            backward = sum(curBatchAllAngles > 150 & curBatchAllAngles < 210);
                            %Calculate anisotropy of the pooled dataset
                            wholeSet(resultsIdx) = backward/forward;


                            %--------Resampling--------------------------

                            %Get total number of angles
                            nAngles = numel(curBatchAllAngles);
                            resampledAnisotropy = zeros(nResamplings,1);

                            for resamplingIdx = 1:nResamplings
                                %Create random logical array where the size
                                %equals the number of angles and the number of
                                %1s equals the number of resamplings
                                randInd = randperm(nAngles, round(nAngles*percResampling/100));

                                %Get random subset of angles
                                anglesRand = curBatchAllAngles(randInd);

                                %Get number of forward jumps
                                forward = sum((anglesRand > 330) | (anglesRand < 30));
                                %Get number of backward jumps
                                backward = sum(anglesRand > 150 & anglesRand < 210);
                                %Calculate anisotropy for current resampling
                                resampledAnisotropy(resamplingIdx) = backward/forward;
                            end

                            %Delete Inf and NaN values to calculate mean
                            %and standard deviation for display
                            resampledAnisotropy = resampledAnisotropy(resampledAnisotropy >= 0 & resampledAnisotropy < inf);

                            %Calculate standard deviation
                            wholeSetErr(resultsIdx) = std(resampledAnisotropy); 
                        end


                    case 'Jump angle anisotropy vs. mean jump distance'

                        %Create y-axis label entry
                        ylabel1 = 'Fold-anisotropy (180° ± 30° / 0° ± 30°)';

                        % Set x-axis label based on user selection
                        if ui.btnPxFr.Value
                            xlabel1 = 'Mean jump distance (px)';
                        else
                            xlabel1 = 'Mean jump distance (\mum)';
                        end

                        % Set visibility of UI elements
                        ui.panelJumpsToConsider.Visible = 'on';
                        ui.btnGroupAnglesJumpDist.Visible =  'on';
                        ui.panelResamplingAnisotropy .Visible = 'on';

                        plotStyle = '';

                        %Get number of bins
                        nBins = str2double(ui.editBinNum.String);

                        %Get percentage and number of resamplings
                        percResampling = str2double(ui.editPercResamplingAnisotropy.String);
                        nResamplings = str2double(ui.editNResamplingAnisotropy.String);
                        
                        %Initialize variables
                        valuesY = cell(nBatches,1);
                        valuesMean = zeros(nBatches,1);
                        valuesStd = zeros(nBatches,1);
                        wholeSet = zeros(nBatches,1);
                        wholeSetErr = zeros(nBatches,1);

                        %Initialize legend entries variable
                        legendString = cell(nBatches,1);

                        %Initialize random number generator
                        rng('default')


                        %Iterate through all selected batches
                        for resultsIdx = 1:nBatches


                            if  resultsIdx == 2
                                hold(ui.ax,'on')
                            end


                            %Create legend entry
                            curBatchName = results(resultsIdx).batchName;
                            legendString{resultsIdx} = curBatchName(1:min(numel(curBatchName),40));


                            %Catenate all angles of all movies of the current batch                            
                            curBatchAllAngles = vertcat(results(resultsIdx).angles{:});
                            
                            %Convert to degrees
                            curBatchAllAngles = curBatchAllAngles*180/pi;
                            curBatchAllAngles(curBatchAllAngles < 0) = curBatchAllAngles(curBatchAllAngles < 0)+360;

                            %Get mean displacement of jumps making up the angles
                            curBatchMeanDisp = vertcat(results(resultsIdx).anglesMeanDisp{:});

                            %Divide mean displacements into histogram bins
                            [~,edges,bin] = histcounts(curBatchMeanDisp,nBins);
                            
                            anisotropy = zeros(nBins,1);
                            meanDisp = zeros(nBins,1);
                            anisotropyErr = zeros(nBins,1);

                            %Iterate through all bins and calculate anisotropy
                            for binIdx = 1:nBins
                                %Get angles in current bin
                                curBinAngles = curBatchAllAngles(bin == binIdx);

                                %Get number of forward jumps
                                forward = sum((curBinAngles > 330) | (curBinAngles < 30));

                                %Get number of backward jumps
                                backward = sum(curBinAngles > 150 & curBinAngles < 210);

                                %Calculate anisotropy
                                anisotropy(binIdx) = backward/forward;

                                %Get center of current bin
                                meanDisp(binIdx) = (edges(binIdx)+edges(binIdx+1))/2;


                                %Get number of angles
                                nAngles = numel(curBinAngles);
                                resampledAnisotropy = zeros(nResamplings,1);

                                %Calculate anisotropy for all resampled data
                                for resamplingIdx = 1:nResamplings
                                    %Create random logical array where the size
                                    %equals the number of angles and the number of
                                    %1s equals the number of resamplings
                                    randInd = randperm(nAngles, round(nAngles*percResampling/100));

                                    %Get random subset of angles
                                    anglesRand = curBinAngles(randInd);
                                    %Get number of forward jumps
                                    forward = sum((anglesRand > 330) | (anglesRand < 30));
                                    %Get number of backward jumps
                                    backward = sum(anglesRand > 150 & anglesRand < 210);
                                    %Calculate anisotropy
                                    resampledAnisotropy(resamplingIdx) = backward/forward;
                                end

                                %Calculate standard deviation of resampled values
                                anisotropyErr(binIdx) = std(resampledAnisotropy);

                            end

                            %Set inf values to NaN
                            meanDisp(anisotropy == inf) = NaN;
                            anisotropy(anisotropy == inf) = NaN;

                            %Display values with error bars
                            ui.hist = errorbar(ui.ax,meanDisp,anisotropy,anisotropyErr,'.-');

                            %Save for export
                            currentPlotValues(resultsIdx).meanJumpDistanceAnisotropyAndError = [meanDisp,anisotropy,anisotropyErr];
                           

                        end



                    case 'Number of jump angles'
                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        ui.panelJumpsToConsider.Visible = 'on';
                        ui.btnGroupAnglesJumpDist.Visible =  'on';
                        
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end

                        hasPooledValue = 0;
                        
                        ylabel1 = 'No. of angles';
                        
                        valuesY = {results(:).nAngles};
                        


                end
            case 'MSD'
                 %% MSD tab



                switch ui.popMSD.String{ui.popMSD.Value}
                    case 'Confinement radius'
                        % Confinement radii
                        ui.btnLinear.Enable = 'off';
                        ui.panelNormalization.Visible = 'on';
                        ui.panelMsdFit.Visible = 'on';
                        ui.btnGroupFitFun.SelectedObject = ui.btnMSD;
                        
                        if ui.btnPxFr.Value
                            xlabel1 = 'Confinement radius (px)';
                        else
                            xlabel1 = 'Confinement radius (\mum)';
                        end
                        
                        valuesY = cell(1,nBatches);
                        
                        for resultsIdx = 1:nBatches                            
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).confRad{:});
                        end
                        
                        plotStyle = 'histogram';
                    case 'Confinement radius vs. mean jump distance'
                        % Confinement radius vs. mean jump distance
                        plotStyle = 'scatterplot';
                        ui.btnLinear.Enable = 'off';
                        ui.panelMsdFit.Visible = 'on';
                        ui.btnGroupFitFun.SelectedObject = ui.btnMSD;


                        if ui.btnPxFr.Value
                            xlabel1 = 'Confinement radius (px)';
                            ylabel1 = 'Mean jump distance (px)';
                        else
                            xlabel1 = 'Confinement radius (\mum)';
                            ylabel1 = 'Mean jump distance (\mum)';
                        end
                        
                        valuesY = cell(1,nBatches);

                        for resultsIdx = 1:nBatches   
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).meanJumpDistConfRad{:});
                        end
                        
                        valuesY = vertcat(valuesY{:});
                        valuesX = cell(1,nBatches);

                        for resultsIdx = 1:nBatches   
                            valuesX{resultsIdx} = vertcat(results(resultsIdx).confRad{:});
                        end
                        
                        valuesX = vertcat(valuesX{:});
                        
                    case 'Alpha values'
                        % Alpha values from MSD
                        ui.panelMsdFit.Visible = 'on';
                        ui.btnLinear.Enable = 'on';
                        
                        xlabel1 = 'Alpha value';
                        
                        valuesY = cell(1,nBatches);
                        
                        for resultsIdx = 1:nBatches   
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).alphaValues{:});
                        end
                                                
                        plotStyle = 'histogram';
                    case 'Diffusion coefficients'
                        % Diffusion coeff from MSD
                        ui.panelMsdFit.Visible = 'on';
                        ui.btnLinear.Enable = 'on';
                        
                        if ui.btnPxFr.Value
                            xlabel1 = 'Diffusion coefficient (px^2/frame)';
                        else
                            xlabel1 = 'Diffusion coefficient (\mum^2/sec)';
                        end
                        
                        valuesY = cell(1,nBatches);
                        
                        for resultsIdx = 1:nBatches   
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).msdDiffConst{:});
                        end
                                                                       
                        plotStyle = 'histogram';
                end
            case 'Tracked fractions'
                %% Tracked fractions tab
                ui.btnGroupITM.Visible = 'on';
                
                ui.cboxNormalizeROI.Visible = 'on';
                ui.btnGroupSwarmVsMovie.Visible =  'on';
                if ui.btnValueVsBatchFile.Value
                    plotStyle = 'swarmplot';
                elseif ui.btnValueVsParameter.Value
                    plotStyle = 'valueVsParameter';
                end
                
                switch ui.popTrackedFraction.Value
                    case 1 %Tracks vs. all events
                        trackedFractions = [results(:).trackedFractions];
                        valuesY = {trackedFractions.allTracksVsAllEventsMoviewise};
                        wholeSet = cell2mat({trackedFractions.allTracksVsAllEventsPooled});
                        wholeSetErr = cell2mat({trackedFractions.errorAllTracksVsAllEventsPooled});
                        valuesMean = cell2mat({trackedFractions.allTracksVsAllEventsMean});
                        valuesStd = cell2mat({trackedFractions.allTracksVsAllEventsStd});
                        hasPooledValue = 1;
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value   
                                ylabel1 = 'Tracks vs. all events (%/pixel)';
                            else
                                ylabel1 = 'Tracks vs. all events (%/µm^2)';
                            end
                        else
                            ylabel1 = 'Ttracks vs. all events';
                        end
                    case 2 %Long tracks vs. all events
                        ui.panelLongTrack.Visible = 'on';
                        trackedFractions = [results(:).trackedFractions];
                        valuesY = {trackedFractions.longVsAllEventsMoviewise};
                        wholeSet = cell2mat({trackedFractions.longVsAllEventsPooled});
                        wholeSetErr = cell2mat({trackedFractions.errorLongVsAllEventsPooled});
                        valuesMean = cell2mat({trackedFractions.longVsAllEventsMean});
                        valuesStd = cell2mat({trackedFractions.longVsAllEventsStd});
                        hasPooledValue = 1;
                        
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value
                                ylabel1 = 'Long tracks vs. all events (%/pixel)';
                            else
                                ylabel1 = 'Long tracks vs. all events (%/µm^2)';
                            end
                        else
                            ylabel1 = 'Long tracks vs. all events';
                        end
                    case 3 %Short tracks vs. all events
                        ui.panelLongTrack.Visible = 'on';
                        trackedFractions = [results(:).trackedFractions];
                        valuesY = {trackedFractions.shortVsAllEventsMoviewise};
                        wholeSet = cell2mat({trackedFractions.shortVsAllEventsPooled});
                        wholeSetErr = cell2mat({trackedFractions.errorShortVsAllEventsPooled});
                        valuesMean = cell2mat({trackedFractions.shortVsAllEventsMean});
                        valuesStd = cell2mat({trackedFractions.shortVsAllEventsStd});
                        hasPooledValue = 1;
                        
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value
                                ylabel1 = 'Short tracks vs. all events (%/pixel)';
                            else
                                ylabel1 = 'Short tracks vs. all events (%/µm^2)';
                            end
                        else
                            ylabel1 = 'Short tracks vs. all events';
                        end
                        
                        
                    case 4 %Long tracks vs. short tracks
                        ui.panelLongTrack.Visible = 'on';
                        
                        trackedFractions = [results(:).trackedFractions];
                        valuesY = {trackedFractions.longVsAllTracksMoviewise};
                        wholeSet = cell2mat({trackedFractions.longVsAllTracksPooled});
                        wholeSetErr = cell2mat({trackedFractions.errorLongVsAllTracksPooled});
                        valuesMean = cell2mat({trackedFractions.longVsAllTracksMean});
                        valuesStd = cell2mat({trackedFractions.longVsAllTracksStd});
                        hasPooledValue = 1;
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value   
                                ylabel1 = 'Long tracks vs. all tracks (%/pixel)';
                            else
                                ylabel1 = 'Long tracks vs. all tracks (%/µm^2)';
                            end
                        else
                            ylabel1 = 'Long tracks vs. all tracks';
                        end
                    case 5 %No. of tracks                        
                        valuesY = {results(:).nTracks};
                        hasPooledValue = 0;
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value   
                                ylabel1 = 'No. of tracks/pixel';
                            else
                                ylabel1 = 'No. of tracks/µm^2';
                            end
                        else
                            ylabel1 = 'No. of tracks';
                        end
                    case 6 %No. of non-linked spots                        
                        valuesY = {results(:).nNonLinkedSpots};
                        hasPooledValue = 0;
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value   
                                ylabel1 = 'No. of non-linked spots/pixel';
                            else
                                ylabel1 = 'No. of non-linked spots/µm^2';
                            end
                        else
                            ylabel1 = 'No. of non-linked spots';
                        end
                    case 7 %No. of all events                        
                        valuesY = {results(:).nAllEvents};
                        hasPooledValue = 0;
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value   
                                ylabel1 = 'No. of all events/pixel';
                            else
                                ylabel1 = 'No. of all events/µm^2';
                            end
                        else
                            ylabel1 = 'No. of all events';
                        end
                    case 8 %No. of long tracks
                        ui.panelLongTrack.Visible = 'on';
                       
                        valuesY = {results(:).nLong};
                        hasPooledValue = 0;
                        
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value   
                                 ylabel1 = 'No. of long tracks/pixel';
                            else
                                 ylabel1 = 'No. of long tracks/µm^2';
                            end
                        else
                             ylabel1 = 'No. of long tracks';
                        end
                    case 9 %No. of short tracks
                        ui.panelLongTrack.Visible = 'on';
                        
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value    
                                ylabel1 = 'No. of short tracks/pixel';
                            else
                                ylabel1 = 'No. of short tracks/µm^2';
                            end
                        else
                            ylabel1 = 'No. of short tracks';
                        end

                        valuesY = {results(:).nShort};
                        hasPooledValue = 0;
                end
            case 'Durations'
                %% Durations tab
                
                
                switch ui.popDurations.String{ui.popDurations.Value}
                    case 'Track lengths'
                        
                        plotStyle = 'histogram';
                        if ui.btnPxFr.Value
                            xlabel1 = 'Tracklength (frames)';
                        else
                            xlabel1 = 'Tracklength (sec)';
                        end
                        
                        
                        valuesY = cell(1,nBatches);
                        
                        for resultsIdx = 1:nBatches
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).trackLengths{:});
                        end
                        
                    case 'Survival time distribution'


                        ui.editBinNum.Visible = 'off';
                        ui.txtBinNum.Visible = 'off';

                        plotStyle = 'survivalPlot';
                        
                        if ui.btnPxFr.Value
                            xlabel1 = 'Tracklength (frames)';
                        else
                            xlabel1 = 'Tracklength (sec)';
                        end

                        tlCurves = cell(nBatches,1);

                        for resultsIdx = 1:nBatches

                            frameCycleTimesAllMovies = results(resultsIdx).frameCycleTimes;
                            
                            uniqueFrameCycleTimes = unique(frameCycleTimesAllMovies);
                            nTL = numel(uniqueFrameCycleTimes); %Amount of tl conditions


                            %Create cell array where each cell contains all track lifes of a given timelapse condition
                            allTrackLifes = repmat({[]},nTL,1);

                            %Accumulate track lifetimes of each tl Condition
                            for movieIdx = 1:numel(frameCycleTimesAllMovies)
                                %Calculate track lifetimes                                
                                curMovieTrackLengths = results(resultsIdx).trackLengths{movieIdx};

                                curMovieTlIdx = find(uniqueFrameCycleTimes == frameCycleTimesAllMovies(movieIdx));

                                if curMovieTrackLengths ~= 0
                                    allTrackLifes{curMovieTlIdx} = [allTrackLifes{curMovieTlIdx}; curMovieTrackLengths];
                                end

                            end

                            curBatchTlCurves = cell(nTL,1);

                            %Create cumulated histogram of track lifetimes for each tl condition
                            for tlIdx = 1:nTL %Iterate through tl conditions

                                curTlTrackLifes = allTrackLifes{tlIdx};

                                %Get current TL condition
                                curFrameCycleTime = uniqueFrameCycleTimes(tlIdx);
                                %Get largest track of this tl condition
                                maxTrackLength = max(curTlTrackLifes);

                                %Get shortest possible track of this tl condition
                                minTrackLength = min(curTlTrackLifes);

                                %Creat time vector and save in data
                                curTlTimeVector = transpose(minTrackLength:curFrameCycleTime:maxTrackLength);
                                curTlCounts = zeros(numel(curTlTimeVector),1);

                                %Unique list of track lifetimes
                                uniqueTrackLengths = unique(curTlTrackLifes);

                                %Number of occurences of each lifetime
                                for j=1:length(uniqueTrackLengths) %Iterate through all occuring track lifetimes

                                    %Find position of current Tracklength in time vector
                                    [~,b] = ismembertol(uniqueTrackLengths(j),curTlTimeVector);

                                    %Get counts of current tracklength
                                    curTlCounts(b) = sum(curTlTrackLifes == uniqueTrackLengths(j));
                                end

                                curTlCounts = flipud(cumsum(flipud(curTlCounts)));
                                curTlCounts = curTlCounts./curTlCounts(1);
                                curTlCurve = [curTlTimeVector,  curTlCounts];
                                curBatchTlCurves{tlIdx} = curTlCurve;
                            end
                            tlCurves{resultsIdx} = curBatchTlCurves;
                        end
                        

                    case 'Average track length'
                        hasPooledValue = 0;
                        ui.cboxNormalizeROI.Visible = 'on';
                        
                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end
                        
                        valuesY = {results(:).meanTrackLength};
                        
                        
                        if ui.btnPxFr.Value                            
                            if ui.cboxNormalizeROI.Value
                                ylabel1 = 'Average tracklength (frames/pixel)';
                            else
                                ylabel1 = 'Average tracklength (frames)';
                            end
                        else
                            
                            if ui.cboxNormalizeROI.Value
                                ylabel1 = 'Average tracklength (sec/µm^2)';
                            else
                                ylabel1 = 'Average tracklength (sec)';
                            end
                        end
                end
            case 'Other'
                %% Other tab
                switch ui.popOther.String{ui.popOther.Value}
                    case 'Average number of tracks per frame'
                        hasPooledValue = 0;

                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end
                        
                        ui.cboxNormalizeROI.Visible = 'on';
                        valuesY = {results(:).meanTracksPerFrame};
                                                
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value    
                                ylabel1 = 'Average no. of tracks / (frame \cdot pixel)';
                            else
                                ylabel1 = 'Average no. of tracks / (frame \cdot µm^2)';
                            end
                        else
                            ylabel1 = 'Average no. of tracks / frame';
                        end
                    case 'Average number of spots per frame'
                        hasPooledValue = 0;
                        ui.cboxNormalizeROI.Visible = 'on';
                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end
                        
                        valuesY = {results(:).meanSpotsPerFrame};
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value
                                ylabel1 = 'Average no. of spots / (frame \cdot pixel)';
                            else
                                ylabel1 = 'Average no. of spots / (frame \cdot µm^2)';
                            end
                        else
                            ylabel1 = 'Average no. of spots / frame';
                        end

                    case 'Total number of spots'
                        hasPooledValue = 0;
                        ui.cboxNormalizeROI.Visible = 'on';
                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end
                        
                        valuesY = {results(:).nSpots};
                        if ui.cboxNormalizeROI.Value
                            if ui.btnPxFr.Value
                                ylabel1 = 'Total number of spots / pixel';
                            else
                                ylabel1 = 'Total number of spots / µm^2)';
                            end
                        else
                            ylabel1 = 'Total number of spots';
                        end
                    case 'ROI size'
                        hasPooledValue = 0;
                        ui.cboxNormalizeROI.Visible = 'on';                                                
                        ui.btnGroupSwarmVsMovie.Visible =  'on';
                        if ui.btnValueVsBatchFile.Value
                            plotStyle = 'swarmplot';
                        elseif ui.btnValueVsParameter.Value
                            plotStyle = 'valueVsParameter';
                        end
                        
                        if ui.btnPxFr.Value
                            ylabel1 = 'No. of pixels';
                        else
                            ylabel1 = 'ROI size (\mum^2)';
                        end
                        
                        valuesY = {results(:).roiSize};
                    case 'Distance to ROI border'
                        plotStyle = 'histogram';
                        
                        ui.btnCalcDistance.Visible = 'on';
                        if ui.btnPxFr.Value
                            xlabel1 = 'Distance from ROI border (px)';
                        else
                            xlabel1 = 'Distance from ROI border (\mum)';
                        end
                                                
                        valuesY = cell(1,nBatches);
                        
                        for resultsIdx = 1:nBatches   
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).distToRoiBorder{:});
                            if isempty(valuesY{resultsIdx})
                                valuesY{resultsIdx} = 0;
                            end
                        end

                        
                    case 'Dist. to ROI border vs. mean jump dist.'
                        plotStyle = 'scatterplot';
                        ui.btnCalcDistance.Visible = 'on';
                        if ui.btnPxFr.Value
                            ylabel1 = 'Distance from ROI border (px)';
                            xlabel1 = 'Mean jump distance (px)';
                        else
                            ylabel1 = 'Distance from ROI border (\mum)';
                            xlabel1 = 'Mean jump distance (\mum)';
                        end

                        
                        
                        valuesY = cell(1,nBatches);
                        valuesX = cell(1,nBatches);

                        for resultsIdx = 1:nBatches   
                            valuesY{resultsIdx} = vertcat(results(resultsIdx).distToRoiBorder{:});
                            valuesX{resultsIdx} = vertcat(results(resultsIdx).meanJumpDists{:});
%                             valuesY{batchIdx} = vertcat(results(batchIdx).jumpDistances{:});
                        end

                        valuesX = vertcat(valuesX{:});
                        valuesY = vertcat(valuesY{:});
   
                        
                        
                end
        end
        
        switch plotStyle

            case 'survivalPlot'
                %% Survival time distribution

                %Create y-axis label entry
                ylabel1 = 'Survival probability';
                
                
                %Initialize legend entries variable
                legendString = cell(nBatches,1);

                % Iterate through selected batches
                for resultsIdx = 1:nBatches

                    %Create legend entry
                    curBatchName = results(resultsIdx).batchName;
                    legendString{resultsIdx} = curBatchName(1:min(numel(curBatchName),40));


                    
                    %Plot histogram
                    curTlCurves = tlCurves{resultsIdx};

                        if  resultsIdx == 2
                            hold(ui.ax,'on')
                        end

                    tlCurvesPlot = zeros(0,2);
                    for tlIdx = 1:length(curTlCurves)


                        tlCurvesPlot = [tlCurvesPlot; NaN NaN; curTlCurves{tlIdx}];
                    end

                    ui.hist = plot(ui.ax,tlCurvesPlot(:,1),tlCurvesPlot(:,2),'-','Color', batchColors(resultsIdx,:));

                    %Save in currentPlotValues structure
                    currentPlotValues(resultsIdx).histogramData =  curTlCurves;
                    %Save batch file names of selected batches into

                    %currentPlotValues structure
                    currentPlotValues(resultsIdx).batchName = results(resultsIdx).batchName;
                end


                
            case 'histogram'
                %% Plot as histogram

                %Make count/probability panel visible
                ui.panelNormalization.Visible = 'on';
                ui.btnGroupBarsStairs.Visible =  'on';

                
                %Get maximum value in the dataset and create histogram limits to ensure that all datasets have the same binwidth
                allYValues = cell2mat(valuesY');
                
                if isempty(allYValues)
                    histLimits = [0 1];
                else
                    histLimits = [min(0, min(allYValues)) max(allYValues)];
                end
                
                %Adjust y-label of the axis to the selected normalization
                if ui.btnCount.Value                    
                    histNorm = 'Count';
                else                    
                    histNorm = 'Probability';
                end
                                
                ylabel1 = histNorm;
                
                
                %Initialize legend entries variable
                legendString = cell(numel(nBatches),1);
                
                %Iterate through selected batches
                for resultsIdx = 1:nBatches
                    
                    %Create legend entry
                    curBatchName = results(resultsIdx).batchName;
                    legendString{resultsIdx} = curBatchName(1:min(numel(curBatchName),40));


                    if resultsIdx == 2
                        hold(ui.ax,'on')
                    end
                    
                    if ui.btnBars.Value
                        edgeColor1 = 'k';
                        edgeAlpha1 = .25;
                        displayStyle1 = 'bar';
                        faceColor1 = batchColors(resultsIdx,:);
                    elseif ui.btnStairs.Value
                        edgeColor1 = batchColors(resultsIdx,:);
                        faceColor1 = 'none';
                        edgeAlpha1 = 1;
                        displayStyle1 = 'stairs';
                    end
                    
                    
                    % if ~isempty(valuesY{resultsIdx})
                    %Create and plot histogram for current batch
                    ui.hist = histogram(valuesY{resultsIdx},...
                        'EdgeColor',edgeColor1,...
                        'EdgeAlpha',edgeAlpha1,...
                        'DisplayStyle',displayStyle1,...
                        'FaceColor',faceColor1,...
                        'BinLimits',histLimits,...
                        'Normalization',histNorm,...
                        'NumBins',str2double(ui.editBinNum.String),...
                        'Parent',ui.ax);
                    % end

                    %Save results ins currentPlotValues structure
                    currentPlotValues(resultsIdx).histogramData = [(ui.hist.BinEdges(2:end)-(ui.hist.BinEdges(2)-ui.hist.BinEdges(1))/2)', ui.hist.Values'];
                    currentPlotValues(resultsIdx).batchName = results(resultsIdx).batchName;

                end

                if ui.cboxShowFit1.Visible && ui.cboxShowFit1.Value

                    ui.panelDiffParam.Visible = 'on';
                    OverlayHistWithDiffFitCB('pdf')
                    if ui.btnOneRate.Value
                        legendString(end+1) = {'Fit'};
                    elseif ui.btnTwoRates.Value
                        legendString(end+1:end+3) = {'Fit','D1','D2'};
                    elseif ui.btnThreeRates.Value
                        legendString(end+1:end+4) = {'Fit','D1','D2','D3'};
                    end
                end
            case 'cumulativeJumpDist'
                %% Plot as cumulative histogram


                %Create y-axis label entry
                ylabel1 = 'Probability';
                                

                %Initialize legend entries variable
                legendString = cell(nBatches,1);
                                
                % Iterate through selected batches
                for resultsIdx = 1:nBatches

                    %Create legend entry
                    curBatchName = results(resultsIdx).batchName;
                    legendString{resultsIdx} = curBatchName(1:min(numel(curBatchName),40));
                    
                    if resultsIdx == 2
                        hold(ui.ax,'on')
                    end                   
                    
                    %Create cumulative density function from valuesY for
                    %current batch
                    [y,x] = histcounts(valuesY{resultsIdx},...
                        'Normalization','cdf',...
                        'BinWidth',str2double(ui.editBinSize.String));
                    
                    %Get bin centers
                    x = (x(2:end)-(x(2)-x(1))/2);

                    %Get frame cycle times as we need them to calculate the
                    %diffusion coefficients

                    frameCycleTimes = {results(:).frameCycleTimes};

                    if ui.btnPxFr.Value
                        %User wants results in pixels and frames
                        curFrameCycleTime = 1;
                    else
                        %User want results in microns and seconds

                        %Get frame cycle times in movies of current batch
                        curframeCycleTimes = unique(frameCycleTimes{resultsIdx});
                        %Convert frame cycle time to seconds. If more than
                        %one frame cycle time is found, use first one
                        curFrameCycleTime = curframeCycleTimes(1);
                    end

                    x = x.^2;
                    x = x./(4*curFrameCycleTime);
                    
                    %Save in currentPlotValues structure
                    currentPlotValues(resultsIdx).histogramData = [x', y'];
                    currentPlotValues(resultsIdx).batchName = results(resultsIdx).batchName;
                    
                    %Plot histogram
                    ui.hist = plot(ui.ax,x,y,'-','Color', batchColors(resultsIdx,:));

                end

                if ui.cboxShowFit1.Value

                    OverlayHistWithDiffFitCB('cdf')
                    legendString(end+1) = {'Fit'};
                end

            case 'angular histogram'
                %% Plot as angular plot
                                                
                %Make count/probability panel visible
                ui.panelNormalization.Visible = 'on';
                ui.btnGroupBarsStairs.Visible =  'on';
                
                %Set histogram normalization according to selected value
                if ui.btnCount.Value
                    histNorm = 'Count';
                else
                    histNorm = 'Probability';
                end
                
                %Set empty legend String for cartesian axis
                legendString = {};
                pLegendString = cell(nBatches,1);
                
                for resultsIdx = 1:nBatches
                    %Create legend entry
                    curBatchName = results(resultsIdx).batchName;
                    pLegendString{resultsIdx} = curBatchName(1:min(numel(curBatchName),40));

                    
                    %Create and plot polar histogram
                    if resultsIdx == 2
                        hold(ui.pax, 'on')
                    end
                     
                    if ui.btnBars.Value
                        edgeColor1 = 'k';
                        edgeAlpha1 = .25;
                        displayStyle1 = 'bar';
                        faceColor1 = batchColors(resultsIdx,:);
                    elseif ui.btnStairs.Value
                        edgeColor1 = batchColors(resultsIdx,:);
                        faceColor1 = 'none';
                        edgeAlpha1 = 1;
                        displayStyle1 = 'stairs';
                    end
                    
                    ui.polhist = polarhistogram(ui.pax, valuesY{resultsIdx},...
                        'BinMethod','Integer',...
                        'EdgeColor',edgeColor1,...
                        'EdgeAlpha',edgeAlpha1,...
                        'FaceColor',faceColor1,...
                        'DisplayStyle',displayStyle1,...
                        'Normalization',histNorm,...
                        'NumBins',str2double(ui.editBinNum.String));
                    
                    %Save results in currentPlotValues structure
                    currentPlotValues(resultsIdx).anglesCounts = [(ui.polhist.BinEdges(2:end)-(ui.polhist.BinEdges(2)-ui.polhist.BinEdges(1))/2)', ui.polhist.Values'];
                    currentPlotValues(resultsIdx).angles = valuesY;
                    currentPlotValues(resultsIdx).batchName = results(resultsIdx).batchName;
                end
                
                hold(ui.pax, 'off')
                legend(ui.pax)
                legend(ui.pax,pLegendString,'Interpreter','None')
                legend(ui.pax,'Location','northeast')

            case 'swarmplot'
                %% Plot as swarmplot
                                
                %Iterate through selected batches and create labels for the
                %x-axis ticks (=batch file numbers)

                
                %Set x-axis label
                xlabel1 = 'Batch file #';
                
                %Retreive the roi sizes in case the user wants to normalize
                %the values by the roi size
                roiSizes = {results(:).roiSize};
                                
                %Get the number of bins entered in the ui
                nBins = str2double(ui.editBinNum.String);
                
                %Catenate all values of all batch files so we know how to
                %set the bin edges
                if ui.cboxNormalizeROI.Value                    
                    allRois = vertcat(roiSizes{:});
                    allValues = vertcat(valuesY{:})./allRois;
                else
                    allValues = vertcat(valuesY{:});
                end
                
                        
                %Calculate bin edges                
                binEdges = linspace(min(allValues),max(allValues(allValues < inf)),nBins+1);
                
                valuesX = cell(1,nBatches);
                cellMovieNames = cell(1,nBatches);
                cellMovieNumbers = cell(1,nBatches);                
                xTicks = zeros(nBatches,1);                

                
                
                for resultsIdx = 1:nBatches


                    xTicks(resultsIdx) = results(resultsIdx).posInBatchList;
                                        
                    if ui.cboxNormalizeROI.Value
                        %Normalize values by roi size
                        currentValuesY = valuesY{resultsIdx}./roiSizes{resultsIdx};
                    else
                        currentValuesY = valuesY{resultsIdx};
                    end
                    
                    %Sort values for nice visualization
                    [currentValuesY, I] = sort(currentValuesY);
                    
                    
                    %Save movie names and movie numbers. This is needed for
                    %showing to which movie a certain value belongs if the
                    %user selects a datapoint with the datatip tool.
                    currentMovieNames = results(resultsIdx).movieNames;
                    currentMovieNumbers = results(resultsIdx).movieNumbers;
                    cellMovieNames{resultsIdx} = currentMovieNames(I);
                    cellMovieNumbers{resultsIdx} = currentMovieNumbers(I);
                             
                    %Initialize x-axis values to the number of the
                    %respective batch file number
                    currentValuesX = ones(numel(currentValuesY),1)*resultsIdx;

                    %Save current x values in cell array
                    valuesX{resultsIdx} = currentValuesX;
                    valuesY{resultsIdx} = currentValuesY;
                    
                    %Create swarm plot using the given y values and their
                    %created x values. Save the values and the respective movie
                    %names and number in user data. This is for later used in
                    %the DataCursorCB function for knowing which datapoint has
                    %been clicked.

                    if resultsIdx == 2
                        hold(ui.ax,'on')
                    end

                    %Sort values into bins
                    [binNum] = discretize(currentValuesY,binEdges);

                    %Iterate through bins an distribute x-axis values depending
                    %on the amount of values in a given bin
                    for binIdx = 1:nBins
                        %Find which values belong to current bin
                        valuesIdx = find(binNum == binIdx);
                        %Get amount of values in current bin
                        nValues = numel(valuesIdx);

                        if nValues > 1
                            %Calculate distribution width
                            curWidth = 0.7*(1-exp(-0.1*nValues));
                            %Get width of one element
                            widthElement = curWidth / (nValues-1);

                            %Initialize offset depending if current bin has
                            %even or odd amount of values
                            if mod(nValues,2) == 0
                                offset = widthElement / 2;
                            else
                                offset = eps;
                            end

                            %Iterate though all values in this bin and
                            %calculate their position on the x-axis
                            for valueIdxCurBin = 1:nValues
                                %Calculate x-value
                                currentValuesX(valuesIdx(valueIdxCurBin),1) = resultsIdx + offset;
                                %Increase offset
                                offset = offset - sign(offset) * widthElement * valueIdxCurBin;
                            end
                        end

                    end


                    ui.hist = scatter(ui.ax,currentValuesX,currentValuesY,[],batchColors(resultsIdx,:),'.','SizeData',200,'UserData',{cellMovieNames{resultsIdx}; cellMovieNumbers{resultsIdx}});

                end

                hold(ui.ax,'on')

                %Save all created vales in the currentPlotValues structure
                [currentPlotValues(:).batchName] = results(:).batchName;
                [currentPlotValues(:).movieNames] = cellMovieNames{:};
                [currentPlotValues(:).movieNumbers] = cellMovieNumbers{:};
                [currentPlotValues(:).movieWiseValues] = valuesY{:};
                
                
                %Set labels and ticks for the x-axis                
                xticks(ui.ax, 1:nBatches)
                xticklabels(ui.ax,xTicks)                
                
                if hasPooledValue > 0 && ~ui.cboxNormalizeROI.Value


                    %Create legend entries
                    if hasPooledValue == 1
                        %Plotted value is tracked fraction
                        legendString = {'Movie-wise mean + standard error','Pooled fraction + error (see manual)'};
                    elseif hasPooledValue == 2
                        %Plotted value is jump angle anisotropy vs. mean jump distance
                        legendString = {'Movie-wise mean + standard error','Pooled anisotropy + std. dev. of resampling'};
                    end

                    %Add movie-wise mean value plus standard error as error bar
                    err(1) = errorbar(ui.ax,(1:nBatches)-0.3,valuesMean,valuesStd,...
                        '.','MarkerSize',20,'Color','r','LineWidth',1.5,'CapSize',8,'Userdata','meanMoviewise');
                    %Add pooled tracked fraction plus error bar
                    err(2) = errorbar(ui.ax,(1:nBatches)+0.3,wholeSet',wholeSetErr',...;
                        '.','MarkerSize',20,'Color','k','LineWidth',1.5,'CapSize',8,'Userdata','wholeSet');
                    
                    %Save all data to currentPlotValues structure
                    cellMean = num2cell(valuesMean);
                    [currentPlotValues(:).mean] = cellMean{:};
                    cellStd = num2cell(valuesStd);
                    [currentPlotValues(:).stdError] = cellStd{:};
                    cellPooled = num2cell(wholeSet);
                    [currentPlotValues(:).pooledValue] = cellPooled{:};
                    cellPooledError = num2cell(wholeSetErr);
                    [currentPlotValues(:).pooledValueError] = cellPooledError{:};
                else
                    
                    %Create legend entries
                    legendString = {'Mean + std. dev.','Median + quartiles'};

                    %Calculate mean values and standard deviations of the values in each batch file                    
                    valuesMean = cellfun(@(x) mean(x, 'omitnan'),valuesY);
                    valuesStd = cellfun(@(x) std(x, 'omitnan'),valuesY);

                    
                    %Plot movie-wise mean values with standard deviation as error bar
                    err(1) = errorbar(ui.ax,(1:nBatches)-0.3,valuesMean,valuesStd,...
                        '.','MarkerSize',20,'Color','r','LineWidth',1.5,'CapSize',8,'Userdata','meanMoviewise');

                    %Calculate median and 0.25 and 0.75 quantiles
                    values25 = cellfun(@(x) quantile(x, .25),valuesY);
                    valuesMedian = cellfun(@(x) quantile(x, .5),valuesY);
                    values75 = cellfun(@(x) quantile(x, .75),valuesY);

                    %Plot median plus quartiles as error bar
                    err(2) = errorbar(ui.ax,(1:nBatches)+0.3,valuesMedian,values25-valuesMedian,values75-valuesMedian,...
                        '.','MarkerSize',20,'Color','k','LineWidth',1.5,'CapSize',8,'Userdata','medianMoviewise');

                    
                    %Save all data to currentPlotValues structure
                    cellMean = num2cell(valuesMean);
                    [currentPlotValues(:).mean] = cellMean{:};
                    cellStd = num2cell(valuesStd);
                    [currentPlotValues(:).stdDev] = cellStd{:};
                    cell25 = num2cell(values25);
                    [currentPlotValues(:).firstQuartile] = cell25{:};
                    cellMedian = num2cell(valuesMedian);
                    [currentPlotValues(:).median] = cellMedian{:};
                    cell75 = num2cell(values75);
                    [currentPlotValues(:).thirdQuartile] = cell75{:};


                end
            case 'valueVsParameter'
                %% Plot values vs. movie number
                
                
                selectedParameter = ui.popValueVsParameter.String{ui.popValueVsParameter.Value};

                switch selectedParameter
                    case 'Movie number'
                        
                        valuesX = {results(:).movieNumbers};
                        
                        xlabel1 = 'Movie number';
                        
                    case 'No. of tracks'
                        valuesX = {results(:).nTracks};
                        
                        xlabel1 = 'No. of tracks';
                    case 'No. of non-linked spots'
                        valuesX = {results(:).nNonLinkedSpots};
                        
                        xlabel1 = 'No. of non-linked spots';
                    case 'No. of all events'
                        valuesX = {results(:).nAllEvents};
                        
                        xlabel1 = 'No. of all events';
                    case 'Mean jump distance'
                        valuesX = {results(:).meanJumpDistMoviewise};
                        xlabel1 = 'Average jump distance';
                    case 'Avg. track length'
                        valuesX = {results(:).meanTrackLength};
                        
                        xlabel1 = 'Average track length';
                    case 'Avg. no. of tracks per frame'
                        valuesX = {results(:).meanTracksPerFrame};
                        
                        xlabel1 = 'Average no. of tracks per frame';
                    case 'Avg. no. of spots per frame'
                        valuesX = {results(:).meanSpotsPerFrame};
                        
                        xlabel1 = 'Average no. of spots per frame';
                    case 'ROI size'
                        valuesX = {results(:).roiSize};
                        
                        xlabel1 = 'ROI size';
                    case 'No. of jumps'
                        valuesX = {results(:).nJumps};
                        
                        xlabel1 = 'No. of jumps';
                end

                %Initialize legend entries variable
                legendString = cell(nBatches,1);
                
                %Iterate through selected batches
                for resultsIdx = 1:nBatches
                    
                    %Create legend entry                    
                    curBatchName = results(resultsIdx).batchName;
                    legendString{resultsIdx} = curBatchName(1:min(numel(curBatchName),40));
                    
                    currentMovieNames = results(resultsIdx).movieNames;
                    currentMovieNumbers = results(resultsIdx).movieNumbers;
                    
                    
                    curMovieValuesX = valuesX{resultsIdx};
                    curMovieValuesY = valuesY{resultsIdx};
                                     
                    if ui.cboxNormalizeROI.Value    
                        curMovieRoiSize = results(:).roiSize;
                        curMovieValuesY = curMovieValuesY./curMovieRoiSize;
                    end
                    
                                                  
                    if resultsIdx == 2
                        hold(ui.ax,'on')
                    end
                    
                    %Plot histogram
                    ui.hist = scatter(ui.ax,curMovieValuesX,curMovieValuesY,[],batchColors(resultsIdx,:),'.','SizeData',100,'UserData',{currentMovieNames; currentMovieNumbers'});
                    
                    currentPlotValues(resultsIdx).batchName = results(resultsIdx).batchName;
                    currentPlotValues(resultsIdx).movieNames = results(resultsIdx).movieNames;
                    currentPlotValues(resultsIdx).values = curMovieValuesY;
                    
                end                    
            case 'scatterplot'
                %% Plot as scatterplot
                
                if strcmp(selectedColor, 'standard')
                    colormap('default')
                else
                    colormap(selectedColor)
                end
                
                if ~isempty(valuesY) && any(valuesY)
                    %Scatterplot is plotted directly in the AdjustAxisLimits()
                    %function so that density calculations are renewed when
                    %the user changes the axis limits.
                    
                    ui.hist = [valuesX, valuesY];
                else
                    ui.hist = [];
                end
                
                colorbar('off')                
            case 'Diffusion fit results'
                %% Plot as barchart
                
                %Make sure axis is not set to logarithmic
                ui.cboxLogX.Value = 0;
                                
                %Get frame cycle times as we need them to calculate the
                %diffusion constants
                frameCycleTimes = {results(:).frameCycleTimes};
                
                %Initialize lengend entries
                legendString = cell(numel(nBatches),1);
                
                %Initialize cell arrays
                movieOrResamplingValues = cell(nBatches,1);
                
                %Initialize variable that is set to true if a batch file contains different
                %tracking radii
                showWarnDlg = false;
                
                %Retreive start values for fitting
                startD = vertcat(ui.tableStartD.Data{:,2});
                
                %Iterate through all selected batches and fit diffusion
                %model
                for resultsIdx = 1:nBatches
                    
                    %Create legend entry
                    curBatchName = results(resultsIdx).batchName;
                    legendString{resultsIdx} = curBatchName(1:min(numel(curBatchName),40));
                    
                    if ui.btnPxFr.Value
                        %User wants results in pixels and frames
                        curFrameCycleTime = 1;
                    else                      
                        %User want results in microns and seconds
                        
                        %Get frame cycle times in movies of current batch
                        curframeCycleTimes = unique(frameCycleTimes{resultsIdx});
                        %Convert frame cycle time to seconds. If more than
                        %one frame cycle time is found, use first one
                        curFrameCycleTime = curframeCycleTimes(1);
                    end
                    
                    %Get tracking radius
                    allTrackingRadii = vertcat(results(resultsIdx).trackingRadii);
                    trackingRadius = max(unique(allTrackingRadii));
                    trackingRadius = trackingRadius^2/(4*curFrameCycleTime);
                    
                                        
                    %Create pooled jump histogram including all movies of current batch
                    jumpDistsPooled = vertcat(results(resultsIdx).jumpDistances{:});
                    
                    %Check if 1, 2 or 3 exponential rates are selected
                    if ui.btnOneRate.Value
                        nRates = 1;
                    elseif ui.btnTwoRates.Value
                        nRates = 2;
                    elseif ui.btnThreeRates.Value
                        nRates = 3;
                    end
                                        
                    if ui.popError.Value == 1
                        [pooledY,pooledX] = histcounts(jumpDistsPooled,'BinMethod','integers',...
                            'Normalization','cdf',...
                            'BinWidth',str2double(ui.editBinSize.String));
                        
                        %Get bin centers and square the x-axis to calculate the diffusion coefficient
                        pooledX = (pooledX(2:end)-(pooledX(2)-pooledX(1))/2).^2;
                        pooledX = pooledX./(4*curFrameCycleTime);
                        
                        %Fit the curve
                        fitResults(resultsIdx) = dispfit_cumulative(pooledX',pooledY', trackingRadius, startD, nRates);
                        
                        %Save results
                        results(resultsIdx).diffParams = fitResults(resultsIdx);
                        
                        nTrackingRadii = numel(unique(allTrackingRadii));
                        
                        if nTrackingRadii > 1
                            showWarnDlg = true;
                        end
                    elseif ui.popError.Value == 2 %Show movie-wise values
                        
                        %User wants to see movie-wise fitted results
                        
                        %Iterate through each movie of current batch
                        for movieIdx = 1:length(results(resultsIdx).movieNames)
                            %Get jump distances of current movie
                            dispsCurMovie = results(resultsIdx).jumpDistances{movieIdx};
                            if ~isempty(dispsCurMovie)
                                
                                %Create cumulative density function
                                [y,x] = histcounts(dispsCurMovie,'BinMethod','integers',...
                                    'Normalization','cdf',...
                                    'BinWidth',str2double(ui.editBinSize.String));
                                
                                
                                %Get bin centers and square the x-axis to calculate the diffusion coefficient
                                x = (x(2:end)-(x(2)-x(1))/2).^2;
                                x = x./(4*curFrameCycleTime);
                                
                                %Create fit results
                                fitResults{resultsIdx}(movieIdx) = dispfit_cumulative(x',y', trackingRadius, startD, nRates);
                                
                                %Adjust fit results with respect to the given
                                %frame cycle time
                            else
                                fitResults{resultsIdx}(movieIdx)=struct('D',[0 0 0],'Derr',[0 0 0], 'A', [0 0 0], 'Aerr',[0 0 0],'EffectiveD',0,'Ajd_R_square',0,'Message',0,'SSE',0,'xy',[0 0]);
                            end
                        end
                        
                        %Save results
                        results(resultsIdx).diffParams = fitResults{resultsIdx};
                    elseif ui.popError.Value == 3 %Show resampling
                        ui.editNResamplingDiff.BackgroundColor = 'r';
                        drawnow
                        rng('default')

                        nResampling = str2double(ui.editNResamplingDiff.String);
                        percResampling = str2double(ui.editPercResamplingDiff.String);
                        
                                        
                        nJumps = numel(jumpDistsPooled);
                                       
                        
                        for resamplingIdx = 1:nResampling
                            %Get jump distances of current movie
                            randInd = randperm(nJumps, round(nJumps*percResampling/100));
                            
                            jumpDistRand = jumpDistsPooled(randInd);
                            
                            %Create cumulative density function
                            [y,x] = histcounts(jumpDistRand,'BinMethod','integers',...
                                'Normalization','cdf',...
                                'NumBins',str2double(ui.editBinNum.String));
                            
                            %Square x-axis
                            x = (x(2:end)-(x(2)-x(1))/2).^2;
                            x = x./(4*curFrameCycleTime);
                            
                            %Create fit results
                            fitResults{resultsIdx}(resamplingIdx) = dispfit_cumulative(x',y', trackingRadius, startD, nRates);
                        end
                        
                        %Save results
                        results(resultsIdx).diffParams = fitResults{resultsIdx};
                        
                        nTrackingRadii = numel(unique(allTrackingRadii));
                        
                        if nTrackingRadii > 1
                            showWarnDlg = true;
                        end
                    end
                    
                end
                
                if ui.btnShowD.Value      
                    %User wants to see diffusion constants
                    
                    %Create label for y-axis
                    if ui.btnPxFr.Value
                        ylabel1 = 'Diffusion coefficient (px^2/frame)';
                    else
                        ylabel1 = 'Diffusion coefficient (\mum^2/sec)';
                    end
                                        
                    %Create x-tick labels
                    if ui.btnOneRate.Value                        
                        xTickLabel1 = {'D_1'};
                    elseif ui.btnTwoRates.Value
                        xTickLabel1 = {'D_1','D_2'};
                    elseif ui.btnThreeRates.Value
                        xTickLabel1 = {'D_1','D_2','D_3'};
                    end
                    
                    if ui.popError.Value == 1
                        %Prepare pooled confidence intervall and diffusion
                        %constants for display
                        error = vertcat(fitResults(:).Derr);
                        yValues = vertcat(fitResults(:).D);
                    else
                        %Prepare movie-wise or resampling values for display
                        for resultsIdx = 1:length(fitResults)
                            movieOrResamplingValues{resultsIdx} = vertcat(fitResults{resultsIdx}(:).D);
                        end
                        
                        yValues = cellfun(@mean, movieOrResamplingValues, 'UniformOutput', false);
                        yValues = vertcat(yValues{:});
                        error = cellfun(@std, movieOrResamplingValues, 'UniformOutput', false);
                        error = vertcat(error{:});
                    end
                               
                elseif ui.btnShowA.Value   
                    %User wants to see amplitudes
                    
                    %Create label for y-axis
                    ylabel1 = 'Fraction';
                     
                    %Create x-ticj labels
                    if ui.btnOneRate.Value
                        xTickLabel1 = {'A_1','A_2'};
                    elseif ui.btnTwoRates.Value
                        xTickLabel1 = {'A_1','A_2'};
                    elseif ui.btnThreeRates.Value
                        xTickLabel1 = {'A_1','A_2','A_3'};
                    end
                    
                    if ui.popError.Value == 1
                        %Prepare pooled confidence intervall and diffusion
                        %constants for display
                        error = vertcat(fitResults(:).Aerr);
                        yValues = vertcat(fitResults(:).A);
                    else
                        %Prepare movie-wise or resampling values for display
                        for resultsIdx = 1:length(fitResults)
                            movieOrResamplingValues{resultsIdx} = vertcat(fitResults{resultsIdx}(:).A);
                        end
                        
                        yValues = cellfun(@mean, movieOrResamplingValues, 'UniformOutput', false);
                        yValues = vertcat(yValues{:});
                        error = cellfun(@std, movieOrResamplingValues, 'UniformOutput', false);
                        error = vertcat(error{:});
                    end
                    
                elseif ui.btnShowEffectiveD.Value   
                    %User wants to see Deff
                    
                    %Create label for y-axis
                    if ui.btnPxFr.Value
                        ylabel1 = 'Effective diffusion coefficient (px^2/frame)';
                    else
                        ylabel1 = 'Effective diffusion coefficient (\mum^2/sec)';
                    end
                    
                    %Create x-axis label
                    xTickLabel1 = {''};
               
                    if ui.popError.Value == 1
                        %Prepare pooled confidence intervall and diffusion
                        %constants for display
                        error = 0;
                        yValues = vertcat(fitResults(:).EffectiveD);
                    else
                        %Prepare movie-wise or resampling values for display
                        for resultsIdx = 1:length(fitResults)
                            movieOrResamplingValues{resultsIdx} = vertcat(fitResults{resultsIdx}(:).EffectiveD);
                        end
                        
                        yValues = cellfun(@mean, movieOrResamplingValues, 'UniformOutput', false);
                        yValues = vertcat(yValues{:});
                        error = cellfun(@std, movieOrResamplingValues, 'UniformOutput', false);
                        error = vertcat(error{:});
                    end
                                           
                end
                
                if size(yValues,2) == 1 && size(yValues,1) > 1
                    %Dirty workaround for displaying only one diffusion
                    %coefficient in a bar chart for Matlab versions < 2020a
                    yPlotValues = yValues;
                    yPlotValues(1,2) = 0;
                    
                    %Create bar chart
                    hBar = bar(ui.ax, 1:2, yPlotValues', 0.8 ,'FaceColor','flat');
                    
                    for tlIdx = 1:numel(hBar)
                        hBar(tlIdx).XData = hBar(tlIdx).XData(1);
                        hBar(tlIdx).YData = hBar(tlIdx).YData(1);
                    end
                else
                    %Create bar chart
                    hBar = bar(ui.ax, 1:size(yValues,2), yValues', 0.8 ,'FaceColor','flat');
                end
                                
                hold(ui.ax, 'on')
                
                %Set bar colors and display moviewise or resampling values
                for k1 = 1:nBatches                    
                    hBar(k1).CData = batchColors(k1,:);
                    
                    %Get centers of bar chart 
                    center(k1,:) = bsxfun(@plus, hBar(k1).XData, hBar(k1).XOffset');      % Note: ‘XOffset’ Is An Undocumented Feature, This Selects The ‘bar’ Centres
                               
                    if ui.popError.Value > 1
                        %Add movie-wise values to bar chart
                        movieOrResamplingX = repmat(center(k1,:),size(movieOrResamplingValues{k1},1),1);
                        movieOrResamplingY = movieOrResamplingValues{k1};
                        plot(ui.ax, movieOrResamplingX,movieOrResamplingY, '.', 'Color','k');
                    end
                end
                
                
                if error ~= 0
                    errorbar(ui.ax, center, yValues, error, '.k', 'Capsize', 20);
                end
                
                    curBatchName = results(resultsIdx).batchName;
                %Save results in currentPlotValues variable
                switch ui.popError.Value
                    case 1
                        currentPlotValues = struct('batchName',curBatchName,'pooledValues',yValues,'confidenceIntervall', error);
                    case 2
                        currentPlotValues = struct('batchName',curBatchName,'meanValue',yValues,'stdMoviewise', error,'moviewiseValues',{movieOrResamplingValues});
                    case 3
                        currentPlotValues = struct('batchName',curBatchName,'meanValue',yValues,'stdResampling', error,'resamplingValues',{movieOrResamplingValues});
                end
                                  
                hold(ui.ax, 'off')
                
                if showWarnDlg
                    warndlg(['At least one batch file contains '...
                        'movies that have been analyzed with different '...
                        'tracking radii. The tracking radius is used to '...
                        'normalize the fitting function (see manual). '...
                        'Using largest tracking radius in batch for normalization.'],'Warning');
                end
                
                %Set x-tick labels 
                set(ui.ax,'XTickLabel',xTickLabel1)
                
                %Set empty x axis labels
                xlabel1 = {};
                ui.editNResamplingDiff.BackgroundColor = [1 1 1];
        end
        
        %Show legend
        if strcmp(plotStyle, 'swarmplot')
            legend(err,legendString)
        else
            legend(ui.ax,legendString,'Interpreter','None')
        end
        legend(ui.ax,'boxoff')

        
        if ~isempty(ylabel1) || ~isempty(xlabel1)
            %Set x and y-axis labels
            xlabel(ui.ax,xlabel1)
            ylabel(ui.ax,ylabel1)
        end
        hold(ui.ax,'off')

        
        AdjustAxis()
    end

    function AdjustAxis()
        %Executed either when the axis limits have changed or after the
        %plot was updated by PlotHistogramCB function
        
        
        
        %Check if y-axis has to be plotted logarithmic or linear
        if ui.cboxLogY.Value
            set(ui.ax,'YScale','log')
        else
            set(ui.ax,'YScale','linear')
        end
        
        %Check if x-axis has to be plotted logarithmic or linear
        if ui.cboxLogX.Value
            set(ui.ax,'XScale','log')
        else
            set(ui.ax,'XScale','linear')
        end

        %Check if legend should be displayed

        % Get handle to the legend
        hLegend = findobj(gcf, 'Type', 'Legend');
        if ui.cboxShowLegend.Value && ~strcmp(plotStyle, 'scatterplot')
            %Show legend
            set(hLegend, 'Visible', 'on');
        else
            %Hide legend
            set(hLegend, 'Visible', 'off');
        end

                    
        %Auto adjust x-axis if checkbox is checked
        if ui.cboxAutoX.Value
            if strcmp(plotStyle, 'swarmplot')
                %Plot style is swarmplot so give a little more space to the
                %left and right
                ui.editLimX1.String = 0.5;
                nBatches = length(results);
                ui.editLimX2.String = nBatches+0.5;
            elseif strcmp(plotStyle, 'scatterplot')
                if ~isempty(ui.hist)
                    %Plot style is scatterplot
                    ui.editLimX1.String = min(ui.hist(:,1));
                    ui.editLimX2.String = max(ui.hist(:,1));
                end
            else
                axis(ui.ax,'tight')
                xLimits = xlim(ui.ax);
                if isnumeric(xLimits)
                    ui.editLimX1.String = round_significant(xLimits(1),2,'floor');
                    ui.editLimX2.String = round_significant(xLimits(2),2,'ceil');
                else
                    ui.editLimX1.String = xLimits(1);
                    ui.editLimX2.String = xLimits(2);
                end
            end
            
        end
        
        %Auto adjust y-axis if checkbox is checked
        if ui.cboxAutoY.Value
            if strcmp(plotStyle, 'scatterplot')
                %Plot style is scatterplot
                if ~isempty(ui.hist)
                    ui.editLimY1.String = min(ui.hist(:,2));
                    ui.editLimY2.String = max(ui.hist(:,2));
                end
            else
                %Auto adjust y-axis selected so calculate limits
                axis(ui.ax,'tight')
                yLimits = ylim(ui.ax);
                
                ui.editLimY1.String = round_significant(max(0,yLimits(1)),12,'floor');
                ui.editLimY2.String = round_significant(yLimits(2),2,'ceil');
            end
        end
        
        
        if strcmp(plotStyle, 'scatterplot')
            %Plot scatterplot with density heat-map using the user defined axis limits
            
            if ~isempty(ui.hist)
                %Get values
                valuesX = ui.hist(:,1);
                valuesY = ui.hist(:,2);
                
                
                xIdx = valuesX < str2double(ui.editLimX2.String);
                yIdx = valuesY < str2double(ui.editLimY2.String);
                
                allIdx = xIdx & yIdx;
                valuesX = valuesX(allIdx);
                valuesY = valuesY(allIdx);
                scatplot(valuesX,valuesY);
                colorbar('off')
            else
                ui.hist = scatter(ui.ax,NaN,NaN);
            end
        end
                
        %Set x -and y-axis limits
        xlim(ui.ax,[str2double(ui.editLimX1.String) str2double(ui.editLimX2.String)]);
        ylim(ui.ax,[str2double(ui.editLimY1.String) str2double(ui.editLimY2.String)]);
        
    end

    function cursorText = dataCursorCB(~,eventHandle)
        %Executed when the cursor is hovered over a data entry or when a data
        %point is selected
        
        graphObjHandle = get(eventHandle,'Target');
        pos = get(eventHandle,'Position');
               
        if strcmp(plotStyle, 'histogram') || strcmp(plotStyle, 'angular histogram')
            %Plotstyle is histogram or angular histogram so display the
            %value and the bin edges
            
            upperEdgeIdx = find(pos(1) <= graphObjHandle.BinEdges,1,'first');
            binEdges = graphObjHandle.BinEdges(upperEdgeIdx-1:upperEdgeIdx);
            cursorText = {['Value: ',num2str(pos(2))],...
                    ['Bin edges: [', num2str(binEdges(1)), ' ',num2str(binEdges(2)), ']']};
        elseif strcmp(plotStyle, 'swarmplot') || strcmp(plotStyle, 'valueVsParameter')
            %Plotstyle is swarmplot

            %Check which datapoint has been selected
            if strcmp(graphObjHandle.UserData,'meanMoviewise')

                cursorText = {'Mean of moviewise values',...
                    ['Mean: ', num2str(graphObjHandle.YData(ceil(pos(1))))],...
                    ['Error: ', num2str(graphObjHandle.YPositiveDelta(ceil(pos(1))))]};
            elseif strcmp(graphObjHandle.UserData,'medianMoviewise')
                median = graphObjHandle.YData(floor(pos(1)));
                cursorText = {'Quartiles of moviewise values',...,...
                    ['Q3: ', num2str(median+graphObjHandle.YPositiveDelta(floor(pos(1))))],...
                    ['Q2 (median): ', num2str(median)],...
                    ['Q1: ', num2str(median+graphObjHandle.YNegativeDelta(floor(pos(1))))]};
            elseif strcmp(graphObjHandle.UserData,'wholeSet')
                cursorText = {'All movies pooled',...
                    ['Value: ', num2str(graphObjHandle.YData(floor(pos(1))))],...
                    ['Error: \pm', num2str(graphObjHandle.YPositiveDelta(floor(pos(1))))]};
            else
                movieNames = graphObjHandle.UserData{1};
                movieNumbers = graphObjHandle.UserData{2};
                
                index = graphObjHandle.XData == pos(1) & graphObjHandle.YData == pos(2);

                movieNumber = movieNumbers(index);
                movieName = char(movieNames{index});
                movieName(strfind(movieName, '_')) = ' ';
                
                cursorText = {['Value: ',num2str(pos(2))],...
                    ['Movienumber: ',num2str(movieNumber)],...
                    ['Filename: ', movieName]};
            end
        else
            %Plotstyle is either diffusion parameter or scatterplot so just
            %show the x and y value of the selected datapoint
            cursorText = {['X: ',num2str(pos(1))],...
                ['Y: ',num2str(pos(2))]};
        end


    end

    function OverlayHistWithDiffFitCB(histType)
        
                
        %Get number of selected batch files
        nBatches = length(results);
        %Iterate through selected batches
        for resultsIdx = 1:nBatches
                        
            curBatchJumps = vertcat(results(resultsIdx).jumpDistances{:});
                        
            %Create cumulative density function from valuesY for
            %current batch
            
            [y,edges] = histcounts(curBatchJumps,...
                'Normalization','cdf',...
                'BinWidth',str2double(ui.editBinSize.String));
            
            %Get bin centers
            x = (edges(2:end)-(edges(2)-edges(1))/2);
            
            
            %Get frame cycle times as we need them to calculate the
            %diffusion constants
            frameCycleTimes = {results(:).frameCycleTimes};
            
            if ui.btnPxFr.Value
                %User wants results in pixels and frames
                frameCycleTime = 1;
            else
                %User want results in microns and seconds
                
                %Get frame cycle times in movies of current batch
                curframeCycleTimes = unique(frameCycleTimes{resultsIdx});
                %Convert frame cycle time to seconds. If more than
                %one frame cycle time is found, use first one

                frameCycleTime = curframeCycleTimes(1);
            end
            
            %Square x axis for diffusion fit
            xSq = x.^2;
            xSq = xSq./(4*frameCycleTime);
            
            %Retreive start values for fitting
            startD = vertcat(ui.tableStartD.Data{:,2});
            
            %Get tracking radius
            allTrackingRadii = vertcat(results(resultsIdx).trackingRadii);
            trackingRadius = max(unique(allTrackingRadii));
            trackingRadius = trackingRadius^2/(4*frameCycleTime);

            
            %Get number of diffusive species
            if ui.btnOneRate.Value
                nRates = 1;
            elseif ui.btnTwoRates.Value
                nRates = 2;
            elseif ui.btnThreeRates.Value
                nRates = 3;
            end
            
            %Fit curve with n-exp diffusion fit
            outDiff = dispfit_cumulative(xSq',y', trackingRadius, startD, nRates);


            hold(ui.ax,'on')

            if strcmp(histType,'cdf')
                plot(ui.ax, outDiff.xy(:,1), outDiff.xy(:,2),'r','linewidth',2)
            else
                xEdges = ui.hist.BinEdges;
                deltaX = xEdges(2)-xEdges(1);

                D = outDiff.D;
                A = outDiff.A;

                %Create y-values
                switch nRates
                    case 1
                        y = (1/(2*frameCycleTime))*deltaX*x.*(A(1)/D(1)*exp(-x.^2/(4*frameCycleTime*D(1))));
                    case 2
                        y = (1/(2*frameCycleTime))*deltaX*x.*(A(1)/D(1)*exp(-x.^2/(4*frameCycleTime*D(1)))+A(2)/D(2)*exp(-x.^2/(4*frameCycleTime*D(2)))/(1-exp(-trackingRadius/(D(2)))));
                    case 3
                        y = (1/(2*frameCycleTime))*deltaX*x.*(A(1)/D(1)*exp(-x.^2/(4*frameCycleTime*D(1)))+A(2)/D(2)*exp(-x.^2/(4*frameCycleTime*D(2)))+A(3)/D(3)*exp(-x.^2/(4*frameCycleTime*D(3)))/(1-exp(-trackingRadius/(D(3)))));
                end

                %Plot complete fit curve
                plot(x, y,'Color','k','linewidth',2)

                if nRates > 1

                    %Plot first component
                    y = (1/(2*frameCycleTime))*deltaX*x.*(A(1)/D(1)*exp(-x.^2/(4*frameCycleTime*D(1))));
                    plot(ui.ax, x, y,'r','linewidth',2)
                    %Plot second component
                    y = (1/(2*frameCycleTime))*deltaX*x.*(A(2)/D(2)*exp(-x.^2/(4*frameCycleTime*D(2)))/(1-exp(-trackingRadius/(D(2)))));
                    plot(ui.ax, x, y,'g','linewidth',2)
                end
                if nRates > 2
                    %Plot thrid component
                    y = (1/(2*frameCycleTime))*deltaX*x.*(A(3)/D(3)*exp(-x.^2/(4*frameCycleTime*D(3)))/(1-exp(-trackingRadius/(D(3)))));
                    plot(ui.ax, x, y,'y','linewidth',2)
                end
            end
            
        end


        
    end

    function AdjustAxisFontSizeCB(~, ~)
        %User made a right click on the axis and clicked "adjust axis,
        %label and legend font size"

        % Get current axis properties
        ax = gca;

        currentAxisFontSize = get(ax, 'FontSize'); % Get current axis font size
        currentLegendFontSize = get(legend, 'FontSize');  % Get current legend font size


        % Check if it's a polar axes
        isPolarAxes = strcmp(ax.Type, 'polaraxes');

        % Display input fields
        if isPolarAxes
            prompt = {'Font size:', 'Legend font size:'};
        else
            currentLabelFontSize = get(get(ax, 'YLabel'), 'FontSize');  % Get current label font size
            prompt = {'Axis font size:', 'Label font size:', 'Legend font size:'};
        end

        if isPolarAxes
            % Default input for polar axes
            defaultinput = {num2str(currentAxisFontSize), num2str(currentLegendFontSize)}; 
        else
            % Default input for Cartesian axes
            defaultinput = {num2str(currentAxisFontSize), num2str(currentLabelFontSize), num2str(currentLegendFontSize)};
        end

        % Prompt user for input
        userInput = inputdlg(prompt, '', 1, defaultinput);

        % Check if the user clicked 'Cancel'
        if isempty(userInput)
            return;
        end

        % Set new axis properties
        try
            % Convert user input to numeric
            newAxisFontSize = str2double(userInput{1});

            if isPolarAxes
                % Convert user input to numeric
                newLegendFontSize = str2double(userInput{2});
                % Set new axis font size
                set(ax, 'FontSize', newAxisFontSize);
                % Set new legend font size
                set(legend, 'FontSize', newLegendFontSize);
            else
                % Convert user input to numeric
                newLabelFontSize = str2double(userInput{2});
                % Convert user input to numeric
                newLegendFontSize = str2double(userInput{3});

                % Set new axis font size
                set(ax, 'FontSize', newAxisFontSize);
                % Set new label font size for x-axis
                set(get(ax, 'XLabel'), 'FontSize', newLabelFontSize);
                % Set new label font size for y-axis
                set(get(ax, 'YLabel'), 'FontSize', newLabelFontSize);

                % Set new legend font size
                set(legend, 'FontSize', newLegendFontSize);
            end
        catch
            % Display error message for invalid input
            disp('Invalid input. Could not change axis properties.');
        end
    end

%Load/remove batch file, select batch file, tl condition or movie number

    function LoadBatchFilesCB(src,~)
        %Executed when "Load .mat batch file(s)" is pressed
        
        %Open file dialog box
        [fileNameList,pathName] = uigetfile('*.mat','Select .mat batch file(s)','MultiSelect','on',currentBatchPath);
        
        if isequal(fileNameList,0)  
            %User didn't choose a file
            return
        elseif ~iscell(fileNameList) 
            %Check if only one file has been chosen
            fileNameList = {fileNameList};
        end
        
        %Save selected path for using it as the starting path in the next
        %file dialog box
        currentBatchPath = pathName;
        
        %Number of batches to load
        nNewBatches = length(fileNameList);
        
        %Number of batches currently loaded in the track analyser
        nOldBatches = length(batches);
        
        %Iterate through files and load each batch file
        newBatchFiles = cell(nNewBatches,1);
        
        for fileIdx = 1:nNewBatches
            %Monitor progress
            src.String = ['Loading ', num2str(fileIdx), ' of ', num2str(nNewBatches)];
            drawnow
            curBatchFile = fullfile(pathName,fileNameList{fileIdx});
            loadedBatch = load(curBatchFile);
            loadedBatch = loadedBatch.batch; 
            
            newBatchFiles{fileIdx} = loadedBatch;
            %Add number to the list of filenames to later display the filenames in the ui
            fileNameList{fileIdx} = [num2str(nOldBatches+fileIdx),': ', fileNameList{fileIdx}];
        end
        
        %Catenate the old and new batches
        batches = vertcat(batches, newBatchFiles);
        
        %List containing unique frame cycle times of each batch
        frameCycleTimesList = cell(length(batches),1);
        %List containing all the frame cycle times of all movies of each batch
        frameCycleTimeMovieList = cell(length(batches),1);
        
        %Iterate through all batches and create lists of frame cycle times
        for batchIdx = 1:length(batches)
           currentBatch = batches{batchIdx};
            
            frameCycleTimeMovieList{batchIdx} = zeros(length(currentBatch),1);
            for movieIdx = 1:length(currentBatch)
                frameCycleTimeMovieList{batchIdx}(movieIdx) = currentBatch(movieIdx).movieInfo.frameCycleTime;
            end
            
            frameCycleTimesList{batchIdx} = unique(frameCycleTimeMovieList{batchIdx}); 
        end
        
         
        %Reset String of the load button
        src.String = 'Load batch .mat file(s)';
        %Set selected batch file to first entry
        ui.popBatchSel.Value = 1;
        %Update list of batch files
        ui.popBatchSel.String = [ui.popBatchSel.String; fileNameList'];
        BatchSelectionCB()
        
    end

    function RemoveBatchFilesCB(~,~)
        %Executed when "remove selected file(s)" button is pressed
        
        %Remove selected batch file names from ui list
        ui.popBatchSel.String(ui.popBatchSel.Value) = [];


        
        %Create new list of batch files
        for idx = 1:length(ui.popBatchSel.String)
            if regexp(ui.popBatchSel.String{idx}, '\d+:')
                ui.popBatchSel.String{idx} = [num2str(idx),': ', ui.popBatchSel.String{idx}(4:end)];
            end
        end

        
        %Remove selected batches from the frame cycle time lists and from
        %the batches structure
        frameCycleTimesList(ui.popBatchSel.Value) = [];
        frameCycleTimeMovieList(ui.popBatchSel.Value) = [];        
        batches(ui.popBatchSel.Value) = [];
        
        %Set seleted batch file to the first entry
        ui.popBatchSel.Value = 1;  
        
        %Selection of batch files changed so call BatchSelectionCB function
        BatchSelectionCB()
    end

    function RenameBatchFilesCB(~,~)
        %Executed when "rename selected file(s)" button is pressed
        
        %Get selected batches
        selectedValues = ui.popBatchSel.Value;       

        %Create input dialogs to for new file names
        dlgtitle = 'Please choose new name(s)';
        dims = [1 70];
        definput = ui.popBatchSel.String(selectedValues);
        prompt = repmat({''},1,length(definput));
        answer = inputdlg(prompt,dlgtitle,dims,definput);

        if isempty(answer)
            %Canceled
            return
        end
        
        %Create new list of batch files
        for idx = 1:length(ui.popBatchSel.String)
            ui.popBatchSel.String(selectedValues) = answer;
        end

        %Update histogram to display new batch names in the legend
        CreateData()
    end

    function BatchSelectionCB()
        %Executed whenever the selection of batch files changes
        
        
        if isempty(batches)
            %No batch files in the list
            ui.popTlSel.String = {};
            ui.editMovie.String = 1;
            ui.txtMovie3.String = 0;
            ui.tableStatistics.ColumnName = {''};
            ui.tableStatistics.Data = {'#movies';'#tracks';'#non-linked spots';'#all events';'#jumps';'#angles'};            
        else
            
            %Create unique list of frame cycle times accouring in the
            %current selection of batch files
            allTl = [];
            nFilesPerBatch = [];

            %Iterate through selected batch files
            for batchSelVal = ui.popBatchSel.Value
                allTl = [allTl; frameCycleTimesList{batchSelVal}];
                nFilesPerBatch = [nFilesPerBatch; length(batches{batchSelVal})];
            end
            
            allTl = unique(allTl);
            
            %Create cell array containing all frame cycle times plus
            %"single" and "all movies" in the list of frame cycle times
            
            tlList = {'Single movie', 'All movies'};
            
            for k = 1:numel(allTl)
                tlList{k+2} = [num2str(allTl(k)), ' ms'];
            end
            
            %Update list of frame cycle times in the ui
            ui.popTlSel.String = tlList;
            
            %Set maximum amount of movies in the single movie selection
            %panel to the maximum number of movies in one batch
            ui.txtMovie3.String = max(nFilesPerBatch);
            
            %Take care that the current movie number is not higher than the
            %maximum amount of movies in a batch
            if str2double(ui.editMovie.String) > max(nFilesPerBatch)
                curMovieIndex = max(nFilesPerBatch);
                ui.editMovie.String = max(nFilesPerBatch);
            end
            
            %Take care that the selected value in the frame cycle time list 
            %is not higher than the amount of enries in this list
            if ui.popTlSel.Value(end)-2 > numel(allTl)
                ui.popTlSel.Value = length(tlList);
            end
        end
        
        %Update all results and plots
        UpdateRegionsList()
        CreateData()
    end

    function TlSelectionCB()
        %Executed when the user interacts with the frame cycle time list or
        %region list
                
        if ui.popTlSel.Value ==1
            %"Single movie" selected so show movie number ui elements
            ui.panelMovieSel.Visible = 'on';
        else
            %Hide movie number ui elements
            ui.panelMovieSel.Visible = 'off';
        end
        
        nRegionsSelected = numel(ui.popRegionSel.Value);
        
        if ui.popRegionSel.Value(1) == 1 && nRegionsSelected > 1
            ui.popRegionSel.Value = 1;            
        end
        
        if nRegionsSelected > 1
            ui.cboxNormalizeROI.Value = 0;
        end
        
        UpdateRegionsList()
        CreateData()
        
        if nRegionsSelected > 1
            ui.cboxNormalizeROI.Visible = 'off';
        end
    end

    function MovieNumberCB(src,~)
        %Executed when the movie number is changed by the user
        
        previousMovieNumber = curMovieIndex;
        
        if strcmp(src.String,'Previous') && previousMovieNumber > 1
            curMovieIndex =  previousMovieNumber - 1;
        elseif strcmp(src.String,'Next') && previousMovieNumber < str2double(ui.txtMovie3.String)
            curMovieIndex = previousMovieNumber + 1;
        elseif str2double(src.String) <= str2double(ui.txtMovie3.String) && str2double(src.String) > 0
            curMovieIndex = str2double(src.String);
        end
                
        ui.editMovie.String = curMovieIndex;
        
        UpdateRegionsList()
        CreateData()
    end

    function UpdateRegionsList()
        %Sub-region analysis will be available in following versions and is
        %currently under developement
        
        %Updates the list of displayed sub-regions
        
        if isempty(batches)
            ui.popRegionSel.String = {};
            return
        end
                
        nMaxRegions = 0;
        
        %Iterate through selected batch files and find the maximum amount
        %of sub-regions a movie contains
        for batchSelVal = ui.popBatchSel.Value
            
            currentBatch = batches{batchSelVal};
            
            %Current movie, all movies or selection of movies
            if ui.popTlSel.Value(1) == 1 %Current movie
                if length(batches{batchSelVal}) < curMovieIndex
                    continue
                else
                    tlMoviesIdx = curMovieIndex;
                end
            elseif ui.popTlSel.Value(1) == 2 %All movies
                tlMoviesIdx = 1:length(currentBatch);
            else %Specific TL
                tlMovies = zeros(length(currentBatch),1);
                for k = 1:numel(ui.popTlSel.Value)
                    curTlCond = str2double(ui.popTlSel.String{ui.popTlSel.Value(k)}(1:end-3));
                    tlMovies = or(tlMovies, frameCycleTimeMovieList{batchSelVal} == curTlCond);
                end
                tlMoviesIdx = find(tlMovies');
            end

            for movieID = tlMoviesIdx
                nMaxRegions = max(nMaxRegions, batches{batchSelVal}(movieID).results.nSubRegions+1);
            end
        end
        
        if ui.popRegionSel.Value > nMaxRegions+1
            ui.popRegionSel.Value = 1;
        end
        
        %Create cell array containing the displayed region strings

        if nMaxRegions == 1
            ui.popRegionSel.Visible = 'off';
            regionList{1} = 'All regions';
        else            
            ui.popRegionSel.Visible = 'on';
            
            regionList = cell(nMaxRegions,1);
            for regionIdx = 0:nMaxRegions
                if regionIdx == 0
                    regionList{regionIdx+1} = 'All regions';
                elseif regionIdx == 1
                    regionList{regionIdx+1} = ['Region ',num2str(regionIdx), ' (tracking-region)'];
                else
                    regionList{regionIdx+1} = ['Region ',num2str(regionIdx)];
                end
            end
        end
        
        %Update regions list
        ui.popRegionSel.String = regionList;
    end

%Other small stuff
    function bgITMselectionCB(~,~)
        %Executed when user switches between "ITM" and "continuous" in the track fractions tab
        
        %editNBrightFrames states the amount of bright frames separated by a long dark time.
        %Currently not used but can be changed if an itm scheme contains
        %more than 2 frames in a row
        if ui.btnITM.Value            
            ui.editNBrightFrames.String = 2; 
            ui.txtNDarkForLong.String = 'Number of survived dark periods to count as long track:';
        elseif ui.btnContinuous.Value
            %ui.editNBrightFrames must be one for continuous illumination
            ui.editNBrightFrames.String = 1;
            ui.txtNDarkForLong.String = 'Count as long track if number of survived frames is greater than:';
        end
        
        CreateData()
    end

    function btnGroupUnitsCB(~,~)
        %Executed when the units are changed or the pixelsize has been
        %changed
        
        
        if ui.btnPxFr.Value
            %User wants to display results in pixels and frames
            ui.txtPixelsize.Visible = 'off';
            ui.editPixelsize.Visible = 'off';
            ui.txtAnglesMinJumpDist.String = 'px';
            ui.txtAnglesMaxJumpDist.String = 'px';

            ui.txtBinSize.String = 'Bin width (px)';
        elseif ui.btnMiMs.Value            
            %User wants to display results in microns and seconds so show
            %field where pixelsize can be entered
            ui.txtPixelsize.Visible = 'on';
            ui.editPixelsize.Visible = 'on';
            ui.txtAnglesMinJumpDist.String = 'µm';
            ui.txtAnglesMaxJumpDist.String = 'µm';
            ui.txtBinSize.String = 'Bin width (µm)';
        end
        
        %Save pixelsize in variable for later returning it to TrackIt when
        %figure is closed
        pixelSize = str2double(ui.editPixelsize.String);
        
        CreateData()
    end

    function EditLimitsCB(src,~)
        %Executed whenever axis limits are changed or the "Auto adjust" or
        %"Logarithmic" checkboxes are pressed
        
        if strcmp(src.Tag,'x')
            %User entered an axis limit so uncheck the "Auto adjust"
            %checkbox for the x-axis
            ui.cboxAutoX.Value = 0;
        elseif strcmp(src.Tag,'y')
            %User entered an axis limit so uncheck the "Auto adjust"
            %checkbox for the y-axis
            ui.cboxAutoY.Value = 0;
        end
        
        AdjustAxis()
    end

    function CopyToWorkspaceCB(~,~)
        %Executed when "Export to Matlab workspace" is pressed
                
        assignin('base','allAnalysisResults',results);
        assignin('base','valuesInCurrentPlot',currentPlotValues);
    end

    function OpenManualCB(~,~)
        %User pressed Help -> Open manual
        open("TrackIt_manual.pdf")
    end

    function PointsToFitBtnCB(src,~)
        %Executed when user presses buttons in the msd analysis panel

        switch src.Tag
            case 'PointsToFit'
                ui.editPointsToFit.String = src.String;
            case 'Offset'
                ui.editOffset.String = src.String;
            case 'FitFun'
            case 'Alpha'
                ui.editAlphaThres.String = src.String;
                TlSelectionCB()
        end

    end

    function CloseHistogram()
        delete(gcf)
    end

end

