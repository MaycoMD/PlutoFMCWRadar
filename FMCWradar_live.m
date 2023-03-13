clc;
clear all;
close all;
% ========================================================================
% ------------- RADAR PARAMETERS ------------
c = 3e8;        % [m/s] Velocidad de la luz
fc = 2.4e9;     % [Hz] Frecuencia de la portadora
lambda = c/fc;  % [m] Longitud de onda
tau = 0.001;    % [s] Duración del pulso
PRI = 1*tau;    % [s] Pulse Repetition Interval
PRF = 1/PRI;
beta = 5e6;   % [Hz] Ancho de banda de la chirp
fs = 2.5e6;%5.0e6;     % [S/s] Frecuencia de muestreo de la banda base
% "Overflows generally come from running at too high a sample rate
% for the computer to handle (MATLAB) or for the USB interface to
% transfer." - Travis

L = fs*PRI;           % Número de celdas de rango (Tamaño del pulso)
delta_R = c/(2*beta); % [m] Resolución en rango: primer cero de la función ambigüedad
R_unam = c*PRI/2;     % [m] Rango sin ambigüedad
celda_R = c/(2*beta)   % [m] Tamaño de la celda de rango
delta_f = 1/tau;      % [Hz] Resolución en frecuencia: primer cero de la función ambigüedad

pulsosTot = 1000;     % Número total de pulsos a recolectar
pulsos = 1000;         % Número de pulsos a analizar
frameSize = (1/(10*PRI))*(PRI*fs);  % frameSize = SamplesPerFrame = 10 pulsos por frame
if(frameSize<3660)
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

% Set up transmitter
tx = sdrtx('Pluto',...
           'CenterFrequency',fc,...
           'Gain',0,...
           'ChannelMapping',1,...
           'BasebandSampleRate',fs,...
           'ShowAdvancedProperties',true,...
           'BISTLoopbackMode','Disabled');%Digital Tx -> Digital Rx');

tx_inicial = zeros(size(t));
tx.transmitRepeat(tx_inicial);

% ========================================================================
% ---------------- WAVE ----------------
chirp = zeros(length(t),1);
chirp = exp(1i*pi*beta*t.^2/tau).*((0 <= t) & (t <= tau));
sine = exp(1i*(fs/400)*t);
y = square(beta*t); 
wave = chirp;

%Pass data through radio
tx.release();
tx.transmitRepeat(wave); 

% ======================================================================== 
% -------------- ANALISYS -------------------
% Conformación del filtro adaptado
Lp = 2^(nextpow2(L)+1);
h_t = wave; % Filtro adaptado a partir de una señal chirp de referencia
H_f = conj(fft(h_t,Lp)); % Espectro del filtro adaptado

figure
xlabel('Tiempo [ms]')
ylabel('Amplitud')
%hold on
% Procesamiento para los pulsos:
frame = 1;
while(1)
    [d,valid,of] = rx(); % d: datos (frame)
    if  ~valid
        warning('Data invalid')
    elseif of
        warning('Overflow occurred')
    else
        x_t = d(1:L);
        X_f = fft(x_t,Lp);      % Espectro de la señal recibida
        Y_f = X_f.*H_f;         % Espectro de la salida del filtro
        Y_t = ifft(Y_f,Lp);     % Señal de salida del filtro adaptado
        Y_t = Y_t(1:L);         % Salida acotada
        plot(t*1000,abs(Y_t));  %
        title(strcat('Respuesta del Filtro Adaptado -',' Frame=',num2str(frame)));
        axis([0 1 0 2.5e6])
        drawnow;
        frame = frame+1;
    end
end