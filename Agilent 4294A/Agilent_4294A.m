%
%  Agilent_4294A.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef Agilent_4294A < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
    ftp
    rtifc
  end
  
  methods
    
    function this = Agilent_4294A(IP)
      s = java.net.Socket();
      try
        s.connect(java.net.InetSocketAddress(IP,5025),3000);
        s.setSoTimeout(3000);
        this.tty.inputStream = java.io.BufferedReader(java.io.InputStreamReader(s.getInputStream()));
        this.tty.outputStream = java.io.PrintStream(s.getOutputStream(),1);
        this.IDN = this.query('*IDN?');
        this.ftp = org.apache.commons.net.ftp.FTPClient();
        this.ftp.connect(IP,21);
        this.ftp.login('anonymous','');
      catch
        error('Agilent_4294A:CommunicationError',...
          'Unable to open the network connection.');
      end
      if isempty(regexp(this.IDN,',4294A,','once'))
        error('Agilent_4294A:InstrumentNotFound',...
          'The instrument at IP %s is not an Agilent 4294A.',IP);
      end
      d = which('-all','rtifc');
      d = cd(fileparts(d{1}));
      this.rtifc = @rtifc;
      cd(d);
    end
    
    function delete(this)
      try %#ok<TRYNC>
        this.tty.inputStream.close();
        this.tty.outputStream.close();
      end
      try %#ok<TRYNC>
        this.ftp.disconnect();
      end
    end
    
    function c = getEquivCircuit(this)
      s = this.query('EQUC?');
      c.circuit = s(4);
      for i = {'R1','L1','C1','C0'}
        c.(i{1}) = this.query(['DEFEC' i{1} '?'],'%f');
      end
    end
    
    function s = getScreen(this)
      tmp = tempname();
      stream = java.io.FileOutputStream(java.io.File(tmp));
      this.ftp.retrieveFile('/data/screen.tif',stream);
      stream.close();
      d = this.rtifc(struct('filename',tmp,'index',1,'pixelregion',[]));
      delete(tmp);
      m = zeros(16,3,'uint8');
      m(1,:) = [255 255 255]; % Background
      m(4,:) = [192 192 192]; % Grid
      m(9,:) = [255 0 0];     % Equivalent circuit
      m(14,:) = [255 0 0];    % Equivalent circuit
      d = double(d)+1;
      c = zeros(size(d),'uint8');
      s = zeros(size(d,1),size(d,2),3,'uint8');
      for i = 1:3
        c(:) = m(d,i);
        s(:,:,i) = c;
      end
    end
    
    function [x,A,B,info] = getTrace(this)
      info.Measure = this.query('MEAS?');
      info.SweepParameter = this.query('SWPP?');
      n = this.query('POIN?','%f');
      a = this.query('STAR?','%f');
      b = this.query('STOP?','%f');
      switch this.query('SWPT?')
        case 'LIN'
          x = a:(b-a)/(n-1):b;
          info.XAxisLog = false;
        case 'LOG'
          a = log10(a);
          b = log10(b);
          x = 10.^(a:(b-a)/(n-1):b);
          info.XAxisLog = true;
        otherwise
          error('Agilent_4294A:UnsupportedSweepType','Unsupported sweep type.');
      end
      tmp = tempname();
      stream = java.io.FileOutputStream(java.io.File(tmp));
      this.ftp.retrieveFile('/data/data_dt.dat',stream);
      stream.close();
      h = fopen(tmp,'r','ieee-be.l64');
      fseek(h,29,-1);
      A = fread(h,2*n,'double');
      A = A(1:2:end)+1i*A(2:2:end);
      fseek(h,10,0);
      B = fread(h,2*n,'double');
      B = B(1:2:end)+1i*B(2:2:end);
      fclose(h);
      delete(tmp);
      if strcmp(info.SweepParameter,'FREQ')
        info.XLabel = 'Frequency (Hz)';
      else
        info.Frequency = this.query('CWFREQ?','%f');
      end
      if strcmp(info.SweepParameter,'OLEV')
        switch this.query('POWMOD?')
          case 'VOLT'
            info.XLabel = 'Oscillator voltage (V)';
          case 'CURR'
            info.XLabel = 'Oscillator current (A)';
        end
      else
        switch this.query('POWMOD?')
          case 'VOLT'
            info.OscVoltage = this.query('POWE?','%f');
          case 'CURR'
            info.OscCurrent = this.query('POWE?','%f');
        end
      end
      if strcmp(info.SweepParameter,'DCB')
        switch this.query('DCMOD?')
          case {'VOLT','CVOLT'}
            info.XLabel = 'DC bias voltage (V)';
          case {'CURR','CCURR'}
            info.XLabel = 'DC bias current (A)';
        end
      else
        if this.query('DCO?','%d')
          info.DCBiasMode = this.query('DCMOD?');
          switch info.DCBiasMode
            case {'VOLT','CVOLT'}
              info.DCBiasVoltage = this.query('DCV?','%f');
            case {'CURR','CCURR'}
              info.DCBiasCurrent = this.query('DCI?','%f');
          end
        end
      end
      switch info.Measure
        case 'IRIM'
          info.ALabel = 'Equivalent series resistance R (\Omega)';
          info.BLabel = 'Equivalent series reactance X (\Omega)';
        case 'LSR'
          info.ALabel = 'Equivalent series inductance Ls (H)';
          info.BLabel = 'Equivalent series resistance Rs (\Omega)';
        case 'LSQ'
          info.ALabel = 'Equivalent series inductance Ls (H)';
          info.BLabel = 'Quality factor Q';
        case 'CSR'
          info.ALabel = 'Equivalent series capacitance Cs (F)';
          info.BLabel = 'Equivalent series resistance Rs (\Omega)';
        case 'CSQ'
          info.ALabel = 'Equivalent series capacitance Cs (F)';
          info.BLabel = 'Quality factor Q';
        case 'CSD'
          info.ALabel = 'Equivalent series capacitance Cs (F)';
          info.BLabel = 'Dissipation factor D';
        case 'AMPH'
          info.ALabel = 'Admittance magnitude |Y| (S)';
          info.BLabel = 'Phase \theta (°)';
        case 'ARIM'
          info.ALabel = 'Equivalent parallel conductance G (S)';
          info.BLabel = 'Equivalent parallel susceptance B (S)';
        case 'LPG'
          info.ALabel = 'Equivalent parallel inductance Lp (H)';
          info.BLabel = 'Equivalent parallel conductance G (S)';
        case 'LPQ'
          info.ALabel = 'Equivalent parallel inductance Lp (H)';
          info.BLabel = 'Quality factor Q';
        case 'CPG'
          info.ALabel = 'Equivalent parallel capacitance Cp (F)';
          info.BLabel = 'Equivalent parallel conductance G (S)';
        case 'CPQ'
          info.ALabel = 'Equivalent parallel capacitance Cp (F)';
          info.BLabel = 'Quality factor Q';
        case 'CPD'
          info.ALabel = 'Equivalent parallel capacitance Cp (F)';
          info.BLabel = 'Dissipation factor D';
        case 'COMP'
          info.ALabel = 'Impedance Z (\Omega)';
          info.BLabel = 'Admittance Y (S)';
        case 'IMLS'
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Equivalent series inductance Ls (H)';
        case 'IMCS'
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Equivalent series capacitance Cs (F)';
        case 'IMLP'
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Equivalent parallel inductance Lp (H)';
        case 'IMCP'
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Equivalent parallel capacitance Cp (F)';
        case 'IMRS'
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Equivalent series resistance Rs (\Omega)';
        case 'IMQ'
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Quality factor Q';
        case 'IMD'
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Dissipation factor D';
        case 'LPR'
          info.ALabel = 'Equivalent parallel inductance Lp (H)';
          info.BLabel = 'Equivalent parallel resistance Rp (\Omega)';
        case 'CPR'
          info.ALabel = 'Equivalent parallel capacitance Cp (F)';
          info.BLabel = 'Equivalent parallel resistance Rp (\Omega)';
        otherwise
          info.ALabel = 'Impedance magnitude |Z| (\Omega)';
          info.BLabel = 'Phase \theta (°)';
      end
    end
    
    function r = query(this,q,format)
      this.tty.outputStream.println(q);
      if any(q == '?')
        try
          r = char(this.tty.inputStream.readLine());
          if nargin > 2
            r = sscanf(r,format);
          end
        catch e
          if strcmp(e.identifier,'MATLAB:Java:GenericException')
            error('Agilent_4294A:SocketException',...
              'Unable to read data from the network connection.');
          else
            rethrow(e);
          end
        end
      end
    end
    
  end
  
end
