%% Attitude Estimation     %
% Author: Mattia Giurato   %
% Last review: 2016/02/25  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all 
clc

%% Data import
load('logsync.mat')
% load('IMUoutput.mat')
% load('OPTIoutput_involo.mat')

%% Estimating variances
% sigma_acc = diag(std(Accelerometer))./3
% sigma_mag = diag(std(Magnetometer))./3
% sigma_u = diag(std(Gyroscope))./3

%% Filtering loop
% IMUsample = 0.01;
IMUsample = 1/68;
sigma_acc = 0.01;
sigma_mag = 0.1;
sigma_u = 0.000001;
sigma_v = 0.001;
Po = 0.001*eye(6);

start = 0;
stop = 65;

Kalman = KalmanAHRS('SamplePeriod', IMUsample, 'sigma_acc', sigma_acc, 'sigma_mag', sigma_mag, 'sigma_u', sigma_u, 'sigma_v', sigma_v,'P', Po);
IMUquaternion = zeros(length(IMUtime), 4);
IMUomega = zeros(length(IMUtime), 3);
IMUbias = zeros(length(IMUtime), 3);
dalpha = zeros(length(IMUtime), 3);
for t = 1:length(IMUtime)
    Kalman.UpdateIMU(Gyroscope(t,:)', Accelerometer(t,:)', Magnetometer(t,:)');	% gyroscope units must be radians
    IMUquaternion(t, :) = Kalman.Quaternion;
    IMUomega(t, :) = Kalman.omehat;
    IMUbias(t, :) = Kalman.bias;
    dalpha(t, :) = Kalman.deltaX(1:3);
%     AHRS.P
end    

beta = 0.0026;
zeta = 0;
AHRS = MadgwickAHRS('SamplePeriod', IMUsample, 'Beta', beta,  'Zeta', zeta);
MADquaternion = zeros(length(IMUtime), 4);
GYRObias = zeros(length(IMUtime), 3);
for t = 1:length(IMUtime)
    AHRS.UpdateIMU(Gyroscope(t,:)-ones(1, 3)*diag(mean(Gyroscope(2800:3000,1:3))), Accelerometer(t,:));	% gyroscope units must be radians
    %AHRS.Update(Gyroscope(t,:), Accelerometer(t,:), Magnetometer(t,:));	% gyroscope units must be radians
    MADquaternion(t, :) = AHRS.Quaternion;
end

[Y, P, R] = quat2angle([IMUquaternion(:,4) IMUquaternion(:,1) IMUquaternion(:,2) IMUquaternion(:,3)]);
RPYkal = [R -P -Y];

[Y, P, R] = quat2angle([-MADquaternion(:,4) -MADquaternion(:,3) MADquaternion(:,2) MADquaternion(:,1)]);
RPYmad = [R -P -Y];

% figure('name', 'Quaternion')
% plot(IMUtime, IMUquaternion)
% title('$$\hat{q}$$','Interpreter','latex')
% grid minor
% xlabel('[s]')
% ylabel('[ ]')
% legend('q_1', 'q_2', 'q_3', 'q_4')

figure('name', 'Euler')
x1 = subplot(3,1,1);
plot(IMUtime, RPYkal(:,1))
hold on
plot(IMUtime, RPYmad(:,1))
plot(OPTItime, OPTIeuler_f(:,1))
hold off
grid minor
title('Euler Angles')
legend('\phi_{Kalman}', '\phi_{Madgwick}','\phi_{OptiTrack}')
x2 = subplot(3,1,2);
plot(IMUtime, RPYkal(:,2))
hold on
plot(IMUtime, RPYmad(:,2))
plot(OPTItime, OPTIeuler_f(:,2))
hold off
grid minor
legend('\theta_{Kalman}', '\theta_{Madgwick}','\theta_{OptiTrack}')
x3 = subplot(3,1,3);
yaw_k = unwrap(RPYkal(:,3));
plot(IMUtime, yaw_k)
hold on
yaw_m = unwrap(RPYmad(:,3));
plot(IMUtime, yaw_m)
plot(OPTItime, OPTIeuler_f(:,3));
hold off
grid minor
legend('\psi_{Kalman}', '\psi_{Madgwick}','\psi_{OptiTrack}')
xlabel('[s]')

xlim(x1,[start stop])
xlim(x2,[start stop])
xlim(x3,[start stop])

% figure('name', 'Angular speeds')
% plot(IMUtime, IMUomega)
% title('$$\hat{\omega}$$','Interpreter','latex')
% grid minor
% xlabel('[s]')
% ylabel('[rad/s]')

figure('name', 'Bias')
plot(IMUtime, IMUbias);
title('$$\beta$$','Interpreter','latex')
grid minor
xlabel('[s]')
ylabel('[rad/s]')
xlim([start stop])

% figure('name', 'dalpha')
% plot(IMUtime, dalpha)
% title('$$\delta\alpha$$','Interpreter','latex')
% grid minor
% xlabel('[s]')
% ylabel('[rad]')

%% End of code