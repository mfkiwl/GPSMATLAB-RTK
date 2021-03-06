%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function selects the optimum satellites to track for best DOP
%   Author: Saurav Agarwal   
%   Email:  saurav6@gmail.com
%   Date:   January 1, 2011  
%   Place:  Dept. of Aerospace Engg., IIT Bombay, Mumbai, India 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% References:
% 1. Enge and Mishra: Global Positioning System
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [optimum_sv_ids, min_GDOP,min_PDOP,min_HDOP,min_VDOP] = select_optimum_sats(gps_sat,gps_time,visible_sats_id,true_user_pos_ecef,initial_user_pos_estimate);

xu = initial_user_pos_estimate.x;
yu = initial_user_pos_estimate.y;
zu = initial_user_pos_estimate.z;

user_ecef_pos_estimate = struct('x',xu,'y',yu,'z',zu);

select_4_sats = nchoosek(visible_sats_id,4); % compute all possible combinations of 4 satellites from the visible ones
rows = size(select_4_sats);

for i = 1:rows
    
    for k = 1:4

         sv_id = select_4_sats(i,k);

         [sat_clk_drift,sat_clk_rel_error] = eval_sat_clock_offset(gps_sat,sv_id,gps_time); % satellite clock offset in seconds (clock drift + relativistic error)

         time_str = gps_time + sat_clk_drift + sat_clk_rel_error; % The time of tranmission from satellite as embedded in transmitted code

         [xs,ys,zs] = calc_sat_pos_ecef(gps_sat,time_str,sv_id); % The position of satellite based on ephemeris data and the time embedded in message

         computed_sat_pos_ecef = struct('x',xs,'y',ys,'z',zs);

         d = compute_distance(computed_sat_pos_ecef,user_ecef_pos_estimate); % what the receiver thinks is true pseduo range

         A(k,1) = -(xs - xu)/d;
         A(k,2) = -(ys - yu)/d ;
         A(k,3) = -(zs - zu)/d ;
         A(k,4) = -1;
         
     end; 

    [GDOP(i), PDOP(i), HDOP(i), VDOP(i)] = eval_DOP(A);  
    
end;

min_GDOP = min(GDOP);

for l = 1:rows
    if GDOP(l) == min_GDOP
        optimum_sv_ids = select_4_sats(l,:); % the satellite geometry with the min DOP is selected for tracking
        min_PDOP = PDOP(l);
        min_HDOP = HDOP(l);
        min_VDOP = VDOP(l);
    end;
end;

end