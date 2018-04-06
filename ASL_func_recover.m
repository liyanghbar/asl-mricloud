function mm = ASL_func_recover(m0,t1,tp,flip_angle,m_init)
% Purpose: Look-Locker T1 saturation recovery model
% Author:Hongli Fan
% Date:  10/20/2017

if nargin == 5
    % Look-Locker T1 recovery model
    % mm = ASL_func_recover(m0,t1,tp,flip_angle,m_init)
    tis_tmp     = unique(tp);
    ti_intvl    = mean( tis_tmp(2:end) - tis_tmp(1:end-1) );
    flip_angle  = flip_angle/180*pi;
    r1_eff      = 1/t1 - log(cos(flip_angle))/ti_intvl;
    mss         = m0 * (1-exp(-ti_intvl/t1)) / (1-exp(-ti_intvl/t1)*cos(flip_angle));
    
    mm          = mss * (1 - exp(-tp*r1_eff)) * sin(flip_angle);        % sat-recover
%     mm          = mss - (mss + m0) * exp(-tp*r1_eff); % inv-recover
%     mm          = mss - (mss - m_init) * exp(-tp*r1_eff); % recover
    
elseif nargin == 3
    % Multi-delay T1 recovery model
    % mm = ASL_func_recover(m0,t1,tp)
    mm          = m0  * (1 - exp(-tp/t1));
end