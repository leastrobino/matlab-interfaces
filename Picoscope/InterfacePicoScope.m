%
%  InterfacePicoScope.m
%
%  Created by Léa Strobino.
%  Copyright 2016 hepia. All rights reserved.
%

classdef InterfacePicoScope < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = InterfacePicoScope()
      
      % Settings
      this.s.color = '0072BD'; % plot color
      this.s.range = [20 10 5 2 1 500E-3 200E-3 100E-3 50E-3];
      this.s.span = [500E-9 1E-6 2E-6 5E-6 10E-6 20E-6 50E-6 100E-6 200E-6 500E-6 1E-3 2E-3 5E-3 10E-3 20E-3 50E-3 100E-3 200E-3 500E-3 1 2 5 10 20 50 100 200 500];
      
      % Default data
      this.d.mode = 0;
      this.d.path = UIComponent.getUserDirectory();
      this.d.size = [0 0];
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Interface PicoScope  |  Laboratoire de physique  |  hepia',...
        'Resize','on',...
        'Size',[1024 768],...
        'SizeChangedFcn',@this.sizeChangedFcn);
      
      % Axes
      this.h.axes_A = UIComponent.Axes(...
        'Parent',this.h.window);
      this.h.axes_B = UIComponent.Axes(...
        'Parent',this.h.window);
      
      % Traces, grid lines & labels
      c = sscanf(this.s.color,'%2X')/255;
      this.h.trace_A = plot(this.h.axes_A,NaN,NaN,NaN,NaN,'v',NaN,NaN,'<','Color',c);
      this.h.trace_B = plot(this.h.axes_B,NaN,NaN,NaN,NaN,'v',NaN,NaN,'<','Color',c);
      set([this.h.axes_A this.h.axes_B],...
        'FontSize',UIComponent.getFontSize()/1.1,...
        'XGrid','on','YGrid','on',...
        'XMinorGrid','on','YMinorGrid','on');
      if ispc, m = 4; else m = 6; end
      set([this.h.trace_A(2:3) this.h.trace_B(2:3)],...
        'MarkerEdgeColor',[0 0 0],...
        'MarkerFaceColor',[0 0 0],...
        'MarkerSize',m);
      set([this.h.axes_A.XLabel this.h.axes_B.XLabel],'String','Time (s)');
      this.h.axes_A.YLabel.String = 'Channel A (V)';
      this.h.axes_B.YLabel.String = 'Channel B (V)';
      
      % Logo
      this.h.logo = UIComponent.Label(...
        'Icon',UIComponent.createIcon('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIwAAAA9CAYAAAB/VoHuAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6RDkzRDE1NzFFQjYzMTFFNUEwMjNDN0Y3QzQ4MTAxQzMiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6RDkzRDE1NzJFQjYzMTFFNUEwMjNDN0Y3QzQ4MTAxQzMiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpEOTNEMTU2RkVCNjMxMUU1QTAyM0M3RjdDNDgxMDFDMyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpEOTNEMTU3MEVCNjMxMUU1QTAyM0M3RjdDNDgxMDFDMyIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PmKQF8gAACXZSURBVHja7H0HnFXV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'),...
        'Parent',this.h.window);
      
      % Channel A
      this.h.A.pannel = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Title','Channel A');
      UIComponent.Label(...
        'Parent',this.h.A.pannel,...
        'Position',[10 45 65 25],...
        'String','Coupling:');
      this.h.A.coupling = UIComponent.ComboBox(...
        'Callback',@this.setChannels,...
        'Parent',this.h.A.pannel,...
        'Position',[75 45 74 25],...
        'String',{'off','DC','AC'},...
        'Value',2);
      UIComponent.Label(...
        'Parent',this.h.A.pannel,...
        'Position',[10 10 45 25],...
        'String','Range:');
      this.h.A.range = UIComponent.ComboBox(...
        'Callback',@this.setChannels,...
        'Parent',this.h.A.pannel,...
        'Position',[55 10 94 25],...
        'String',{'±20 V','±10 V','±5 V','±2 V','±1 V','±500 mV','±200 mV','±100 mV','±50 mV'},...
        'Value',2);
      
      % Channel B
      this.h.B.pannel = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Title','Channel B');
      UIComponent.Label(...
        'Parent',this.h.B.pannel,...
        'Position',[10 45 65 25],...
        'String','Coupling:');
      this.h.B.coupling = UIComponent.ComboBox(...
        'Callback',@this.setChannels,...
        'Parent',this.h.B.pannel,...
        'Position',[75 45 74 25],...
        'String',{'off','DC','AC'});
      UIComponent.Label(...
        'Parent',this.h.B.pannel,...
        'Position',[10 10 45 25],...
        'String','Range:');
      this.h.B.range = UIComponent.ComboBox(...
        'Callback',@this.setChannels,...
        'Parent',this.h.B.pannel,...
        'Position',[55 10 94 25],...
        'String',this.h.A.range.String,...
        'Value',2);
      
      % Time
      this.h.time.pannel = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Title','Time');
      UIComponent.Label(...
        'Parent',this.h.time.pannel,...
        'Position',[10 10 40 25],...
        'String','Span:');
      this.h.time.span = UIComponent.ComboBox(...
        'Callback',@this.setTime,...
        'Parent',this.h.time.pannel,...
        'Position',[50 10 99 25],...
        'String',{'500 ns','1 µs','2 µs','5 µs','10 µs','20 µs','50 µs','100 µs','200 µs','500 µs','1 ms','2 ms','5 ms','10 ms','20 ms','50 ms','100 ms','200 ms','500 ms','1 s','2 s','5 s','10 s','20 s','50 s','100 s','200 s','500 s'},...
        'Value',11);
      
      % Trigger
      this.h.trigger.pannel = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Title','Trigger');
      UIComponent.Label(...
        'Parent',this.h.trigger.pannel,...
        'Position',[10 115 60 25],...
        'String','Channel:');
      this.h.trigger.channel = UIComponent.ComboBox(...
        'Callback',@this.setTrigger,...
        'Parent',this.h.trigger.pannel,...
        'Position',[70 115 79 25],...
        'String',{'-','A','B'});
      UIComponent.Label(...
        'Parent',this.h.trigger.pannel,...
        'Position',[10 80 75 25],...
        'String','Threshold:');
      this.h.trigger.threshold = UIComponent.TextField(...
        'Callback',@this.setTrigger,...
        'Parent',this.h.trigger.pannel,...
        'Position',[85 80 64 25],...
        'Value','0');
      UIComponent.Label(...
        'Parent',this.h.trigger.pannel,...
        'Position',[10 45 40 25],...
        'String','Edge:');
      this.h.trigger.edge = UIComponent.ComboBox(...
        'Callback',@this.setTrigger,...
        'Parent',this.h.trigger.pannel,...
        'Position',[50 45 99 25],...
        'String',{'rising','falling'});
      UIComponent.Label(...
        'Parent',this.h.trigger.pannel,...
        'Position',[10 10 60 25],...
        'String','Position:');
      this.h.trigger.position = UIComponent.Spinner(...
        'Callback',@this.setTrigger,...
        'Increment',.01,...
        'Min',0,...
        'Max',1,...
        'NumberFormat','0%',...
        'Parent',this.h.trigger.pannel,...
        'Position',[70 10 79 25],...
        'Value',.5);
      
      % Control
      this.h.control.pannel = UIComponent.Panel(...
        'Parent',this.h.window);
      this.h.control.start_single = UIComponent.Button(...
        'Callback',@this.start,...
        'Parent',this.h.control.pannel,...
        'Position',[10 56 65 35],...
        'String','Single',...
        'Visible','off');
      this.h.control.start_continuous = UIComponent.Button(...
        'Callback',@this.start,...
        'Parent',this.h.control.pannel,...
        'Position',[85 56 65 35],...
        'String','Cont.',...
        'Visible','off');
      this.h.control.stop = UIComponent.Button(...
        'Callback',@this.stop,...
        'Parent',this.h.control.pannel,...
        'Position',[10 56 140 35],...
        'String','Stop');
      this.h.control.export = UIComponent.Button(...
        'Callback',@this.export,...
        'Enable','off',...
        'Parent',this.h.control.pannel,...
        'Position',[10 12 140 35],...
        'String','Export');
      
      % Timer
      this.h.timer = timer(...
        'ExecutionMode','FixedRate',...
        'Period',1/25,...
        'TimerFcn',@this.timerFcn);
      
      % Connect to the PicoScope, allowing only one instance
      try
        global picoScope_instance %#ok<TLEV>
        if picoScope_instance == 1
          error('InterfacePicoScope:OneInstanceAllowed',...
            'Only one instance of the PicoScope interface is allowed.');
        end
        this.h.pico = PicoScope();
        this.h.window.Name = ['Interface PicoScope ' this.h.pico.VariantInfo ...
          '  |  ' this.h.pico.IDN '  |  Laboratoire de physique  |  hepia'];
        picoScope_instance = 1;
      catch e
        jerrordlg(e.message);
        this.closeRequestFcn();
        if isdeployed
          return
        else
          rethrow(e);
        end
      end
      
      % Set defaults
      this.setTime();
      
      % Start
      start(this.h.timer);
      this.start(this.h.control.start_continuous);
      
      % Show the main window and get the JFrame
      jframe = UIComponent.getJFrame(this.h.window);
      jframe.setMinimumSize(jframe.getSize());
      
    end
    
  end
  
  methods (Access = private)
    
    function closeRequestFcn(this,~,~)
      global picoScope_instance
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      stop(this.h.timer);
      delete(this.h.timer);
      try %#ok<TRYNC>
        delete(this.h.pico);
        picoScope_instance = 0;
      end
      close(this.h.window,'force');
    end
    
    function sizeChangedFcn(this,~,~)
      if ~all(this.h.window.Position(3:4) == this.d.size)
        this.d.size = this.h.window.Position(3:4);
        this.h.axes_A.Position = [65 this.d.size(2)/2+54 this.d.size(1)-274 this.d.size(2)/2-84];
        this.h.axes_B.Position = [65 60 this.d.size(1)-274 this.d.size(2)/2-84];
        this.h.logo.Position = [this.d.size-[169 91] 140 61];
        this.h.A.pannel.Position = [this.d.size-[179 218] 162 95];
        this.h.B.pannel.Position = [this.d.size-[179 338] 162 95];
        this.h.time.pannel.Position = [this.d.size-[179 423] 162 60];
        this.h.trigger.pannel.Position = [this.d.size-[179 613] 162 165];
        this.h.control.pannel.Position = [this.d.size-[179 743] 162 105];
      end
    end
    
    function setTime(this,~)
      this.d.span = this.s.span(this.h.time.span.Value);
      this.setChannels();
    end
    
    function setChannels(this,~)
      this.h.pico.stop();
      range_A = this.s.range(this.h.A.range.Value);
      coupling_A = this.h.A.coupling.String{this.h.A.coupling.Value};
      range_B = this.s.range(this.h.B.range.Value);
      coupling_B = this.h.B.coupling.String{this.h.B.coupling.Value};
      this.h.pico.setChannel(1,range_A,coupling_A);
      this.h.pico.setChannel(2,range_B,coupling_B);
      this.d.info.ChannelA = this.h.pico.ChannelA;
      this.d.info.ChannelB = this.h.pico.ChannelB;
      this.h.axes_A.YLim = [-1 1]*this.s.range(this.h.A.range.Value);
      this.h.axes_B.YLim = [-1 1]*this.s.range(this.h.B.range.Value);
      if this.d.span < 1
        if ~strcmp(this.d.info.ChannelA,'off') && ~strcmp(this.d.info.ChannelB,'off')
          this.d.n = 8064;
        else
          this.d.n = 16256;
        end
        this.d.stream = 0;
        this.h.trigger.channel.Enable = 'on';
      else
        this.d.n = 32768;
        this.d.stream = 1;
        this.h.trigger.channel.Value = 1;
        this.h.trigger.channel.Enable = 'off';
      end
      this.d.dt = this.d.span/this.d.n;
      if this.d.n == 8064 && this.d.dt <= this.h.pico.Timebase
        this.d.dt = 2*this.h.pico.Timebase;
      end
      this.setTrigger();
    end
    
    function setTrigger(this,~)
      this.h.pico.stop();
      channel = this.h.trigger.channel.Value-1;
      threshold = unit2double(this.h.trigger.threshold.Value,'V');
      this.h.trigger.threshold.Value = double2unit(threshold,3,'V');
      edge = this.h.trigger.edge.String{this.h.trigger.edge.Value};
      this.d.position = this.h.trigger.position.Value;
      span = [0 this.d.span];
      if ~this.d.stream
        span = span-this.d.span*this.d.position;
      end
      set([this.h.axes_A this.h.axes_B],'XLim',span);
      set([this.h.trace_A(2:3) this.h.trace_B(2:3)],'XData',NaN,'YData',NaN);
      if channel
        this.h.trigger.threshold.Enable = 'on';
        this.h.trigger.edge.Enable = 'on';
        this.h.trigger.position.Enable = 'on';
        if channel == 1
          set(this.h.trace_A(2),'XData',0,'YData',this.h.axes_A.YLim(2));
          set(this.h.trace_A(3),'XData',this.h.axes_A.XLim(2),'YData',threshold);
        else
          set(this.h.trace_B(2),'XData',0,'YData',this.h.axes_B.YLim(2));
          set(this.h.trace_B(3),'XData',this.h.axes_B.XLim(2),'YData',threshold);
        end
      else
        this.h.trigger.threshold.Enable = 'off';
        this.h.trigger.edge.Enable = 'off';
        this.h.trigger.position.Enable = 'off';
      end
      for i = 0:31
        if this.h.pico.Timebase*2^i >= this.d.dt
          break
        end
      end
      delay = -100*this.d.position*this.d.span/(this.d.n*this.h.pico.Timebase*2^i);
      this.h.pico.setTrigger(channel,threshold,edge,delay);
      this.d.info.Trigger = this.h.pico.Trigger;
      if this.d.mode == 2
        this.run();
      end
    end
    
    function start(this,o)
      switch o
        case this.h.control.start_single
          this.d.mode = 1;
        case this.h.control.start_continuous
          this.d.mode = 2;
      end
      this.run();
      this.h.control.start_single.Visible = 'off';
      this.h.control.start_continuous.Visible = 'off';
      this.h.control.stop.Visible = 'on';
      this.h.control.export.Enable = 'off';
    end
    
    function stop(this,~)
      this.h.pico.stop();
      this.d.mode = 0;
      this.h.control.stop.Visible = 'off';
      this.h.control.start_single.Visible = 'on';
      this.h.control.start_continuous.Visible = 'on';
      this.h.control.export.Enable = 'on';
    end
    
    function run(this)
      if this.d.stream
        this.h.pico.stop();
        this.d.trace_A = [];
        this.d.trace_B = [];
        this.h.pico.runStreaming(this.d.n,this.d.dt);
      else
        this.h.pico.runBlock(this.d.n,this.d.dt);
      end
    end
    
    function export(this,~)
      filter = {'*.csv','Comma-separated values';...
        '*.txt','Tabulation-separated values';...
        '*.pdf','PDF plot'};
      [f,p,i] = uiputfile(filter,'Save as',this.d.path);
      if ~f
        return
      end
      this.h.window.Pointer = 'watch';
      drawnow();
      [p,n,e] = fileparts([p f]);
      this.d.path = [p '/'];
      switch i
        case 1
          ext = '.csv';
          sep = ',';
        case 2
          ext = '.txt';
          sep = sprintf('\t');
        case 3
          ext = '.pdf';
      end
      if ~strcmpi(e,ext)
        e = [e ext];
      end
      file = fullfile(this.d.path,[n e]);
      switch ext
        case {'.csv','.txt'}
          f = fopen(file,'w');
          fprintf(f,'%% %s\n%% %s\n%%\n',this.h.window.Name,datestr(now));
          fprintf(f,'%% Channel A: %s\n',strrep(this.d.info.ChannelA,',',' /'));
          fprintf(f,'%% Channel B: %s\n',strrep(this.d.info.ChannelB,',',' /'));
          fprintf(f,'%% Trigger: %s\n',strrep(this.d.info.Trigger,',',' /'));
          fprintf(f,'%%\n%% Time (s)%sChannel A (V)%sChannel B (V)\n',sep,sep);
          for i = 1:min([length(this.d.x) ceil(this.d.span/diff(this.d.x(1:2)))+1]);
            fprintf(f,'%.9g%s%.9g%s%.9g\n',...
              this.d.x(i),sep,...
              this.d.trace_A(i),sep,...
              this.d.trace_B(i));
          end
          fclose(f);
        case '.pdf'
          f = figure('Visible','off');
          a(1) = subplot(2,1,1,'Parent',f);
          a(2) = subplot(2,1,2,'Parent',f);
          c = sscanf(this.s.color,'%2X')/255;
          plot(a(1),this.d.x,this.d.trace_A,'Color',c);
          plot(a(2),this.d.x,this.d.trace_B,'Color',c);
          span = [0 this.d.span];
          if ~this.d.stream
            span = span-this.d.span*this.d.position;
          end
          set(a,...
            'XLim',span,...
            'XGrid','on','YGrid','on',...
            'XMinorGrid','on','YMinorGrid','on');
          a(1).YLim = [-1 1]*this.s.range(this.h.A.range.Value);
          a(2).YLim = [-1 1]*this.s.range(this.h.B.range.Value);
          set([a(1).XLabel a(2).XLabel],'String','Time (s)');
          a(1).YLabel.String = this.h.axes_A.YLabel.String;
          a(2).YLabel.String = this.h.axes_B.YLabel.String;
          exportfig(f,file,[297 210],10);
          close(f);
      end
      this.h.window.Pointer = 'arrow';
    end
    
    function timerFcn(this,~,~)
      if this.d.mode == 0
        return
      end
      last_values = 1;
      if this.d.stream
        try
          [dt,A,B,last_values] = this.h.pico.getStreamingLastValues();
        catch
          return
        end
        this.d.trace_A = [this.d.trace_A ; A];
        this.d.trace_B = [this.d.trace_B ; B];
        this.d.x = dt*(0:length(this.d.trace_A)-1)';
        if length(this.d.x) >= this.d.n
          last_values = 1;
        end
      else
        if this.h.pico.isready()
          try
            [x,this.d.trace_A,this.d.trace_B] = this.h.pico.getValues(this.d.n);
            this.d.x = x-this.d.span*this.d.position;
          catch e
            jwarndlg(e.message);
            return
          end
        else
          return
        end
      end
      this.h.trace_A(1).XData = this.d.x;
      this.h.trace_A(1).YData = this.d.trace_A;
      this.h.trace_B(1).XData = this.d.x;
      this.h.trace_B(1).YData = this.d.trace_B;
      if last_values
        if this.d.mode == 1
          this.stop();
        else
          this.run();
        end
      end
    end
    
  end
  
end
