model Sodium_CO2System_v3 "High temperature Sodium-sCO2 system"
  import SolarTherm.{Models,Media};
  import Modelica.SIunits.Conversions.from_degC;
  import SI = Modelica.SIunits;
  import nSI = Modelica.SIunits.Conversions.NonSIunits;
  import CN = Modelica.Constants;
  import CV = Modelica.SIunits.Conversions;
  import FI = SolarTherm.Models.Analysis.Finances;
  import SolarTherm.Types.Solar_angles;
  import SolarTherm.Types.Currency;
  extends Modelica.Icons.Example;
  //Media
  replaceable package Medium1 = Media.Sodium.Sodium_pT "Medium props for Sodium";
  replaceable package Medium2 = Media.ChlorideSalt.ChlorideSalt_pT "Medium props for Molten Salt";
  // Input Parameters
  parameter Boolean match_sam = false "Configure to match SAM output";
  parameter Boolean fixed_field = false "true if the size of the solar field is fixed";
  parameter String pri_file = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Data/Prices/aemo_vic_2014.motab") "Electricity price file";
  parameter Currency currency = Currency.USD "Currency used for cost analysis";
  parameter Boolean const_dispatch = true "Constant dispatch of energy";
  parameter String sch_file = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Data/Schedules/daily_sch_0.motab") if not const_dispatch "Discharging schedule from a file";
  // Weather data
  parameter String wea_file = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Data/Weather/example_TMY3.motab");
  parameter Real wdelay[8] = {0, 0, 0, 0, 0, 0, 0, 0} "Weather file delays";
  parameter nSI.Angle_deg lon = 133.889 "Longitude (+ve East)";
  parameter nSI.Angle_deg lat = -23.795 "Latitude (+ve North)";
  parameter nSI.Time_hour t_zone = 9.5 "Local time zone (UCT=0)";
  parameter Integer year = 1996 "Meteorological year";
  // Field
  parameter String opt_file = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Data/Optics/example_optics.motab");
  parameter Solar_angles angles = Solar_angles.elo_hra "Angles used in the lookup table file";
  parameter Real SM = 1.8 "Solar multiple";
  parameter Real land_mult = 6.16783860571 "Land area multiplier";
  parameter Boolean polar = false "True for polar field layout, otherwise surrounded";
  parameter SI.Area A_heliostat = 144.375 "Heliostat module reflective area";
  parameter Real he_av_design = 0.99 "Helisotats availability";
  parameter SI.Efficiency eff_opt = 0.6389 "Field optical efficiency at design point";
  parameter SI.Irradiance dni_des = 950 "DNI at design point";
  parameter Real C = 1046.460400794 "Concentration ratio";
  parameter Real gnd_cvge = 0.26648 "Ground coverage";
  parameter Real excl_fac = 0.97 "Exclusion factor";
  parameter Real twr_ht_const = if polar then 2.25 else 1.25 "Constant for tower height calculation";
  // Receiver
  parameter Integer N_pa_rec = 20 "Number of panels in receiver";
  parameter SI.Thickness t_tb_rec = 1.25e-3 "Receiver tube wall thickness";
  parameter SI.Diameter D_tb_rec = 40e-3 "Receiver tube outer diameter";
  parameter Real ar_rec = 18.67 / 15 "Height to diameter aspect ratio of receiver aperture";
  parameter SI.Efficiency ab_rec = 0.94 "Receiver coating absorptance";
  parameter SI.Efficiency em_rec = 0.88 "Receiver coating emissivity";
  parameter SI.RadiantPower R_des(fixed = if fixed_field then true else false) "Input power to receiver at design point";
  parameter Real rec_fr = 1.0 - 0.9569597659257708 "Receiver loss fraction of radiance at design point";
  parameter SI.Temperature rec_T_amb_des = 298.15 "Ambient temperature at design point";
  parameter SI.Temperature T_cold_set_Na = Shell_and_Tube_HX.T_Na2_design "Cold HX target temperature";
  parameter SI.Temperature T_hot_set_Na = CV.from_degC(740) "Hot Receiver target temperature";
  parameter SI.Temperature T_hot_set_Na_2 = CV.from_degC(750) "Hot Receiver target temperature";
  parameter Medium1.ThermodynamicState state_cold_set_Na = Medium1.setState_pTX(101325, T_cold_set_Na) "Cold Sodium thermodynamic state at design";
  parameter Medium1.ThermodynamicState state_hot_set_Na = Medium1.setState_pTX(101325, T_hot_set_Na) "Hot Sodium thermodynamic state at design";
  // Storage
  parameter Real t_storage(unit = "h") = 4 "Hours of storage";
  parameter SI.Temperature T_cold_set_CS = CV.from_degC(500) "Cold tank target temperature";
  parameter SI.Temperature T_hot_set_CS = CV.from_degC(720) "Hot tank target temperature";
  parameter SI.Temperature T_cold_start_CS = CV.from_degC(500) "Cold tank starting temperature";
  parameter SI.Temperature T_hot_start_CS = CV.from_degC(720) "Hot tank starting temperature";
  parameter SI.Temperature T_cold_aux_set = CV.from_degC(495) "Cold tank auxiliary heater set-point temperature";
  parameter SI.Temperature T_hot_aux_set = CV.from_degC(725) "Hot tank auxiliary heater set-point temperature";
  parameter Medium2.ThermodynamicState state_cold_set_CS = Medium2.setState_pTX(101325, T_cold_set_CS) "Cold salt thermodynamic state at design";
  parameter Medium2.ThermodynamicState state_hot_set_CS = Medium2.setState_pTX(101325, T_hot_set_CS) "Hold salt thermodynamic state at design";
  parameter Real tnk_fr = 0.01 "Tank loss fraction of tank in one day at design point";
  parameter SI.Temperature tnk_T_amb_des = 298.15 "Ambient temperature at design point";
  parameter Real split_cold = 0.7 "Starting medium fraction in cold tank";
  parameter Boolean tnk_use_p_top = true "true if tank pressure is to connect to weather file";
  parameter Boolean tnk_enable_losses = true "true if the tank heat loss calculation is enabled";
  parameter SI.CoefficientOfHeatTransfer alpha = 3 "Tank constant heat transfer coefficient with ambient";
  parameter SI.SpecificEnergy k_loss_cold = 0.15e3 "Cold tank parasitic power coefficient";
  parameter SI.SpecificEnergy k_loss_hot = 0.55e3 "Hot tank parasitic power coefficient";
  parameter SI.Power W_heater_hot = 30e8 "Hot tank heater capacity";
  parameter SI.Power W_heater_cold = 30e8 "Cold tank heater capacity";
  parameter Real tank_ar = 20 / 18.667 "storage aspect ratio";
  // Power block
  replaceable model Cycle = Models.PowerBlocks.Correlation.sCO2 "sCO2 cycle regression model";
  parameter SI.Temperature T_comp_in = 318.15 "Compressor inlet temperature at design";
  replaceable model Cooling = Models.PowerBlocks.Cooling.DryCooling "PB cooling model";
  parameter SI.Power P_gross(fixed = if fixed_field then false else true) = 111e6 "Power block gross rating at design point";
  parameter SI.Efficiency eff_blk = 0.3774 "Power block efficiency at design point";
  parameter Real par_fr = 0.099099099 "Parasitics fraction of power block rating at design point";
  parameter Real par_fix_fr = 0.0055 "Fixed parasitics as fraction of gross rating";
  parameter Boolean blk_enable_losses = true "true if the power heat loss calculation is enabled";
  parameter Boolean external_parasities = true "true if there is external parasitic power losses";
  parameter Real nu_min_blk = 0.5 "minimum allowed part-load mass flow fraction to power block";
  parameter SI.Power W_base_blk = par_fix_fr * P_gross "Power consumed at all times in power block";
  parameter SI.AbsolutePressure p_blk = 10e6 "Power block operating pressure";
  parameter SI.Temperature blk_T_amb_des = 316.15 "Ambient temperature at design for power block";
  parameter SI.Temperature par_T_amb_des = 298.15 "Ambient temperature at design point";
  parameter Real nu_net_blk = 0.9 "Gross to net power conversion factor at the power block";
  parameter SI.Temperature T_in_ref_blk = from_degC(720) "HTF inlet temperature to power block at design";
  parameter SI.Temperature T_out_ref_blk = from_degC(500) "HTF outlet temperature to power block at design";
  // Control
  parameter SI.Angle ele_min = 0.13962634015955 "Heliostat stow deploy angle";
  parameter Boolean use_wind = true "true if using wind stopping strategy in the solar field";
  parameter SI.Velocity Wspd_max = 15 if use_wind "Wind stow speed";
  parameter SI.HeatFlowRate Q_flow_defocus = 330 / 294.18 * Q_flow_des "Solar field thermal power at defocused state";
  // This only works if const_dispatch=true. TODO for variable disptach Q_flow_defocus should be turned into an input variable to match the field production rate to the dispatch rate to the power block.
  parameter Real nu_start = 0.6 "Minimum energy start-up fraction to start the receiver";
  parameter Real nu_min_sf = 0.3 "Minimum turn-down energy fraction to stop the receiver";
  parameter Real nu_defocus = 1 "Energy fraction to the receiver at defocus state";
  parameter Real hot_tnk_empty_lb = 5 "Hot tank empty trigger lower bound";
  // Level (below which) to stop disptach
  parameter Real hot_tnk_empty_ub = 10 "Hot tank empty trigger upper bound";
  // Level (above which) to start disptach
  parameter Real hot_tnk_full_lb = 123 "Hot tank full trigger lower bound";
  parameter Real hot_tnk_full_ub = 120 "Hot tank full trigger upper bound";
  parameter Real cold_tnk_defocus_lb = 5 "Cold tank empty trigger lower bound";
  // Level (below which) to stop disptach
  parameter Real cold_tnk_defocus_ub = 7 "Cold tank empty trigger upper bound";
  // Level (above which) to start disptach
  parameter Real cold_tnk_crit_lb = 0 "Cold tank critically empty trigger lower bound";
  // Level (below which) to stop disptach
  parameter Real cold_tnk_crit_ub = 30 "Cold tank critically empty trigger upper bound";
  // Level (above which) to start disptach
  parameter Real Ti = 0.1 "Time constant for integral component of receiver control";
  parameter Real Kp = -940 "Gain of proportional component in receiver control";
  parameter Real Ti_CS = 0.1 "Time constant for integral component of receiver control";
  parameter Real Kp_CS = -930 "Gain of proportional component in receiver control";
  //Storage Control and Calculated parameters
  parameter SI.HeatFlowRate Q_flow_des = if fixed_field then if match_sam then R_des / ((1 + rec_fr) * SM) else R_des * (1 - rec_fr) / SM else P_gross / eff_blk "Heat to power block at design";
  parameter SI.Energy E_max = t_storage * 3600 * Q_flow_des "Maximum tank stored energy";
  parameter SI.SpecificEnthalpy h_cold_set_CS = Medium2.specificEnthalpy(state_cold_set_CS) "Cold salt specific enthalpy at design";
  parameter SI.SpecificEnthalpy h_hot_set_CS = Medium2.specificEnthalpy(state_hot_set_CS) "Hot salt specific enthalpy at design";
  parameter SI.Density rho_cold_set = Medium2.density(state_cold_set_CS) "Cold salt density at design";
  parameter SI.Density rho_hot_set = Medium2.density(state_hot_set_CS) "Hot salt density at design";
  parameter SI.Mass m_max = E_max / (h_hot_set_CS - h_cold_set_CS) "Max salt mass in tanks";
  parameter SI.Volume V_max = m_max / ((rho_hot_set + rho_cold_set) / 2) "Max salt volume in tanks";
  parameter SI.MassFlowRate m_flow_fac = SM * Q_flow_des / (h_hot_set_CS - h_cold_set_CS) "Mass flow rate to receiver at design point";
  parameter SI.MassFlowRate m_flow_max_CS = 1.5 * m_flow_fac "Maximum mass flow rate to receiver";
  parameter SI.MassFlowRate m_flow_start_CS = 0.252485 * m_flow_fac "Initial or guess value of mass flow rate to receiver in the feedback controller";
  parameter SI.Length H_storage = ceil((4 * V_max * tank_ar ^ 2 / CN.pi) ^ (1 / 3)) "Storage tank height";
  parameter SI.Diameter D_storage = H_storage / tank_ar "Storage tank diameter";
  //Receiver Control and Calculated parameters
  parameter SI.HeatFlowRate Q_rec_out = Q_flow_des * SM "Heat to HX at design";
  parameter SI.SpecificEnthalpy h_cold_set_Na = Medium1.specificEnthalpy(state_cold_set_Na) "Cold Sodium specific enthalpy at design";
  parameter SI.SpecificEnthalpy h_hot_set_Na = Medium1.specificEnthalpy(state_hot_set_Na) "Hot Sodium specific enthalpy at design";
  parameter SI.MassFlowRate m_flow_rec = Q_rec_out / (h_hot_set_Na - h_cold_set_Na) "Mass flow rate to receiver at design point";
  parameter SI.MassFlowRate m_flow_max_Na = 1.135 * m_flow_rec "Maximum mass flow rate to receiver";
  parameter SI.MassFlowRate m_flow_start_Na = 0.201911 * m_flow_rec "Initial or guess value of mass flow rate to receiver in the feedback controller";
  // SF Calculated Parameters
  parameter SI.Area A_field = R_des / eff_opt / he_av_design / dni_des "Heliostat field reflective area";
  parameter Integer n_heliostat = integer(ceil(A_field / A_heliostat)) "Number of heliostats";
  parameter SI.Area A_receiver = A_field / C "Receiver aperture area";
  parameter SI.Diameter D_receiver = sqrt(A_receiver / (CN.pi * ar_rec)) "Receiver diameter";
  parameter SI.Length H_receiver = D_receiver * ar_rec "Receiver height";
  parameter SI.Area A_land = land_mult * A_field + 197434.207385281 "Land area";
  parameter SI.Length H_tower = 0.154 * sqrt(twr_ht_const * (A_field / (gnd_cvge * excl_fac)) / CN.pi) "Tower height";
  // A_field/(gnd_cvge*excl_fac) is the field gross area
  parameter SI.Diameter D_tower = D_receiver "Tower diameter";
  // That's a fair estimate. An accurate H-to-D correlation may be used.
  //Power Block Control and Calculated parameters
  parameter SI.MassFlowRate m_flow_blk = Q_flow_des / (h_hot_set_CS - h_cold_set_CS) "Mass flow rate to power block at design point";
  parameter SI.Power P_net = (1 - par_fr) * P_gross "Power block net rating at design point";
  parameter SI.Power P_name = P_net "Nameplate rating of power block";
  // Cost data in USD (default) or AUD
  parameter Real r_disc = 0.07 "Real discount rate";
  parameter Real r_i = 0.03 "Inflation rate";
  parameter Integer t_life(unit = "year") = 27 "Lifetime of plant";
  parameter Integer t_cons(unit = "year") = 3 "Years of construction";
  parameter Real r_cur = 0.71 "The currency rate from AUD to USD";
  // Valid for 2019. See https://www.rba.gov.au/
  parameter Real f_Subs = 0 "Subsidies on initial investment costs";
  parameter FI.AreaPrice pri_field = if currency == Currency.USD then 180 else 180 / r_cur "Field cost per design aperture area";
  // SAM 2018 cost data: 177*(603.1/525.4) in USD. Note that (603.1/525.4) is CEPCI index from 2007 to 2018
  parameter FI.AreaPrice pri_site = if currency == Currency.USD then 20 else 20 / r_cur "Site improvements cost per area";
  // SAM 2018 cost data: 16
  parameter FI.EnergyPrice pri_storage = if currency == Currency.USD then 37 / (1e3 * 3600) else 37 / (1e3 * 3600) / r_cur "Storage cost per energy capacity";
  // SAM 2018 cost data: 22 / (1e3 * 3600)
  parameter FI.PowerPrice pri_block = if currency == Currency.USD then 1000 / 1e3 else 1000 / r_cur "Power block cost per gross rated power";
  // SAM 2018 cost data: 1040
  parameter FI.PowerPrice pri_bop = if currency == Currency.USD then 350 / 1e3 else 350 / 1e3 / r_cur "Balance of plant cost per gross rated power";
  //SAM 2018 cost data: 290
  parameter FI.AreaPrice pri_land = if currency == Currency.USD then 10000 / 4046.86 else 10000 / 4046.86 / r_cur "Land cost per area";
  parameter Real pri_om_name(unit = "$/W/year") = if currency == Currency.USD then 56.715 / 1e3 else 56.715 / 1e3 / r_cur "Fixed O&M cost per nameplate per year";
  //SAM 2018 cost data: 66
  parameter Real pri_om_prod(unit = "$/J/year") = if currency == Currency.USD then 5.7320752 / (1e6 * 3600) else 5.7320752 / (1e6 * 3600) / r_cur "Variable O&M cost per production per year";
  //SAM 2018 cost data: 3.5
  parameter FI.Money C_field = pri_field * A_field "Field cost";
  parameter FI.Money C_site = pri_site * A_field "Site improvements cost";
  parameter FI.Money C_tower(fixed = false) "Tower cost";
  parameter FI.Money C_receiver = if currency == Currency.USD then 71708855 * (A_receiver / 879.8) ^ 0.7 else 71708855 * (A_receiver / 879.8) ^ 0.7 / r_cur "Receiver cost";
  // SAM 2018 cost data: 103e6 * (A_receiver / 1571) ^ 0.7
  parameter FI.Money C_storage = pri_storage * E_max "Storage cost";
  parameter FI.Money C_block = pri_block * P_gross "Power block cost";
  parameter FI.Money C_bop = pri_bop * P_gross "Balance of plant cost";
  parameter FI.Money C_cap_dir_sub = (1 - f_Subs) * (C_field + C_site + C_tower + C_receiver + C_storage + C_block + C_bop) "Direct capital cost subtotal";
  // i.e. purchased equipment costs
  parameter FI.Money C_contingency = 0.07 * C_cap_dir_sub "Contingency costs";
  parameter FI.Money C_cap_dir_tot = C_cap_dir_sub + C_contingency "Direct capital cost total";
  parameter FI.Money C_EPC = 0.11 * C_cap_dir_tot "Engineering, procurement and construction(EPC) and owner costs";
  // SAM 2018 cost data: 0.13
  parameter FI.Money C_land = pri_land * A_land "Land cost";
  parameter FI.Money C_cap = C_cap_dir_tot + C_EPC + C_land "Total capital (installed) cost";
  parameter FI.MoneyPerYear C_year = pri_om_name * P_name "Fixed O&M cost per year";
  parameter Real C_prod(unit = "$/J/year") = pri_om_prod "Variable O&M cost per production per year";
  // ***************************************************************************
  // System components
  //Weather data
  SolarTherm.Models.Sources.DataTable.DataTable data(lon = lon, lat = lat, t_zone = t_zone, year = year, file = wea_file) annotation(
    Placement(visible = true, transformation(extent = {{-176, -50}, {-146, -22}}, rotation = 0)));
  //DNI_input
  Modelica.Blocks.Sources.RealExpression DNI_input(y = data.DNI) annotation(
    Placement(visible = true, transformation(extent = {{-168, 58}, {-148, 78}}, rotation = 0)));
  //Tamb_input
  Modelica.Blocks.Sources.RealExpression Tamb_input(y = data.Tdry) annotation(
    Placement(visible = true, transformation(extent = {{148, 98}, {128, 118}}, rotation = 0)));
  //WindSpeed_input
  Modelica.Blocks.Sources.RealExpression Wspd_input(y = data.Wspd) annotation(
    Placement(visible = true, transformation(extent = {{-168, 20}, {-142, 40}}, rotation = 0)));
  //pressure_input
  Modelica.Blocks.Sources.RealExpression Pres_input(y = data.Pres) annotation(
    Placement(visible = true, transformation(extent = {{160, -22}, {140, -2}}, rotation = 0)));
  //parasitic inputs
  Modelica.Blocks.Sources.RealExpression parasities_input(y = heliostatsField.W_loss + pumpHot.W_loss + pumpCold1.W_loss + pumpCold2.W_loss + tankHot.W_loss + tankCold.W_loss) annotation(
    Placement(visible = true, transformation(origin = {181, 58}, extent = {{-13, -10}, {13, 10}}, rotation = -90)));
  // Or block for defocusing 1
  Modelica.Blocks.Logical.Or or1 annotation(
    Placement(visible = true, transformation(extent = {{-116, 2}, {-108, 10}}, rotation = 0)));
  // Or block for defocusing 2
  //Sun
  SolarTherm.Models.Sources.SolarModel.Sun sun(lon = data.lon, lat = data.lat, t_zone = data.t_zone, year = data.year, redeclare function solarPosition = Models.Sources.SolarFunctions.PSA_Algorithm) annotation(
    Placement(visible = true, transformation(extent = {{-116, 58}, {-96, 78}}, rotation = 0)));
  // Solar field
  SolarTherm.Models.CSP.CRS.HeliostatsField.HeliostatsField heliostatsField(n_h = n_heliostat, lon = data.lon, lat = data.lat, ele_min(displayUnit = "deg") = ele_min, use_wind = use_wind, Wspd_max = Wspd_max, he_av = he_av_design, use_on = true, use_defocus = true, A_h = A_heliostat, nu_defocus = nu_defocus, nu_min = nu_min_sf, Q_design = Q_flow_defocus, nu_start = nu_start, redeclare model Optical = Models.CSP.CRS.HeliostatsField.Optical.Table(angles = angles, file = opt_file)) annotation(
    Placement(visible = true, transformation(extent = {{-98, 2}, {-66, 36}}, rotation = 0)));
  // Receiver
  SolarTherm.Models.CSP.CRS.Receivers.SodiumReceiver_v3 receiver(em = em_rec, redeclare package Medium = Medium1, H_rcv = H_receiver, D_rcv = D_receiver, N_pa = N_pa_rec, t_tb = t_tb_rec, D_tb = D_tb_rec, ab = ab_rec, T_in_0 = T_cold_set_Na, T_out_0 = T_hot_set_Na) annotation(
    Placement(visible = true, transformation(extent = {{-56, 4}, {-20, 40}}, rotation = 0)));
  // Temperature sensor1
  SolarTherm.Models.Fluid.Sensors.Temperature temperature1(redeclare package Medium = Medium1) annotation(
    Placement(visible = true, transformation(extent = {{-16, 36}, {-6, 26}}, rotation = 0)));
  // Pump cold1
  SolarTherm.Models.Fluid.Pumps.PumpSimple pumpCold1(redeclare package Medium = Medium1, k_loss = k_loss_cold) annotation(
    Placement(visible = true, transformation(extent = {{-4, -38}, {-16, -26}}, rotation = 0)));
  //HX Control
  SolarTherm.Models.Control.HX_Control hX_Control(T_ref_rec = T_hot_set_Na, m_flow_max_rec = m_flow_max_Na, y_start_rec = m_flow_start_Na, L_df_on = cold_tnk_defocus_lb, L_df_off = cold_tnk_defocus_ub, L_off = cold_tnk_crit_lb, L_on = cold_tnk_crit_ub, Ti_rec = Ti, Kp_rec = Kp, T_ref_HX = T_hot_set_CS, m_flow_max_HX = m_flow_max_CS, y_start_HX = m_flow_start_CS, Ti_HX = Ti_CS, Kp_HX = Kp_CS) annotation(
    Placement(visible = true, transformation(origin = {40, -56}, extent = {{10, -10}, {-10, 10}}, rotation = -90)));
  //HX
  SolarTherm.Models.Fluid.HeatExchangers.HX_wi_noF_modified_v3 Shell_and_Tube_HX(replaceable package Medium1 = Medium1, replaceable package Medium2 = Medium2, Q_d_des = Q_rec_out) annotation(
    Placement(visible = true, transformation(origin = {19, 1}, extent = {{21, -21}, {-21, 21}}, rotation = 90)));
  SolarTherm.Models.Fluid.HeatExchangers.loop_breaker loop_breaker(replaceable package Medium = Medium1) annotation(
    Placement(visible = true, transformation(origin = {11, -33}, extent = {{5, -5}, {-5, 5}}, rotation = 0)));
  // Hot tank
  SolarTherm.Models.Storage.Tank.Tank tankHot(redeclare package Medium = Medium2, D = D_storage, H = H_storage, T_start = T_hot_start_CS, L_start = (1 - split_cold) * 100, alpha = alpha, use_p_top = tnk_use_p_top, enable_losses = tnk_enable_losses, use_L = true, W_max = W_heater_hot, T_set = T_hot_aux_set) annotation(
    Placement(visible = true, transformation(extent = {{48, 54}, {68, 74}}, rotation = 0)));
  // Pump hot
  SolarTherm.Models.Fluid.Pumps.PumpSimple pumpHot(redeclare package Medium = Medium2, k_loss = k_loss_hot) annotation(
    Placement(visible = true, transformation(extent = {{78, 42}, {90, 54}}, rotation = 0)));
  // Cold tank
  SolarTherm.Models.Storage.Tank.Tank tankCold(redeclare package Medium = Medium2, D = D_storage, H = H_storage, T_start = T_cold_start_CS, L_start = split_cold * 100, alpha = alpha, use_p_top = tnk_use_p_top, enable_losses = tnk_enable_losses, use_L = true, W_max = W_heater_cold, T_set = T_cold_aux_set) annotation(
    Placement(visible = true, transformation(extent = {{98, -42}, {78, -22}}, rotation = 0)));
  // Pump cold 2
  SolarTherm.Models.Fluid.Pumps.PumpSimple pumpCold2(redeclare package Medium = Medium2, k_loss = k_loss_cold) annotation(
    Placement(visible = true, transformation(extent = {{66, 8}, {54, 20}}, rotation = 0)));
  // Temperature sensor 2
  SolarTherm.Models.Fluid.Sensors.Temperature temperature2(redeclare package Medium = Medium2) annotation(
    Placement(visible = true, transformation(extent = {{26, 74}, {36, 64}}, rotation = 0)));
  // PowerBlockControl
  SolarTherm.Models.Control.PowerBlockControl controlHot(m_flow_on = m_flow_blk, L_on = hot_tnk_empty_ub, L_off = hot_tnk_empty_lb, L_df_on = hot_tnk_full_ub, L_df_off = hot_tnk_full_lb) annotation(
    Placement(visible = true, transformation(extent = {{98, 80}, {110, 66}}, rotation = 0)));
  // Power block
  SolarTherm.Models.PowerBlocks.PowerBlockModel powerBlock(redeclare package Medium = Medium2, W_des = P_gross, enable_losses = blk_enable_losses, redeclare model Cycle = Cycle, nu_min = nu_min_blk, external_parasities = external_parasities, W_base = W_base_blk, p_bo = p_blk, T_des = blk_T_amb_des, nu_net = nu_net_blk, T_in_ref = T_in_ref_blk, T_out_ref = T_out_ref_blk, Q_flow_ref = Q_flow_des, redeclare model Cooling = Cooling(T_co = T_comp_in)) annotation(
    Placement(visible = true, transformation(extent = {{102, 4}, {138, 42}}, rotation = 0)));
  // Price
  SolarTherm.Models.Analysis.Market market(redeclare model Price = Models.Analysis.EnergyPrice.Constant) annotation(
    Placement(visible = true, transformation(extent = {{140, 12}, {160, 32}}, rotation = 0)));
  // TODO Needs to be configured in instantiation if not const_dispatch. See SimpleResistiveStorage model
  SolarTherm.Models.Sources.Schedule.Scheduler sch if not const_dispatch;
  // Variables:
  SI.Power P_elec "Output power of power block";
  SI.Energy E_elec(start = 0, fixed = true, displayUnit = "MW.h") "Generate electricity";
  FI.Money R_spot(start = 0, fixed = true) "Spot market revenue";
initial equation
  if fixed_field then
    P_gross = Q_flow_des * eff_cyc;
  else
    R_des = if match_sam then SM * Q_flow_des * (1 + rec_fr) else SM * Q_flow_des / (1 - rec_fr);
  end if;
  if H_tower > 120 then
// then use concrete tower
    C_tower = if currency == Currency.USD then 3117043.67 * exp(0.0113 * H_tower) else 3117043.67 * exp(0.0113 * H_tower) / r_cur "Tower cost";
//SAM 2018 cost data: 3e6 * exp(0.0113 * H_tower) in USD
  else
// use Latticework steel tower
    C_tower = if currency == Currency.USD then 1.09025e6 * exp(0.00879 * H_tower) else 1.09025e6 * exp(0.00879 * H_tower) / r_cur "Tower cost";
// SAM 2018 cost data: 1.09025e6 * (603.1/318.4) * exp(0.00879 * H_tower)
  end if;
equation
  connect(tankHot.L, controlHot.L_mea) annotation(
    Line(points = {{68, 68}, {72, 68}, {72, 76.5}, {98, 76.5}}, color = {0, 0, 127}));
  connect(controlHot.m_flow, pumpHot.m_flow) annotation(
    Line(points = {{111, 73}, {112, 73}, {112, 58}, {84, 58}, {84, 54}}, color = {0, 0, 127}));
  connect(hX_Control.m_flow_HX, controlHot.m_flow_in) annotation(
    Line(points = {{45, -44}, {45, -22}, {48, -22}, {48, 24}, {94, 24}, {94, 69.5}, {98, 69.5}}, color = {0, 0, 127}));
  connect(controlHot.defocus, or1.u1) annotation(
    Line(points = {{104, 81}, {104, 86}, {-126, 86}, {-126, 6}, {-117, 6}}, color = {255, 0, 255}, pattern = LinePattern.Dash));
  connect(hX_Control.T_out_HX, temperature2.T) annotation(
    Line(points = {{50, -68}, {50, -88}, {60, -88}, {60, 0}, {31, 0}, {31, 64}}, color = {0, 0, 127}));
  connect(temperature2.fluid_b, tankHot.fluid_a) annotation(
    Line(points = {{36, 69}, {44, 69}, {44, 70}, {48, 70}}, color = {0, 127, 255}));
  connect(Shell_and_Tube_HX.port_b_out, temperature2.fluid_a) annotation(
    Line(points = {{10, 7}, {6, 7}, {6, 69}, {26, 69}}, color = {0, 127, 255}));
  connect(hX_Control.T_out_rec, temperature1.T) annotation(
    Line(points = {{44, -66}, {44, -66}, {44, -88}, {-20, -88}, {-20, 20}, {-10, 20}, {-10, 26}, {-10, 26}}, color = {0, 0, 127}));
  connect(hX_Control.L_mea, tankCold.L) annotation(
    Line(points = {{38, -66}, {38, -66}, {38, -74}, {70, -74}, {70, -28}, {78, -28}, {78, -28}}, color = {0, 0, 127}));
  connect(or1.u2, hX_Control.defocus) annotation(
    Line(points = {{-117, 3}, {-126, 3}, {-126, -54}, {27, -54}, {27, -56}}, color = {255, 0, 255}));
  connect(or1.y, heliostatsField.defocus) annotation(
    Line(points = {{-108, 6}, {-98, 6}, {-98, 9}}, color = {255, 0, 255}, pattern = LinePattern.Dash));
  connect(heliostatsField.on, hX_Control.sf_on) annotation(
    Line(points = {{-82, 2}, {-82, -20}, {-44, -20}, {-44, -74}, {34, -74}, {34, -67}, {33, -67}}, color = {255, 0, 255}));
  connect(hX_Control.m_flow_HX, pumpCold2.m_flow) annotation(
    Line(points = {{45, -44}, {45, -22}, {48, -22}, {48, 24}, {60, 24}, {60, 20}}, color = {0, 0, 127}));
  connect(hX_Control.m_flow_rec, pumpCold1.m_flow) annotation(
    Line(points = {{35, -44}, {34, -44}, {34, -22}, {-10, -22}, {-10, -26}}, color = {0, 0, 127}));
// Fluid connections
  connect(temperature1.fluid_b, Shell_and_Tube_HX.port_a_in) annotation(
    Line(points = {{-6, 32}, {14, 32}, {14, 14}, {14, 14}}, color = {0, 127, 255}));
  connect(receiver.fluid_b, temperature1.fluid_a) annotation(
    Line(points = {{-32, 30}, {-16, 30}, {-16, 31}}, color = {0, 127, 255}));
  connect(receiver.fluid_a, pumpCold1.fluid_b) annotation(
    Line(points = {{-34, 6}, {-26, 6}, {-26, -32}, {-16, -32}, {-16, -32}}, color = {0, 127, 255}));
  connect(loop_breaker.port_b, pumpCold1.fluid_a) annotation(
    Line(points = {{6, -33}, {6, -32}, {-4, -32}}, color = {0, 127, 255}));
  connect(Shell_and_Tube_HX.port_a_out, loop_breaker.port_a) annotation(
    Line(points = {{20, -12}, {20, -32}, {16, -32}, {16, -33}}, color = {0, 127, 255}));
  connect(pumpCold2.fluid_b, Shell_and_Tube_HX.port_b_in) annotation(
    Line(points = {{54, 14}, {34, 14}, {34, -4}, {24, -4}, {24, -4}, {24, -4}}, color = {0, 127, 255}));
  connect(tankCold.fluid_b, pumpCold2.fluid_a) annotation(
    Line(points = {{78, -38}, {72, -38}, {72, 14}, {66, 14}, {66, 14}, {66, 14}}, color = {0, 127, 255}));
  connect(receiver.Tamb, tankHot.T_amb) annotation(
    Line(points = {{-38, 36}, {-38, 80}, {54, 80}, {54, 74}}, color = {0, 0, 127}, pattern = LinePattern.Dot));
  connect(tankHot.fluid_b, pumpHot.fluid_a) annotation(
    Line(points = {{68, 58}, {72, 58}, {72, 48}, {78, 48}, {78, 48}}, color = {0, 127, 255}));
//Connections from data
  connect(Tamb_input.y, tankHot.T_amb) annotation(
    Line(points = {{127, 108}, {54, 108}, {54, 74}}, color = {0, 0, 127}, pattern = LinePattern.Dot));
  connect(parasities_input.y, powerBlock.parasities) annotation(
    Line(points = {{181, 44}, {181, 40.85}, {124, 40.85}, {124, 34}}, color = {0, 0, 127}, pattern = LinePattern.Dot));
  connect(Tamb_input.y, powerBlock.T_amb) annotation(
    Line(points = {{127, 108}, {116, 108}, {116, 34}}, color = {0, 0, 127}, pattern = LinePattern.Dot));
  connect(Wspd_input.y, heliostatsField.Wspd) annotation(
    Line(points = {{-141, 30}, {-98, 30}}, color = {0, 0, 127}, pattern = LinePattern.Dot));
  connect(Pres_input.y, tankHot.p_top) annotation(
    Line(points = {{140, -12}, {84, -12}, {84, -12}, {42, -12}, {42, 84}, {62, 84}, {62, 74}, {62, 74}}, color = {0, 0, 127}));
  connect(DNI_input.y, sun.dni) annotation(
    Line(points = {{-147, 68}, {-117, 68}}, color = {0, 0, 127}, pattern = LinePattern.Dot));
  connect(Pres_input.y, tankCold.p_top) annotation(
    Line(points = {{140, -12}, {83.5, -12}, {83.5, -22}}, color = {0, 0, 127}));
  connect(Tamb_input.y, tankCold.T_amb) annotation(
    Line(points = {{128, 108}, {116, 108}, {116, 42}, {108, 42}, {108, 20}, {92, 20}, {92, -22}, {92, -22}, {92, -22}}, color = {0, 0, 127}));
// controlHot connections
//Solar field connections i.e. solar.heat port and control
  connect(heliostatsField.on, Shell_and_Tube_HX.HF_on) annotation(
    Line(points = {{-82, 2}, {-82, -20}, {-44, -20}, {-44, -4}, {9, -4}}, color = {255, 0, 255}));
  connect(sun.solar, heliostatsField.solar) annotation(
    Line(points = {{-106, 58}, {-106, 48}, {-82, 48}, {-82, 36}}, color = {255, 128, 0}));
  connect(heliostatsField.on, receiver.on) annotation(
    Line(points = {{-82, 2}, {-82, -20}, {-44, -20}, {-44, 5}, {-41, 5}}, color = {255, 0, 255}));
  connect(heliostatsField.heat, receiver.heat) annotation(
    Line(points = {{-66, 27.5}, {-54.82, 27.5}, {-54.82, 27}, {-56, 27}}, color = {191, 0, 0}));
//PowerBlock connections
  connect(pumpHot.fluid_b, powerBlock.fluid_a) annotation(
    Line(points = {{90, 48}, {102, 48}, {102, 30}, {112, 30}, {112, 30}, {112, 30}, {112, 30}}, color = {0, 127, 255}));
  connect(powerBlock.W_net, market.W_net) annotation(
    Line(points = {{129, 22}, {140, 22}}, color = {0, 0, 127}));
  connect(tankCold.fluid_a, powerBlock.fluid_b) annotation(
    Line(points = {{98, -27}, {104, -27}, {104, 14}, {110, 14}}, color = {0, 127, 255}));
  P_elec = powerBlock.W_net;
  E_elec = powerBlock.E_net;
  R_spot = market.profit;
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -120}, {160, 140}}, initialScale = 0.1), graphics = {Text(lineColor = {217, 67, 180}, extent = {{4, 92}, {40, 90}}, textString = "defocus strategy", fontSize = 9), Text(origin = {0, -18}, lineColor = {217, 67, 180}, extent = {{-50, -40}, {-14, -40}}, textString = "on/off strategy", fontSize = 9), Text(origin = {-10, 2}, extent = {{-52, 8}, {-4, -12}}, textString = "Receiver", fontSize = 3, fontName = "CMU Serif"), Text(origin = {6, 2}, extent = {{-110, 4}, {-62, -16}}, textString = "Heliostats Field", fontSize = 3, fontName = "CMU Serif"), Text(origin = {-50, 6}, extent = {{-80, 86}, {-32, 66}}, textString = "Sun", fontSize = 3, fontName = "CMU Serif"), Text(origin = {34, 2}, extent = {{0, 58}, {48, 38}}, textString = "Hot Tank", fontSize = 3, fontName = "CMU Serif"), Text(origin = {36, -14}, extent = {{30, -24}, {78, -44}}, textString = "Cold Tank", fontSize = 3, fontName = "CMU Serif"), Text(origin = {16, 2}, extent = {{80, 12}, {128, -8}}, textString = "Power Block", fontSize = 3, fontName = "CMU Serif"), Text(origin = {14, 2}, extent = {{112, 16}, {160, -4}}, textString = "Market", fontSize = 3, fontName = "CMU Serif"), Text(origin = {22, -88}, extent = {{-6, 20}, {42, 0}}, textString = "HX Control", fontSize = 3, fontName = "CMU Serif"), Text(origin = {44, 38}, extent = {{30, 62}, {78, 42}}, textString = "Power Block Control", fontSize = 3, fontName = "CMU Serif"), Text(origin = {-38, -22}, extent = {{-146, -26}, {-98, -46}}, textString = "Data Source", fontSize = 3, fontName = "CMU Serif")}),
    Icon(coordinateSystem(extent = {{-140, -120}, {160, 140}})),
    experiment(StopTime = 3.1536e+07, StartTime = 0, Tolerance = 0.0001, Interval = 60),
    __Dymola_experimentSetupOutput,
    Documentation(revisions = "<html>
	<ul>
	<li> A. Shirazi and A. Fontalvo Lascano (June 2019) :<br>Released first version. </li>
	</ul>

	</html>"),
    uses(SolarTherm(version = "0.2")));
end Sodium_CO2System_v3;