%
%  InterfaceAgilent4294A.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef InterfaceAgilent4294A < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = InterfaceAgilent4294A()
      
      % Settings
      this.s.ip = '10.136.133.1';
      this.s.n = 4; % digits
      this.s.color = ['0072BD';'D95319']; % plot colors
      
      % Default data
      this.d.appdir = [fileparts(mfilename('fullpath')) filesep];
      this.d.path = UIComponent.getUserDirectory();
      this.d.background = UIComponent.getBackgroundColor();
      this.d.export = 0;
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Interface Agilent 4294A  |  hepia',...
        'Size',[1024 768]);
      zoom(this.h.window,'on');
      
      % Axes
      this.h.axes_A = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 438 630 300]);
      this.h.axes_B = UIComponent.Axes(...
        'Parent',this.h.window,...
        'Position',[65 60 630 300]);
      
      % Traces, grid lines & labels
      this.h.trace_A = plot(this.h.axes_A,NaN,NaN,NaN,NaN);
      this.h.trace_B = plot(this.h.axes_B,NaN,NaN,NaN,NaN);
      set([this.h.trace_A(1) this.h.trace_B(1)],...
        'Color',sscanf(this.s.color(1,:),'%2X')/255);
      set([this.h.trace_A(2) this.h.trace_B(2)],...
        'Color',sscanf(this.s.color(2,:),'%2X')/255);
      set([this.h.axes_A this.h.axes_B],...
        'FontSize',UIComponent.getFontSize()/1.1,...
        'XGrid','on','YGrid','on');
      this.h.XLabel = [this.h.axes_A.XLabel this.h.axes_B.XLabel];
      this.h.ALabel = this.h.axes_A.YLabel;
      this.h.BLabel = this.h.axes_B.YLabel;
      this.h.parameters = this.h.axes_B.Title;
      set(this.h.parameters,...
        'HorizontalAlignment','right',...
        'Units','pixels',...
        'Position',[630 315 0]);
      linkaxes([this.h.axes_A this.h.axes_B],'x');
      
      % Logo
      UIComponent.Label(...
        'Icon',UIComponent.createIcon([this.d.appdir 'agilent.png']),...
        'Parent',this.h.window,...
        'Position',[745 698 260 50]);
      
      % Equivalent circuit group
      this.h.equivCircuit = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Position',[745 80 260 598],...
        'Title','Equivalent circuit');
      
      % Equivalent circuit image
      this.h.equivCircuitImage = UIComponent.Label(...
        'HorizontalAlignment','center',...
        'Parent',this.h.equivCircuit,...
        'Position',[20 260 220 300]);
      
      % Equivalent circuit parameters
      this.h.equivCircuitAxes = UIComponent.Axes(...
        'Parent',this.h.equivCircuit,...
        'Position',[20 65 220 190],...
        'Visible','off',...
        'XLim',[-1 1],...
        'YLim',[-1 1]);
      setAllowAxesZoom(zoom(this.h.window),this.h.equivCircuitAxes,0);
      this.h.equivCircuitParams = text(0,0,'',...
        'FontSize',UIComponent.getFontSize()+1,...
        'HorizontalAlignment','center',...
        'Interpreter','LaTeX',...
        'Parent',this.h.equivCircuitAxes,...
        'VerticalAlignment','middle');
      
      % Equivalent circuit transfer & show/hide buttons
      this.h.getEquivCircuit = UIComponent.Button(...
        'Callback',@this.getEquivCircuit,...
        'Enable','off',...
        'Parent',this.h.equivCircuit,...
        'Position',[20 20 80 40],...
        'String','Transfer');
      this.h.showHideEquivCircuit = UIComponent.Button(...
        'Callback',@this.showHideEquivCircuit,...
        'Enable','off',...
        'Parent',this.h.equivCircuit,...
        'Position',[120 20 120 40],...
        'String','Show simulation');
      
      % Transfer & export buttons
      this.h.getTrace = UIComponent.Button(...
        'Callback',@this.getTrace,...
        'Parent',this.h.window,...
        'Position',[745 20 140 40],...
        'String','Transfer traces');
      this.h.export = UIComponent.Button(...
        'Callback',@this.export,...
        'Parent',this.h.window,...
        'Position',[905 20 100 40],...
        'String','Export');
      
      % Connect to the Agilent 4294A, allowing only one instance
      try
        global agilent4294A_instance %#ok<TLEV>
        if agilent4294A_instance == 1
          error('InterfaceAgilent4294A:OneInstanceAllowed',...
            'Only one instance of the Agilent 4294A interface is allowed.');
        end
        this.h.a4294A = Agilent_4294A(this.s.ip);
        IDN = strsplit(this.h.a4294A.IDN,',');
        this.h.window.Name = ['Interface Agilent 4294A  |  IP ' this.s.ip ...
          '  |  IDN ' IDN{3} '  |  ' IDN{4} '  |  hepia'];
        agilent4294A_instance = 1;
      catch e
        jerrordlg(e.message);
        this.closeRequestFcn();
        if isdeployed
          return
        else
          rethrow(e);
        end
      end
      
      % Show the main window
      this.h.window.Visible = 'on';
      
    end
    
  end
  
  methods (Access = private)
    
    function closeRequestFcn(this,~,~)
      global agilent4294A_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      try %#ok<TRYNC>
        delete(this.h.a4294A);
        agilent4294A_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    % Traces
    
    function getTrace(this,~,~,~)
      this.h.window.Pointer = 'watch';
      drawnow();
      try
        [this.d.x,this.d.trace_A,this.d.trace_B,this.d.info] = this.h.a4294A.getTrace();
      catch e
        this.h.window.Pointer = 'arrow';
        jwarndlg(e.message);
        return
      end
      this.h.trace_A(1).XData = this.d.x;
      this.h.trace_A(1).YData = real(this.d.trace_A);
      this.h.trace_B(1).XData = this.d.x;
      this.h.trace_B(1).YData = real(this.d.trace_B);
      this.autoScale();
      set(this.h.XLabel,'String',this.d.info.XLabel);
      this.h.ALabel.String = this.d.info.ALabel;
      this.h.BLabel.String = this.d.info.BLabel;
      this.d.parameters = {};
      if isfield(this.d.info,'Frequency')
        this.d.parameters{end+1} = ['Frequency: '...
          double2unit(this.d.info.Frequency,this.s.n,'Hz')];
      end
      if isfield(this.d.info,'OscVoltage')
        this.d.parameters{end+1} = ['Oscillator voltage: '...
          double2unit(this.d.info.OscVoltage,this.s.n,'V')];
      end
      if isfield(this.d.info,'OscCurrent')
        this.d.parameters{end+1} = ['Oscillator current: '...
          double2unit(this.d.info.OscCurrent,this.s.n,'A')];
      end
      if isfield(this.d.info,'DCBiasVoltage')
        this.d.parameters{end+1} = ['DC bias voltage: '...
          double2unit(this.d.info.DCBiasVoltage,this.s.n,'V')];
      end
      if isfield(this.d.info,'DCBiasCurrent')
        this.d.parameters{end+1} = ['DC bias current: '...
          double2unit(this.d.info.DCBiasCurrent,this.s.n,'A')];
      end
      this.h.parameters.String = strjoin(this.d.parameters,', ');
      this.h.getEquivCircuit.Enable = 'on';
      this.enableShowHideEquivCircuit();
      this.d.export = 1;
      this.h.window.Pointer = 'arrow';
    end
    
    function autoScale(this)
      if this.d.info.XAxisLog
        set([this.h.axes_A this.h.axes_B],...
          'XLimMode','auto',...
          'YLimMode','auto',...
          'XScale','log');
      else
        set([this.h.axes_A this.h.axes_B],...
          'XLim',[this.d.x(1) this.d.x(end)],...
          'YLimMode','auto',...
          'XScale','linear');
      end
    end
    
    % Equivalent circuit
    
    function getEquivCircuit(this,~,~,~)
      this.h.window.Pointer = 'watch';
      drawnow();
      try
        c = this.h.a4294A.getEquivCircuit();
      catch e
        this.h.window.Pointer = 'arrow';
        jwarndlg(e.message);
        return
      end
      str = {['$R_1$ = ' double2unit(c.R1,this.s.n,'$\Omega$')],[],...
        ['$L_1$ = ' double2unit(c.L1,this.s.n,'H')],[],...
        ['$C_1$ = ' double2unit(c.C1,this.s.n,'F')]};
      jw = 2j*pi*this.d.x;
      switch c.circuit
        case 'A'
          this.d.sim = 1./(1/c.R1+1./(jw*c.L1)+jw*c.C1);
        case 'B'
          this.d.sim = 1./(1./(c.R1+jw*c.L1)+jw*c.C1);
        case 'C'
          this.d.sim = jw*c.L1+1./(1/c.R1+jw*c.C1);
        case 'D'
          this.d.sim = c.R1+jw*c.L1+1./(jw*c.C1);
        case 'E'
          this.d.sim = 1./(1./(c.R1+jw*c.L1+1./(jw*c.C1))+jw*c.C0);
          str = [str,{[],['$C_0$ = ' double2unit(c.C0,this.s.n,'F')]}];
      end
      this.loadEquivCircuitImage(c.circuit);
      this.h.equivCircuitParams.String = str;
      this.enableShowHideEquivCircuit(1);
      this.h.window.Pointer = 'arrow';
    end
    
    function loadEquivCircuitImage(this,c)
      i = UIComponent.createIcon([this.d.appdir mfilename '_equc' c '.png']);
      i = i.getImage();
      p = this.h.equivCircuitImage.Position;
      if p(3)/p(4) > i.getWidth()/i.getHeight()
        i = i.getScaledInstance(-1,p(4),java.awt.Image.SCALE_SMOOTH);
      else
        i = i.getScaledInstance(p(3),-1,java.awt.Image.SCALE_SMOOTH);
      end
      this.h.equivCircuitImage.Icon = UIComponent.createIcon(i);
    end
    
    function enableShowHideEquivCircuit(this,force)
      if isfield(this.d,'info') ...
          && strcmp(this.d.info.SweepParameter,'FREQ') ...
          && any(strcmp(this.d.info.Measure,{'IMPH','IRIM'})) ...
          && isfield(this.d,'sim')
        this.h.showHideEquivCircuit.Enable = 'on';
        if nargin > 1 && force
          this.showEquivCircuit();
        end
      else
        this.h.showHideEquivCircuit.Enable = 'off';
        this.hideEquivCircuit();
      end
    end
    
    function showHideEquivCircuit(this,~,~,~)
      if all(isnan(this.h.trace_A(2).XData))
        this.showEquivCircuit();
      else
        this.hideEquivCircuit();
      end
    end
    
    function showEquivCircuit(this)
      switch this.d.info.Measure
        case 'IMPH'
          A = abs(this.d.sim);
          B = (180/pi)*atan2(imag(this.d.sim),real(this.d.sim));
        case 'IRIM'
          A = real(this.d.sim);
          B = imag(this.d.sim);
        otherwise
          return
      end
      this.h.trace_A(2).XData = this.d.x;
      this.h.trace_A(2).YData = A;
      this.h.trace_B(2).XData = this.d.x;
      this.h.trace_B(2).YData = B;
      this.autoScale();
      this.h.showHideEquivCircuit.String = 'Hide simulation';
    end
    
    function hideEquivCircuit(this)
      this.h.trace_A(2).XData = NaN;
      this.h.trace_A(2).YData = NaN;
      this.h.trace_B(2).XData = NaN;
      this.h.trace_B(2).YData = NaN;
      this.autoScale();
      this.h.showHideEquivCircuit.String = 'Show simulation';
    end
    
    % Export
    
    function export(this,~,~,~)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values';...
        '*.pdf','PDF plot';...
        '*.png','PNG screen copy'};
      if ~this.d.export
        filter = filter(end,:);
      end
      [f,p,i] = uiputfile(filter,'Save as',this.d.path);
      if ~f
        return
      end
      this.h.window.Pointer = 'watch';
      drawnow();
      [p,n,e] = fileparts([p f]);
      this.d.path = [p '/'];
      if this.d.export
        switch i
          case 1
            ext = '.csv';
            sep = ',';
          case 2
            ext = '.txt';
            sep = sprintf('\t');
          case 3
            ext = '.pdf';
          case 4
            ext = '.png';
        end
      else
        ext = '.png';
      end
      if ~strcmpi(e,ext)
        e = [e ext];
      end
      file = fullfile(this.d.path,[n e]);
      switch ext
        case {'.csv','.txt'}
          f = fopen(file,'w');
          fprintf(f,'%% %s\n%% %s\n%%\n',this.h.window.Name,datestr(now));
          fprintf(f,'%% %s\n',this.d.parameters{:});
          fprintf(f,'%%\n%% %s%s',this.d.info.XLabel,sep);
          if isreal(this.d.trace_A) && isreal(this.d.trace_B)
            fprintf(f,'%s%s%s\n',this.d.info.ALabel,sep,this.d.info.BLabel);
            for i = 1:length(this.d.x)
              fprintf(f,'%.9g%s%.9g%s%.9g\n',...
                this.d.x(i),sep,...
                this.d.trace_A(i),sep,...
                this.d.trace_B(i));
            end
          else
            fprintf(f,'real(%s)%simag(%s)%sreal(%s)%simag(%s)\n',...
              this.d.info.ALabel,sep,this.d.info.ALabel,sep,...
              this.d.info.BLabel,sep,this.d.info.BLabel);
            for i = 1:length(this.d.x)
              fprintf(f,'%.9g%s%.9g%s%.9g%s%.9g%s%.9g\n',...
                this.d.x(i),sep,...
                real(this.d.trace_A(i)),sep,imag(this.d.trace_A(i)),sep,...
                real(this.d.trace_B(i)),sep,imag(this.d.trace_B(i)));
            end
          end
          fclose(f);
        case '.pdf'
          f = figure('Visible','off');
          a(1) = subplot(2,1,1,'Parent',f);
          a(2) = subplot(2,1,2,'Parent',f);
          p = [plot(a(1),...
            this.h.trace_A(1).XData,this.h.trace_A(1).YData,...
            this.h.trace_A(2).XData,this.h.trace_A(2).YData)...
            plot(a(2),...
            this.h.trace_B(1).XData,this.h.trace_B(1).YData,...
            this.h.trace_B(2).XData,this.h.trace_B(2).YData)];
          set(p([1 3]),'Color',sscanf(this.s.color(1,:),'%2X')/255);
          set(p([2 4]),'Color',sscanf(this.s.color(2,:),'%2X')/255);
          set(a,...
            'XLim',[this.d.x(1) this.d.x(end)],...
            'YLimMode','auto',...
            'XGrid','on','YGrid','on');
          set([a(1).XLabel a(2).XLabel],'String',this.d.info.XLabel);
          a(1).YLabel.String = this.d.info.ALabel;
          a(2).YLabel.String = this.d.info.BLabel;
          exportfig(f,file,[297 210],10);
          close(f);
        case '.png'
          try
            img = this.h.a4294A.getScreen();
          catch e
            this.h.window.Pointer = 'arrow';
            jwarndlg(e.message);
            return
          end
          imwrite(img,file,'Software',strrep(this.h.window.Name,'  | ',','));
      end
      this.h.window.Pointer = 'arrow';
    end
    
  end
  
end
