clc;
clear all;
% ========================================================================
% To improve the performance of your ADALM-PLUTO radio, make these 
% adjustments on your host computer:
% -> Turn off antivirus and firewall software.
% -> Turn off all nonessential background processes on your computer.
% -> Use USB for radio connection.

% -------------- PLUTO PARAMETERS -----------
% Power DC Input (USB):4.5 V to 5.5 V
% ADC and DAC Sample Rate: 65.2 kSPS to 61.44 MSPS
% ADC and DAC Resolution: 12 bits
% Frequency Accuracy: ±25 ppm
% Tuning Range: 325 MHz to 3800 MHz
% Antennas Bandwidth: 824 MHz to ~894 MHz / 1710 MHz to ~2170 MHz
% Up to 20 MHz of instantaneous bandwidth (complex I/Q)
% Tx Power Output: 7 dBm
% Rx Noise Figure: <3.5 dB
% Rx and Tx Modulation Accuracy (EVM): –34 dB (2%)
% RF Shielding: None
% Digital USB2.0 On-the-Go
% Core: Single ARM Cortex®-A9 @ 667 MHz
% FPGA Logic Cells: 28k
% DSP Slices:80
% DDR3L: 4 Gb (512 MB)
% QSPI Flash: 256 Mb (32 MB)
% Temperature: 10°C to 40°C

% ------------- RADAR PARAMETERS ------------
c = 3e8;        % [m/s] Velocidad de la luz
fc = 2.4e9;     % [Hz] Frecuencia de la portadora
lambda = c/fc;
tau = 0.001;    % [s] Duración del pulso
PRI = 1*tau;    % [s] Pulse Repetition Interval
PRF = 1/PRI;
beta = 500e3;   % [Hz] Ancho de banda de la chirp
fs = 2.5e6;     % [S/s] Frecuencia de muestreo de la banda base
% "Overflows generally come from running at too high a sample rate
% for the computer to handle (MATLAB) or for the USB interface to
% transfer." - Travis

L = fs*PRI;           % Número de celdas de rango
delta_R = c/(2*beta); % [m] Resolución en rango: primer cero de la función ambigüedad
R_unam = c*PRI/2;     % [m] Rango sin ambigüedad
celda_R = c/(2*fs);   % [m] Tamaño de la celda de rango
delta_f = 1/tau;      % [Hz] Resolución en frecuencia: primer cero de la función ambigüedad

pulsosTot = 100;      % Número total de pulsos a recolectar
pulsos = 1;          % Número de pulsos a analizar
frameSize = (1/(10*PRI))*(PRI*fs);  % frameSize = SamplesPerFrame = 10 pulsos por frame
if(frameSize<3660)
    %The default is 3660, which represents 10 Ethernet packets
    warning('Using less than 3660 samples per frame can yield poor performance')
end
framesToCollect = pulsosTot/(frameSize/(PRI*fs));
data = zeros(frameSize, framesToCollect);
fig = 0; % índice para figuras
of_count = 0; % contador de overflows

t = (0:1/fs:PRI-(1/fs)).'; % Tiempo de muestreo para un pulso


% ========================================================================
% -------------- RADIO PARAMETERS ---------------
% Set up receiver
rx=sdrrx('Pluto',...
         'CenterFrequency',fc,...
         'GainSource','AGC Fast Attack',...
         'ChannelMapping',1,...
         'BasebandSampleRate',fs,...
         'OutputDataType','int16',...
         'SamplesPerFrame',frameSize,...
         'ShowAdvancedProperties',true,...
         'BISTLoopbackMode','Disabled');%Digital Tx -> Digital Rx');
%          'BISTToneInject','Tone Inject Rx',...
%          'BISTSignalGen','Tone',...
%          'BISTToneFreq','Fs/32',...
%          'BISTToneLevel','0');

% Set up transmitter
tx = sdrtx('Pluto',...
           'CenterFrequency',fc,...
           'Gain',-10,...
           'ChannelMapping',1,...
           'BasebandSampleRate',fs,...
           'ShowAdvancedProperties',true,...
           'BISTLoopbackMode','Disabled');%Digital Tx -> Digital Rx');
%            'BISTToneInject','Tone Inject Rx',...
%            'BISTSignalGen','Tone',...
%            'BISTToneFreq','Fs/32',...
%            'BISTToneLevel','0');
tx_inicial = zeros(size(t));
tx.transmitRepeat(tx_inicial);

% ========================================================================
% ---------------- WAVE ----------------
% Generate wave
% sine1 = dsp.SineWave('Frequency',4000e3,...
%                      'SampleRate',rx.BasebandSampleRate,...
%                      'SamplesPerFrame', 2^10,...
%                      'ComplexOutput', true);         

% chirpDSPtool = dsp.Chirp('Type','Linear', ...
%                          'SweepDirection','Unidirectional',...
%                          'InitialFrequency',0, ...
%                          'TargetFrequency',2.5e6, ...
%                          'TargetTime',0.000025, ... %'SweepTime',1, ...
%                          'InitialPhase',0, ...
%                          'SampleRate',rx.BasebandSampleRate, ...
%                          'SamplesPerFrame',2^10, ...
%                          'OutputDataType','double');

chirp = zeros(length(t),1);
chirp = exp(1i*pi*beta*t.^2/tau).*((0 <= t) & (t <= tau));
sine = exp(1i*(fs/400)*t);
y = square(beta*t); 
wave = chirp;

fig = fig+1;
figure(fig);
plot(t*1000,real(wave),t*1000,imag(wave));
title('Señal transmitida (1 período)');
legend('Parte real','Parte imaginaria');
xlabel('Tiempo [ms]');
ylabel('Amplitud');

%Pass data through radio
tx.release();
tx.transmitRepeat(wave); 
tic

% ----------- VISUALIZATION ---------
% Setup time scope
% samplesPerStep = rx.SamplesPerFrame/rx.BasebandSampleRate;
% steps = 2;
% scopeTx = dsp.TimeScope(1,... % Número de ondas a plotear
%                         'SampleRate', rx.BasebandSampleRate,...
%                         'TimeSpan', tau,...%0.000025*steps,...
%                         'BufferLength', rx.SamplesPerFrame,...
%                         'ShowLegend',true,...
%                         'ChannelNames',{'RealTx' 'ImagTx'});
% 
% scopeRx = dsp.TimeScope(1,... % Número de ondas a plotear
%                         'SampleRate', rx.BasebandSampleRate,...
%                         'TimeSpan', tau,...%0.000025*steps,...
%                         'BufferLength', rx.SamplesPerFrame,...
%                         'ShowLegend',true,...
%                         'ChannelNames',{'RealRx' 'ImagRx'});
%        
% for k=1:steps
%     scopeTx(wave);
%     scopeRx(rx());
% end
%  
% Set up spectrum analyzer
% sa = dsp.SpectrumAnalyzer(2,...
%                           'ViewType','Spectrum',...
%                           'SampleRate',rx.BasebandSampleRate,...
%                           'YLimits',[-40,100]);
%                       
% for k=1:1e2
%   sa(wave,rx()); 
% end


% ======================================================================== 
% -------------- ANALISYS -------------------
% Perform data collection then offline processing
% Collect all frames in continuity
toc
 for frame = 1:framesToCollect
     [d,valid,of] = rx(); % d: datos (frame)
     % Collect data without overflow and is valid
     if  ~valid
          warning('Data invalid')
     elseif of
         warning('Overflow occurred')
         of_count = of_count+1;
         frame
     else
          data(:,frame) = d; % arma la matriz de frames
    end
 end
 of_count
 
% % Process new live data
% sa1 = dsp.SpectrumAnalyzer(1,...
%                            'SampleRate',rx.BasebandSampleRate,...
%                            'YLimits',[-30,80]);
% for frame = 1:framesToCollect
%     sa1(data(:,frame)); % Algorithm processing
% end

matRadar = reshape(data,[PRI*fs,pulsosTot]); % Matriz Radar (LxM)

% offset = 2000;
% for pulso=1:pulsosTot
%     AA = [matRadar(:,pulso);matRadar(:,pulso)];
%     A = AA(offset:L+offset-1);
%     matRadar(:,pulso) = matRadar(:,pulso) + A; 
% end

% % Calcula y elimina el offset de la matriz radar:
% [V,I] = max(abs(Y_t));
% offset = I;
% for k=1:pulsosTot
%     for i=1:offset
%         temp = matRadar(1,k);
%         for j=2:L
%             matRadar(j-1,k) = matRadar(j,k);
%         end
%         x_t(L,k) = temp;
%     end
% end

 
% ------------------------------------------------------------------------
% Gráfica en el tiempo de la señal recibida:
fig = fig+1;
for pulso=1:pulsos
x_t = matRadar(:,pulso);
x_real = real(x_t);
x_imag = imag(x_t);
figure(fig);
plot(t*1000,x_real,t*1000,x_imag);
title(strcat('Señal recibida -',' Pulso=',num2str(pulso)));
legend('Parte real','Parte imaginaria');
xlabel('Tiempo [ms]');
ylabel('Amplitud');
end

% ------------------------------------------------------------------------
% Componentes en frecuencia de la señal recibida:
n0 = length(matRadar(:,1)); % Calcula el tamaño de la matriz de datos de la chirp
n = nextpow2(n0);     % Saca la potencia de 2 que le sigue
n = 2^n;              % Cantidad de puntos para la FFT
frec = (-fs/2:fs/n:fs/2-1);             % Escala de frecuencia
fig = fig+1;
for pulso=1:pulsos
espectroChirp = fft(matRadar(:,pulso),n); % length(chirp)<N -> se completa con ceros (zero-padding)
espectroChirp = fftshift(espectroChirp);% Corre la frecuencia cero al centro del espectro
espectroChirp = abs(espectroChirp);     % Valor absoluto de componentes reales e imaginarias
potEspectroChirp = (espectroChirp.^2);  % Potencia
figure(fig);
plot(frec/1e6,10*log10(potEspectroChirp)); % Gráfica del espectro en escala dB
title(strcat('Señal recibida - Componentes en frecuencia -',' Pulso=',num2str(pulso)));
xlabel('Frecuencia [MHz]');
ylabel('Potencia [dB]');
end

% ------------------------------------------------------------------------
% Espectrograma:
window = 2^7;   % La función "chirp" es dividida en segmentos de longitud "window", y se aplica una ventana Hamming de igual longitud
n_overlap = 1;  % Número de muestras que cada segmento de la función "chirp" se superpone
n_fft = 2^8;    % Número de puntos de frecuencia utilizados para calcular la transformada discreta de Fourier

fig = fig+1;
for pulso=1:pulsos
[S,F,T] = spectrogram(matRadar(:,pulso),window,n_overlap,n_fft,fs);
pot = abs(fftshift(S,1)).^2; % Cálculo de la potencia
figure(fig);
pcolor(T*1000,(F-fs/2)/1e6,10*log10(pot));
shading flat;
title(strcat('Variación de la frecuencia en el tiempo -',' Pulso=',num2str(pulso)));
xlabel('Tiempo [ms]');
ylabel('Frecuencia [MHz]');
end

% ------------------------------------------------------------------------
% Procesamiento con filtro adaptado:
% Para evitar el solapamiento de esta convolucion circular, las
% transformadas se deben hacer duplicando el largo de la sequencia de
% datos y completando con ceros. Pero esto lo hace el comando fft por si
% solo si le piden una transformada mas larga que los datos. Ej, si L es
% el largo de la sequencia de datos a transformar, usar
% Lp = 2^(nextpow2(L)+1); para calcular la fft.
Lp = 2^(nextpow2(L)+1);

% Procesamiento para 1 pulso:
% Conformación del filtro adaptado
h_t = wave; % Filtro adaptado a partir de una señal chirp de referencia
H_f = conj(fft(h_t,Lp));% Espectro del filtro adaptado
x_t = matRadar(:,pulso);% Columna 1 de la matriz radar (señal recibida)
X_f = fft(x_t,Lp);      % Espectro de la señal recibida
Y_f = X_f.*H_f;         % Espectro de la salida del filtro
Y_t = ifft(Y_f,Lp);     % Señal de salida del filtro adaptado
Y_t = Y_t(1:L);         % Salida acotada

fig = fig+1;
for pulso = 1:pulsos
    x_t = matRadar(:,pulso);% Columna 1 de la matriz radar (señal recibida)
    X_f = fft(x_t,Lp);      % Espectro de la señal recibida
    Y_f = X_f.*H_f;         % Espectro de la salida del filtro
    Y_t = ifft(Y_f,Lp);     % Señal de salida del filtro adaptado
    Y_t = Y_t(1:L);         % Salida acotada
    figure(fig);
    plot(t*1000,real(Y_t),t*1000,abs(Y_t));
    title(strcat('Respuesta del Filtro Adaptado -',' Pulso=',num2str(pulso)));
    xlabel('Tiempo [ms]');
    ylabel('Amplitud');
end

% % ------------------------------------------------------------------------
% % Gráfico de la intensidad de los datos correspondientes a un pulso:
% r = 1:L;
% f = f+1;
% for pulso = 1:pulsos
% X_r = 20*log10(abs(matRadar(:,pulso)));
% figure(f);
% plot(r,X_r);
% title(strcat('Pulso=',num2str(pulso)));
% xlabel('Celdas de rango');
% ylabel('Intensidad');
% legend({'Datos'});
% end

% ------------------------------------------------------------------------
% Procesamiento con filtro adaptado para un bloque de M pulsos:
M = pulsosTot;          % Cantidad de pulsos a analizar
H_f = H_f*ones(1,M);    % Filtro adaptado extendido (repetido en M columnas)
x_t = matRadar(:,1:M);  % Señal recibida compuesta por M pulsos
X_f = fft(x_t,Lp);      % Espectro de la señal compuesta de M pulsos
Y_f = X_f.*H_f;         % Espectro de la salida del filtro
y_t = ifft(Y_f,Lp);     % Señal de salida del filtro
y_t = y_t(1:L,:);       % Señal acotada
t_L = (0:M-1);          % Escala de tiempo lento
t_R = (0:L-1);          % Escala de tiempo rápido
fig = fig+1;
figure(fig);
pcolor(t_L,t_R,20*log10(abs(y_t))); % tomo el logaritmo para exagerar los colores en el gráfico
shading flat;
title('Tiempo lento vs tiempo rápido');
xlabel('Pulsos (tiempo lento)');
ylabel('Celdas en rango (tiempo rápido)');

% % ------------------------------------------------------------------------
% % Generar y graficar una imagen de rango/Doppler usando los primeros 256
% % pulsos de la matriz VV. Repetir para las siguientes dos ventanas de 256 
% % pulsos y observar el cambio de frecuencia Doppler para el objetivo y el
% % clutter.
% f = f+1;
% for i=1:3
%     desde = 1+32*(i-1);
%     hasta = 32*i;
%     v = matRadar(:,desde:hasta);
%     [l,m] = size(v);
%     Z = fft(v,m,2);
%     Z = fftshift(Z,2);
%     rango = (0:l-1)*c/(2*fs); % Escala de Rango [m]
%     doppler = (-m/2:m/2-1)*(1/(m*PRI)); % Escala de frecuencia Doppler [Hz]
%     figure(f);
%     subplot(1,3,i);
%     pcolor(doppler,rango,20*log10(abs(Z)));
%     shading flat;
%     title(strcat('Pulsos: ',num2str(desde),'~',num2str(hasta)));
%     xlabel('Frecuencia Doppler [Hz]');
%     ylabel('Rango [m]');
% end