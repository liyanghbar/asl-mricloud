% Purpose: Look Locker T1 saturation recovery model
% Author:Hongli Fan
% Date:  10/20/2017
function y = LLrecovery(beta0,x,flip_angle,TI)
if (size(x,1)==1)
    x=x(:);
end

alpha   = flip_angle/180*pi;
M0      = beta0(2);
T1      = beta0(1);
T1eff_r = 1/T1-log(cos(alpha))/TI;
Mss     = M0*(1-exp(-TI/T1))/(1-exp(-TI/T1)*cos(alpha));
for i=1:length(x)
      M    = Mss*(1-exp(-x(i).*T1eff_r));
      y(i) = M*sin(alpha);
end                                                                                                                                                                             
y = y(:);
end