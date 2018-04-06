function mm = ASL_func_gkm_pasl_looklocker(cbf,att,pasl_dur,tis,flip_angle,assum_paras)
% Purpose: pulsed ASL model
% Input
%	beta       -- parameter of the function, must have 3 elements
%                  the first element is initial value for BAT
%                  the second element is initial value for bolus duration
%                  the third element is initial value for CBF
%	x          -- input vector, time point
%	T1b        -- blood T1
%	lambda     -- tissue/blood partition coefficient
%	labeff     -- labelling efficiency
%	flip_angle -- flip angle
% Output
%   mm         -- the corresponding value
% Author: Hongli Fan
% Date:   10/11/2017

t1_blood    = assum_paras.t1_blood;
part_coef   = assum_paras.part_coef;
labl_eff    = assum_paras.labl_eff;

t_tail      = att + pasl_dur;   % time when tail of bolus arrived
t1_app       = t1_blood;        % assumption

flip_angle  = flip_angle / 180 * pi;
tis_tmp     = unique(tis);
ti_intvl    = mean( tis_tmp(2:end) - tis_tmp(1:end-1) );

r1_blood    = 1/t1_blood;
r1_app      = 1/t1_app;
r1_appeff   = r1_app - log(cos(flip_angle)) / ti_intvl;
delta_r     = r1_blood - r1_appeff;

const   = 2 * labl_eff * cbf / part_coef / 6000 / delta_r;

w1      = tis(          tis <  att                   )'; % before bolus
w2      = tis( logical((tis >= att).*(tis <  t_tail)))'; % during bolus flooding in
w3      = tis(                        tis >= t_tail  )'; % all bolus arrived

m1      = w1 * 0;
m2      = -( 1 - exp(delta_r*(w2-att)) ) .* exp(-    w2*r1_blood);
m3      = -( 1 - exp(delta_r*(w3-att)) )  * exp(-t_tail*r1_blood) .* exp(-r1_appeff*(w3-t_tail));
m2      = const * m2 * sin(flip_angle);
m3      = const * m3 * sin(flip_angle);
mm      = [m1, m2, m3]';

